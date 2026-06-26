local M = {}

local skins_data = nil

-- Load and decode the skins JSON configuration
function M.load()
	local json_str = sys.load_resource("/first_anim/skins.json")
	if not json_str then
		error("Failed to load /first_anim/skins.json. Ensure it is listed in game.project's custom_resources.")
	end
	skins_data = json.decode(json_str)
end

-- Get a sorted list of attachment IDs available for a specific slot
function M.get_attachments_for_slot(slot_name)
	if not skins_data then
		M.load()
	end
	local slot = skins_data.slots[slot_name]
	if not slot then
		return {}
	end
	
	local list = {}
	for attachment_id, _ in pairs(slot.attachments) do
		table.insert(list, attachment_id)
	end
	table.sort(list) -- Ensure a consistent order for switching
	return list
end

-- Apply a single attachment to its slot on a given character prefix
function M.apply_attachment(character_prefix, slot_name, attachment_id)
	if not skins_data then
		M.load()
	end

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

	local sprite_url = msg.url(nil, "/" .. character_prefix .. "/" .. slot.node, slot.component)
	
	-- Play the sprite animation/flipbook
	sprite.play_flipbook(sprite_url, attachment.animation)
end

-- Apply all default attachments for all slots to a given character prefix
function M.apply_defaults(character_prefix)
	if not skins_data then
		M.load()
	end

	for slot_name, slot in pairs(skins_data.slots) do
		if slot.default then
			M.apply_attachment(character_prefix, slot_name, slot.default)
		end
	end
end

return M
