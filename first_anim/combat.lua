-- combat.lua
-- The autobattle simulation: spawning, the per-frame FSM, movement/targeting,
-- attacks (data-driven timing + burst), win/lose detection and depth sorting.
--
-- It owns no UI: it pushes named events through `world.emit` (log / status /
-- speed / group / loadout) and lets the controller route them to the panel.

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

local function spawn_player(world)
	local p = world.config.player
	local center = go.get_position(SPAWN.player)
	local pos
	if world.speed > 0 then
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

	if world.speed > 0 then
		unit.state = "walk"
		unit:play("walk", { is_loop = true })
		unit:set_hp_bar_visible(true)
	else
		unit.state = "idle"
		unit:play("default", { is_loop = true })
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
		unit.state = "walk"
		unit:play("walk", { is_loop = true })
		unit:position_hp_bar()
		world.enemies[#world.enemies + 1] = unit
	end

	if world.player then
		world.player.state = "walk"
		world.player:play("walk", { is_loop = true })
		world.player:set_hp_bar_visible(true)
	end

	world.state = "fighting"
	log(world, string.format("Simulating %s", group.name or "Wave"))
	status(world, "BATTLE IN PROGRESS", theme.color.status_battle)
end

-- Combat --------------------------------------------------------------------

local function get_next_alive_enemy(world)
	for _, e in ipairs(world.enemies) do
		if e:is_alive() then return e end
	end
	return nil
end

local function perform_attack(world, attacker, defender)
	attacker.state = "attack"
	attacker.attack_timer = 0
	local def = attacker.weapon_def
	fx.muzzle(attacker.resolve, attacker.is_enemy, def)

	attacker:play(attacker.attack_animation, {
		is_loop = false,
		callback = function()
			if attacker.state == "attack" then
				attacker.state = "attack_cooldown"
			end
		end,
	})

	local denom = math.max(world.speed, EPSILON)
	local ctx = world.dmg_ctx
	local function deal(amount)
		return function()
			if world.state == "fighting" and attacker:is_alive() and defender:is_alive() then
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
	local upos = unit:get_position()
	local tpos = target:get_position()
	local dx, dy = tpos.x - upos.x, tpos.y - upos.y
	local dist = math.sqrt(dx * dx + dy * dy)

	if dist <= unit.attack_range then
		if unit.state == "walk" then
			unit.state = "attack_cooldown"
			unit:play("default", { is_loop = true })
		end
		if unit.state == "attack_cooldown" then
			unit.attack_timer = unit.attack_timer + sim_dt
			if unit.attack_timer >= unit.attack_cooldown then
				perform_attack(world, unit, target)
			end
		end
	else
		if unit.state ~= "walk" and unit.state ~= "attack" then
			unit.state = "walk"
			unit:play("walk", { is_loop = true })
		end
		if unit.state == "walk" and dist > EPSILON then
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

function M.new(opts)
	local world = {
		emit = opts.emit,
		factory_url = opts.factory_url,
		smudge_factory_url = opts.smudge_factory_url,
		player = nil,
		enemies = {},
		smudges = {},
		state = "paused",
		speed = 0,
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

-- Full (re)start: reload config, respawn everything for the current speed.
function M.start(world)
	world.config = config.load()

	if not world.loadout then
		local p = world.config.player
		world.loadout = { weapon = p.weapon_skin, body = p.body_skin, head = p.head_skin }
	end

	cleanup(world)
	spawn_player(world)

	if world.speed > 0 then
		spawn_enemies(world)
	else
		world.state = "paused"
		world.emit({ type = "speed", speed = world.speed })
		world.emit({ type = "group", group_id = world.active_group })
		world.emit({ type = "loadout", weapon = world.loadout.weapon, body = world.loadout.body, head = world.loadout.head })
		status(world, "PAUSED - EDIT LOADOUT", theme.color.status_paused)
	end
end

function M.update(world, dt)
	if world.state ~= "fighting" then return end

	local sim_dt = dt * world.speed
	local player = world.player

	if not player or not player:is_alive() then
		world.state = "defeat"
		for _, e in ipairs(world.enemies) do
			if e:is_alive() then e:play("default", { is_loop = true }) end
		end
		log(world, "Defeat! Survivor perished.")
		status(world, "DEFEAT!", theme.color.status_defeat)
		return
	end

	local target = get_next_alive_enemy(world)
	if not target then
		world.state = "victory"
		player:play("default", { is_loop = true })
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

local function pause(world)
	world.state = "paused"
	destroy_enemies(world)

	local p = world.player
	if p then
		p:set_position(go.get_position(SPAWN.player))
		p:revive()
		p:set_hp_bar_visible(false)
		p:position_hp_bar()
	end

	status(world, "PAUSED - EDIT LOADOUT", theme.color.status_paused)
end

function M.set_speed(world, speed)
	local prev = world.speed
	world.speed = speed
	if speed == 0 then
		panthera.SPEED = 1
		world.emit({ type = "speed", speed = 0 })
		log(world, "Simulation PAUSED")
		pause(world)
	else
		panthera.SPEED = speed
		world.emit({ type = "speed", speed = speed })
		log(world, string.format("Speed changed to %dx", speed))
		if prev == 0 then
			spawn_enemies(world)
		end
	end
end

function M.select_group(world, group_id)
	world.active_group = group_id
	M.start(world)
end

function M.set_loadout(world, weapon, body, head)
	world.loadout = { weapon = weapon, body = body, head = head }
	if world.speed == 0 then
		if world.player then
			world.player:set_equipment(weapon, body, head)
		end
	else
		M.start(world)
	end
end

return M
