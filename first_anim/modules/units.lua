-- units.lua
-- The registry of unit *types* (not only "human"). Each type names the rig
-- module that draws/animates it, the factory component that spawns it, whether
-- it equips weapons, and (for weaponless types) its built-in melee combat data.
--
-- Rig modules are required statically here so the bundler always includes them.

local rig_human = require("first_anim.modules.rig_human")
local rig_quadruped = require("first_anim.modules.rig_quadruped")

local M = {}

local RIGS = {
	human = rig_human,
	quadruped = rig_quadruped,
}

local data = nil

function M.load()
	local json_str = sys.load_resource("/first_anim/data/units.json")
	if not json_str then
		error("units.lua: failed to load /first_anim/data/units.json (add it to game.project custom_resources)")
	end
	data = json.decode(json_str)
end

local function ensure_loaded()
	if not data then M.load() end
end

function M.get(unit_type)
	ensure_loaded()
	return data[unit_type]
end

function M.exists(unit_type)
	return M.get(unit_type) ~= nil
end

-- The rig module implementing a unit type's visuals/animation.
function M.get_rig(unit_type)
	local def = M.get(unit_type)
	return def and RIGS[def.rig] or nil
end

return M
