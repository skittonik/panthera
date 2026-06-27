-- fx.lua
-- The single implementation of combat visual effects (damage flash, muzzle
-- fire). Previously copy-pasted across battle/autobattle/sandbox with diverging
-- signatures. Addressing is unified via resolve(node_id) -> go path (or nil),
-- so the same code works for factory-spawned and statically placed rigs.

local theme = require("first_anim.theme")

local M = {}

-- Rig sprites that tint red on hit.
local FLASH_NODES = {
	"body", "head", "hand_right", "hand_left", "left_leg", "right_leg",
	"weapon_impact", "weapon_stabbing", "weapon_pistol", "weapon_rifle", "weapon_shotgun",
}

local RANGED = { pistol = true, rifle = true, shotgun = true }

-- Flash all rig sprites red, fading back to clear.
function M.flash(resolve)
	for _, node_id in ipairs(FLASH_NODES) do
		local path = resolve(node_id)
		if path then
			local url = msg.url(nil, path, "sprite")
			go.set(url, "flash", theme.color.flash)
			go.animate(url, "flash", go.PLAYBACK_ONCE_FORWARD, theme.color.flash_clear,
				go.EASING_LINEAR, theme.flash_time, 0)
		end
	end
end

-- Fire muzzle flash + smoke for ranged weapons, following the weapon's
-- data-driven offset and fire timing. weapon_def is a skins weapon definition.
function M.muzzle(resolve, is_enemy, weapon_def)
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
