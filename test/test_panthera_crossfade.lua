-- Fork (skittonik/panthera): panthera.crossfade is not in upstream, see FORK.md
return function()
	describe("Panthera Crossfade", function()
		---@type panthera
		local panthera
		local test_engine
		local utils
		local project

		before(function()
			panthera = require("panthera.panthera")
			test_engine = require("test.test_engine")
			utils = require("test.test_utils")
			panthera.set_logger(nil)
			panthera.SPEED = 1
			test_engine.mock()

			project = utils.project({
				utils.animation("move", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 100 }) }),
				utils.animation("back", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 100, end_value = 0 }) }),
				utils.animation("grow", 1, {
					utils.tween("box", "scale_x", { duration = 1, start_value = 0, end_value = 1 }) }),
			})
		end)

		after(function()
			test_engine.unmock()
		end)


		it("Blends into the start of the target, then plays it", function()
			local state, nodes = utils.create_scene(project)
			local finished = 0

			panthera.play(state, "move")
			utils.play_frames(30)
			local at_start = nodes.box.position_x
			assert(utils.near(at_start, 50, 3), "move is halfway, got " .. tostring(at_start))

			local is_started = panthera.crossfade(state, "back", 0.2, { callback = function() finished = finished + 1 end })
			assert(is_started == true, "the crossfade starts")
			assert(panthera.is_playing(state) == true, "a blend counts as playing")
			assert(state.target_animation_id == "back", "the state is tagged with the target")

			utils.play_frames(6)
			assert(nodes.box.position_x > at_start and nodes.box.position_x < 100,
				"halfway through the blend, got " .. tostring(nodes.box.position_x))
			assert(state.animation_id == nil, "the target does not play during the blend")

			utils.play_frames(8)
			assert(state.animation_id == "back", "the target plays after the blend")
			assert(state.target_animation_id == nil, "the tag is cleared")
			assert(nodes.box.position_x > 90, "the target starts from the blended pose, got " .. tostring(nodes.box.position_x))

			utils.play_frames(70)
			assert(utils.near(nodes.box.position_x, 0, 1), "the target plays to its end, got " .. tostring(nodes.box.position_x))
			assert(finished == 1, "the play options reach the target, got " .. finished)
		end)


		it("A property the target does not drive rests where it is", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "grow")
			utils.play_frames(30)
			local scale = nodes.box.scale_x

			panthera.crossfade(state, "move", 0.1)
			assert(test_engine.tween_count() == 2, "the target and the resting property blend, got " .. test_engine.tween_count())

			utils.play_frames(30)
			assert(state.animation_id == "move", "the target plays")
			assert(utils.near(nodes.box.scale_x, scale), "scale_x stays, got " .. tostring(nodes.box.scale_x))
		end)


		it("Stop during the blend cancels the pending target", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "move")
			utils.play_frames(30)

			panthera.crossfade(state, "back", 0.2)
			utils.play_frames(3)
			assert(panthera.stop(state) == true, "the blend stops")
			local at_stop = nodes.box.position_x

			utils.play_frames(30)
			assert(state.animation_id == nil, "the target never plays")
			assert(panthera.is_playing(state) == false, "nothing is playing")
			assert(test_engine.timer_count() == 0, "the crossfade timer is cancelled, got " .. test_engine.timer_count())
			assert(nodes.box.position_x == at_stop, "the blend tween is stopped too")
		end)


		it("Play during the blend wins over the pending target", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "move")
			utils.play_frames(30)

			panthera.crossfade(state, "back", 0.2)
			utils.play_frames(3)
			panthera.play(state, "grow")

			utils.play_frames(30)
			assert(state.animation_id == "grow", "the played animation keeps playing, got " .. tostring(state.animation_id))
			assert(test_engine.timer_count() == 1, "only the play timer is left, got " .. test_engine.timer_count())
			assert(utils.near(nodes.box.position_x, 100), "the blended node is reset to the rest pose of the target, got " .. tostring(nodes.box.position_x))
		end)


		it("A second crossfade during the blend redirects it", function()
			local state, nodes = utils.create_scene(project)
			panthera.play(state, "move")
			utils.play_frames(30)

			panthera.crossfade(state, "back", 0.2)
			utils.play_frames(3)
			panthera.crossfade(state, "move", 0.2)
			assert(state.target_animation_id == "move", "the newest target wins")

			utils.play_frames(20)
			assert(state.animation_id == "move", "the second target plays, got " .. tostring(state.animation_id))
			assert(test_engine.timer_count() == 1, "the first crossfade timer is gone, got " .. test_engine.timer_count())
		end)


		it("Properties of the running clips rest where they are", function()
			local template = utils.project({ utils.animation("inner", 1, {
				utils.tween("box", "scale_x", { duration = 1, start_value = 0, end_value = 1 }) }) })
			local clips_project = utils.project({
				utils.animation("grow", 1, {
					utils.tween("box", "scale_x", { duration = 1, start_value = 0, end_value = 1 }) }),
				utils.animation("root", 1, {
					utils.clip("grow", { duration = 1 }),
					utils.clip("inner", { node_id = "holder", duration = 1 }),
				}),
				utils.animation("move", 1, {
					utils.tween("box", "position_x", { duration = 1, start_value = 0, end_value = 100 }) }),
			}, { holder = template })
			local state, nodes = utils.create_scene(clips_project)

			panthera.play(state, "root")
			utils.play_frames(30)
			assert(#state.clips == 2, "the nested and the template clip run, got " .. #state.clips)
			local scale = nodes.box.scale_x
			local holder_scale = nodes["holder/box"].scale_x

			panthera.crossfade(state, "move", 0.1)
			assert(state.clips[1] == nil, "the clips are stopped")
			assert(test_engine.tween_count() == 3, "the target and both clip properties blend, got " .. test_engine.tween_count())

			utils.play_frames(30)
			assert(state.animation_id == "move", "the target plays")
			assert(utils.near(nodes.box.scale_x, scale), "the nested clip node stays, got " .. tostring(nodes.box.scale_x))
			assert(utils.near(nodes["holder/box"].scale_x, holder_scale), "the template clip node stays, got " .. tostring(nodes["holder/box"].scale_x))
		end)


		it("Crossfade to an unknown animation is reported and changes nothing", function()
			local state = utils.create_scene(project)
			local logged = 0
			panthera.set_logger({
				trace = function() end, debug = function() end, info = function() end,
				warn = function() logged = logged + 1 end,
				error = function() logged = logged + 1 end,
			})

			panthera.play(state, "move")
			assert(panthera.crossfade(state, "no_such_animation") == false, "the crossfade is refused")
			assert(logged == 1, "the failure is logged, got " .. logged)
			assert(state.animation_id == "move", "the current animation keeps playing")
			panthera.stop(state)
		end)
	end)
end
