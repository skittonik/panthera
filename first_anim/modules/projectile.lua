-- projectile.lua
-- Cosmetic flying projectiles layered over the hitscan combat. Damage is still
-- applied by combat.lua on its own timing; these GOs are pure visuals that fly
-- from the firing unit's muzzle to the target and self-delete on arrival.
--
-- Every effect is built from a single bullet GO (effects.atlas): pistol/rifle
-- fire one ball per shot, shotgun fires a fan of smaller pellets plus a
-- shockwave_ring blast at the impact point. The bullet sprite is a round ball,
-- so no rotation/flip is needed.

local theme = require("first_anim.modules.theme")

local M = {}

local RANGED = { pistol = true, rifle = true, shotgun = true }
local factory_url = nil

function M.init(url)
	factory_url = url
end

function M.is_ranged(weapon_def)
	return (weapon_def and RANGED[weapon_def.type]) or false
end

-- Spawn one effect GO at `pos`, optionally swapping its sprite image.
local function spawn(pos, animation, scale)
	if not factory_url then return nil end
	local p = vmath.vector3(pos.x, pos.y, theme.projectile.z)
	local id = factory.create(factory_url, p)
	if animation then
		sprite.play_flipbook(msg.url(nil, id, "sprite"), animation)
	end
	if scale then
		go.set_scale(vmath.vector3(scale, scale, 1), id)
	end
	return id
end

-- A quick spark where a single bullet lands: grow + fade, then delete.
local function spark(at, denom)
	local id = spawn(at, theme.projectile.spark_anim, 0.05)
	if not id then return end
	local t = theme.projectile.spark_time / denom
	go.animate(id, "scale", go.PLAYBACK_ONCE_FORWARD,
		vmath.vector3(theme.projectile.spark_scale, theme.projectile.spark_scale, 1),
		go.EASING_OUTQUAD, t, 0)
	go.animate(msg.url(nil, id, "sprite"), "tint.w", go.PLAYBACK_ONCE_FORWARD, 0,
		go.EASING_INQUAD, t, 0, function() go.delete(id) end)
end

-- Fly one ball from -> to, then delete (and optionally spark on arrival).
local function travel(from, to, denom, scale, do_spark)
	local id = spawn(from, nil, scale)
	if not id then return end
	local dx, dy = to.x - from.x, to.y - from.y
	local dist = math.sqrt(dx * dx + dy * dy)
	local dur = math.max(theme.projectile.min_time, dist / theme.projectile.speed) / denom
	go.animate(id, "position", go.PLAYBACK_ONCE_FORWARD,
		vmath.vector3(to.x, to.y, theme.projectile.z), go.EASING_LINEAR, dur, 0,
		function()
			if do_spark then spark(to, denom) end
			go.delete(id)
		end)
end

-- Expanding shockwave ring marking the shotgun's area blast.
function M.shockwave(at, denom)
	local id = spawn(at, theme.projectile.wave_anim, 0.1)
	if not id then return end
	local t = theme.projectile.wave_time / denom
	go.animate(id, "scale", go.PLAYBACK_ONCE_FORWARD,
		vmath.vector3(theme.projectile.wave_scale, theme.projectile.wave_scale, 1),
		go.EASING_OUTQUAD, t, 0)
	go.animate(msg.url(nil, id, "sprite"), "tint.w", go.PLAYBACK_ONCE_FORWARD, 0,
		go.EASING_INQUAD, t, 0, function() go.delete(id) end)
end

-- Launch the visual for one attack. `attacker` supplies the live muzzle world
-- position (lazily, so delayed shots fire from the current muzzle); target_pos
-- is captured at attack time. denom is the sim speed multiplier so visuals keep
-- pace with 2x/4x.
function M.launch(attacker, weapon_def, target_pos, denom)
	denom = denom or 1
	local kind = weapon_def.type
	local muzzle = weapon_def.muzzle or {}
	local delays = muzzle.fire_delays or { 0 }

	local function fire_at(when, fn)
		if when <= 0 then fn() else timer.delay(when / denom, false, fn) end
	end

	if kind == "shotgun" then
		fire_at(delays[1] or 0, function()
			local o = attacker:muzzle_world_position()
			if not o then return end
			local dx, dy = target_pos.x - o.x, target_pos.y - o.y
			local ang = math.atan2(dy, dx)
			local dist = math.sqrt(dx * dx + dy * dy)
			local n = theme.projectile.pellets
			for i = 1, n do
				local frac = (n == 1) and 0 or ((i - 1) / (n - 1) - 0.5)
				local a = ang + frac * theme.projectile.spread
				local to = vmath.vector3(o.x + math.cos(a) * dist, o.y + math.sin(a) * dist, 0)
				travel(o, to, denom, theme.projectile.pellet_scale, false)
			end
		end)
		fire_at(weapon_def.hit_delay or 0.12, function()
			M.shockwave(target_pos, denom)
		end)
	else
		-- pistol: one ball per (single) delay; rifle: one ball per burst shot.
		for _, d in ipairs(delays) do
			fire_at(d, function()
				local o = attacker:muzzle_world_position()
				if o then travel(o, target_pos, denom, theme.projectile.bullet_scale, true) end
			end)
		end
	end
end

return M
