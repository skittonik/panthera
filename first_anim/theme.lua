-- theme.lua
-- Single source of truth for every visual constant used by the autobattle:
-- colors, layout offsets, scales, durations and spawn-zone geometry.
-- Nothing here knows about game logic - it is pure presentation data.

local M = {}

-- Palette -------------------------------------------------------------------
M.color = {
	ui_active   = vmath.vector4(0.15, 0.75, 0.55, 1.0),
	ui_inactive = vmath.vector4(0.22, 0.25, 0.30, 1.0),

	status_battle  = vmath.vector4(0.15, 0.75, 0.55, 1.0),
	status_victory = vmath.vector4(0.15, 0.75, 0.55, 1.0),
	status_defeat  = vmath.vector4(0.85, 0.15, 0.15, 1.0),
	status_paused  = vmath.vector4(0.90, 0.60, 0.10, 1.0),

	hp_bg        = vmath.vector4(0.11, 0.12, 0.15, 0.8),
	hp_fill_ally = vmath.vector4(0.15, 0.75, 0.15, 1.0),
	hp_fill_enemy= vmath.vector4(0.85, 0.15, 0.15, 1.0),

	flash        = vmath.vector4(1, 0, 0, 0),
	flash_clear  = vmath.vector4(0, 0, 0, 0),
}

-- Spawn-zone placeholder tints
M.color.zone = {
	player = vmath.vector4(0.15, 0.75, 0.55, 0.35),
	melee  = vmath.vector4(0.85, 0.15, 0.15, 0.35),
	ranged = vmath.vector4(0.90, 0.50, 0.10, 0.35),
	boss   = vmath.vector4(0.70, 0.10, 0.80, 0.35),
}

-- Unit ----------------------------------------------------------------------
-- Child templates (hit, shadow, hp bars) are authored at 1.0 and scaled down.
M.unit_scale = 0.5

-- HP bar floats above the unit's root.
M.hp_bar = {
	offset_y    = 210,   -- both bars sit this far above root.y
	fill_dx     = -40,   -- fill is left-anchored, shifted left of bg center
	z_bg        = 0.9,
	z_fill      = 0.91,
}

-- Death smudge that replaces the shadow.
M.smudge = {
	z          = 0.02,
	scale      = 0.55,
	grow_time  = 0.45,
}

-- Damage flash on the rig sprites.
M.flash_time = 0.3

-- Painter's-algorithm depth sorting of alive units.
M.zsort = {
	base = 0.1,
	step = 0.05,
}

-- Spawn geometry ------------------------------------------------------------
-- Placeholder sprite base size is 64x64; scales below render the zone bounds.
M.spawn = {
	enemy = { scale = vmath.vector3(1.5625, 3.75, 1.0), spread_x = 100, spread_y = 240 },
	player= { scale = vmath.vector3(0.625, 0.9375, 1.0), spread_x = 40,  spread_y = 60  },
	-- Depth keeps units painted by Y while idle before zsort kicks in.
	z_divisor = 10000,
	z_base    = 0.5,
}

-- Battle log ----------------------------------------------------------------
M.log_max_lines = 5

return M
