-- rig_quadruped.lua
-- Generic non-humanoid rig: body + head + 4 independent legs + shadow, melee
-- only. Drives rat/dog/boar/burelom (and any future quadruped) from a single
-- animation implementation - only the collection GO path prefix (species id)
-- and the art's native body height (to normalize on-screen scale across
-- differently-authored art) vary per species. Structure mirrors rig_human.lua:
-- root (logical position - owned by unit.lua, never animated here) -> hit
-- (purely visual flinch/scale layer) -> body/head/legs, with shadow as a root
-- sibling. Walk is a diagonal trot: front-left/back-right lift-and-swing
-- forward together while front-right/back-left drag back along the ground,
-- then they swap. Each leg pivots around its own hip. Attack is a forward
-- lunge (on `hit`, never `root`) with a head bite snap.

local fx = require("first_anim.modules.fx")

local R = {}
R.__index = R

-- Every species' art is normalized to the same nominal on-screen body height
-- (px) before the per-unit `scale` cfg and the base multiplier below are
-- applied, so a given cfg.scale value reads as roughly the same size
-- regardless of the source art's native resolution. rat_body.png was
-- authored at 205px tall; REFERENCE_PX/205 reproduces its original tuning.
local REFERENCE_PX = 64
local BASE_SCALE_MULT = 1.4

-- Per-species native body art height (px), used to derive each species'
-- art_scale_factor = REFERENCE_PX / body_h. Add an entry here (and the
-- matching rigs/<species>/ assets) for any new quadruped.
local SPECIES_BODY_H = {
	rat = 205,
	dog = 224,
	boar = 401,
}

-- Per-species leg-length-to-body-height ratio relative to rat's (the tuning
-- baseline for WALK_SWING_DEG/DEATH_LEG_SPLAY below). dog_leg_*.png are ~2.9x
-- longer relative to dog_body.png than rat's legs are to rat_body.png (avg
-- leg px / body_h: rat 76.5/205=0.37, dog 244/224=1.09), so the same rotation
-- angle sweeps the dog's feet through a much larger arc than intended.
-- Scaling rotation-based leg tracks by 1/ratio keeps the on-screen foot
-- excursion consistent across species instead of each inheriting rat's tuning
-- verbatim. boar's ratio (~0.42) is close enough to rat's to need no override.
local SPECIES_LEG_SWING_MULT = {
	dog = 0.34,
}

local WALK_SWING_DEG = 24
local WALK_LIFT = 12
local WALK_STEP_TIME = 0.17
local WALK_BODY_BOB = 5
local WALK_HEAD_BOB = 6
local WALK_HEAD_NOD_DEG = 4

-- Attack: a ram/charge, not a quick snap - a short pull-back (windup), a hard
-- forward slam, then a slower recoil back to rest. Head dips down into the
-- charge as one motion instead of a separate sharp bite-rotation.
local ATTACK_WINDUP_TIME = 0.07
local ATTACK_WINDUP_PULL = 10
local ATTACK_CHARGE_TIME = 0.1
local ATTACK_CHARGE_DIST = 42
local ATTACK_RETURN_TIME = 0.18
local ATTACK_HEAD_TILT_DEG = 12

-- Idle: a quick breathing loop - chest rise/expand, head bob with a lag, and
-- a small weight shift side to side. Mirrors the spirit of the human
-- "default" Panthera clip.
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
local function mirror_for_enemy(p_ids, species)
	for _, id in ipairs(PARTS) do
		local path = p_ids[hash("/" .. species .. "/" .. id)]
		local pos = go.get_position(path)
		go.set_position(vmath.vector3(-pos.x, pos.y, pos.z), path)
		sprite.set_hflip(msg.url(nil, path, "sprite"), true)
	end
end

function R.new(opts)
	local species = opts.unit_type
	local body_h = SPECIES_BODY_H[species]
	if not body_h then
		error("rig_quadruped.lua: no SPECIES_BODY_H entry for unit_type '" .. tostring(species) .. "'")
	end
	local art_scale_factor = REFERENCE_PX / body_h

	local flip = opts.is_enemy and -1.0 or 1.0
	local p_ids = collectionfactory.create(opts.factory_url, opts.pos, vmath.quat(), {}, nil)

	local self = setmetatable({}, R)
	self.p_ids = p_ids
	self.species = species
	self.art_scale_factor = art_scale_factor
	self.is_enemy = opts.is_enemy
	-- Directional sign only (never fed into go.set_scale - see mirror_for_enemy).
	self.flip = flip
	-- sprite.set_hflip() mirrors the *texture* only, not the GO's rotation
	-- math, so a rotation that reads as "down"/"forward" on the unflipped art
	-- reads as the opposite once hflip is on (the rotated quad still turns
	-- the same physical way, but the visual snout/paw landmark is now drawn
	-- on the other edge of it). Multiply any canonical (unflipped-reference,
	-- i.e. authored-for-player) directional angle by this before applying it
	-- to a part: identity for the never-flipped player (flip=+1), negated for
	-- the hflipped enemy (flip=-1) - so this tracks self.flip, not -self.flip
	-- (rat death's head-drop went the wrong way for the player until this was
	-- corrected: the old -flip sign matched the enemy case, not the player's).
	self.rot_sign = flip
	self.leg_swing_mult = SPECIES_LEG_SWING_MULT[species] or 1.0
	-- root is the *logical* position unit.lua reads/writes every frame for
	-- movement; it must never be scaled or animated by this rig.
	self.root_path = p_ids[hash("/" .. species .. "/root")]
	self.hit_path = p_ids[hash("/" .. species .. "/hit")]
	self.shadow_path = p_ids[hash("/" .. species .. "/shadow")]
	self.body_path = p_ids[hash("/" .. species .. "/body")]
	self.head_path = p_ids[hash("/" .. species .. "/head")]
	self.leg_paths = {}
	for _, id in ipairs(LEGS) do
		self.leg_paths[id] = p_ids[hash("/" .. species .. "/" .. id)]
	end
	self.walk_token = 0

	-- All six part sprites, for effects that must hit the whole rig (hurt
	-- flash, death fade) instead of just the body.
	self.part_paths = {}
	for _, id in ipairs(PARTS) do
		self.part_paths[#self.part_paths + 1] = p_ids[hash("/" .. species .. "/" .. id)]
	end

	if opts.is_enemy then
		mirror_for_enemy(p_ids, species)
	end

	-- Rest positions are read from whatever's authored in <species>.collection
	-- (never hardcoded here) so hand-tuned placement in the editor is always
	-- the source of truth - matches rig_human.lua, which never assumes a
	-- fixed pose either.
	self.leg_rest_y = {}
	for _, id in ipairs(LEGS) do
		self.leg_rest_y[id] = go.get_position(self.leg_paths[id]).y
	end
	self.body_rest_y = go.get_position(self.body_path).y
	self.head_rest_y = go.get_position(self.head_path).y

	self.base_scale = BASE_SCALE_MULT * art_scale_factor
	local s = vmath.vector3(self.base_scale, self.base_scale, 1.0)
	go.set_scale(s, self.hit_path)
	go.set_scale(s, self.shadow_path)
	return self
end

function R:apply_appearance(cfg)
	-- Scale the rig so each quadruped variant (rat/dog/boar/burelom) reads as
	-- a distinct, escalating threat. Tint is left at the art's native colors
	-- unless a cfg override is given (still used by placeholder variants that
	-- reuse another species' art, e.g. burelom on the rat rig).
	if cfg and cfg.scale then
		self.base_scale = cfg.scale * self.art_scale_factor
		local s = vmath.vector3(self.base_scale, self.base_scale, 1.0)
		go.set_scale(s, self.hit_path)
		go.set_scale(s, self.shadow_path)
	end
	if cfg and cfg.tint then
		local tint = vmath.vector4(cfg.tint[1], cfg.tint[2], cfg.tint[3], 1.0)
		for _, path in ipairs(self.part_paths) do
			go.set(msg.url(nil, path, "sprite"), "tint", tint)
		end
	end
end

-- Quadrupeds carry no weapons; equipment calls are no-ops.
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

	-- Leg positions are mirrored per-part for enemies (see mirror_for_enemy),
	-- so "swing toward +local_x" only means "swing toward the front" for the
	-- unmirrored (player) facing. self.flip carries that correction: +1 keeps
	-- the raw angle, -1 (enemy) points the swing at the enemy's actual front
	-- (-x, since its legs now sit on the negative side).
	local swing = WALK_SWING_DEG * self.leg_swing_mult
	for _, id in ipairs(fwd) do
		local path = self.leg_paths[id]
		local rest_y = self.leg_rest_y[id]
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, swing * self.flip, go.EASING_OUTSINE, WALK_STEP_TIME)
		go.animate(path, "position.y", go.PLAYBACK_ONCE_FORWARD, rest_y + WALK_LIFT,
			go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
				go.animate(path, "position.y", go.PLAYBACK_ONCE_FORWARD, rest_y,
					go.EASING_INSINE, WALK_STEP_TIME * 0.5)
			end)
	end
	for _, id in ipairs(back) do
		local path = self.leg_paths[id]
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -swing * self.flip, go.EASING_INOUTSINE, WALK_STEP_TIME)
	end
	go.animate(self.body_path, "position.y", go.PLAYBACK_ONCE_FORWARD, self.body_rest_y - WALK_BODY_BOB * 0.5,
		go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
			go.animate(self.body_path, "position.y", go.PLAYBACK_ONCE_FORWARD, self.body_rest_y + WALK_BODY_BOB * 0.5,
				go.EASING_INOUTSINE, WALK_STEP_TIME * 0.5)
		end)

	-- Head nods with the same cadence as the body bob (dips as the body dips)
	-- plus a small forward-down tilt, so the head reads as part of the trot
	-- instead of floating rigidly above it.
	go.animate(self.head_path, "position.y", go.PLAYBACK_ONCE_FORWARD, self.head_rest_y - WALK_HEAD_BOB * 0.5,
		go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
			go.animate(self.head_path, "position.y", go.PLAYBACK_ONCE_FORWARD, self.head_rest_y + WALK_HEAD_BOB * 0.5,
				go.EASING_INOUTSINE, WALK_STEP_TIME * 0.5)
		end)
	go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -WALK_HEAD_NOD_DEG * self.rot_sign,
		go.EASING_OUTSINE, WALK_STEP_TIME * 0.5, 0, function()
			go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, WALK_HEAD_NOD_DEG * self.rot_sign,
				go.EASING_INOUTSINE, WALK_STEP_TIME * 0.5)
		end)

	timer.delay(WALK_STEP_TIME, false, function()
		trot_phase(self, token, back, fwd)
	end)
end

-- Collapses the rig straight down onto the ground (not a sideways topple):
-- the body sinks and tilts slightly nose-down, the head drops hard, front
-- legs splay forward and back legs splay backward, then everything fades
-- once it has settled. Hand-animated since quadrupeds have no Panthera
-- skeleton (see the human "death" clip in human_panthera.lua for the
-- equivalent).
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
	-- (toward the tail), settling as the body sinks between them. Same
	-- self.flip correction as the walk trot - this is a spatial front/back
	-- swing, not a hflip-texture-landmark thing, so it needs flip, not
	-- rot_sign (see trot_phase).
	for _, id in ipairs(LEGS) do
		local path = self.leg_paths[id]
		go.cancel_animations(path, "euler.z")
		go.cancel_animations(path, "position.y")
		go.animate(path, "euler.z", go.PLAYBACK_ONCE_FORWARD, DEATH_LEG_SPLAY[id] * self.flip * self.leg_swing_mult,
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
	local swing = WALK_SWING_DEG * self.leg_swing_mult
	go.set(self.leg_paths["leg_front_left"], "euler.z", -swing * self.flip)
	go.set(self.leg_paths["leg_back_right"], "euler.z", -swing * self.flip)
	go.set(self.leg_paths["leg_front_right"], "euler.z", swing * self.flip)
	go.set(self.leg_paths["leg_back_left"], "euler.z", swing * self.flip)
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
		-- Ram charge on `hit` (never `root` - root is the logical battlefield
		-- position unit.lua owns; animating it to a small local offset would
		-- teleport the unit): pull back, slam forward, recoil back to rest.
		-- opts.callback fires once the recoil settles, matching the old
		-- lunge's full-cycle timing.
		local pull = -self.flip * ATTACK_WINDUP_PULL
		local charge = self.flip * ATTACK_CHARGE_DIST
		local shadow = self.shadow_path
		go.cancel_animations(self.hit_path, "position.x")
		if shadow then go.cancel_animations(shadow, "position.x") end
		go.cancel_animations(self.head_path, "euler.z")
		go.set(self.hit_path, "position.x", 0)
		if shadow then go.set(shadow, "position.x", 0) end
		go.set(self.head_path, "euler.z", 0)
		-- Shadow rides the same charge as "hit" so it stays tied to the body during the ram.
		go.animate(self.hit_path, "position.x", go.PLAYBACK_ONCE_FORWARD, pull,
			go.EASING_OUTSINE, ATTACK_WINDUP_TIME, 0, function()
				go.animate(self.hit_path, "position.x", go.PLAYBACK_ONCE_FORWARD, charge,
					go.EASING_INQUAD, ATTACK_CHARGE_TIME, 0, function()
						go.animate(self.hit_path, "position.x", go.PLAYBACK_ONCE_FORWARD, 0,
							go.EASING_OUTQUAD, ATTACK_RETURN_TIME, 0, opts.callback)
					end)
			end)
		if shadow then
			go.animate(shadow, "position.x", go.PLAYBACK_ONCE_FORWARD, pull,
				go.EASING_OUTSINE, ATTACK_WINDUP_TIME, 0, function()
					go.animate(shadow, "position.x", go.PLAYBACK_ONCE_FORWARD, charge,
						go.EASING_INQUAD, ATTACK_CHARGE_TIME, 0, function()
							go.animate(shadow, "position.x", go.PLAYBACK_ONCE_FORWARD, 0,
								go.EASING_OUTQUAD, ATTACK_RETURN_TIME)
						end)
				end)
		end
		go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, -ATTACK_HEAD_TILT_DEG * self.rot_sign,
			go.EASING_OUTSINE, ATTACK_WINDUP_TIME + ATTACK_CHARGE_TIME, 0, function()
				go.animate(self.head_path, "euler.z", go.PLAYBACK_ONCE_FORWARD, 0, go.EASING_OUTQUAD, ATTACK_RETURN_TIME)
			end)
	elseif state == "death" then
		stop_ambient_cycle(self)
		play_death(self)
		if opts.callback then opts.callback() end
	elseif state == "walk" then
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

-- Knockback recoil: a quick squash on `hit`. Visual only - `root` (the
-- logical position) never moves, so the combat FSM never chases or drifts.
function R:recoil(_)
	for _, path in ipairs(self.part_paths) do
		fx.flash_single(path)
	end
	local base = self.base_scale
	local shadow = self.shadow_path
	go.cancel_animations(self.hit_path, "scale.x")
	if shadow then go.cancel_animations(shadow, "scale.x") end
	-- Reset to base before the squash so a pingpong always returns to base,
	-- never to a mid-squash value (which would accumulate and leave the rig
	-- standing crooked after repeated splash hits).
	go.set_scale(vmath.vector3(base, base, 1.0), self.hit_path)
	go.animate(self.hit_path, "scale.x", go.PLAYBACK_ONCE_PINGPONG, base * 0.85,
		go.EASING_OUTQUAD, 0.12)
	-- Shadow squashes with "hit" so it stays tied to the body on knockback.
	if shadow then
		go.set(shadow, "scale.x", base)
		go.animate(shadow, "scale.x", go.PLAYBACK_ONCE_PINGPONG, base * 0.85,
			go.EASING_OUTQUAD, 0.12)
	end
end

function R:stop()
	go.cancel_animations(self.hit_path, "scale.x")
	go.cancel_animations(self.hit_path, "position.x")
	stop_ambient_cycle(self)
end

return R
