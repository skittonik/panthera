-- rig_rat.lua
-- A simple non-humanoid rig: one sprite GO (placeholder art for now), melee only.
-- Demonstrates that unit types are not limited to the Panthera humanoid.
--
-- Implements the same rig interface as rig_human (see unit.lua). idle/walk are
-- static (placeholder); attack is a quick scale lunge; hurt/death are procedural.

local fx = require("first_anim.modules.fx")
local theme = require("first_anim.modules.theme")

local R = {}
R.__index = R

local RAT_SCALE = 1.4
local PLACEHOLDER_TINT = vmath.vector4(0.45, 0.32, 0.28, 1.0) -- brownish stand-in

function R.new(opts)
	local flip = opts.is_enemy and -1.0 or 1.0
	local p_ids = collectionfactory.create(opts.factory_url, opts.pos, vmath.quat(), {},
		vmath.vector3(flip, 1.0, 1.0))

	local self = setmetatable({}, R)
	self.p_ids = p_ids
	self.is_enemy = opts.is_enemy
	self.root_path = p_ids[hash("/rat")]
	self.shadow_path = nil -- rat placeholder has no separate shadow
	self.sprite_url = msg.url(nil, self.root_path, "sprite")

	self.base_scale = RAT_SCALE
	go.set_scale(vmath.vector3(RAT_SCALE, RAT_SCALE, 1.0), self.root_path)
	return self
end

function R:apply_appearance(cfg)
	-- Placeholder: tint + scale the box so each rat-rig stand-in (rat/dog/boar/
	-- burelom) reads as a distinct, escalating threat until real rigs exist.
	local tint = PLACEHOLDER_TINT
	if cfg and cfg.tint then
		tint = vmath.vector4(cfg.tint[1], cfg.tint[2], cfg.tint[3], 1.0)
	end
	go.set(self.sprite_url, "tint", tint)
	if cfg and cfg.scale then
		self.base_scale = cfg.scale
		go.set_scale(vmath.vector3(cfg.scale, cfg.scale, 1.0), self.root_path)
	end
end

-- Rats carry no weapons; equipment calls are no-ops.
function R:set_weapon(_) end
function R:set_equipment(_, _, _) end

function R:play(state, opts)
	opts = opts or {}
	if state == "attack" then
		-- Quick lunge: punch scale up and back, firing the callback on return.
		go.animate(self.root_path, "scale.x", go.PLAYBACK_ONCE_PINGPONG, RAT_SCALE * 1.25,
			go.EASING_OUTQUAD, 0.16, 0, opts.callback)
	elseif state == "death" then
		go.animate(self.sprite_url, "tint.w", go.PLAYBACK_ONCE_FORWARD, 0.0, go.EASING_INQUAD, 0.3)
		if opts.callback then opts.callback() end
	else
		-- idle / walk: static placeholder.
		if opts.callback then opts.callback() end
	end
end

function R:muzzle() end -- melee, no muzzle

function R:hurt()
	fx.flash_single(self.root_path)
end

-- Knockback recoil for the placeholder rat: a quick squash. Visual only (scale
-- does not move the logical position), so the FSM is unaffected. strength is
-- ignored for the box stand-in.
function R:recoil(_)
	fx.flash_single(self.root_path)
	local base = self.base_scale or RAT_SCALE
	go.cancel_animations(self.root_path, "scale.x")
	-- Reset to base before the squash so a pingpong always returns to base,
	-- never to a mid-squash value (which would accumulate and leave the rat
	-- standing crooked after repeated splash hits).
	go.set_scale(vmath.vector3(base, base, 1.0), self.root_path)
	go.animate(self.root_path, "scale.x", go.PLAYBACK_ONCE_PINGPONG, base * 0.85,
		go.EASING_OUTQUAD, 0.12)
end

function R:stop()
	go.cancel_animations(self.root_path, "scale.x")
end

return R
