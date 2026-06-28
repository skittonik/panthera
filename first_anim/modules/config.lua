-- config.lua
-- Loads and validates the data-driven battle configuration:
--   data/player.json   -> player loadout + stats
--   data/waves.json    -> enemy groups (waves)
--   data/enemies.json  -> reusable enemy templates
-- and ensures the skin / weapon / unit references they use actually exist.

local skins = require("first_anim.modules.skins")
local weapons = require("first_anim.modules.weapons")
local units = require("first_anim.modules.units")

local M = {}

local ENEMY_DEFAULTS = {
	hp = 80,
	move_speed = 100,
	attack_speed = 100,
	damage = 15,
	defense = 0,
}

local PLAYER_DEFAULTS = {
	name = "Survivor",
	hp = 100,
	move_speed = 130,
	attack_speed = 100,
	damage = 10,
	defense = 0,
	unit = "human",
	weapon_skin = "rifle_ak",
	body_skin = "body_armor",
	head_skin = "head_gasmask",
}

local function load_json(path)
	local str = sys.load_resource(path)
	if not str then
		error("config.lua: failed to load " .. path .. " (add it to game.project custom_resources)")
	end
	local ok, decoded = pcall(json.decode, str)
	if not ok then
		error("config.lua: failed to decode " .. path .. ": " .. tostring(decoded))
	end
	return decoded
end

local function warn(fmt, ...)
	print("config: " .. string.format(fmt, ...))
end

local function uses_weapons(unit_type)
	local u = units.get(unit_type)
	return u and u.uses_weapons
end

local function validate_unit(unit_type, context)
	if not units.exists(unit_type) then
		warn("%s uses unknown unit type '%s'", context, tostring(unit_type))
		return false
	end
	return true
end

local function validate(data)
	local p = data.player
	validate_unit(p.unit, "player")
	if p.weapon_skin and not weapons.get_weapon_def(p.weapon_skin) then
		warn("player references unknown weapon '%s'", tostring(p.weapon_skin))
	end
	if p.body_skin and not skins.get_attachment("body", p.body_skin) then
		warn("player references unknown body skin '%s'", tostring(p.body_skin))
	end
	if p.head_skin and not skins.get_attachment("head", p.head_skin) then
		warn("player references unknown head skin '%s'", tostring(p.head_skin))
	end

	for key, tmpl in pairs(data.enemies) do
		local unit_type = tmpl.unit or "human"
		if validate_unit(unit_type, "enemy '" .. key .. "'") and uses_weapons(unit_type) then
			if tmpl.weapon_skin and not weapons.get_weapon_def(tmpl.weapon_skin) then
				warn("enemy '%s' references unknown weapon '%s'", key, tostring(tmpl.weapon_skin))
			end
		end
	end
end

-- Loads, validates and returns the full config. Call once per simulation start.
function M.load()
	skins.load()
	weapons.load()
	units.load()

	local player = load_json("/first_anim/data/player.json")
	local waves = load_json("/first_anim/data/waves.json")
	local enemies = load_json("/first_anim/data/enemies.json")

	for k, v in pairs(PLAYER_DEFAULTS) do
		if player[k] == nil then player[k] = v end
	end

	local data = {
		player = player,
		groups = waves.groups or {},
		enemies = enemies or {},
	}
	validate(data)
	return data
end

-- Resolve one group entry into a complete enemy stat table.
-- entry is either a template key (string) or { key, <overrides> }.
function M.resolve_enemy(data, entry, index)
	local cfg = {}
	local key = (type(entry) == "string") and entry or (type(entry) == "table" and entry.key)

	local template = key and data.enemies[key]
	if template then
		for k, v in pairs(template) do cfg[k] = v end
	end
	if type(entry) == "table" then
		for k, v in pairs(entry) do
			if k ~= "key" then cfg[k] = v end
		end
	end

	cfg.unit = cfg.unit or "human"
	cfg.name = cfg.name or ("Enemy " .. tostring(index))
	for k, v in pairs(ENEMY_DEFAULTS) do
		if cfg[k] == nil then cfg[k] = v end
	end
	if uses_weapons(cfg.unit) and not cfg.weapon_skin then
		cfg.weapon_skin = "stabbing_common"
	end
	return cfg
end

return M
