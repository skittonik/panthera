local M = {}

local skins_data = nil

local function load()
	local json_str = sys.load_resource("/first_anim/skins.json")
	if not json_str then
		error("Failed to load /first_anim/skins.json. Ensure it is listed in game.project's custom_resources.")
	end
	skins_data = json.decode(json_str)
end

local function ensure_loaded()
	if not skins_data then load() end
end

-- Sorted list of attachment IDs for a slot.
function M.get_attachments_for_slot(slot_name)
	ensure_loaded()
	local slot = skins_data.slots[slot_name]
	if not slot then return {} end
	local list = {}
	for attachment_id in pairs(slot.attachments) do
		table.insert(list, attachment_id)
	end
	table.sort(list)
	return list
end

-- Returns the weapon "type" string for an attachment (e.g. "impact", "pistol").
function M.get_weapon_type(attachment_id)
	ensure_loaded()
	local slot = skins_data.slots["weapon"]
	if not slot then return nil end
	local att = slot.attachments[attachment_id]
	return att and att.type or nil
end

-- Apply a single attachment to a character.
-- For slots with typed_nodes (weapon): enables the active typed GO, disables the rest.
function M.apply_attachment(character_prefix, slot_name, attachment_id)
	ensure_loaded()
	local slot = skins_data.slots[slot_name]
	if not slot then
		print("Warning: Slot not found: " .. tostring(slot_name))
		return
	end
	local attachment = slot.attachments[attachment_id]
	if not attachment then
		print("Warning: Attachment not found: " .. tostring(attachment_id) .. " in slot " .. tostring(slot_name))
		return
	end

	-- Weapon slot: enable only the active typed GO, disable all others.
	if slot.typed_nodes then
		local active_node = attachment.node
		for _, node_id in ipairs(slot.typed_nodes) do
			go.set_enabled("/" .. character_prefix .. "/" .. node_id, node_id == active_node)
		end
	end

	local node = attachment.node or slot.node
	local sprite_url = msg.url(nil, "/" .. character_prefix .. "/" .. node, slot.component)
	sprite.play_flipbook(sprite_url, attachment.animation)
end

-- Apply all default attachments to a character.
function M.apply_defaults(character_prefix)
	ensure_loaded()
	for slot_name, slot in pairs(skins_data.slots) do
		if slot.default then
			M.apply_attachment(character_prefix, slot_name, slot.default)
		end
	end
end

return M
