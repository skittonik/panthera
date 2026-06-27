return {
    data = {
        animations = {
            -- =========================================================
            -- IDLE (default) - calm combat-ready breathing + weight shift
            -- =========================================================
            {
                animation_id = "default",
                duration = 3.0,
                animation_keys = {
                    -- Breathing: torso rises on the inhale, settles on the exhale
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 1.5, start_value = 70.0, end_value = 73.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 1.5, duration = 1.5, start_value = 73.0, end_value = 70.0, easing = "inoutsine" },

                    -- Chest expands subtly with the breath
                    { key_type = "tween", node_id = "body", property_id = "scale_x", start_time = 0.0, duration = 1.5, start_value = 1.0, end_value = 1.02, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "scale_x", start_time = 1.5, duration = 1.5, start_value = 1.02, end_value = 1.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "scale_y", start_time = 0.0, duration = 1.5, start_value = 1.0, end_value = 1.03, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "scale_y", start_time = 1.5, duration = 1.5, start_value = 1.03, end_value = 1.0, easing = "inoutsine" },

                    -- Head bobs with a slight lag (secondary motion)
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.0, duration = 1.7, start_value = 109.0, end_value = 113.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 1.7, duration = 1.3, start_value = 113.0, end_value = 109.0, easing = "inoutsine" },

                    -- Gentle head tilt in time with the breath
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = -1.5, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = -1.5, end_value = 0.0, easing = "inoutsine" },

                    -- Legs settle weight
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = 2.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = 2.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = -2.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = -2.0, end_value = 0.0, easing = "inoutsine" },

                    -- Weapon idles with a slow sway and a soft bob
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = 4.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = 4.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 1.5, start_value = 129.0, end_value = 131.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 1.5, duration = 1.5, start_value = 131.0, end_value = 129.0, easing = "inoutsine" },

                    -- hand_right follows weapon sway identically
                    { key_type = "tween", node_id = "hand_right", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = 4.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = 4.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "position_y", start_time = 0.0, duration = 1.5, start_value = 181.0, end_value = 183.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "position_y", start_time = 1.5, duration = 1.5, start_value = 183.0, end_value = 181.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- WALK - two steps, legs pendulum. Loops cleanly.
            -- =========================================================
            {
                animation_id = "walk",
                duration = 0.8,
                animation_keys = {
                    -- Right leg: full forward at the seam, swings back and returns.
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = 20.0, end_value = -20.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = -20.0, end_value = 20.0, easing = "inoutsine" },

                    -- Left leg: opposite phase
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = -20.0, end_value = 20.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = 20.0, end_value = -20.0, easing = "inoutsine" },

                    -- Torso bob: two bobs/cycle
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 67.0, end_value = 73.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 73.0, end_value = 67.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 67.0, end_value = 73.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 73.0, end_value = 67.0, easing = "inoutsine" },

                    -- Head bob (secondary, follows the torso)
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 107.0, end_value = 111.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 111.0, end_value = 107.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 107.0, end_value = 111.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 111.0, end_value = 107.0, easing = "inoutsine" },

                    -- Head counter-tilt sway
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = -1.5, end_value = 1.5, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = 1.5, end_value = -1.5, easing = "inoutsine" },

                    -- Weapon counter-swing
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = 6.0, end_value = -6.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = -6.0, end_value = 6.0, easing = "inoutsine" },

                    -- Weapon bob (follows the torso)
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 127.0, end_value = 132.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 132.0, end_value = 127.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 127.0, end_value = 132.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 132.0, end_value = 127.0, easing = "inoutsine" },

                    -- hand_right follows weapon during walk
                    { key_type = "tween", node_id = "hand_right", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = 6.0, end_value = -6.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = -6.0, end_value = 6.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 179.0, end_value = 184.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 184.0, end_value = 179.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 179.0, end_value = 184.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "hand_right", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 184.0, end_value = 179.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- =========================================================
            -- ATTACK_IMPACT - blunt melee (bat, tire iron).
            -- Compact backswing (38 deg) -> fast drive through target -> settle.
            -- Impact at ~0.3s.
            -- =========================================================
            {
                animation_id = "attack_impact",
                duration = 0.7,
                animation_keys = {
                    -- Body winds back on coil, follows through on strike
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.25, start_value = 0.0, end_value = -5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.25, duration = 0.12, start_value = -5.0, end_value = 3.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.37, duration = 0.33, start_value = 3.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.25, start_value = 0.0, end_value = 5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.25, duration = 0.12, start_value = 5.0, end_value = -3.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.37, duration = 0.33, start_value = -3.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.25, start_value = 0.0, end_value = -10.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.25, duration = 0.12, start_value = -10.0, end_value = 14.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.37, duration = 0.33, start_value = 14.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 0.25, start_value = 70.0, end_value = 67.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.25, duration = 0.12, start_value = 67.0, end_value = 73.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.37, duration = 0.33, start_value = 73.0, end_value = 70.0, easing = "inoutsine" },
                    -- Weapon: backswing pulls back in x, drives forward through target, recover
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 0.25, start_value = 0.0, end_value = 38.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.25, duration = 0.12, start_value = 38.0, end_value = -60.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.37, duration = 0.33, start_value = -60.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 0.25, start_value = 129.0, end_value = 145.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.25, duration = 0.12, start_value = 145.0, end_value = 118.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.37, duration = 0.33, start_value = 118.0, end_value = 129.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.0, duration = 0.25, start_value = -15.0, end_value = -28.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.25, duration = 0.12, start_value = -28.0, end_value = 22.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.37, duration = 0.33, start_value = 22.0, end_value = -15.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.25, start_value = 0.0, end_value = -4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.25, duration = 0.12, start_value = -4.0, end_value = 5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.37, duration = 0.33, start_value = 5.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.25, start_value = 0.0, end_value = -4.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.25, duration = 0.12, start_value = -4.0, end_value = 5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.37, duration = 0.33, start_value = 5.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.25, start_value = 0.0, end_value = 4.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.25, duration = 0.12, start_value = 4.0, end_value = -4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.37, duration = 0.33, start_value = -4.0, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- =========================================================
            -- ATTACK_STABBING - knife/blade thrust: coil -> explosive lunge -> retract.
            -- Impact at ~0.22s.
            -- =========================================================
            {
                animation_id = "attack_stabbing",
                duration = 0.45,
                animation_keys = {
                    -- Root: coil back then lunge forward
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = 4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.12, duration = 0.08, start_value = 4.0, end_value = -5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.2, duration = 0.25, start_value = -5.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.12, duration = 0.08, start_value = -4.0, end_value = 5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.2, duration = 0.25, start_value = 5.0, end_value = 0.0, easing = "inoutsine" },
                    -- Body lunges forward, arm extends
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -10.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.12, duration = 0.08, start_value = -10.0, end_value = 18.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.2, duration = 0.25, start_value = 18.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 0.12, start_value = 70.0, end_value = 68.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.12, duration = 0.08, start_value = 68.0, end_value = 72.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.2, duration = 0.25, start_value = 72.0, end_value = 70.0, easing = "inoutsine" },
                    -- Weapon: pull back, then explosive thrust far forward in x, retract
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = 6.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.12, duration = 0.08, start_value = 6.0, end_value = -10.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.2, duration = 0.25, start_value = -10.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 0.12, start_value = 129.0, end_value = 127.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.12, duration = 0.08, start_value = 127.0, end_value = 133.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.2, duration = 0.25, start_value = 133.0, end_value = 129.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.0, duration = 0.12, start_value = -15.0, end_value = -32.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.12, duration = 0.08, start_value = -32.0, end_value = 38.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.2, duration = 0.25, start_value = 38.0, end_value = -15.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = 3.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.12, duration = 0.08, start_value = 3.0, end_value = -4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.2, duration = 0.25, start_value = -4.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -6.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.12, duration = 0.08, start_value = -6.0, end_value = 7.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.2, duration = 0.25, start_value = 7.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = 6.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.12, duration = 0.08, start_value = 6.0, end_value = -5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.2, duration = 0.25, start_value = -5.0, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- ATTACK_PISTOL - weapon already in hand. Fire = recoil only. Impact at ~0.12s.
            -- =========================================================
            {
                animation_id = "attack_pistol",
                duration = 0.55,
                animation_keys = {
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = -2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.1, duration = 0.07, start_value = -2.0, end_value = 1.5, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.17, duration = 0.38, start_value = 1.5, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = 2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.1, duration = 0.07, start_value = 2.0, end_value = -1.5, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.17, duration = 0.38, start_value = -1.5, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = 4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.1, duration = 0.07, start_value = 4.0, end_value = -3.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.17, duration = 0.38, start_value = -3.0, end_value = 0.0, easing = "inoutsine" },
                    -- Weapon: big recoil kick up+back, settle
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = -8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.1, duration = 0.07, start_value = -8.0, end_value = 28.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.17, duration = 0.12, start_value = 28.0, end_value = 8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.29, duration = 0.26, start_value = 8.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 0.1, start_value = 129.0, end_value = 126.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.1, duration = 0.07, start_value = 126.0, end_value = 138.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.17, duration = 0.38, start_value = 138.0, end_value = 129.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.0, duration = 0.1, start_value = -15.0, end_value = -8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.1, duration = 0.07, start_value = -8.0, end_value = -28.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.17, duration = 0.38, start_value = -28.0, end_value = -15.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = -1.5, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.1, duration = 0.07, start_value = -1.5, end_value = 2.5, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.17, duration = 0.38, start_value = 2.5, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- ATTACK_RIFLE - weapon in hand, 3-burst recoil. Impact at ~0.12s.
            -- =========================================================
            {
                animation_id = "attack_rifle",
                duration = 0.7,
                animation_keys = {
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = -2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.1, duration = 0.06, start_value = -2.0, end_value = 1.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.16, duration = 0.54, start_value = 1.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = 2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.1, duration = 0.06, start_value = 2.0, end_value = -1.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.16, duration = 0.54, start_value = -1.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = 4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.1, duration = 0.06, start_value = 4.0, end_value = -2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.16, duration = 0.54, start_value = -2.0, end_value = 0.0, easing = "inoutsine" },
                    -- Weapon: 3-burst recoil, each kick with x+y push
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 0.06, start_value = 0.0, end_value = 8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.06, duration = 0.07, start_value = 8.0, end_value = 1.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.13, duration = 0.06, start_value = 1.0, end_value = 8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.19, duration = 0.07, start_value = 8.0, end_value = 1.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.26, duration = 0.06, start_value = 1.0, end_value = 8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.32, duration = 0.38, start_value = 8.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 129.0, end_value = 131.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.2, duration = 0.5, start_value = 131.0, end_value = 129.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.0, duration = 0.06, start_value = -15.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.06, duration = 0.07, start_value = -20.0, end_value = -17.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.13, duration = 0.06, start_value = -17.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.19, duration = 0.07, start_value = -20.0, end_value = -17.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.26, duration = 0.06, start_value = -17.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.32, duration = 0.38, start_value = -20.0, end_value = -15.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = -1.5, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.1, duration = 0.06, start_value = -1.5, end_value = 2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.16, duration = 0.54, start_value = 2.0, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- ATTACK_SHOTGUN - weapon in hand, single hard blast + body pushed back. Impact at ~0.1s.
            -- =========================================================
            {
                animation_id = "attack_shotgun",
                duration = 0.65,
                animation_keys = {
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = -2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.1, duration = 0.08, start_value = -2.0, end_value = 2.5, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.18, duration = 0.47, start_value = 2.5, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = 2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.1, duration = 0.08, start_value = 2.0, end_value = -2.5, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.18, duration = 0.47, start_value = -2.5, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = 5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.1, duration = 0.08, start_value = 5.0, end_value = -8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.18, duration = 0.47, start_value = -8.0, end_value = 0.0, easing = "inoutsine" },
                    -- Weapon: single hard recoil kick (up+back), slow return
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = 18.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.1, duration = 0.55, start_value = 18.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 0.1, start_value = 129.0, end_value = 127.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.1, duration = 0.55, start_value = 127.0, end_value = 129.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.0, duration = 0.1, start_value = -15.0, end_value = -26.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_x", start_time = 0.1, duration = 0.55, start_value = -26.0, end_value = -15.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.1, start_value = 0.0, end_value = -1.5, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.1, duration = 0.08, start_value = -1.5, end_value = 3.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.18, duration = 0.47, start_value = 3.0, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- DAMAGE - sharp hit reaction. OVERLAY — only drives "hit"
            -- and "head_pivot" nodes. Played on an independent state.
            -- Everything returns to 0, so the layer resets itself.
            -- =========================================================
            {
                animation_id = "damage",
                duration = 0.55,
                animation_keys = {
                    { key_type = "tween", node_id = "hit", property_id = "position_x", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = -12.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hit", property_id = "position_x", start_time = 0.07, duration = 0.23, start_value = -12.0, end_value = 2.0, easing = "outcubic" },
                    { key_type = "tween", node_id = "hit", property_id = "position_x", start_time = 0.3, duration = 0.25, start_value = 2.0, end_value = 0.0, easing = "inoutsine" },

                    { key_type = "tween", node_id = "hit", property_id = "position_y", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = -2.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hit", property_id = "position_y", start_time = 0.07, duration = 0.23, start_value = -2.0, end_value = 0.5, easing = "outcubic" },
                    { key_type = "tween", node_id = "hit", property_id = "position_y", start_time = 0.3, duration = 0.25, start_value = 0.5, end_value = 0.0, easing = "inoutsine" },

                    { key_type = "tween", node_id = "hit", property_id = "rotation_z", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = 4.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hit", property_id = "rotation_z", start_time = 0.07, duration = 0.21, start_value = 4.0, end_value = -1.5, easing = "outcubic" },
                    { key_type = "tween", node_id = "hit", property_id = "rotation_z", start_time = 0.28, duration = 0.27, start_value = -1.5, end_value = 0.0, easing = "inoutsine" },

                    -- Head snaps harder than the body, pivoting about the neck
                    { key_type = "tween", node_id = "head_pivot", property_id = "rotation_z", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = 6.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head_pivot", property_id = "rotation_z", start_time = 0.07, duration = 0.23, start_value = 6.0, end_value = -2.0, easing = "outcubic" },
                    { key_type = "tween", node_id = "head_pivot", property_id = "rotation_z", start_time = 0.3, duration = 0.25, start_value = -2.0, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- DEATH - topples clockwise (-84°), bounce, settle, fade.
            -- Legs kick UP (positive = against fall direction = inertia).
            -- Weapon swings positively (+85° local ≈ 0° world = falls to side).
            -- =========================================================
            {
                animation_id = "death",
                duration = 1.4,
                animation_keys = {
                    -- Topple: tiny recoil, accelerating fall, bounce, settle
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = 8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.12, duration = 0.5, start_value = 8.0, end_value = -88.0, easing = "incubic" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.62, duration = 0.16, start_value = -88.0, end_value = -78.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.78, duration = 0.17, start_value = -78.0, end_value = -84.0, easing = "inoutsine" },

                    -- Keep the shadow flat on the ground
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.12, duration = 0.5, start_value = -8.0, end_value = 88.0, easing = "incubic" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.62, duration = 0.16, start_value = 88.0, end_value = 78.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.78, duration = 0.17, start_value = 78.0, end_value = 84.0, easing = "inoutsine" },

                    -- Head lolls in the fall direction
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -14.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.12, duration = 0.5, start_value = -14.0, end_value = -32.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.62, duration = 0.18, start_value = -32.0, end_value = -22.0, easing = "outquad" },

                    -- Weapon: brief grip, then swings positively (+85° local ≈ 0° world)
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -12.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "rotation_z", start_time = 0.12, duration = 0.4, start_value = -12.0, end_value = 85.0, easing = "outquad" },
                    { key_type = "tween", node_id = "weapon", property_id = "position_y", start_time = 0.0, duration = 0.52, start_value = 129.0, end_value = 75.0, easing = "outquad" },

                    -- Legs kick UP (positive = against fall direction)
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = 28.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.5, duration = 0.2, start_value = 28.0, end_value = 20.0, easing = "outsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = 20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.5, duration = 0.2, start_value = 20.0, end_value = 14.0, easing = "outsine" },

                    -- Shadow shrinks on impact
                    { key_type = "tween", node_id = "shadow", property_id = "scale_x", start_time = 0.0, duration = 0.62, start_value = 1.0, end_value = 0.6, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "scale_y", start_time = 0.0, duration = 0.62, start_value = 1.0, end_value = 0.6, easing = "inoutsine" },

                    -- hand_right falls with weapon (gripped through death)
                    { key_type = "tween", node_id = "hand_right", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -12.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hand_right", property_id = "rotation_z", start_time = 0.12, duration = 0.4, start_value = -12.0, end_value = 85.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hand_right", property_id = "position_y", start_time = 0.0, duration = 0.52, start_value = 181.0, end_value = 75.0, easing = "outquad" },

                    -- Fade everything out
                    { key_type = "tween", node_id = "body#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
                    { key_type = "tween", node_id = "head#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
                    { key_type = "tween", node_id = "left_leg#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
                    { key_type = "tween", node_id = "right_leg#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
                    { key_type = "tween", node_id = "shadow#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
                }
            }
        },
        metadata = {
            fps = 60,
            gizmo_steps = {},
            gui_path = "first_anim/first_anim.collection",
            layers = {},
            settings = {
                font_size = 30,
            },
            template_animation_paths = {},
        },
        nodes = {
            -- ROOT
            { node_id = "root", node_index = 1, node_type = "box", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 1, size_y = 1, visible = true, enabled = true },

            -- HIT - dedicated overlay layer for the damage flinch.
            { node_id = "hit", node_index = 14, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 1, size_y = 1, visible = true, enabled = true },

            -- SHADOW (stays under root, outside hit)
            { node_id = "shadow", node_index = 2, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 227, size_y = 52, visible = true, enabled = true },
            { node_id = "shadow#sprite", node_index = 3, node_type = "box", parent = "shadow", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 227, size_y = 52, visible = true, enabled = true },

            -- LEFT LEG
            { node_id = "left_leg", node_index = 4, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 87, size_y = 150, visible = true, enabled = true },
            { node_id = "left_leg#sprite", node_index = 5, node_type = "box", parent = "left_leg", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 87, size_y = 150, visible = true, enabled = true },

            -- RIGHT LEG
            { node_id = "right_leg", node_index = 6, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 86, size_y = 148, visible = true, enabled = true },
            { node_id = "right_leg#sprite", node_index = 7, node_type = "box", parent = "right_leg", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 86, size_y = 148, visible = true, enabled = true },

            -- BODY
            { node_id = "body", node_index = 8, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 221, size_y = 228, visible = true, enabled = true },
            { node_id = "body#sprite", node_index = 9, node_type = "box", parent = "body", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 221, size_y = 228, visible = true, enabled = true },

            -- HEAD_PIVOT - sits at the neck. "damage" rotates this for head snap.
            { node_id = "head_pivot", node_index = 15, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 1, size_y = 1, visible = true, enabled = true },

            -- HEAD (child of head_pivot)
            { node_id = "head", node_index = 10, node_type = "box", parent = "head_pivot", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 218, size_y = 219, visible = true, enabled = true },
            { node_id = "head#sprite", node_index = 11, node_type = "box", parent = "head", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 218, size_y = 219, visible = true, enabled = true },

            -- WEAPON pivot (no sprite — sprite lives on weapon_impact/stabbing/pistol/rifle/shotgun children)
            { node_id = "weapon", node_index = 12, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 1, size_y = 1, visible = true, enabled = true },

            -- HAND_RIGHT - at hit level (z -0.005 = behind body). Has its own Panthera keys
            -- so it is NOT a child of weapon and doesn't orbit the weapon pivot.
            { node_id = "hand_right", node_index = 16, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 1, size_y = 1, visible = true, enabled = true },
        }
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}
