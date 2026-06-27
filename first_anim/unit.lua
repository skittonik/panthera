-- unit.lua
-- A combat unit: one factory-spawned rig (player or enemy) plus its stats,
-- animation states, HP bar and damage/death handling. Player and enemy share
-- this exact code; the only differences are flip direction and HP bar color.

local panthera = require("panthera.panthera")
local animation = require("first_anim.first_anim_panthera")
local skins = require("first_anim.skins")
local fx = require("first_anim.fx")
local theme = require("first_anim.theme")

local Unit = {}
Unit.__index = Unit

local MIN_FILL = 0.0001

-- Maps the animation's logical node hashes onto this rig's factory paths.
local function build_anim_objects(p_ids)
	local map = {}
	local nodes = {
		"root", "hit", "shadow", "body", "head", "head_pivot",
		"left_leg", "right_leg", "hand_right", "hand_left", "weapon", "muzzle",
		"weapon_impact", "weapon_stabbing", "weapon_pistol", "weapon_rifle", "weapon_shotgun",
	}
	for _, id in ipairs(nodes) do
		map[hash("/" .. id)] = p_ids[hash("/human/" .. id)]
	end
	return map
end

-- opts: { factory_url, pos, is_enemy, cfg }
-- cfg:  { name, hp, move_speed, attack_cooldown, damage, weapon_skin, body_skin, head_skin }
function Unit.spawn(opts)
	local cfg = opts.cfg
	local flip = opts.is_enemy and -1.0 or 1.0
	local p_ids = collectionfactory.create(opts.factory_url, opts.pos, vmath.quat(), {},
		vmath.vector3(flip, 1.0, 1.0))

	local self = setmetatable({}, Unit)
	self.p_ids = p_ids
	self.resolve = skins.resolver_from_factory(p_ids)
	self.is_enemy = opts.is_enemy

	self.root_path   = p_ids[hash("/human/root")]
	self.shadow_path = p_ids[hash("/human/shadow")]
	self.hp_bg_path  = p_ids[hash("/hp_bg")]
	self.hp_fill_path= p_ids[hash("/hp_fill")]

	-- Stats
	self.name = cfg.name
	self.hp = cfg.hp
	self.max_hp = cfg.hp
	self.move_speed = cfg.move_speed
	self.attack_cooldown = cfg.attack_cooldown
	self.attack_timer = opts.is_enemy and cfg.attack_cooldown or 0
	self.damage = cfg.damage
	self.attacking = false   -- true only while a one-shot attack clip is playing
	self.current_anim = nil  -- last base clip, for ensure_anim de-duplication

	-- Scale child templates down to unit size.
	local s = vmath.vector3(theme.unit_scale, theme.unit_scale, 1.0)
	go.set_scale(s, p_ids[hash("/human/hit")])
	go.set_scale(s, self.shadow_path)
	go.set_scale(s, self.hp_bg_path)
	go.set_scale(s, self.hp_fill_path)

	-- Independent base + overlay animation states on the same rig.
	self.anim = panthera.create_go(animation, nil, build_anim_objects(p_ids))
	self.overlay = panthera.create_go(animation, nil, build_anim_objects(p_ids))

	-- Apply appearance.
	skins.apply_defaults(self.resolve)
	if cfg.body_skin then skins.apply_attachment(self.resolve, "body", cfg.body_skin) end
	if cfg.head_skin then skins.apply_attachment(self.resolve, "head", cfg.head_skin) end
	self:set_weapon(cfg.weapon_skin)

	-- HP bar appearance.
	local fill_color = opts.is_enemy and theme.color.hp_fill_enemy or theme.color.hp_fill_ally
	go.set(msg.url(nil, self.hp_fill_path, "sprite"), "tint", fill_color)
	go.set(msg.url(nil, self.hp_bg_path, "sprite"), "tint", theme.color.hp_bg)
	self:refresh_hp_label()

	return self
end

function Unit:is_alive()
	return self.hp > 0
end

function Unit:get_position()
	return go.get_position(self.root_path)
end

function Unit:set_position(pos)
	go.set_position(pos, self.root_path)
end

function Unit:set_z(z)
	local pos = go.get_position(self.root_path)
	pos.z = z
	go.set_position(pos, self.root_path)
end

-- Re-resolve all weapon-derived combat data and swap the visible weapon.
function Unit:set_weapon(weapon_skin)
	self.weapon_skin = weapon_skin
	self.weapon_def = skins.get_weapon_def(weapon_skin)
	self.weapon_type = skins.get_weapon_type(weapon_skin) or "impact"
	self.attack_range = skins.get_attack_range(weapon_skin)
	self.attack_animation = skins.get_attack_animation(weapon_skin)
	skins.apply_attachment(self.resolve, "weapon", weapon_skin)
end

-- Live loadout edit while paused (player only).
function Unit:set_equipment(weapon_skin, body_skin, head_skin)
	skins.apply_attachment(self.resolve, "body", body_skin)
	skins.apply_attachment(self.resolve, "head", head_skin)
	self:set_weapon(weapon_skin)
end

-- Play a base clip (always restarts it, even if it's the current one).
function Unit:play(anim_id, opts)
	self.current_anim = anim_id
	panthera.play(self.anim, anim_id, opts)
end

-- Play a looping base clip only if it isn't already the active one. Keeps the
-- per-frame FSM from restarting walk/idle every tick.
function Unit:ensure_anim(anim_id, loop)
	if self.current_anim ~= anim_id then
		self:play(anim_id, { is_loop = loop })
	end
end

function Unit:refresh_hp_label()
	label.set_text(msg.url(nil, self.hp_bg_path, "label"),
		string.format("%s: %d / %d", self.name, math.max(0, self.hp), self.max_hp))
end

function Unit:set_hp_bar_visible(visible)
	local cmd = visible and "enable" or "disable"
	msg.post(self.hp_bg_path, cmd)
	msg.post(self.hp_fill_path, cmd)
end

-- Keep the HP bar floating above the rig's current position.
function Unit:position_hp_bar()
	local pos = self:get_position()
	go.set_position(vmath.vector3(pos.x, pos.y + theme.hp_bar.offset_y, theme.hp_bar.z_bg), self.hp_bg_path)
	go.set_position(vmath.vector3(pos.x + theme.hp_bar.fill_dx, pos.y + theme.hp_bar.offset_y, theme.hp_bar.z_fill), self.hp_fill_path)
end

local function set_fill(self)
	local ratio = self.hp / self.max_hp
	local scale_x = math.max(MIN_FILL, theme.unit_scale * ratio)
	go.set_scale(vmath.vector3(scale_x, theme.unit_scale, 1), self.hp_fill_path)
end

-- Reset to full health (used when reviving the player on pause).
function Unit:reset_hp()
	self.hp = self.max_hp
	set_fill(self)
	self:refresh_hp_label()
end

-- Fully restore a unit that may have died: HP, shadow and a clean idle pose.
-- (Death disables the shadow and plays a terminal clip, so revive undoes both.)
function Unit:revive()
	self:reset_hp()
	self.attacking = false
	msg.post(self.shadow_path, "enable")
	self:play("default", { is_loop = true })
end

-- Apply damage. ctx = { smudge_factory, track(path) } for the death smudge.
-- Returns "hit", "dead" or "already_dead".
function Unit:apply_damage(amount, ctx)
	if self.hp <= 0 then return "already_dead" end

	self.hp = math.max(0, self.hp - amount)
	set_fill(self)
	self:refresh_hp_label()

	if self.hp > 0 then
		panthera.play(self.overlay, "damage", { is_loop = false })
		fx.flash(self.resolve)
		return "hit"
	end

	-- Death: terminal animation, hide bars, swap shadow for a ground smudge.
	self.attacking = false
	self:play("death", { is_loop = false })
	self:set_hp_bar_visible(false)
	msg.post(self.shadow_path, "disable")

	local pos = self:get_position()
	pos.z = theme.smudge.z
	local smudge = factory.create(ctx.smudge_factory, pos)
	ctx.track(smudge)
	go.set_scale(vmath.vector3(MIN_FILL, MIN_FILL, 1.0), smudge)
	go.animate(smudge, "scale", go.PLAYBACK_ONCE_FORWARD,
		vmath.vector3(theme.smudge.scale, theme.smudge.scale, 1.0),
		go.EASING_OUTQUAD, theme.smudge.grow_time)
	return "dead"
end

function Unit:destroy()
	if self.anim then panthera.stop(self.anim) end
	if self.overlay then panthera.stop(self.overlay) end
	for _, path in pairs(self.p_ids) do
		go.delete(path, true)
	end
end

return Unit
