-- skins.lua
-- Cosmetic appearance attachments only (body, head). Weapons live in weapons.lua.
--
-- Addressing is unified through a `resolve` function: resolve(node_id) -> go path
-- (or nil). Build one with the helpers below (humanoid rig layout under /human).

local M = {}

local data = nil

function M.load()
	local json_str = sys.load_resource("/first_anim/data/skins.json")
	if not json_str then
		error("skins.lua: failed to load /first_anim/data/skins.json (add it to game.project custom_resources)")
	end
	data = json.decode(json_str)
end

local function ensure_loaded()
	if not data then M.load() end
end

-- Resolver builders (humanoid rig: nodes live under /human/<id>) ---------------

function M.resolver_from_factory(p_ids)
	return function(node_id)
		return p_ids[hash("/human/" .. node_id)]
	end
end

function M.resolver_from_prefix(prefix)
	return function(node_id)
		return prefix .. "/" .. node_id
	end
end

-- Lookups ---------------------------------------------------------------------

function M.get_slot(slot_name)
	ensure_loaded()
	return data.slots[slot_name]
end

function M.get_attachment(slot_name, attachment_id)
	local slot = M.get_slot(slot_name)
	return slot and slot.attachments[attachment_id] or nil
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

-- Mutation --------------------------------------------------------------------

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
	local path = resolve(attachment.node or slot.node)
	if path then
		sprite.play_flipbook(msg.url(nil, path, slot.component), attachment.animation)
	end
end

function M.apply_defaults(resolve)
	ensure_loaded()
	for slot_name, slot in pairs(data.slots) do
		if slot.default then
			M.apply_attachment(resolve, slot_name, slot.default)
		end
	end
end

return M
