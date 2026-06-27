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
-- It owns no UI: it pushes named events through `world.emit` (phase / log /
-- status / speed / group / loadout) and lets the controller route them.

local panthera = require("panthera.panthera")
local skins = require("first_anim.skins")
local fx = require("first_anim.fx")
local theme = require("first_anim.theme")
local config = require("first_anim.config")
local Unit = require("first_anim.unit")

local M = {}

local SPAWN = {
	player = "/spawn_player",
	melee  = "/spawn_melee",
	ranged = "/spawn_ranged",
	boss   = "/spawn_boss",
}
local RANGED = { pistol = true, rifle = true, shotgun = true }
local EPSILON = 0.001

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

local function spawn_player(world, in_battle)
	local p = world.config.player
	local center = go.get_position(SPAWN.player)
	local pos
	if in_battle then
		pos = random_in_zone(center, theme.spawn.player.spread_x, theme.spawn.player.spread_y)
	else
		pos = vmath.vector3(center.x, center.y, theme.spawn.z_base - center.y / theme.spawn.z_divisor)
	end

	local unit = Unit.spawn({
		factory_url = world.factory_url,
		pos = pos,
		is_enemy = false,
		cfg = {
			name = p.name, hp = p.hp, move_speed = p.move_speed,
			attack_cooldown = p.attack_cooldown, damage = p.damage,
			weapon_skin = world.loadout.weapon,
			body_skin = world.loadout.body,
			head_skin = world.loadout.head,
		},
	})
	world.player = unit

	if in_battle then
		unit:ensure_anim("walk", true)
		unit:set_hp_bar_visible(true)
	else
		unit:ensure_anim("default", true)
		unit:set_hp_bar_visible(false)
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

	local group = world.config.groups[world.active_group] or world.config.groups[1]
	for i, entry in ipairs(group.enemies) do
		local cfg = config.resolve_enemy(world.config, entry, i)
		local wtype = skins.get_weapon_type(cfg.weapon_skin) or "impact"

		local spawn_name = SPAWN.melee
		if cfg.name:find("Boss") then
			spawn_name = SPAWN.boss
		elseif RANGED[wtype] then
			spawn_name = SPAWN.ranged
		end

		local pos = random_in_zone(go.get_position(spawn_name), theme.spawn.enemy.spread_x, theme.spawn.enemy.spread_y)
		local unit = Unit.spawn({ factory_url = world.factory_url, pos = pos, is_enemy = true, cfg = cfg })
		unit:ensure_anim("walk", true)
		unit:position_hp_bar()
		world.enemies[#world.enemies + 1] = unit
	end
end

-- Combat --------------------------------------------------------------------

local function get_next_alive_enemy(world)
	for _, e in ipairs(world.enemies) do
		if e:is_alive() then return e end
	end
	return nil
end

local function perform_attack(world, attacker, defender)
	attacker.attacking = true
	attacker.attack_timer = 0
	local def = attacker.weapon_def
	fx.muzzle(attacker.resolve, attacker.is_enemy, def)

	attacker:play(attacker.attack_animation, {
		is_loop = false,
		callback = function() attacker.attacking = false end,
	})

	local denom = math.max(world.speed, EPSILON)
	local ctx = world.dmg_ctx
	local function deal(amount)
		return function()
			if world.phase == "running" and attacker:is_alive() and defender:is_alive() then
				local result = defender:apply_damage(amount, ctx)
				if result == "dead" then
					log(world, string.format("%s defeated %s!", attacker.name, defender.name))
				elseif result == "hit" then
					log(world, string.format("%s hit %s for %d DMG!", attacker.name, defender.name, amount))
				end
			end
		end
	end

	if def and def.burst then
		-- Automatic weapon: split damage across the burst's shots.
		local shots = def.burst.shots
		local per = math.floor(attacker.damage / shots)
		for i = 1, shots do
			local amount = (i == shots) and (attacker.damage - per * (shots - 1)) or per
			local delay = def.burst.delays[i] or def.hit_delay or 0.12
			timer.delay(delay / denom, false, deal(amount))
		end
	else
		local delay = (def and def.hit_delay) or 0.12
		timer.delay(delay / denom, false, deal(attacker.damage))
	end
end

-- Drive one unit toward its target: walk in range, then attack on cooldown.
local function advance(world, unit, target, sim_dt)
	if unit.attacking then return end

	local upos = unit:get_position()
	local tpos = target:get_position()
	local dx, dy = tpos.x - upos.x, tpos.y - upos.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if dist <= unit.attack_range then
		unit.attack_timer = unit.attack_timer + sim_dt
		if unit.attack_timer >= unit.attack_cooldown then
			perform_attack(world, unit, target)
		else
			unit:ensure_anim("default", true)
		end
	else
		unit:ensure_anim("walk", true)
		if dist > EPSILON then
			upos.x = upos.x + (dx / dist) * unit.move_speed * sim_dt
			upos.y = upos.y + (dy / dist) * unit.move_speed * sim_dt
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
	world.emit({ type = "group", group_id = world.active_group })
	world.emit({ type = "loadout", weapon = world.loadout.weapon, body = world.loadout.body, head = world.loadout.head })
	status(world, "READY - PRESS PLAY", theme.color.status_paused)
end

-- Spawn a fresh battle for the current group and start fighting.
local function begin_battle(world)
	cleanup(world)
	spawn_player(world, true)
	spawn_enemies(world)
	world.phase = "running"
	panthera.SPEED = world.speed

	emit_phase(world)
	local group = world.config.groups[world.active_group] or world.config.groups[1]
	log(world, string.format("Simulating %s", group.name or "Wave"))
	status(world, "BATTLE IN PROGRESS", theme.color.status_battle)
end

function M.new(opts)
	local world = {
		emit = opts.emit,
		factory_url = opts.factory_url,
		smudge_factory_url = opts.smudge_factory_url,
		player = nil,
		enemies = {},
		smudges = {},
		phase = "idle",
		speed = 1,
		active_group = 1,
		loadout = nil,
		config = nil,
	}
	world.dmg_ctx = {
		smudge_factory = world.smudge_factory_url,
		track = function(path) world.smudges[#world.smudges + 1] = path end,
	}
	return world
end

-- Initial boot: load config, show the setup screen.
function M.start(world)
	world.config = config.load()
	if not world.loadout then
		local p = world.config.player
		world.loadout = { weapon = p.weapon_skin, body = p.body_skin, head = p.head_skin }
	end
	setup_idle(world)
end

function M.update(world, dt)
	if world.phase ~= "running" then return end

	local sim_dt = dt * world.speed
	local player = world.player

	if not player or not player:is_alive() then
		world.phase = "finished"
		for _, e in ipairs(world.enemies) do
			if e:is_alive() then e:ensure_anim("default", true) end
		end
		emit_phase(world)
		log(world, "Defeat! Survivor perished.")
		status(world, "DEFEAT!", theme.color.status_defeat)
		return
	end

	local target = get_next_alive_enemy(world)
	if not target then
		world.phase = "finished"
		player:ensure_anim("default", true)
		emit_phase(world)
		log(world, "Victory! All enemies defeated!")
		status(world, "VICTORY!", theme.color.status_victory)
		return
	end

	advance(world, player, target, sim_dt)
	player:position_hp_bar()

	for _, e in ipairs(world.enemies) do
		if e:is_alive() then
			advance(world, e, player, sim_dt)
			e:position_hp_bar()
		end
	end

	zsort(world)
end

-- Controls ------------------------------------------------------------------

-- PLAY: start (idle/finished) or resume (paused). No-op while running.
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

-- PAUSE: freeze a running battle in place. No-op otherwise.
function M.pause(world)
	if world.phase ~= "running" then return end
	world.phase = "paused"
	panthera.SPEED = 1
	if world.player and world.player:is_alive() then
		world.player.attacking = false
		world.player:ensure_anim("default", true)
	end
	for _, e in ipairs(world.enemies) do
		if e:is_alive() then
			e.attacking = false
			e:ensure_anim("default", true)
		end
	end
	emit_phase(world)
	status(world, "PAUSED", theme.color.status_paused)
end

-- Speed is a pure multiplier; it only touches playback while running.
function M.set_speed(world, speed)
	world.speed = speed
	if world.phase == "running" then
		panthera.SPEED = speed
	end
	world.emit({ type = "speed", speed = speed })
end

-- Group is a setting; locked while a battle is in progress.
function M.set_group(world, group_id)
	if world.phase == "running" or world.phase == "paused" then return end
	world.active_group = group_id
	world.emit({ type = "group", group_id = group_id })
end

-- Loadout edits apply live to the standing player; ignored while running.
function M.set_loadout(world, weapon, body, head)
	world.loadout = { weapon = weapon, body = body, head = head }
	if world.phase ~= "running" and world.player then
		world.player:set_equipment(weapon, body, head)
	end
end

return M
