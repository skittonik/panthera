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

-- Idle: a quick breathing loop (rats breathe faster than the human's 3s
-- cycle) - chest rise/expand, head bob with a lag, and a small weight shift
-- side to side. Mirrors the spirit of the human "default" Panthera clip.
local IDLE_BREATH_TIME = 0.9
local IDLE_BODY_BOB = 3
local IDLE_BODY_SCALE_X = 0.02
local IDLE_BODY_SCALE_Y = 0.03
local IDLE_HEAD_BOB = 4
local IDLE_HEAD_TILT_DEG = 1.5
local IDLE_LEG_SHIFT_DEG = 2

-- Death: collapse straight down (not a sideways topple) - body sinks, head
-- drops, front legs splay forward, back legs splay backward - then fade.
local DEATH_COLLAPSE_DROP = 16
local DEATH_HIT_TILT_DEG = -14
local DEATH_HEAD_DOWN_DEG = -58
local DEATH_LEG_SPLAY = {
	leg_front_left = 34, leg_front_right = 28,
	leg_back_left = -34, leg_back_right = -28,
}
local DEATH_FADE_DELAY = 0.5
local DEATH_FADE_TIME = 0.35

local PARTS = { "body", "head", "leg_front_left", "leg_front_right", "leg_back_left", "leg_back_right" }
local LEGS = { "leg_front_left", "leg_front_right", "leg_back_left", "leg_back_right" }
-- Diagonal trot pairing: FL+BR swing together, opposite to FR+BL.
local DIAG_A = { "leg_front_left", "leg_back_right" }
local DIAG_B = { "leg_front_right", "leg_back_left" }
-- Left/right grouping for the idle weight-shift (as opposed to the diagonal
-- trot pairing above).
local SIDE_LEFT = { "leg_front_left", "leg_back_left" }
local SIDE_RIGHT = { "leg_front_right", "leg_back_right" }

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
	-- sprite.set_hflip() mirrors the *texture* only, not the GO's rotation
	-- math, so a rotation that reads as "down"/"forward" on the unflipped art
	-- reads as the opposite once hflip is on (the rotated quad still turns
	-- the same physical way, but the visual snout/paw landmark is now drawn
	-- on the other edge of it). Multiply any canonical (unflipped-reference)
	-- directional angle by this before applying it to a hflipped part.
	self.rot_sign = -flip
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
	self.walk_token = 0

	-- All six part sprites, for effects that must hit the whole rat (hurt
	-- flash, death fade) instead of just the body.
	self.part_paths = {}
	for _, id in ipairs(PARTS) do
		self.part_paths[#self.part_paths + 1] = p_ids[hash("/rat/" .. id)]
	end

	if opts.is_enemy then
		mirror_for_enemy(p_ids)
	end

	-- Rest positions are read from whatever's authored in rat.collection
	-- (never hardcoded here) so hand-tuned placement in the editor is always
	-- the source of truth - matches rig_human.lua, which never assumes a
	-- fixed pose either.
	self.leg_rest_y = {}
	for _, id in ipairs(LEGS) do
		self.leg_rest_y[id] = go.get_position(self.leg_paths[id]).y
	end
	self.body_rest_y = go.get_position(self.body_path).y
	self.head_rest_y = go.get_position(self.head_path).y

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

-- Stops whichever ambient loop is running (walk trot or idle breathing) and
-- resets every part it might touch back to its authored rest pose. Called at
-- the start of every state transition so switching state never leaves a
-- stray mid-loop offset behind.
local function stop_ambient_cycle(self)
	self.walk_token = self.walk_token + 1
	for _, id in ipairs(LEGS) do
		local path = self.leg_paths[id]
		go.cancel_animations(path, "euler.z")
		go.cancel_animations(path, "position.y")
		go.set(path, "euler.z", 0)
		go.set(path, "position.y", self.leg_rest_y[id])
	end
	go.cancel_animations(self.body_path, "position.y")
	go.cancel_animations(self.body_path, "scale.x")
	go.cancel_animations(self.body_path, "scale.y")
	go.set(self.body_path, "position.y", self.body_rest_y)
	go.set(self.body_path, "scale", vmath.vector3(1.0, 1.0, 1.0))
	go.cancel_animations(self.head_path, "position.y")
	go.cancel_animations(self.head_path, "euler.z")
	go.set(self.head_path, "position.y", self.head_rest_y)
	go.set(self.head_path, "euler.z", 0)
end

-- One trot phase: `fwd` pair swings forward with a lift, `back` pair drags
-- back along the ground. Recurses (via timer) into the swapped phase, guarded
-- by `token` so a stopped/restarted cycle never leaves stray callbacks running.
local function trot_phase(self, token, fwd, back)
	if self.walk_token ~= token then return end

	for _, id in ipairs(fwd) do
		local path = self.leg_paths[id]
		local rest_y = self.leg_rest_y[id]
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, WALK_SWING_DEG, go.EASING_OUTSINE, WALK_STEP_TIME)
		go.animate(path, "position.y", go.PLAYBACK_ONCE_FORWARD, rest_y + WALK_LIFT,
			go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
				go.animate(path, "position.y", go.PLAYBACK_ONCE_FORWARD, rest_y,
					go.EASING_INSINE, WALK_STEP_TIME * 0.5)
			end)
	end
	for _, id in ipairs(back) do
		local path = self.leg_paths[id]
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -WALK_SWING_DEG, go.EASING_INOUTSINE, WALK_STEP_TIME)
	end
	go.animate(self.body_path, "position.y", go.PLAYBACK_ONCE_FORWARD, self.body_rest_y - WALK_BODY_BOB * 0.5,
		go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
			go.animate(self.body_path, "position.y", go.PLAYBACK_ONCE_FORWARD, self.body_rest_y + WALK_BODY_BOB * 0.5,
				go.EASING_INOUTSINE, WALK_STEP_TIME * 0.5)
		end)

	timer.delay(WALK_STEP_TIME, false, function()
		trot_phase(self, token, back, fwd)
	end)
end

-- Collapses the rat straight down onto the ground (not a sideways topple):
-- the body sinks and tilts slightly nose-down, the head drops hard, front
-- legs splay forward and back legs splay backward, then everything fades
-- once it has settled. Hand-animated since the rat has no Panthera skeleton
-- (see the human "death" clip in human_panthera.lua for the equivalent).
local function play_death(self)
	local hit = self.hit_path
	go.cancel_animations(hit, "scale.x")
	go.cancel_animations(hit, "position.x")
	go.cancel_animations(hit, "position.y")
	go.cancel_animations(hit, "euler.z")
	go.set(hit, "scale", vmath.vector3(self.base_scale, self.base_scale, 1.0))
	go.set(hit, "position", vmath.vector3(0, 0, 0))

	-- Brief stumble up, then sink down and settle - the whole body dropping
	-- toward the ground rather than falling over sideways.
	go.animate(hit, "position.y", go.PLAYBACK_ONCE_FORWARD, 4, go.EASING_OUTQUAD, 0.06, 0, function()
		go.animate(hit, "position.y", go.PLAYBACK_ONCE_FORWARD, -DEATH_COLLAPSE_DROP,
			go.EASING_INCUBIC, 0.22, 0, function()
				go.animate(hit, "position.y", go.PLAYBACK_ONCE_FORWARD, -DEATH_COLLAPSE_DROP + 3,
					go.EASING_OUTQUAD, 0.1)
			end)
	end)
	go.animate(hit, "euler.z", go.PLAYBACK_ONCE_FORWARD, DEATH_HIT_TILT_DEG, go.EASING_OUTSINE, 0.28, 0.04)

	-- Head drops down hard, further than the body tilts.
	go.cancel_animations(self.head_path, "euler.z")
	go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -14 * self.rot_sign, go.EASING_OUTQUAD, 0.08, 0, function()
		go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, DEATH_HEAD_DOWN_DEG * self.rot_sign,
			go.EASING_INOUTSINE, 0.3)
	end)

	-- Front legs splay forward (toward the snout), back legs splay backward
	-- (toward the tail), settling as the body sinks between them.
	for _, id in ipairs(LEGS) do
		local path = self.leg_paths[id]
		go.cancel_animations(path, "euler.z")
		go.cancel_animations(path, "position.y")
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, DEATH_LEG_SPLAY[id] * self.rot_sign,
			go.EASING_OUTQUAD, 0.26, 0.03)
	end

	-- Fade everything out once it has settled ("color.w", not "tint.w" - see
	-- panthera/adapters/adapter_go.lua's color_a mapping; "tint"/"flash" are
	-- separate material constants used only by fx.lua's hit-flash effect and
	-- don't drive visibility).
	for _, path in ipairs(self.part_paths) do
		go.animate(msg.url(nil, path, "sprite"), "color.w", go.PLAYBACK_ONCE_FORWARD, 0.0,
			go.EASING_OUTSINE, DEATH_FADE_TIME, DEATH_FADE_DELAY)
	end
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

-- Breathing idle loop: chest rise/expand, head bob with a slight lag, and a
-- small side-to-side weight shift. Every track is a self-looping
-- PLAYBACK_LOOP_PINGPONG, so (unlike the walk trot) no timer chaining is
-- needed - go.cancel_animations in stop_ambient_cycle stops it cleanly.
local function start_idle_cycle(self)
	local body, head = self.body_path, self.head_path
	go.animate(body, "position.y", go.PLAYBACK_LOOP_PINGPONG, self.body_rest_y + IDLE_BODY_BOB,
		go.EASING_INOUTSINE, IDLE_BREATH_TIME)
	go.animate(body, "scale.x", go.PLAYBACK_LOOP_PINGPONG, 1.0 + IDLE_BODY_SCALE_X,
		go.EASING_INOUTSINE, IDLE_BREATH_TIME)
	go.animate(body, "scale.y", go.PLAYBACK_LOOP_PINGPONG, 1.0 + IDLE_BODY_SCALE_Y,
		go.EASING_INOUTSINE, IDLE_BREATH_TIME)

	-- Head lags the chest slightly (longer duration) for secondary motion.
	go.animate(head, "position.y", go.PLAYBACK_LOOP_PINGPONG, self.head_rest_y + IDLE_HEAD_BOB,
		go.EASING_INOUTSINE, IDLE_BREATH_TIME + 0.15)
	go.animate(head, "euler.z", go.PLAYBACK_LOOP_PINGPONG, IDLE_HEAD_TILT_DEG * self.rot_sign,
		go.EASING_INOUTSINE, IDLE_BREATH_TIME)

	-- Weight shifts side to side: left legs and right legs sway oppositely.
	for _, id in ipairs(SIDE_LEFT) do
		go.animate(self.leg_paths[id], "euler.z", go.PLAYBACK_LOOP_PINGPONG, IDLE_LEG_SHIFT_DEG * self.rot_sign,
			go.EASING_INOUTSINE, IDLE_BREATH_TIME)
	end
	for _, id in ipairs(SIDE_RIGHT) do
		go.animate(self.leg_paths[id], "euler.z", go.PLAYBACK_LOOP_PINGPONG, -IDLE_LEG_SHIFT_DEG * self.rot_sign,
			go.EASING_INOUTSINE, IDLE_BREATH_TIME)
	end
end

function R:play(state, opts)
	opts = opts or {}
	if state == "attack" then
		stop_ambient_cycle(self)
		-- Forward lunge on `hit` (never `root` - root is the logical battlefield
		-- position unit.lua owns; animating it to a small local offset would
		-- teleport the unit) with a head bite snap, both springing back to rest
		-- once the bite lands.
		local lunge = self.flip * 26
		go.cancel_animations(self.hit_path, "position.x")
		go.set(self.hit_path, "position.x", 0)
		go.animate(self.hit_path, "position.x", go.PLAYBACK_ONCE_PINGPONG, lunge,
			go.EASING_OUTQUAD, 0.11, 0, opts.callback)
		go.set(self.head_path, "euler.z", 12 * self.rot_sign)
		go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -28 * self.rot_sign, go.EASING_OUTQUAD, 0.1, 0, function()
			go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_INOUTQUAD, 0.15)
		end)
	elseif state == "death" then
		stop_ambient_cycle(self)
		play_death(self)
		if opts.callback then opts.callback() end
	elseif state == "walk" or state == "run" then
		-- No dedicated run cycle for the rat rig; the trot keeps it in sync
		-- with the RUN toggle instead of freezing into the idle branch below.
		stop_ambient_cycle(self)
		start_walk_cycle(self)
		if opts.callback then opts.callback() end
	else
		-- idle: breathing loop.
		stop_ambient_cycle(self)
		start_idle_cycle(self)
		if opts.callback then opts.callback() end
	end
end

function R:muzzle() end -- melee, no muzzle

function R:hurt()
	for _, path in ipairs(self.part_paths) do
		fx.flash_single(path)
	end
end

-- Knockback recoil for the rat rig: a quick squash on `hit`. Visual only -
-- `root` (the logical position) never moves, so the combat FSM never chases
-- or drifts.
function R:recoil(_)
	for _, path in ipairs(self.part_paths) do
		fx.flash_single(path)
	end
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
	stop_ambient_cycle(self)
end

return R
