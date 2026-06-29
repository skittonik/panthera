-- rig_human.lua
-- The humanoid rig: a Panthera-animated skeleton (body/head/legs/hands + a
-- swappable weapon) with muzzle particles and a per-sprite damage flash.
--
-- Implements the rig interface consumed by unit.lua:
--   .new(opts) -> rig   (opts: factory_url, pos, is_enemy)
--   .root_path, .shadow_path, .p_ids
--   :apply_appearance(cfg) / :set_weapon(id) / :set_equipment(w,b,h)
--   :play(state, opts)  (state: idle|walk|attack|death)
--   :muzzle() / :hurt() / :stop()

local panthera = require("panthera.panthera")
local animation = require("first_anim.rigs.human.human_panthera")
local skins = require("first_anim.modules.skins")
local weapons = require("first_anim.modules.weapons")
local fx = require("first_anim.modules.fx")
local theme = require("first_anim.modules.theme")

local R = {}
R.__index = R

-- Normalized state -> Panthera clip. "attack" is resolved from the weapon.
local CLIP = { idle = "default", walk = "walk", death = "death" }

local CROSSFADE = 0.15

local ANIM_NODES = {
	"root", "hit", "shadow", "body", "head", "head_pivot",
	"left_leg", "right_leg", "hand_right", "hand_left", "weapon", "muzzle",
	"weapon_impact", "weapon_stabbing", "weapon_pistol", "weapon_rifle", "weapon_shotgun",
}

local function build_anim_objects(p_ids)
	local map = {}
	for _, id in ipairs(ANIM_NODES) do
		map[hash("/" .. id)] = p_ids[hash("/human/" .. id)]
	end
	return map
end

function R.new(opts)
	local flip = opts.is_enemy and -1.0 or 1.0
	local p_ids = collectionfactory.create(opts.factory_url, opts.pos, vmath.quat(), {},
		vmath.vector3(flip, 1.0, 1.0))

	local self = setmetatable({}, R)
	self.p_ids = p_ids
	self.is_enemy = opts.is_enemy
	self.resolve = skins.resolver_from_factory(p_ids)
	self.root_path = p_ids[hash("/human/root")]
	self.shadow_path = p_ids[hash("/human/shadow")]
	self.weapon_def = nil

	-- Scale the rig's visual children down to unit size.
	local s = vmath.vector3(theme.unit_scale, theme.unit_scale, 1.0)
	go.set_scale(s, p_ids[hash("/human/hit")])
	go.set_scale(s, self.shadow_path)

	-- Independent base + overlay (hit reaction) animation states.
	self.anim_objects = build_anim_objects(p_ids)
	self.anim = panthera.create_go(animation, nil, self.anim_objects)
	self.overlay = panthera.create_go(animation, nil, self.anim_objects)

	self.alive = true

	return self
end

function R:apply_appearance(cfg)
	skins.apply_defaults(self.resolve)
	if cfg.body_skin then skins.apply_attachment(self.resolve, "body", cfg.body_skin) end
	if cfg.head_skin then skins.apply_attachment(self.resolve, "head", cfg.head_skin) end
	if cfg.weapon_skin then self:set_weapon(cfg.weapon_skin) end
end

function R:set_weapon(weapon_id)
	self.weapon_def = weapons.get_weapon_def(weapon_id)
	weapons.equip(self.resolve, weapon_id)
end

function R:set_equipment(weapon_id, body_id, head_id)
	skins.apply_attachment(self.resolve, "body", body_id)
	skins.apply_attachment(self.resolve, "head", head_id)
	self:set_weapon(weapon_id)
end

function R:play(state, opts)
	opts = opts or {}
	local clip
	if state == "attack" then
		clip = (self.weapon_def and self.weapon_def.attack_animation) or "attack_impact"
	else
		clip = CLIP[state] or state
	end

	-- Attack is a hard one-shot: its muzzle/hit beats are driven by combat's own
	-- timers, so it must start instantly and stay in sync. The smooth blend back
	-- to idle/walk lands on the next state change (crossfade branch below).
	--
	-- stop() before play() cancels any pending walk→idle crossfade timer. Without
	-- this, at 2x/4x speed the crossfade fires AFTER the attack starts (RANGE_ENTRY_DELAY
	-- is sim-time, crossfade timer is real-time), silently interrupting the attack
	-- and leaving the attacking flag stuck true.
	if state == "attack" then
		panthera.stop(self.anim, true)
		panthera.play(self.anim, clip, opts)
		return
	end

	if state == "death" then
		local hr_rifle = self.resolve("hand_right_rifle")
		if hr_rifle then msg.post(hr_rifle, "disable") end
		local hr_shotgun = self.resolve("hand_right_shotgun")
		if hr_shotgun then msg.post(hr_shotgun, "disable") end
		-- Instant switch (no crossfade): prevents a 0.15s ghost-attack visual where
		-- the attack animation blends into death, making the unit look alive.
		panthera.play(self.anim, clip, opts)
		self.prev_was_death = true
		return
	end

	-- Base loop (idle / walk): crossfade for a smooth blend, except on the first
	-- play (nothing to blend from) or when leaving the terminal death pose, where
	-- crossfade can't restore the properties death zeroed out - a plain play resets
	-- them back to node defaults first.
	if not self.has_played or self.prev_was_death then
		panthera.play(self.anim, clip, opts)
	else
		panthera.crossfade(self.anim, clip, CROSSFADE, opts)
	end
	self.has_played = true
	self.prev_was_death = false
end

function R:muzzle()
	fx.muzzle(self.resolve, self.is_enemy, self.weapon_def, function() return self.alive end)
end

-- World position of the muzzle GO (positioned by fx.muzzle at attack time).
-- Guarded by `alive` so a delayed shot never reads a destroyed GO.
function R:muzzle_position()
	if not self.alive then return nil end
	local m = self.resolve("muzzle")
	return m and go.get_world_position(m) or nil
end

function R:hurt()
	panthera.play(self.overlay, "damage", { is_loop = false })
	fx.flash(self.resolve)
end

-- Directional knockback recoil: a hard backward lurch of the visual body that
-- springs back. Driven on the "hit" node (the same flinch layer the "damage"
-- clip uses) so it stays purely visual - the logical root never moves, so the
-- combat FSM never chases or drifts. Local -x = backward for both facings.
function R:recoil(strength)
	fx.flash(self.resolve)
	local hit = self.p_ids[hash("/human/hit")]
	if not hit then return end
	local shadow = self.shadow_path
	local out = vmath.vector3(-strength, 0, 0)
	local home = vmath.vector3(0, 0, 0)

	go.cancel_animations(hit, "position")
	if shadow then go.cancel_animations(shadow, "position") end
	-- Reset to home first so a recoil interrupting an unfinished return can never
	-- leave the body/shadow offset (units standing crooked after the battle).
	go.set_position(home, hit)
	if shadow then go.set_position(home, shadow) end

	-- Shove out fast, then ease back smoothly (no elastic bounce -> reads as a
	-- weighty hit, not a cartoon spring). The shadow rides along so the body
	-- stays grounded instead of sliding off its own shadow.
	local function settle()
		go.animate(hit, "position", go.PLAYBACK_ONCE_FORWARD, home, go.EASING_INOUTCUBIC, 0.45)
		if shadow then
			go.animate(shadow, "position", go.PLAYBACK_ONCE_FORWARD, home, go.EASING_INOUTCUBIC, 0.45)
		end
	end
	go.animate(hit, "position", go.PLAYBACK_ONCE_FORWARD, out, go.EASING_OUTCUBIC, 0.12, 0, settle)
	if shadow then
		go.animate(shadow, "position", go.PLAYBACK_ONCE_FORWARD, out, go.EASING_OUTCUBIC, 0.12)
	end
end

function R:stop()
	self.alive = false
	if self.anim then panthera.stop(self.anim) end
	if self.overlay then panthera.stop(self.overlay) end
end

return R
