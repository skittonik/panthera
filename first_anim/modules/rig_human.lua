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
	local clip
	if state == "attack" then
		clip = (self.weapon_def and self.weapon_def.attack_animation) or "attack_impact"
	else
		clip = CLIP[state] or state
	end
	if state == "death" then
		local hr_rifle = self.resolve("hand_right_rifle")
		if hr_rifle then msg.post(hr_rifle, "disable") end
		local hr_shotgun = self.resolve("hand_right_shotgun")
		if hr_shotgun then msg.post(hr_shotgun, "disable") end
	end
	panthera.play(self.anim, clip, opts)
end

function R:muzzle()
	fx.muzzle(self.resolve, self.is_enemy, self.weapon_def, function() return self.alive end)
end

function R:hurt()
	panthera.play(self.overlay, "damage", { is_loop = false })
	fx.flash(self.resolve)
end

function R:stop()
	self.alive = false
	if self.anim then panthera.stop(self.anim) end
	if self.overlay then panthera.stop(self.overlay) end
end

return R
