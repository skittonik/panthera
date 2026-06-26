return {
    data = {
        animations = {
            -- =========================================================
            -- IDLE (default) - calm combat-ready breathing + weight shift
            -- Whole-body sway is driven by "root" so the character feels
            -- alive as one piece; head/bat add lagged secondary motion.
            -- Loops cleanly: every property starts and ends at rest.
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

                    -- Gentle head tilt in time with the breath (single slow ease, not a sway)
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = -1.5, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = -1.5, end_value = 0.0, easing = "inoutsine" },

                    -- Legs settle weight: a slow symmetric splay so the stance feels alive
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = 2.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = 2.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = -2.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = -2.0, end_value = 0.0, easing = "inoutsine" },

                    -- Bat idles with a slow sway and a soft bob
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 1.5, start_value = 0.0, end_value = 4.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 1.5, duration = 1.5, start_value = 4.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.0, duration = 1.5, start_value = 129.0, end_value = 131.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 1.5, duration = 1.5, start_value = 131.0, end_value = 129.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- WALK - two steps. Legs pendulum from the hips (the rotation
            -- itself lifts the foot off the ground), torso bobs twice per
            -- cycle, root sways toward each stance leg. Loops cleanly.
            -- =========================================================
            {
                animation_id = "walk",
                duration = 0.8,
                animation_keys = {
                    -- The loop seam (t=0 / t=0.8) is parked on every property's
                    -- velocity-ZERO extreme. Panthera restarts the clip by cancelling
                    -- all native tweens and re-firing them on the next 1/60s tick, so
                    -- there is a 1-frame hold at the seam; placing it on an extreme
                    -- (where motion is momentarily still) makes that hold invisible.
                    -- The neutral crossings happen MID-cycle, where inoutsine carries
                    -- max speed through them, so the legs never pause at center.

                    -- Right leg: full forward at the seam, swings back and returns.
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = 20.0, end_value = -20.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = -20.0, end_value = 20.0, easing = "inoutsine" },

                    -- Left leg: opposite phase (full back at the seam)
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = -20.0, end_value = 20.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = 20.0, end_value = -20.0, easing = "inoutsine" },

                    -- Torso bob: LOW at the seam (legs apart at full stride), high as
                    -- the body vaults over the passing legs mid-cycle. Two bobs/cycle.
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 67.0, end_value = 73.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 73.0, end_value = 67.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 67.0, end_value = 73.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 73.0, end_value = 67.0, easing = "inoutsine" },

                    -- Head bob (secondary, follows the torso)
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 107.0, end_value = 111.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 111.0, end_value = 107.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 107.0, end_value = 111.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 111.0, end_value = 107.0, easing = "inoutsine" },

                    -- Head counter-tilt sway: one full sway/cycle, extreme at the seam
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = -1.5, end_value = 1.5, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = 1.5, end_value = -1.5, easing = "inoutsine" },

                    -- Bat counter-swing: extreme at the seam
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = 6.0, end_value = -6.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = -6.0, end_value = 6.0, easing = "inoutsine" },

                    -- Bat bob (follows the torso, low at the seam)
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 127.0, end_value = 132.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 132.0, end_value = 127.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 127.0, end_value = 132.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 132.0, end_value = 127.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- ATTACK - full baseball swing: coil (wind-up) -> drive
            -- (strike) -> settle -> recover. The whole body leans via
            -- "root"; the bat whips through ~215 degrees with overshoot.
            -- =========================================================
            {
                animation_id = "attack",
                duration = 0.9,
                animation_keys = {
                    -- Whole-body coil back, then lean into the strike (kept subtle
                    -- so the torso doesn't slide off the planted legs)
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = 6.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = 6.0, end_value = -9.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.45, duration = 0.45, start_value = -9.0, end_value = 0.0, easing = "inoutsine" },

                    -- Keep the shadow flat on the ground (cancels the root lean)
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = -6.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = -6.0, end_value = 9.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.45, duration = 0.45, start_value = 9.0, end_value = 0.0, easing = "inoutsine" },

                    -- Weight shifts back on the coil, drives forward on the hit
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = -8.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.3, duration = 0.15, start_value = -8.0, end_value = 18.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.45, duration = 0.13, start_value = 18.0, end_value = 13.0, easing = "outsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.58, duration = 0.32, start_value = 13.0, end_value = 0.0, easing = "inoutsine" },

                    -- Crouch on the coil, rise through the swing
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 0.3, start_value = 70.0, end_value = 66.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.3, duration = 0.15, start_value = 66.0, end_value = 73.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.45, duration = 0.45, start_value = 73.0, end_value = 70.0, easing = "inoutsine" },

                    -- Bat: cock over the shoulder, whip forward with overshoot, return
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = 115.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = 115.0, end_value = -100.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.45, duration = 0.13, start_value = -100.0, end_value = -78.0, easing = "outback" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.58, duration = 0.32, start_value = -78.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.0, duration = 0.3, start_value = 129.0, end_value = 150.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.3, duration = 0.15, start_value = 150.0, end_value = 120.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.45, duration = 0.45, start_value = 120.0, end_value = 129.0, easing = "inoutsine" },

                    -- Head leads into the target, snaps with the strike
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = 8.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = 8.0, end_value = -10.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.45, duration = 0.45, start_value = -10.0, end_value = 0.0, easing = "inoutsine" },

                    -- Legs brace and push off through the swing (small, so the back
                    -- leg stays tucked behind the body)
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = -4.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = -4.0, end_value = 5.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.45, duration = 0.45, start_value = 5.0, end_value = 0.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = 4.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = 4.0, end_value = -3.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.45, duration = 0.45, start_value = -3.0, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- DAMAGE - sharp hit reaction, authored as an OVERLAY so it can be
            -- play_detached over idle / walk / attack. It only touches dedicated
            -- layer nodes the base clips never use:
            --   "hit"        - whole-body recoil (slide + jolt), carries every
            --                  part (head included) so the neck can't separate
            --   "head_pivot" - extra head snap about the neck, on top of the body
            -- The shadow sits outside "hit", so it stays flat with no counter-key.
            -- Everything returns to 0, so the layer resets itself when it ends.
            -- =========================================================
            {
                animation_id = "damage",
                duration = 0.55,
                animation_keys = {
                    -- Whole body recoils LEFT and leans the same way (coherent jolt)
                    { key_type = "tween", node_id = "hit", property_id = "position_x", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = -32.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hit", property_id = "position_x", start_time = 0.07, duration = 0.23, start_value = -32.0, end_value = 6.0, easing = "outcubic" },
                    { key_type = "tween", node_id = "hit", property_id = "position_x", start_time = 0.3, duration = 0.25, start_value = 6.0, end_value = 0.0, easing = "inoutsine" },

                    { key_type = "tween", node_id = "hit", property_id = "position_y", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = -6.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hit", property_id = "position_y", start_time = 0.07, duration = 0.23, start_value = -6.0, end_value = 2.0, easing = "outcubic" },
                    { key_type = "tween", node_id = "hit", property_id = "position_y", start_time = 0.3, duration = 0.25, start_value = 2.0, end_value = 0.0, easing = "inoutsine" },

                    { key_type = "tween", node_id = "hit", property_id = "rotation_z", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = 12.0, easing = "outquad" },
                    { key_type = "tween", node_id = "hit", property_id = "rotation_z", start_time = 0.07, duration = 0.21, start_value = 12.0, end_value = -4.0, easing = "outcubic" },
                    { key_type = "tween", node_id = "hit", property_id = "rotation_z", start_time = 0.28, duration = 0.27, start_value = -4.0, end_value = 0.0, easing = "inoutsine" },

                    -- Head snaps harder than the body, pivoting about the neck
                    { key_type = "tween", node_id = "head_pivot", property_id = "rotation_z", start_time = 0.0, duration = 0.07, start_value = 0.0, end_value = 18.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head_pivot", property_id = "rotation_z", start_time = 0.07, duration = 0.23, start_value = 18.0, end_value = -5.0, easing = "outcubic" },
                    { key_type = "tween", node_id = "head_pivot", property_id = "rotation_z", start_time = 0.3, duration = 0.25, start_value = -5.0, end_value = 0.0, easing = "inoutsine" },
                }
            },
            -- =========================================================
            -- DEATH - the whole rig topples as one piece by rotating
            -- "root" about the feet, with a small ground bounce. The
            -- shadow is counter-rotated so it stays flat on the floor,
            -- then everything shrinks and fades out.
            -- =========================================================
            {
                animation_id = "death",
                duration = 1.4,
                animation_keys = {
                    -- Topple: tiny recoil, accelerating fall, bounce, settle
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = 8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.12, duration = 0.5, start_value = 8.0, end_value = -86.0, easing = "incubic" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.62, duration = 0.16, start_value = -86.0, end_value = -78.0, easing = "outquad" },
                    { key_type = "tween", node_id = "root", property_id = "rotation_z", start_time = 0.78, duration = 0.17, start_value = -78.0, end_value = -84.0, easing = "inoutsine" },

                    -- Keep the shadow flat on the ground (cancels root rotation)
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -8.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.12, duration = 0.5, start_value = -8.0, end_value = 86.0, easing = "incubic" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.62, duration = 0.16, start_value = 86.0, end_value = 78.0, easing = "outquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "rotation_z", start_time = 0.78, duration = 0.17, start_value = 78.0, end_value = 84.0, easing = "inoutsine" },

                    -- Head lolls back as the body goes down
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -12.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.12, duration = 0.5, start_value = -12.0, end_value = -30.0, easing = "inoutsine" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.62, duration = 0.18, start_value = -30.0, end_value = -20.0, easing = "outquad" },

                    -- Bat flings out of the grip and drops
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.12, duration = 0.38, start_value = -20.0, end_value = -120.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.0, duration = 0.5, start_value = 129.0, end_value = 90.0, easing = "outquad" },

                    -- Legs kick up from the fall, swinging the SAME way as the
                    -- topple (root falls clockwise, so the legs go negative too)
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = -32.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.5, duration = 0.2, start_value = -32.0, end_value = -24.0, easing = "outsine" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.5, duration = 0.2, start_value = -20.0, end_value = -14.0, easing = "outsine" },

                    -- Shadow shrinks as the body lifts off the ground
                    { key_type = "tween", node_id = "shadow", property_id = "scale_x", start_time = 0.0, duration = 0.62, start_value = 1.0, end_value = 0.6, easing = "inoutsine" },
                    { key_type = "tween", node_id = "shadow", property_id = "scale_y", start_time = 0.0, duration = 0.62, start_value = 1.0, end_value = 0.6, easing = "inoutsine" },

                    -- Fade everything out at the end
                    { key_type = "tween", node_id = "body#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
                    { key_type = "tween", node_id = "head#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
                    { key_type = "tween", node_id = "baseball_bat#sprite", property_id = "color_a", start_time = 0.85, duration = 0.55, start_value = 1.0, end_value = 0.0, easing = "outsine" },
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

            -- HIT - dedicated overlay layer for the damage flinch. Base clips never
            -- touch it, so "damage" can play_detached on top of idle/walk/attack.
            { node_id = "hit", node_index = 14, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 1, size_y = 1, visible = true, enabled = true },

            -- SHADOW (stays under root, outside hit, so the flinch never tilts it)
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

            -- HEAD_PIVOT - sits at the neck (y=131). "damage" rotates this for a
            -- sharp head snap about the neck, independent of the head's base bob.
            { node_id = "head_pivot", node_index = 15, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 1, size_y = 1, visible = true, enabled = true },

            -- HEAD (now child of head_pivot; local y dropped 131 to keep world y=240)
            { node_id = "head", node_index = 10, node_type = "box", parent = "head_pivot", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 218, size_y = 219, visible = true, enabled = true },
            { node_id = "head#sprite", node_index = 11, node_type = "box", parent = "head", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 218, size_y = 219, visible = true, enabled = true },

            -- BASEBALL BAT
            { node_id = "baseball_bat", node_index = 12, node_type = "box", parent = "hit", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 289, size_y = 302, visible = true, enabled = true },
            { node_id = "baseball_bat#sprite", node_index = 13, node_type = "box", parent = "baseball_bat", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 289, size_y = 302, visible = true, enabled = true },
        }
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}
