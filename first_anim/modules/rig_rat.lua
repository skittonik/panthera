-- rig_rat.lua
-- A simple non-humanoid rig: body + head + 4 independent legs + shadow,
-- melee only. Demonstrates that unit types are not limited to the Panthera
-- humanoid.
--
-- Structure mirrors rig_human.lua: root (logical position - owned by unit.lua,
-- never animated here) -> hit (purely visual flinch/scale layer) -> body/head/
-- legs, with shadow as a root sibling. Walk is a diagonal trot: front-left/
-- back-right lift-and-swing forward together while front-right/back-left drag
-- back along the ground, then they swap. Each leg pivots around its own hip.
-- Attack is a forward lunge (on `hit`, never `root`) with a head bite snap.

local fx = require("first_anim.modules.fx")

local R = {}
R.__index = R

-- Source art (rat_body.png) was authored at 205px tall; earlier tuning
-- (RAT_SCALE / enemies.json scale) targeted the old 64px placeholder box.
-- Rescale every scale value by this factor so on-screen sizes are unchanged.
local ART_SCALE_FACTOR = 64 / 205
local RAT_SCALE = 1.4 * ART_SCALE_FACTOR

local WALK_SWING_DEG = 24
local WALK_LIFT = 12
local WALK_STEP_TIME = 0.17
local WALK_BODY_BOB = 5

local LEG_REST_Y = 60
local BODY_REST_Y = 147.5

local PARTS = { "body", "head", "leg_front_left", "leg_front_right", "leg_back_left", "leg_back_right" }
local LEGS = { "leg_front_left", "leg_front_right", "leg_back_left", "leg_back_right" }
-- Diagonal trot pairing: FL+BR swing together, opposite to FR+BL.
local DIAG_A = { "leg_front_left", "leg_back_right" }
local DIAG_B = { "leg_front_right", "leg_back_left" }

-- go.set_scale() rejects zero/negative components, so the rig can't be
-- mirrored with a negative scale (Defold hard error - this is why the old
-- collectionfactory.create "scale" flip silently never applied). Instead each
-- part is individually hflipped and its authored x offset (facing right)
-- negated, which mirrors the silhouette without touching any scale sign.
local function mirror_for_enemy(p_ids)
	for _, id in ipairs(PARTS) do
		local path = p_ids[hash("/rat/" .. id)]
		local pos = go.get_position(path)
		go.set_position(vmath.vector3(-pos.x, pos.y, pos.z), path)
		sprite.set_hflip(msg.url(nil, path, "sprite"), true)
	end
end

function R.new(opts)
	local flip = opts.is_enemy and -1.0 or 1.0
	local p_ids = collectionfactory.create(opts.factory_url, opts.pos, vmath.quat(), {}, nil)

	local self = setmetatable({}, R)
	self.p_ids = p_ids
	self.is_enemy = opts.is_enemy
	-- Directional sign only (never fed into go.set_scale - see mirror_for_enemy).
	self.flip = flip
	-- root is the *logical* position unit.lua reads/writes every frame for
	-- movement; it must never be scaled or animated by this rig.
	self.root_path = p_ids[hash("/rat/root")]
	self.hit_path = p_ids[hash("/rat/hit")]
	self.shadow_path = p_ids[hash("/rat/shadow")]
	self.body_path = p_ids[hash("/rat/body")]
	self.head_path = p_ids[hash("/rat/head")]
	self.leg_paths = {}
	for _, id in ipairs(LEGS) do
		self.leg_paths[id] = p_ids[hash("/rat/" .. id)]
	end
	self.sprite_url = msg.url(nil, self.body_path, "sprite")
	self.walk_token = 0

	if opts.is_enemy then
		mirror_for_enemy(p_ids)
	end

	self.base_scale = RAT_SCALE
	local s = vmath.vector3(RAT_SCALE, RAT_SCALE, 1.0)
	go.set_scale(s, self.hit_path)
	go.set_scale(s, self.shadow_path)
	return self
end

function R:apply_appearance(cfg)
	-- Scale the rig so each rat-rig variant (rat/dog/boar/burelom) reads as
	-- a distinct, escalating threat. Tint is left at the art's native colors.
	if cfg and cfg.scale then
		self.base_scale = cfg.scale * ART_SCALE_FACTOR
		local s = vmath.vector3(self.base_scale, self.base_scale, 1.0)
		go.set_scale(s, self.hit_path)
		go.set_scale(s, self.shadow_path)
	end
end

-- Rats carry no weapons; equipment calls are no-ops.
function R:set_weapon(_) end
function R:set_equipment(_, _, _) end

local function stop_walk_cycle(self)
	self.walk_token = self.walk_token + 1
	for _, id in ipairs(LEGS) do
		local path = self.leg_paths[id]
		go.cancel_animations(path, "euler.z")
		go.cancel_animations(path, "position.y")
		go.set(path, "euler.z", 0)
		go.set(path, "position.y", LEG_REST_Y)
	end
	go.cancel_animations(self.body_path, "position.y")
	go.set(self.body_path, "position.y", BODY_REST_Y)
end

-- One trot phase: `fwd` pair swings forward with a lift, `back` pair drags
-- back along the ground. Recurses (via timer) into the swapped phase, guarded
-- by `token` so a stopped/restarted cycle never leaves stray callbacks running.
local function trot_phase(self, token, fwd, back)
	if self.walk_token ~= token then return end

	for _, id in ipairs(fwd) do
		local path = self.leg_paths[id]
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, WALK_SWING_DEG, go.EASING_OUTSINE, WALK_STEP_TIME)
		go.animate(path, "position.y", go.PLAYBACK_ONCE_FORWARD, LEG_REST_Y + WALK_LIFT,
			go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
				go.animate(path, "position.y", go.PLAYBACK_ONCE_FORWARD, LEG_REST_Y,
					go.EASING_INSINE, WALK_STEP_TIME * 0.5)
			end)
	end
	for _, id in ipairs(back) do
		local path = self.leg_paths[id]
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -WALK_SWING_DEG, go.EASING_INOUTSINE, WALK_STEP_TIME)
	end
	go.animate(self.body_path, "position.y", go.PLAYBACK_ONCE_FORWARD, BODY_REST_Y - WALK_BODY_BOB * 0.5,
		go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
			go.animate(self.body_path, "position.y", go.PLAYBACK_ONCE_FORWARD, BODY_REST_Y + WALK_BODY_BOB * 0.5,
				go.EASING_INOUTSINE, WALK_STEP_TIME * 0.5)
		end)

	timer.delay(WALK_STEP_TIME, false, function()
		trot_phase(self, token, back, fwd)
	end)
end

local function start_walk_cycle(self)
	self.walk_token = self.walk_token + 1
	local token = self.walk_token
	go.set(self.leg_paths["leg_front_left"], "euler.z", -WALK_SWING_DEG)
	go.set(self.leg_paths["leg_back_right"], "euler.z", -WALK_SWING_DEG)
	go.set(self.leg_paths["leg_front_right"], "euler.z", WALK_SWING_DEG)
	go.set(self.leg_paths["leg_back_left"], "euler.z", WALK_SWING_DEG)
	trot_phase(self, token, DIAG_A, DIAG_B)
end

function R:play(state, opts)
	opts = opts or {}
	if state == "attack" then
		stop_walk_cycle(self)
		-- Forward lunge on `hit` (never `root` - root is the logical battlefield
		-- position unit.lua owns; animating it to a small local offset would
		-- teleport the unit) with a head bite snap, both springing back to rest
		-- once the bite lands.
		local lunge = self.flip * 26
		go.cancel_animations(self.hit_path, "position.x")
		go.set(self.hit_path, "position.x", 0)
		go.animate(self.hit_path, "position.x", go.PLAYBACK_ONCE_PINGPONG, lunge,
			go.EASING_OUTQUAD, 0.11, 0, opts.callback)
		go.set(self.head_path, "euler.z", 12)
		go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -28, go.EASING_OUTQUAD, 0.1, 0, function()
			go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INOUTQUAD, 0.15)
		end)
	elseif state == "death" then
		stop_walk_cycle(self)
		go.animate(self.sprite_url, "tint.w", go.PLAYBACK_ONCE_FORWARD, 0.0, go.EASING_INQUAD, 0.3)
		if opts.callback then opts.callback() end
	elseif state == "walk" then
		start_walk_cycle(self)
		if opts.callback then opts.callback() end
	else
		-- idle: static, legs at rest.
		stop_walk_cycle(self)
		if opts.callback then opts.callback() end
	end
end

function R:muzzle() end -- melee, no muzzle

function R:hurt()
	fx.flash_single(self.body_path)
end

-- Knockback recoil for the rat rig: a quick squash on `hit`. Visual only -
-- `root` (the logical position) never moves, so the combat FSM never chases
-- or drifts.
function R:recoil(_)
	fx.flash_single(self.body_path)
	local base = self.base_scale or RAT_SCALE
	go.cancel_animations(self.hit_path, "scale.x")
	-- Reset to base before the squash so a pingpong always returns to base,
	-- never to a mid-squash value (which would accumulate and leave the rat
	-- standing crooked after repeated splash hits).
	go.set_scale(vmath.vector3(base, base, 1.0), self.hit_path)
	go.animate(self.hit_path, "scale.x", go.PLAYBACK_ONCE_PINGPONG, base * 0.85,
		go.EASING_OUTQUAD, 0.12)
end

function R:stop()
	go.cancel_animations(self.hit_path, "scale.x")
	go.cancel_animations(self.hit_path, "position.x")
	stop_walk_cycle(self)
end

return R
