-- unit.lua
-- A combat unit: stats, HP bar and damage/death handling, with all visuals and
-- animation delegated to a per-type rig (rig_human, rig_quadruped, ...). This keeps
-- the combat code identical across unit types.

local units = require("first_anim.modules.units")
local weapons = require("first_anim.modules.weapons")
local theme = require("first_anim.modules.theme")
local dmg_number = require("first_anim.modules.dmg_number")

local Unit = {}
Unit.__index = Unit

local MIN_FILL = 0.0001

-- Resolve attack range / timing: from the equipped weapon, or the unit type's
-- built-in melee for weaponless types (e.g. rat).
function Unit:resolve_combat(weapon_skin)
	if self.uses_weapons then
		local w = weapons.get_weapon_def(weapon_skin)
		self.weapon_def = w
		self.attack_range = w and w.attack_range or 110
		self.hit_delay = w and w.hit_delay or 0.12
		self.burst = w and w.burst or nil
		self.damage_mult = (w and w.damage_mult) or 1.0
		self.splash_radius = w and w.splash_radius or nil
		self.max_targets = w and w.max_targets or nil
		self.slow = w and w.slow or nil
		self.knockback = w and w.knockback or nil
	else
		local m = units.get(self.unit_type).melee or {}
		self.weapon_def = nil
		self.attack_range = m.attack_range or 110
		self.hit_delay = m.hit_delay or 0.3
		self.burst = nil
		self.damage_mult = 1.0
		self.splash_radius = nil
		self.max_targets = nil
		self.slow = m.slow or nil
		self.knockback = nil
	end
end

-- opts: { unit_type, pos, is_enemy, cfg }
function Unit.spawn(opts)
	local udef = units.get(opts.unit_type)
	local rig = units.get_rig(opts.unit_type).new({
		unit_type = opts.unit_type,
		factory_url = "/factories#" .. udef.factory,
		pos = opts.pos,
		is_enemy = opts.is_enemy,
	})

	local self = setmetatable({}, Unit)
	self.unit_type = opts.unit_type
	self.uses_weapons = udef.uses_weapons
	-- cfg override lets scaled placeholders (boar/burelom on the rat rig) lift the bar.
	self.hp_bar_offset_y = opts.cfg.hp_bar_offset_y or udef.hp_bar_offset_y or theme.hp_bar.offset_y
	self.aim_offset_y = udef.aim_offset_y or 0
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
	-- attack_speed is the canonical stat (100 = 1 atk/s); cooldown is derived once.
	self.attack_speed = math.max(cfg.attack_speed or 100, 1)
	self.attack_cooldown = 100 / self.attack_speed
	self.attack_timer = self.attack_cooldown
	self.damage = cfg.damage
	self.defense = cfg.defense or 0
	self.attacking = false
	self.in_range = false
	self.range_entry_timer = 0
	self.current_anim = nil
	self.slow_mult = 1.0
	self.slow_timer = 0
	self:resolve_combat(cfg.weapon_skin)
	self.power = self:compute_power()

	local s = vmath.vector3(theme.unit_scale, theme.unit_scale, 1.0)
	go.set_scale(s, self.hp_bg_path)
	go.set_scale(s, self.hp_fill_path)

	rig:apply_appearance(cfg)

	local fill = opts.is_enemy and theme.color.hp_fill_enemy or theme.color.hp_fill_ally
	go.set(msg.url(nil, self.hp_fill_path, "sprite"), "tint", fill)
	go.set(msg.url(nil, self.hp_bg_path, "sprite"), "tint", theme.color.hp_bg)
	self:refresh_hp_label()
	self:set_hp_bar_visible(false)

	return self
end

-- Analytic build strength (doc "Power"): DPS * effective HP. Static per loadout,
-- recomputed whenever weapon-derived stats change. Used only for the matchup readout.
function Unit:compute_power()
	local dps = (self.damage * (self.damage_mult or 1.0)) / self.attack_cooldown
	return math.floor(dps * self.max_hp * (1 + self.defense / 100) + 0.5)
end

function Unit:is_alive()
	return self.hp > 0 and not self.destroyed
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

-- Where incoming projectiles should aim: the unit's body center (root + a
-- per-type vertical offset), not its feet.
function Unit:aim_world_position()
	local p = self:get_position()
	return vmath.vector3(p.x, p.y + self.aim_offset_y, p.z)
end

-- World position of the weapon muzzle, used as the projectile origin. nil for
-- rigs without a muzzle (e.g. the rat).
function Unit:muzzle_world_position()
	if self.rig.muzzle_position then
		return self.rig:muzzle_position()
	end
	return nil
end

-- Slow status: a hit shaves `factor` (0..1) off move speed for `duration`s.
-- The strongest active slow wins; its timer is refreshed by later hits.
function Unit:apply_slow(factor, duration)
	local mult = 1.0 - factor
	if mult < self.slow_mult then self.slow_mult = mult end
	if duration > self.slow_timer then self.slow_timer = duration end
end

function Unit:update_slow(dt)
	if self.slow_timer > 0 then
		self.slow_timer = self.slow_timer - dt
		if self.slow_timer <= 0 then
			self.slow_timer = 0
			self.slow_mult = 1.0
		end
	end
end

-- Live loadout edit (player only); recompute weapon-derived combat data.
function Unit:set_equipment(weapon_skin, body_skin, head_skin)
	self.rig:set_equipment(weapon_skin, body_skin, head_skin)
	self:resolve_combat(weapon_skin)
	self.power = self:compute_power()
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
	self:set_hp_bar_visible(false)
end

function Unit:revive()
	self:reset_hp()
	self.attacking = false
	self.in_range = false
	self.range_entry_timer = 0
	self.slow_mult = 1.0
	self.slow_timer = 0
	if self.rig.shadow_path then
		msg.post(self.rig.shadow_path, "enable")
	end
	self:play("idle", { is_loop = true })
end

-- Damage / death --------------------------------------------------------------

-- ctx = { smudge_factory, track(path) } for the death smudge.
-- recoil (px, optional): a directional knockback lurch (visual only, via the
-- rig) used instead of the normal flinch; composes with the death topple too.
function Unit:apply_damage(amount, ctx, recoil)
	if self.hp <= 0 then return "already_dead" end

	self.hp = math.max(0, self.hp - amount)
	set_fill(self)
	self:refresh_hp_label()

	if self.hp > 0 then
		self:set_hp_bar_visible(true)
		dmg_number.spawn(self:aim_world_position(), amount)
		if recoil and recoil > 0 and self.rig.recoil then
			self.rig:recoil(recoil)
		else
			self.rig:hurt()
		end
		return "hit"
	end

	self.attacking = false
	dmg_number.spawn(self:aim_world_position(), amount)
	self:play("death", { is_loop = false })
	if recoil and recoil > 0 and self.rig.recoil then
		self.rig:recoil(recoil)
	end
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
	self.destroyed = true
	self.rig:stop()
	for _, path in pairs(self.p_ids) do
		go.delete(path, true)
	end
end

return Unit
