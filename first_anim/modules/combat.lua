-- combat.lua
-- The autobattle simulation: spawning, the per-frame FSM, movement/targeting,
-- attacks (data-driven timing + burst), win/lose detection and depth sorting.
--
-- Control model (driven by the panel):
--   * phase = idle | running | paused | finished
--   * PLAY starts the battle (from idle/finished) or resumes it (from paused).
--   * PAUSE freezes a running battle in place.
--   * speed (1x/2x/4x) is a pure multiplier - it never spawns or despawns.
--   * the active group is a setting, locked while a battle is in progress.
--
-- Units are spawned through unit.lua, which delegates visuals to a per-type rig,
-- so the same loop drives humans, rats and any future unit type. No UI here:
-- events go out via world.emit (phase / log / status / speed / group / loadout).

local panthera = require("panthera.panthera")
local theme = require("first_anim.modules.theme")
local config = require("first_anim.modules.config")
local weapons = require("first_anim.modules.weapons")
local projectile = require("first_anim.modules.projectile")
local dmg_number = require("first_anim.modules.dmg_number")
local Unit = require("first_anim.modules.unit")

local M = {}

-- Several discrete spawn points per role. A unit takes one point (distributed
-- across the list) plus a small random jitter, so spawns read as a loose group.
local SPAWN_POINTS = {
	player = { "/spawn_player_1", "/spawn_player_2", "/spawn_player_3" },
	melee  = { "/spawn_melee_1", "/spawn_melee_2", "/spawn_melee_3", "/spawn_melee_4", "/spawn_melee_5", "/spawn_melee_6" },
	ranged = { "/spawn_ranged_1", "/spawn_ranged_2", "/spawn_ranged_3", "/spawn_ranged_4", "/spawn_ranged_5", "/spawn_ranged_6" },
	boss   = { "/spawn_boss_1", "/spawn_boss_2", "/spawn_boss_3" },
}
local RANGED_ZONE = { pistol = true, rifle = true, shotgun = true }
local EPSILON = 0.001
local RANGE_ENTRY_DELAY = 0.3
local SHOTGUN_MAX_TARGETS = 5

-- Wave auto-scaling (GDD section 4). Enemy HP and Damage are multiplied by
--   Growth(wave) * RandomFactor * FightModifier
-- at spawn. AttackSpeed / Defense stay at base, so archetypes keep their shape.
local FIGHT_MOD = { 0.8, 1.0, 1.2 } -- fight 1 (easy) / 2 (mid) / 3 (boss)
local RANDOM_MIN, RANDOM_MAX = 0.85, 1.35 -- the difficulty "swing", rolled per fight

local function growth(n)
	return 1 + 0.05 * (n ^ 0.7)
end

local function pick(list)
	return list[math.random(#list)]
end

-- Events --------------------------------------------------------------------

local function emit_phase(world)
	world.emit({ type = "phase", phase = world.phase })
end

local function log(world, text)
	world.emit({ type = "log", text = text })
end

local function status(world, text, color)
	world.emit({ type = "status", text = text, color = color })
end

-- Spawning ------------------------------------------------------------------

local function random_in_zone(center, spread_x, spread_y)
	local x = center.x - spread_x * 0.5 + math.random() * spread_x
	local y = center.y - spread_y * 0.5 + math.random() * spread_y
	local z = theme.spawn.z_base - y / theme.spawn.z_divisor
	return vmath.vector3(x, y, z)
end

-- Pick the spawn-zone key for an enemy by role (boss name) / weapon range.
local function spawn_zone(cfg)
	if cfg.name and cfg.name:find("Boss") then
		return "boss"
	end
	if cfg.weapon_skin then
		local w = weapons.get_weapon_def(cfg.weapon_skin)
		if w and RANGED_ZONE[w.type] then
			return "ranged"
		end
	end
	return "melee"
end

local function spawn_player(world, in_battle)
	local p = world.config.player
	local pos
	if in_battle then
		pos = random_in_zone(go.get_position(pick(SPAWN_POINTS.player)), theme.spawn.spread_x, theme.spawn.spread_y)
	else
		local center = go.get_position(SPAWN_POINTS.player[1])
		pos = vmath.vector3(center.x, center.y, theme.spawn.z_base - center.y / theme.spawn.z_divisor)
	end

	local unit = Unit.spawn({
		unit_type = p.unit or "human",
		pos = pos,
		is_enemy = false,
		cfg = {
			name = p.name, hp = p.hp, move_speed = p.move_speed,
			attack_speed = p.attack_speed, damage = p.damage, defense = p.defense,
			weapon_skin = world.loadout.weapon,
			body_skin = world.loadout.body,
			head_skin = world.loadout.head,
		},
	})
	world.player = unit

	if in_battle then
		unit:ensure_anim("walk", true)
	else
		unit:ensure_anim("idle", true)
	end
	unit:position_hp_bar()
end

local function destroy_enemies(world)
	for _, e in ipairs(world.enemies) do
		e:destroy()
	end
	world.enemies = {}
end

local function spawn_enemies(world)
	destroy_enemies(world)

	local battle = world.active_battle
	local group = world.config.groups[battle] or world.config.groups[1]
	-- One swing per fight: every enemy in this fight shares the same roll, so the
	-- whole wave reads as a single difficulty spike/dip ("качели").
	local rand = RANDOM_MIN + math.random() * (RANDOM_MAX - RANDOM_MIN)
	world.scale = growth(world.wave) * rand * (FIGHT_MOD[battle] or 1.0)

	local used = {} -- per-zone counter, so enemies fan out across that zone's points
	for i, entry in ipairs(group.enemies) do
		local cfg = config.resolve_enemy(world.config, entry, i)
		-- Scale HP / Damage only (doc): keeps AttackSpeed and Defense archetypal.
		cfg.hp = math.max(1, math.floor(cfg.hp * world.scale + 0.5))
		cfg.damage = math.max(1, math.floor(cfg.damage * world.scale + 0.5))
		local zone = spawn_zone(cfg)
		local points = SPAWN_POINTS[zone]
		used[zone] = (used[zone] or 0) + 1
		local point = points[((used[zone] - 1) % #points) + 1]

		local pos = random_in_zone(go.get_position(point), theme.spawn.spread_x, theme.spawn.spread_y)
		local unit = Unit.spawn({ unit_type = cfg.unit, pos = pos, is_enemy = true, cfg = cfg })
		unit:ensure_anim("walk", true)
		unit:position_hp_bar()
		world.enemies[#world.enemies + 1] = unit
	end
end

-- Tint the spawn markers by role (kept at authored size) so the discrete
-- spawn points are visible in-scene.
local function decorate_points()
	local function tint(list, color)
		for _, name in ipairs(list) do
			go.set(name .. "#sprite", "tint", color)
		end
	end
	tint(SPAWN_POINTS.player, theme.color.zone.player)
	tint(SPAWN_POINTS.melee, theme.color.zone.melee)
	tint(SPAWN_POINTS.ranged, theme.color.zone.ranged)
	tint(SPAWN_POINTS.boss, theme.color.zone.boss)
end

-- Combat --------------------------------------------------------------------

local function get_closest_enemy(world, from_pos)
	local best, best_sq = nil, math.huge
	for _, e in ipairs(world.enemies) do
		if e:is_alive() then
			local ep = e:get_position()
			local dx, dy = ep.x - from_pos.x, ep.y - from_pos.y
			local sq = dx * dx + dy * dy
			if sq < best_sq then best, best_sq = e, sq end
		end
	end
	return best
end

-- Enemies within `radius` of `center`, nearest first, capped to `max`.
local function get_enemies_in_radius(world, center, radius, max)
	local r2 = radius * radius
	local hits = {}
	for _, e in ipairs(world.enemies) do
		if e:is_alive() then
			local ep = e:get_position()
			local dx, dy = ep.x - center.x, ep.y - center.y
			local d2 = dx * dx + dy * dy
			if d2 <= r2 then hits[#hits + 1] = { unit = e, d2 = d2 } end
		end
	end
	table.sort(hits, function(a, b) return a.d2 < b.d2 end)
	local out = {}
	for i = 1, math.min(#hits, max or #hits) do out[i] = hits[i].unit end
	return out
end

local function perform_attack(world, attacker, defender)
	attacker.attacking = true
	attacker.attack_timer = 0
	attacker:attack(function() attacker.attacking = false end)

	local denom = math.max(world.speed, EPSILON)
	local ctx = world.dmg_ctx
	local slow = attacker.slow
	local kb = attacker.knockback
	-- Shotgun splash only makes sense for the player vs the enemy crowd.
	local splash = (not attacker.is_enemy) and attacker.splash_radius or nil

	local function hit_one(target, amount)
		if not (target:is_alive()) then return end
		-- Armor (doc): FinalDamage = Damage * 100 / (100 + Defense). Per-target so
		-- splash mitigates correctly, and the log shows the real post-armor number.
		local dmg = math.floor(amount * 100 / (100 + target.defense) + 0.5)
		-- knockback is a visual recoil only (no logical displacement), so the FSM
		-- never chases a shoved target.
		local result = target:apply_damage(dmg, ctx, kb)
		if slow and result ~= "already_dead" then
			target:apply_slow(slow.factor, slow.duration)
		end
		if result == "dead" then
			log(world, string.format("%s defeated %s!", attacker.name, target.name))
		elseif result == "hit" then
			log(world, string.format("%s hit %s for %d DMG!", attacker.name, target.name, dmg))
		end
	end

	-- amount is per-target; splash deals it to everyone in the blast radius.
	local function deal(amount)
		return function()
			if world.phase ~= "running" or not attacker:is_alive() then return end
			if splash then
				local center = defender:get_position()
				local cap = attacker.max_targets or SHOTGUN_MAX_TARGETS
				for _, t in ipairs(get_enemies_in_radius(world, center, splash, cap)) do
					hit_one(t, amount)
				end
			else
				hit_one(defender, amount)
			end
		end
	end

	local total = math.floor(attacker.damage * (attacker.damage_mult or 1.0) + 0.5)
	if attacker.burst then
		local shots = attacker.burst.shots
		local per = math.floor(total / shots)
		for i = 1, shots do
			local amount = (i == shots) and (total - per * (shots - 1)) or per
			local delay = attacker.burst.delays[i] or attacker.hit_delay or 0.12
			timer.delay(delay / denom, false, deal(amount))
		end
	else
		timer.delay((attacker.hit_delay or 0.12) / denom, false, deal(total))
	end

	-- Cosmetic flying bullets over the hitscan damage above.
	if projectile.is_ranged(attacker.weapon_def) then
		projectile.launch(attacker, attacker.weapon_def, defender:aim_world_position(), denom)
	end
end

-- Drive one unit toward its target: walk in range, then attack on cooldown.
local function advance(world, unit, target, sim_dt)
	if unit.attacking then return end

	local upos = unit:get_position()
	local tpos = target:get_position()
	local dx, dy = tpos.x - upos.x, tpos.y - upos.y
	local dist = math.sqrt(dx * dx + dy * dy)

	unit.attack_timer = math.min(unit.attack_timer + sim_dt, unit.attack_cooldown)

	if dist <= unit.attack_range then
		if not unit.in_range then
			unit.in_range = true
			unit.range_entry_timer = 0
		end
		unit.range_entry_timer = unit.range_entry_timer + sim_dt
		if unit.attack_timer >= unit.attack_cooldown and unit.range_entry_timer >= RANGE_ENTRY_DELAY then
			perform_attack(world, unit, target)
		else
			unit:ensure_anim("idle", true)
		end
	else
		unit.in_range = false
		unit:ensure_anim("walk", true)
		if dist > EPSILON then
			local speed = unit.move_speed * unit.slow_mult
			upos.x = upos.x + (dx / dist) * speed * sim_dt
			upos.y = upos.y + (dy / dist) * speed * sim_dt
			unit:set_position(upos)
		end
	end
end

-- Paint units back-to-front by Y so rigs never interleave.
local function zsort(world)
	local alive = {}
	if world.player and world.player:is_alive() then alive[#alive + 1] = world.player end
	for _, e in ipairs(world.enemies) do
		if e:is_alive() then alive[#alive + 1] = e end
	end
	table.sort(alive, function(a, b) return a:get_position().y > b:get_position().y end)
	for i, unit in ipairs(alive) do
		unit:set_z(theme.zsort.base + i * theme.zsort.step)
	end
end

-- Lifecycle -----------------------------------------------------------------

local function cleanup(world)
	if world.player then
		world.player:destroy()
		world.player = nil
	end
	destroy_enemies(world)
	for _, path in ipairs(world.smudges) do
		go.delete(path, true)
	end
	world.smudges = {}
end

-- Reset to the editable setup screen: player idle at spawn, no enemies.
local function setup_idle(world)
	cleanup(world)
	spawn_player(world, false)
	world.phase = "idle"
	panthera.SPEED = 1

	emit_phase(world)
	world.emit({ type = "speed", speed = world.speed })
	world.emit({ type = "battle", battle = world.active_battle })
	world.emit({ type = "wave", wave = world.wave })
	world.emit({ type = "loadout", weapon = world.loadout.weapon, body = world.loadout.body, head = world.loadout.head })
	status(world, "READY - PRESS PLAY", theme.color.status_paused)
end

-- Summed analytic Power of a unit list, for the at-a-glance matchup readout.
local function total_power(units)
	local sum = 0
	for _, u in ipairs(units) do sum = sum + (u.power or 0) end
	return sum
end

-- Spawn a fresh battle for the current group and start fighting.
local function begin_battle(world)
	cleanup(world)
	spawn_player(world, true)
	spawn_enemies(world)
	world.phase = "running"
	panthera.SPEED = world.speed

	emit_phase(world)
	local group = world.config.groups[world.active_battle] or world.config.groups[1]
	log(world, string.format("Wave %d - Fight %d  (x%.2f)", world.wave, world.active_battle, world.scale))
	log(world, string.format("%s", group.name or "Wave"))
	log(world, string.format("Power  You: %d  vs  Enemies: %d",
		world.player.power, total_power(world.enemies)))
	status(world, "BATTLE IN PROGRESS", theme.color.status_battle)
end

function M.new(opts)
	local world = {
		emit = opts.emit,
		player = nil,
		enemies = {},
		smudges = {},
		phase = "idle",
		speed = 1,
		active_battle = 1,
		wave = 1,
		scale = 1,
		loadout = nil,
		config = nil,
	}
	world.dmg_ctx = {
		smudge_factory = opts.smudge_factory_url,
		track = function(path) world.smudges[#world.smudges + 1] = path end,
	}
	projectile.init(opts.bullet_factory_url)
	dmg_number.init(opts.dmg_factory_url)
	return world
end

-- Initial boot: load config, show the setup screen.
function M.start(world)
	world.config = config.load()
	if not world.loadout then
		local p = world.config.player
		world.loadout = { weapon = p.weapon_skin, body = p.body_skin, head = p.head_skin }
	end
	decorate_points()
	setup_idle(world)
end

function M.update(world, dt)
	if world.phase ~= "running" then return end

	local sim_dt = dt * world.speed
	local player = world.player

	if not player or not player:is_alive() then
		world.phase = "finished"
		panthera.SPEED = 1
		for _, e in ipairs(world.enemies) do
			if e:is_alive() then e:ensure_anim("idle", true) end
		end
		emit_phase(world)
		log(world, "Defeat! Survivor perished.")
		status(world, "DEFEAT!", theme.color.status_defeat)
		return
	end

	local target = get_closest_enemy(world, player:get_position())
	if not target then
		world.phase = "finished"
		panthera.SPEED = 1
		player:ensure_anim("idle", true)
		emit_phase(world)
		log(world, "Victory! All enemies defeated!")
		status(world, "VICTORY!", theme.color.status_victory)
		return
	end

	advance(world, player, target, sim_dt)
	player:update_slow(sim_dt)
	player:position_hp_bar()

	for _, e in ipairs(world.enemies) do
		if e:is_alive() then
			advance(world, e, player, sim_dt)
			e:update_slow(sim_dt)
			e:position_hp_bar()
		end
	end

	zsort(world)
end

-- Controls ------------------------------------------------------------------

function M.play(world)
	if world.phase == "running" then
		return
	elseif world.phase == "paused" then
		world.phase = "running"
		panthera.SPEED = world.speed
		emit_phase(world)
		status(world, "BATTLE IN PROGRESS", theme.color.status_battle)
	else
		begin_battle(world)
	end
end

function M.pause(world)
	if world.phase ~= "running" then return end
	world.phase = "paused"
	panthera.SPEED = 1
	if world.player and world.player:is_alive() then
		world.player.attacking = false
		world.player:ensure_anim("idle", true)
	end
	for _, e in ipairs(world.enemies) do
		if e:is_alive() then
			e.attacking = false
			e:ensure_anim("idle", true)
		end
	end
	emit_phase(world)
	status(world, "PAUSED", theme.color.status_paused)
end

function M.set_speed(world, speed)
	world.speed = speed
	if world.phase == "running" then
		panthera.SPEED = speed
	end
	world.emit({ type = "speed", speed = speed })
end

-- Battle = which of the 3 fights (composition + FightModifier). Locked mid-battle.
function M.set_battle(world, battle)
	if world.phase == "running" or world.phase == "paused" then return end
	world.active_battle = math.max(1, math.min(#world.config.groups, battle))
	world.emit({ type = "battle", battle = world.active_battle })
end

-- Wave = difficulty level n driving Growth(n). Unbounded upward. Locked mid-battle.
function M.set_wave(world, wave)
	if world.phase == "running" or world.phase == "paused" then return end
	world.wave = math.max(1, wave)
	world.emit({ type = "wave", wave = world.wave })
end

function M.reset(world)
	setup_idle(world)
end

function M.set_loadout(world, weapon, body, head)
	world.loadout = { weapon = weapon, body = body, head = head }
	if world.phase ~= "running" and world.player and world.player:is_alive() then
		world.player:set_equipment(weapon, body, head)
	end
end

return M
