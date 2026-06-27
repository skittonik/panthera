-- config.lua
-- Loads and validates the data-driven battle configuration:
--   autobattle_config.json  -> player loadout + enemy groups (waves)
--   enemies_config.json     -> reusable enemy templates
-- Resolves enemy group entries (template ref or inline override) into full
-- stat tables, and validates that every skin reference exists in skins.json.

local skins = require("first_anim.skins")

local M = {}

-- Stat defaults applied when a config entry omits a field.
local ENEMY_DEFAULTS = {
	hp = 80,
	move_speed = 100,
	attack_cooldown = 1.5,
	damage = 15,
	weapon_skin = "stabbing_common",
}

local PLAYER_DEFAULTS = {
	name = "Survivor",
	hp = 220,
	move_speed = 130,
	attack_cooldown = 1.2,
	damage = 30,
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

-- Warn (don't crash) if a skin reference points at something that doesn't exist.
local function check_skin(slot, attachment_id, context)
	if attachment_id and not skins.get_attachment(slot, attachment_id) then
		print(string.format("config: %s references unknown %s skin '%s'", context, slot, tostring(attachment_id)))
	end
end

local function validate(data)
	local p = data.player
	check_skin("weapon", p.weapon_skin, "player")
	check_skin("body", p.body_skin, "player")
	check_skin("head", p.head_skin, "player")
	for key, tmpl in pairs(data.enemies) do
		check_skin("weapon", tmpl.weapon_skin, "enemy '" .. key .. "'")
	end
end

-- Loads, validates and returns the full config table. Call once per simulation.
function M.load()
	skins.load()
	local battle = load_json("/first_anim/autobattle_config.json")
	local enemies = load_json("/first_anim/enemies_config.json")

	local data = {
		player = battle.player or {},
		groups = battle.groups or {},
		enemies = enemies or {},
	}

	-- Fill player defaults for any missing field.
	for k, v in pairs(PLAYER_DEFAULTS) do
		if data.player[k] == nil then data.player[k] = v end
	end

	validate(data)
	return data
end

-- Resolve one group entry into a complete enemy stat table.
-- entry is either a template key (string) or { key, <overrides> }.
function M.resolve_enemy(data, entry, index)
	local cfg = {}
	local key

	if type(entry) == "string" then
		key = entry
	elseif type(entry) == "table" then
		key = entry.key
	end

	local template = key and data.enemies[key]
	if template then
		for k, v in pairs(template) do cfg[k] = v end
	end
	if type(entry) == "table" then
		for k, v in pairs(entry) do
			if k ~= "key" then cfg[k] = v end
		end
	end

	cfg.name = cfg.name or ("Zombie " .. tostring(index))
	for k, v in pairs(ENEMY_DEFAULTS) do
		if cfg[k] == nil then cfg[k] = v end
	end
	return cfg
end

return M
