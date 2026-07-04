local M = {}

local factory_url = nil
local WHITE       = vmath.vector4(1, 1, 1, 1)
local TRANSPARENT = vmath.vector4(0, 0, 0, 0)
local FLOAT_DY    = 70    -- px to float upward
local FLOAT_DUR   = 0.65  -- seconds for the rise
local SHRINK_DEL  = 0.3   -- seconds before shrink/fade starts
local SHRINK_DUR  = 0.3   -- seconds to shrink to zero
local Z           = 0.95  -- above units and HP bars

function M.init(url)
    factory_url = url
end

function M.spawn(pos, amount)
    if not factory_url then return end
    local p = vmath.vector3(pos.x, pos.y + 30, Z)
    local id = factory.create(factory_url, p)
    local lurl = msg.url(nil, id, "label")
    label.set_text(lurl, tostring(amount))
    -- Зануляем outline и shadow независимо от дефолтов DF-шрифта
    go.set(lurl, "color",   WHITE)
    go.set(lurl, "outline", TRANSPARENT)
    go.set(lurl, "shadow",  TRANSPARENT)
    -- Float up
    go.animate(id, "position", go.PLAYBACK_ONCE_FORWARD,
        vmath.vector3(p.x, p.y + FLOAT_DY, Z), go.EASING_OUTQUAD, FLOAT_DUR, 0)
    -- Shrink to zero — убирает SDF-артефакты при alpha→0
    go.animate(id, "scale", go.PLAYBACK_ONCE_FORWARD,
        vmath.vector3(0, 0, 1), go.EASING_INQUAD, SHRINK_DUR, SHRINK_DEL,
        function() go.delete(id) end)
    go.animate(lurl, "color.w", go.PLAYBACK_ONCE_FORWARD, 0,
        go.EASING_INQUAD, SHRINK_DUR, SHRINK_DEL)
end

return M
