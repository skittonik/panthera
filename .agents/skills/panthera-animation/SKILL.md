---
name: panthera-animation
description: "Designing, structuring, generating, and blending 2D keyframe animations and adapters for the Panthera runtime in Defold."
---

# Panthera 2D Animation & Pipeline

This skill instructs how to design, generate, structure, and control 2D animations using the **Panthera Runtime** for the **Defold game engine**.

---

## 1. Animation File Structure (Lua Table Format)

Panthera animations are typically exported as Lua files returning a table structure. Below is the canonical format for generating or editing animations programmatically.

```lua
return {
    data = {
        animations = {
            {
                animation_id = "animation_name", -- Unique identifier (e.g., "walk", "click", "idle")
                animation_keys = {
                    -- Trigger Key (Non-tweened events or instant property changes)
                    {
                        key_type = "trigger",
                        node_id = "node_or_go_name",
                        property_id = "text", -- or "clipping_mode", "visible", etc.
                        start_data = "Initial Value",
                        data = "Target Value",
                        easing = "linear"
                    },
                    -- Tween Key (Interpolated transitions over time)
                    {
                        key_type = "tween",
                        node_id = "node_or_go_name",
                        property_id = "scale_x", -- Specific component property
                        start_value = 1.0,       -- Optional start value
                        end_value = 1.2,         -- Target value
                        duration = 0.15,         -- Duration in seconds
                        easing = "outsine"       -- Easing function name
                    }
                }
            }
        }
    }
}
```

### Supported Easing Functions
Panthera maps custom curves to Defold's internal easings via adapters. Standard options:
- `linear`
- `insine`, `outsine`, `inoutsine`
- `inquad`, `outquad`, `inoutquad`
- `inback`, `outback`, `inoutback`
- `inelastic`, `outelastic`, `inoutelastic`

---

## 2. Properties Reference

When animating nodes or Game Objects (GO), target these component-specific properties:

### GUI Nodes
- **Scale**: `scale_x`, `scale_y`, `scale_z`
- **Position**: `position_x`, `position_y`, `position_z`
- **Rotation**: `rotation_x`, `rotation_y`, `rotation_z`
- **Color/Opacity**: `color_r`, `color_g`, `color_b`, `color_a`
- **Text properties**: `outline_r`, `outline_g`, `outline_b`, `outline_a`, `shadow_r`, `shadow_g`, `shadow_b`, `shadow_a`, `text_tracking`
- **Triggers**: `text`, `visible`, `clipping_mode`, `clipping_inverted`, `clipping_visible`

### Game Objects (GO)
- **Position/Scale/Rotation**: `position_x`, `position_y`, `position_z`, `scale_x`, `scale_y`, `scale_z`, `rotation_z`
- **Sprite Tint**: `tint_r`, `tint_g`, `tint_b`, `tint_a`

---

## 3. Integration & Runtime Execution

### GUI Node Initialization
```lua
local panthera = require("panthera.panthera")
local animation_data = require("path.to.generated_panthera_file")

function init(self)
    -- Creates animation state bound to the current GUI scene
    self.anim_state = panthera.create_gui(animation_data)
    
    -- Play default looping state
    panthera.play(self.anim_state, "idle", { is_loop = true })
end
```

### GO (Game Object) Initialization
```lua
local panthera = require("panthera.panthera")
local animation_data = require("path.to.generated_panthera_file")

function init(self)
    -- Creates animation state bound to the current collection/game object
    self.anim_state = panthera.create_go(animation_data)
    
    -- Play one-off action
    panthera.play(self.anim_state, "jump", {
        is_loop = false,
        on_complete = function()
            print("Jump animation finished!")
        end
    })
end
```

---

## 4. Animation Blending (Multi-Track Setup)

To execute multiple animations concurrently (e.g., playing a walking animation while simultaneously playing an eye-blink or hand-wave):

1. **Clone the State**: Generate secondary states from the master animation state.
2. **Prevent Overlaps**: Ensure concurrent tracks **never** target the same `node_id` + `property_id` combination. Overlapping property updates will override each other unpredictably.

```lua
function init(self)
    self.base_track = panthera.create_go(character_anims)
    self.overlay_track = panthera.clone_state(self.base_track)

    -- Play simultaneously
    panthera.play(self.base_track, "walk", { is_loop = true })
    panthera.play(self.overlay_track, "blink", { is_loop = true })
end
```

---

## 5. Pipeline Best Practices & Anti-Patterns

### ✅ Do
- Organize animations into logical, reusable modules matching specific UI panels or entity types.
- Always match the exact casing of property names (e.g., use `scale_x`, not `ScaleX`).
- Ensure all nodes targeted by `node_id` exist within the template or GUI hierarchy before triggering.

### ❌ Don't
- Do not animate the same node property on two different running states (blending conflict).
- Do not use complex frame-by-frame lists where math formulas or simple tweens could save file size.
- Avoid nesting triggers inside hot game loops; trigger them once using event listeners.

---

## 6. Pivot Calculations & Sprite Transform Animations

### Defold Sprite Limitation
Sprite components in Defold do not have animatable `position`, `rotation`, or `scale` properties of their own relative to their parent Game Object.
* **Correction**: To build a skeletal rig (e.g., body, head, weapon), do **not** use multiple sprite components on a single Game Object. Instead, create **separate child Game Objects** for each part parented under a root Game Object.

### Pivot Setup & Offset Calculation
By default, Defold sprites are anchored at the center of their image. When you rotate a Game Object, it rotates around the sprite's center. To move the pivot point (e.g., to the feet of the body, the neck of the head, or the handle of the weapon):
1. **Offset Sprite inside `.go`**: Shift the sprite component's `position.y` inside the `.go` file by half of the image's height:
   - **Body (Height 366)**: Shift sprite `y` to `183.0` inside `body.go`. Pivot is now at the feet.
   - **Head (Height 168)**: Shift sprite `y` to `84.0` inside `head.go`. Pivot is now at the neck.
   - **Weapon (Height 218)**: Shift sprite `y` to `109.0` inside `melee_weapon.go`. Pivot is now at the handle.
2. **Offset Game Objects inside `.collection`**: Position the Game Objects relative to the root pivot:
   - **Head GO**: Position at `y = 350.0` (neck sits on top of the body).
   - **Weapon GO**: Position at `x = 70.0, y = 150.0` (hand holds the handle).

### Animation Keys Matching
When creating animations (e.g. `idle`, `walk`), your tween start/end values **must match** these calculated initial offsets (e.g., head start/end values around `y = 350`, weapon around `x = 70, y = 150`). If a property is animated but does not start at its correct pivot offset, the part will instantly snap back to the coordinate origin `(0,0)` when the animation begins.


