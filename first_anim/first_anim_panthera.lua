return {
    data = {
        animations = {
            -- IDLE (default)
            {
                animation_id = "default",
                duration = 2.0,
                animation_keys = {
                    -- Body breathing bob (base y = 70.0)
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 1.0, start_value = 70.0, end_value = 67.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 1.0, duration = 1.0, start_value = 67.0, end_value = 70.0, easing = "inoutquad" },
                    
                    -- Body breathing squash
                    { key_type = "tween", node_id = "body", property_id = "scale_y", start_time = 0.0, duration = 1.0, start_value = 1.0, end_value = 0.95, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "scale_y", start_time = 1.0, duration = 1.0, start_value = 0.95, end_value = 1.0, easing = "inoutquad" },

                    -- Head relative bob (base y = 240.0)
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.0, duration = 1.0, start_value = 240.0, end_value = 237.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 1.0, duration = 1.0, start_value = 237.0, end_value = 240.0, easing = "inoutquad" },

                    -- Head relative tilt
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 1.0, start_value = 0.0, end_value = -2.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 1.0, duration = 1.0, start_value = -2.0, end_value = 0.0, easing = "inoutquad" },

                    -- Baseball bat idle swing (base y = 129.0)
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 1.0, start_value = 0.0, end_value = 5.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 1.0, duration = 1.0, start_value = 5.0, end_value = 0.0, easing = "inoutquad" },

                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.0, duration = 1.0, start_value = 129.0, end_value = 126.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 1.0, duration = 1.0, start_value = 126.0, end_value = 129.0, easing = "inoutquad" },

                    -- Shadow breathing stretch
                    { key_type = "tween", node_id = "shadow", property_id = "scale_x", start_time = 0.0, duration = 1.0, start_value = 1.0, end_value = 1.05, easing = "inoutquad" },
                    { key_type = "tween", node_id = "shadow", property_id = "scale_x", start_time = 1.0, duration = 1.0, start_value = 1.05, end_value = 1.0, easing = "inoutquad" },
                }
            },
            -- WALK
            {
                animation_id = "walk",
                duration = 0.8,
                animation_keys = {
                    -- Right leg swing (walk cycle phase 1)
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.2, start_value = 0.0, end_value = 20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.2, duration = 0.2, start_value = 20.0, end_value = 0.0, easing = "inquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.4, duration = 0.2, start_value = 0.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.6, duration = 0.2, start_value = -20.0, end_value = 0.0, easing = "inquad" },

                    -- Left leg swing (walk cycle phase 2 - opposite)
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.2, start_value = 0.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.2, duration = 0.2, start_value = -20.0, end_value = 0.0, easing = "inquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.4, duration = 0.2, start_value = 0.0, end_value = 20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.6, duration = 0.2, start_value = 20.0, end_value = 0.0, easing = "inquad" },

                    -- Body bobbing (base y = 70.0)
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 70.0, end_value = 64.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 64.0, end_value = 70.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 70.0, end_value = 64.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 64.0, end_value = 70.0, easing = "inoutquad" },

                    -- Head bobbing (base y = 240.0)
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.0, duration = 0.2, start_value = 240.0, end_value = 234.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.2, duration = 0.2, start_value = 234.0, end_value = 240.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.4, duration = 0.2, start_value = 240.0, end_value = 234.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "head", property_id = "position_y", start_time = 0.6, duration = 0.2, start_value = 234.0, end_value = 240.0, easing = "inoutquad" },

                    -- Bat sway during walk
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 0.4, start_value = 0.0, end_value = -10.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.4, duration = 0.4, start_value = -10.0, end_value = 0.0, easing = "inoutquad" },
                }
            },
            -- ATTACK
            {
                animation_id = "attack",
                duration = 1.0,
                animation_keys = {
                    -- Wind up (0.0 -> 0.3)
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = -20.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = -10.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 0.3, start_value = 0.0, end_value = -45.0, easing = "inoutquad" },

                    -- Slash strike (0.3 -> 0.5)
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.3, duration = 0.15, start_value = -20.0, end_value = 60.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = -10.0, end_value = 15.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.3, duration = 0.15, start_value = -45.0, end_value = 90.0, easing = "outquad" },

                    -- Recover/Return (0.55 -> 1.0)
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.55, duration = 0.45, start_value = 60.0, end_value = 0.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "rotation_z", start_time = 0.55, duration = 0.45, start_value = 15.0, end_value = 0.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.55, duration = 0.45, start_value = 90.0, end_value = 0.0, easing = "inoutquad" },
                }
            },
            -- DAMAGE
            {
                animation_id = "damage",
                duration = 0.6,
                animation_keys = {
                    -- Recoil impact (0.0 -> 0.12)
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -40.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -15.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -20.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 0.12, start_value = 0.0, end_value = -25.0, easing = "outquad" },

                    -- Recover (0.12 -> 0.6)
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.12, duration = 0.48, start_value = -40.0, end_value = 0.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "body", property_id = "rotation_z", start_time = 0.12, duration = 0.48, start_value = -15.0, end_value = 0.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.12, duration = 0.48, start_value = -20.0, end_value = 0.0, easing = "inoutquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.12, duration = 0.48, start_value = -25.0, end_value = 0.0, easing = "inoutquad" },
                }
            },
            -- DEATH
            {
                animation_id = "death",
                duration = 1.2,
                animation_keys = {
                    -- Falling back (0.0 -> 0.5) (base y = 70.0)
                    { key_type = "tween", node_id = "body", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = -90.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_y", start_time = 0.0, duration = 0.5, start_value = 70.0, end_value = -30.0, easing = "outquad" },
                    { key_type = "tween", node_id = "body", property_id = "position_x", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = -85.0, easing = "outquad" },
                    { key_type = "tween", node_id = "head", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = -25.0, easing = "outquad" },

                    -- Bat drops (base x = -15.0, y = 129.0)
                    { key_type = "tween", node_id = "baseball_bat", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = -110.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_x", start_time = 0.0, duration = 0.5, start_value = -15.0, end_value = -90.0, easing = "outquad" },
                    { key_type = "tween", node_id = "baseball_bat", property_id = "position_y", start_time = 0.0, duration = 0.5, start_value = 129.0, end_value = 59.0, easing = "outquad" },

                    -- Legs kick up slightly
                    { key_type = "tween", node_id = "left_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = 35.0, easing = "outquad" },
                    { key_type = "tween", node_id = "right_leg", property_id = "rotation_z", start_time = 0.0, duration = 0.5, start_value = 0.0, end_value = 20.0, easing = "outquad" },

                    -- Fade out (0.5 -> 1.2)
                    { key_type = "tween", node_id = "body#sprite", property_id = "color_a", start_time = 0.5, duration = 0.7, start_value = 1.0, end_value = 0.0, easing = "linear" },
                    { key_type = "tween", node_id = "head#sprite", property_id = "color_a", start_time = 0.5, duration = 0.7, start_value = 1.0, end_value = 0.0, easing = "linear" },
                    { key_type = "tween", node_id = "baseball_bat#sprite", property_id = "color_a", start_time = 0.5, duration = 0.7, start_value = 1.0, end_value = 0.0, easing = "linear" },
                    { key_type = "tween", node_id = "left_leg#sprite", property_id = "color_a", start_time = 0.5, duration = 0.7, start_value = 1.0, end_value = 0.0, easing = "linear" },
                    { key_type = "tween", node_id = "right_leg#sprite", property_id = "color_a", start_time = 0.5, duration = 0.7, start_value = 1.0, end_value = 0.0, easing = "linear" },
                    { key_type = "tween", node_id = "shadow#sprite", property_id = "color_a", start_time = 0.5, duration = 0.7, start_value = 1.0, end_value = 0.0, easing = "linear" },
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
            
            -- SHADOW
            { node_id = "shadow", node_index = 2, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 227, size_y = 52, visible = true, enabled = true },
            { node_id = "shadow#sprite", node_index = 3, node_type = "box", parent = "shadow", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 227, size_y = 52, visible = true, enabled = true },

            -- LEFT LEG
            { node_id = "left_leg", node_index = 4, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 87, size_y = 150, visible = true, enabled = true },
            { node_id = "left_leg#sprite", node_index = 5, node_type = "box", parent = "left_leg", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 87, size_y = 150, visible = true, enabled = true },

            -- RIGHT LEG
            { node_id = "right_leg", node_index = 6, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 86, size_y = 148, visible = true, enabled = true },
            { node_id = "right_leg#sprite", node_index = 7, node_type = "box", parent = "right_leg", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 86, size_y = 148, visible = true, enabled = true },

            -- BODY
            { node_id = "body", node_index = 8, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 221, size_y = 228, visible = true, enabled = true },
            { node_id = "body#sprite", node_index = 9, node_type = "box", parent = "body", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 221, size_y = 228, visible = true, enabled = true },

            -- HEAD
            { node_id = "head", node_index = 10, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 218, size_y = 219, visible = true, enabled = true },
            { node_id = "head#sprite", node_index = 11, node_type = "box", parent = "head", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 218, size_y = 219, visible = true, enabled = true },

            -- BASEBALL BAT
            { node_id = "baseball_bat", node_index = 12, node_type = "box", parent = "root", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 289, size_y = 302, visible = true, enabled = true },
            { node_id = "baseball_bat#sprite", node_index = 13, node_type = "box", parent = "baseball_bat", scale_x = 1, scale_y = 1, scale_z = 1, size_x = 289, size_y = 302, visible = true, enabled = true },
        }
    },
    format = "json",
    type = "animation_editor",
    version = 1,
}