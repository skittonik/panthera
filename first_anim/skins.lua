-- skins.lua
-- Facade over skins.json: the single source of truth for attachments and the
-- combat/UI metadata attached to weapons.
--
-- Addressing is unified through a `resolve` function: resolve(node_id) -> go path
-- (or nil). This lets the same code drive both factory-spawned rigs (path table)
-- and statically placed rigs (string prefix). Build one with the helpers below.

local M = {}

local DEFAULT_ATTACK_RANGE = 70

local data = nil

function M.load()
	local json_str = sys.load_resource("/first_anim/skins.json")
	if not json_str then
		error("skins.lua: failed to load /first_anim/skins.json (add it to game.project custom_resources)")
	end
	data = json.decode(json_str)
end

local function ensure_loaded()
	if not data then M.load() end
end

-- Resolver builders ---------------------------------------------------------

-- For collectionfactory.create results: p_ids maps relative hashes to go ids.
function M.resolver_from_factory(p_ids)
	return function(node_id)
		return p_ids[hash("/human/" .. node_id)]
	end
end

-- For statically placed rigs (e.g. the sandbox), addressed by a path prefix.
function M.resolver_from_prefix(prefix)
	return function(node_id)
		return prefix .. "/" .. node_id
	end
end

-- Lookups -------------------------------------------------------------------

function M.get_slot(slot_name)
	ensure_loaded()
	return data.slots[slot_name]
end

function M.get_attachment(slot_name, attachment_id)
	local slot = M.get_slot(slot_name)
	return slot and slot.attachments[attachment_id] or nil
end

-- Full weapon definition table (type, ranges, timings, muzzle, burst, ...).
function M.get_weapon_def(attachment_id)
	return M.get_attachment("weapon", attachment_id)
end

function M.get_weapon_type(attachment_id)
	local def = M.get_weapon_def(attachment_id)
	return def and def.type or nil
end

function M.get_attack_range(attachment_id)
	local def = M.get_weapon_def(attachment_id)
	return def and def.attack_range or DEFAULT_ATTACK_RANGE
end

function M.get_attack_animation(attachment_id)
	local def = M.get_weapon_def(attachment_id)
	if def and def.attack_animation then return def.attack_animation end
	return "attack_" .. (def and def.type or "impact")
end

function M.get_muzzle_offset(attachment_id)
	local def = M.get_weapon_def(attachment_id)
	if def and def.muzzle and def.muzzle.offset then
		return vmath.vector3(def.muzzle.offset.x, def.muzzle.offset.y, 0)
	end
	return nil
end

function M.default_attachment(slot_name)
	local slot = M.get_slot(slot_name)
	return slot and slot.default or nil
end

-- Sorted list of every attachment id in a slot (used by the sandbox cycler).
function M.get_attachments_for_slot(slot_name)
	local slot = M.get_slot(slot_name)
	if not slot then return {} end
	local list = {}
	for attachment_id in pairs(slot.attachments) do
		list[#list + 1] = attachment_id
	end
	table.sort(list)
	return list
end

-- Ordered { id, label } list of UI-selectable attachments for a slot.
function M.get_ui_list(slot_name)
	local slot = M.get_slot(slot_name)
	if not slot then return {} end
	local list = {}
	for id, att in pairs(slot.attachments) do
		if att.show_in_ui then
			list[#list + 1] = { id = id, label = att.ui_label or id, order = att.ui_order or 999 }
		end
	end
	table.sort(list, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.id < b.id
	end)
	return list
end

-- Mutation ------------------------------------------------------------------

-- Apply a single attachment. resolve(node_id) -> go path (or nil).
-- For typed-node slots (weapon) the active node is enabled, the rest disabled.
function M.apply_attachment(resolve, slot_name, attachment_id)
	ensure_loaded()
	local slot = data.slots[slot_name]
	if not slot then
		print("skins: unknown slot '" .. tostring(slot_name) .. "'")
		return
	end
	local attachment = slot.attachments[attachment_id]
	if not attachment then
		print("skins: unknown attachment '" .. tostring(attachment_id) .. "' in slot '" .. tostring(slot_name) .. "'")
		return
	end

	if slot.typed_nodes then
		for _, node_id in ipairs(slot.typed_nodes) do
			local path = resolve(node_id)
			if path then
				msg.post(path, node_id == attachment.node and "enable" or "disable")
			end
		end
	end

	if attachment.node == "none" then
		return
	end

	local node = attachment.node or slot.node
	local path = resolve(node)
	if path then
		sprite.play_flipbook(msg.url(nil, path, slot.component), attachment.animation)
	end
end

-- Apply every slot's default attachment.
function M.apply_defaults(resolve)
	ensure_loaded()
	for slot_name, slot in pairs(data.slots) do
		if slot.default then
			M.apply_attachment(resolve, slot_name, slot.default)
		end
	end
end

return M
