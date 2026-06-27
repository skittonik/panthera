-- unit.lua
-- A combat unit: stats, HP bar and damage/death handling, with all visuals and
-- animation delegated to a per-type rig (rig_human, rig_rat, ...). This keeps
-- the combat code identical across unit types.

local units = require("first_anim.modules.units")
local weapons = require("first_anim.modules.weapons")
local theme = require("first_anim.modules.theme")

local Unit = {}
Unit.__index = Unit

local MIN_FILL = 0.0001

-- Resolve attack range / timing: from the equipped weapon, or the unit type's
-- built-in melee for weaponless types (e.g. rat).
function Unit:resolve_combat(weapon_skin)
	if self.uses_weapons then
		local w = weapons.get_weapon_def(weapon_skin)
		self.attack_range = w and w.attack_range or 110
		self.hit_delay = w and w.hit_delay or 0.12
		self.burst = w and w.burst or nil
	else
		local m = units.get(self.unit_type).melee or {}
		self.attack_range = m.attack_range or 110
		self.hit_delay = m.hit_delay or 0.3
		self.burst = nil
	end
end

-- opts: { unit_type, pos, is_enemy, cfg }
function Unit.spawn(opts)
	local udef = units.get(opts.unit_type)
	local rig = units.get_rig(opts.unit_type).new({
		factory_url = "/factories#" .. udef.factory,
		pos = opts.pos,
		is_enemy = opts.is_enemy,
	})

	local self = setmetatable({}, Unit)
	self.unit_type = opts.unit_type
	self.uses_weapons = udef.uses_weapons
	self.hp_bar_offset_y = udef.hp_bar_offset_y or theme.hp_bar.offset_y
	self.rig = rig
	self.is_enemy = opts.is_enemy
	self.p_ids = rig.p_ids
	self.root_path = rig.root_path
	self.hp_bg_path = rig.p_ids[hash("/hp_bg")]
	self.hp_fill_path = rig.p_ids[hash("/hp_fill")]

	local cfg = opts.cfg
	self.name = cfg.name
	self.hp = cfg.hp
	self.max_hp = cfg.hp
	self.move_speed = cfg.move_speed
	self.attack_cooldown = cfg.attack_cooldown
	self.attack_timer = cfg.attack_cooldown
	self.damage = cfg.damage
	self.attacking = false
	self.current_anim = nil
	self:resolve_combat(cfg.weapon_skin)

	local s = vmath.vector3(theme.unit_scale, theme.unit_scale, 1.0)
	go.set_scale(s, self.hp_bg_path)
	go.set_scale(s, self.hp_fill_path)

	rig:apply_appearance(cfg)

	local fill = opts.is_enemy and theme.color.hp_fill_enemy or theme.color.hp_fill_ally
	go.set(msg.url(nil, self.hp_fill_path, "sprite"), "tint", fill)
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

-- Animation (delegated to rig) ------------------------------------------------

function Unit:play(state, opts)
	self.current_anim = state
	self.rig:play(state, opts)
end

function Unit:ensure_anim(state, loop)
	if self.current_anim ~= state then
		self:play(state, { is_loop = loop })
	end
end

function Unit:attack(callback)
	self.rig:muzzle()
	self.current_anim = "attack"
	self.rig:play("attack", { is_loop = false, callback = callback })
end

-- Live loadout edit (player only); recompute weapon-derived combat data.
function Unit:set_equipment(weapon_skin, body_skin, head_skin)
	self.rig:set_equipment(weapon_skin, body_skin, head_skin)
	self:resolve_combat(weapon_skin)
end

-- HP bar ----------------------------------------------------------------------

function Unit:refresh_hp_label()
	label.set_text(msg.url(nil, self.hp_bg_path, "label"),
		string.format("%s: %d / %d", self.name, math.max(0, self.hp), self.max_hp))
end

function Unit:set_hp_bar_visible(visible)
	local cmd = visible and "enable" or "disable"
	msg.post(self.hp_bg_path, cmd)
	msg.post(self.hp_fill_path, cmd)
end

function Unit:position_hp_bar()
	local pos = self:get_position()
	local offset_y = self.hp_bar_offset_y
	go.set_position(vmath.vector3(pos.x, pos.y + offset_y, theme.hp_bar.z_bg), self.hp_bg_path)
	go.set_position(vmath.vector3(pos.x + theme.hp_bar.fill_dx, pos.y + offset_y, theme.hp_bar.z_fill), self.hp_fill_path)
end

local function set_fill(self)
	local ratio = self.hp / self.max_hp
	local scale_x = math.max(MIN_FILL, theme.unit_scale * ratio)
	go.set_scale(vmath.vector3(scale_x, theme.unit_scale, 1), self.hp_fill_path)
end

function Unit:reset_hp()
	self.hp = self.max_hp
	set_fill(self)
	self:refresh_hp_label()
end

function Unit:revive()
	self:reset_hp()
	self.attacking = false
	if self.rig.shadow_path then
		msg.post(self.rig.shadow_path, "enable")
	end
	self:play("idle", { is_loop = true })
end

-- Damage / death --------------------------------------------------------------

-- ctx = { smudge_factory, track(path) } for the death smudge.
function Unit:apply_damage(amount, ctx)
	if self.hp <= 0 then return "already_dead" end

	self.hp = math.max(0, self.hp - amount)
	set_fill(self)
	self:refresh_hp_label()

	if self.hp > 0 then
		self.rig:hurt()
		return "hit"
	end

	self.attacking = false
	self:play("death", { is_loop = false })
	self:set_hp_bar_visible(false)
	if self.rig.shadow_path then
		msg.post(self.rig.shadow_path, "disable")
	end

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
	self.rig:stop()
	for _, path in pairs(self.p_ids) do
		go.delete(path, true)
	end
end

return Unit
