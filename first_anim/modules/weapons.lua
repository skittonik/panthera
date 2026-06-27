-- weapons.lua
-- Weapon items: their visual attachment (sprite node + flipbook) AND their
-- gameplay data (type, range, hit timing, burst pattern, muzzle). This is the
-- single source of truth for weapons - skins.json holds no weapon data.
--
-- Equipping uses the same `resolve` addressing as skins.lua.

local M = {}

local data = nil

function M.load()
	local json_str = sys.load_resource("/first_anim/data/weapons.json")
	if not json_str then
		error("weapons.lua: failed to load /first_anim/data/weapons.json (add it to game.project custom_resources)")
	end
	data = json.decode(json_str)
end

local function ensure_loaded()
	if not data then M.load() end
end

function M.get_weapon_def(weapon_id)
	ensure_loaded()
	return data.weapons[weapon_id]
end

function M.default_weapon()
	ensure_loaded()
	return data.slot.default
end

-- Sorted list of every weapon id (used by the sandbox cycler).
function M.get_all_ids()
	ensure_loaded()
	local list = {}
	for id in pairs(data.weapons) do
		list[#list + 1] = id
	end
	table.sort(list)
	return list
end

-- Ordered { id, label } list of UI-selectable weapons.
function M.get_ui_list()
	ensure_loaded()
	local list = {}
	for id, w in pairs(data.weapons) do
		if w.show_in_ui then
			list[#list + 1] = { id = id, label = w.ui_label or id, order = w.ui_order or 999 }
		end
	end
	table.sort(list, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.id < b.id
	end)
	return list
end

-- Equip a weapon: enable its typed node, disable the others, play its flipbook.
-- Optionally takes animation states and mapping table to handle two-handed hand_right parenting dynamically.
function M.equip(resolve, weapon_id, anim_state_base, anim_state_overlay, anim_objects)
	ensure_loaded()
	local slot = data.slot
	local w = data.weapons[weapon_id]
	if not w then
		print("weapons: unknown weapon '" .. tostring(weapon_id) .. "'")
		return
	end

	for _, node_id in ipairs(slot.typed_nodes) do
		local path = resolve(node_id)
		if path then
			msg.post(path, node_id == w.node and "enable" or "disable")
		end
	end

	if w.node == "none" then
		-- Fists or no weapon
	else
		local path = resolve(w.node)
		if path then
			sprite.play_flipbook(msg.url(nil, path, slot.component), w.animation)
		end
	end

	-- Dynamic parenting for hand_right
	local function to_hash(val)
		if type(val) == "string" then
			return hash(val)
		end
		return val
	end

	local hand_right = to_hash(resolve("hand_right"))
	local weapon = to_hash(resolve("weapon"))
	local hit = to_hash(resolve("hit"))
	local dummy = to_hash(resolve("weapon_pistol")) -- Use disabled pistol GO as dummy when two-handed

	local key1 = hash("/hand_right")
	local key2 = hash("/human/hand_right")

	if w.type == "rifle" or w.type == "shotgun" then
		go.set_parent(hand_right, weapon, false)
		go.set_position(vmath.vector3(140, 52, -0.025), hand_right)
		go.set_rotation(vmath.quat(), hand_right)
		if anim_objects then
			if anim_objects[key1] then anim_objects[key1] = dummy end
			if anim_objects[key2] then anim_objects[key2] = dummy end
		end
	else
		go.set_parent(hand_right, hit, false)
		go.set_position(vmath.vector3(125, 181, -0.005), hand_right)
		go.set_rotation(vmath.quat(), hand_right)
		if anim_objects then
			if anim_objects[key1] then anim_objects[key1] = hand_right end
			if anim_objects[key2] then anim_objects[key2] = hand_right end
		end
	end

	if anim_state_base then
		anim_state_base.nodes["hand_right"] = nil
	end
	if anim_state_overlay then
		anim_state_overlay.nodes["hand_right"] = nil
	end
end

return M
