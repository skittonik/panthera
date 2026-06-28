-- fx.lua
-- Low-level combat visual effects (damage flash, muzzle fire). Rigs call into
-- these; addressing is via resolve(node_id) -> go path (or nil).

local theme = require("first_anim.modules.theme")

local M = {}

-- Humanoid rig sprites that tint red on hit.
local HUMANOID_FLASH_NODES = {
	"body", "head", "hand_right", "hand_left", "left_leg", "right_leg",
	"weapon_impact", "weapon_stabbing", "weapon_pistol", "weapon_rifle", "weapon_shotgun",
}

local RANGED = { pistol = true, rifle = true, shotgun = true }

local function flash_url(url)
	go.set(url, "flash", theme.color.flash)
	go.animate(url, "flash", go.PLAYBACK_ONCE_FORWARD, theme.color.flash_clear,
		go.EASING_LINEAR, theme.flash_time, 0)
end

-- Flash all humanoid rig sprites red, fading back to clear.
function M.flash(resolve)
	for _, node_id in ipairs(HUMANOID_FLASH_NODES) do
		local path = resolve(node_id)
		if path then
			flash_url(msg.url(nil, path, "sprite"))
		end
	end
end

-- Flash a single sprite component (simple rigs like the rat).
function M.flash_single(go_path)
	if go_path then
		flash_url(msg.url(nil, go_path, "sprite"))
	end
end

-- Fire muzzle flash + smoke for ranged weapons, following the weapon's
-- data-driven offset and fire timing. weapon_def is a weapons definition.
-- is_valid: optional function() -> bool; delayed shots are skipped if it returns false.
function M.muzzle(resolve, is_enemy, weapon_def, is_valid)
	if not weapon_def or not RANGED[weapon_def.type] then return end
	local muzzle = weapon_def.muzzle
	if not muzzle then return end

	local muzzle_go = resolve("muzzle")
	if not muzzle_go then return end

	if muzzle.offset then
		go.set_position(vmath.vector3(muzzle.offset.x, muzzle.offset.y, 0), muzzle_go)
		go.set_rotation(is_enemy and vmath.quat_rotation_z(math.pi) or vmath.quat(), muzzle_go)
	end

	local url_flash = msg.url(nil, muzzle_go, "muzzle_flash")
	local url_smoke = msg.url(nil, muzzle_go, "smoke_puff")
	local function fire()
		if is_valid and not is_valid() then return end
		particlefx.stop(url_flash)
		particlefx.stop(url_smoke)
		particlefx.play(url_flash)
		particlefx.play(url_smoke)
	end

	for _, delay in ipairs(muzzle.fire_delays or { 0 }) do
		if delay <= 0 then
			fire()
		else
			timer.delay(delay, false, fire)
		end
	end
end

return M
