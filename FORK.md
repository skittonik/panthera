# skittonik/panthera

A fork of [Insality/panthera](https://github.com/Insality/panthera), the Panthera runtime for
Defold. `main` is upstream `main` plus the runtime patches below, nothing else. Games live in
their own repositories and vendor `panthera/` from here.

Based on upstream release 11 (`3cf7557`, 2026-10-06).

## Patches over upstream

| Patch | Files | Why |
|---|---|---|
| `panthera.crossfade(state, target_id, duration?, play_options?)` | `panthera/panthera.lua` | Blend from the current pose into the start of another animation, then play it from the blended pose. `stop`, `play` or another `crossfade` during the blend cancel the pending target. |
| `get_node_property(node, property_id)` in both adapters | `panthera/adapters/adapter_go.lua`, `adapter_gui.lua` | Reads the current value of a tween property, crossfade blends from it. |
| No public `play_detached` | `panthera/panthera.lua` | A detached child shared the nodes and the stop / reset / crossfade cycle of its parent, overlapping ones froze each other. A second track is a state of its own: `panthera.clone_state()` + `panthera.play()`. |
| `cd` instead of `pwd` on Windows | `panthera/panthera_internal.lua` | Hot reload of animation files finds `game.project` on Windows. |
| `tint` and `flash` uniforms in the sprite material | `panthera/materials/sprite.*` | `tint` multiplies the color (default white), `flash.x` in 0..1 mixes towards a white silhouette (damage flash). Fragments with alpha below 0.01 are discarded. GLSL 140. |

Tests of the patches: `test/test_panthera_crossfade.lua`, the cloned state test in
`test/test_panthera_playback.lua`. The test engine adapter reads node properties and its timer
mock waits for the delay of a one shot timer.

### Dropped when the fork moved to release 11

- `stop(state, is_skip_reset)`. It reset the nodes of nested child states unless
  `is_skip_reset` was true. Upstream now resets nested and template animations on the next
  `play` and its `stop` never resets nodes, so both modes were the same. A call with the extra
  argument still works.
- The `save_file_from_dependency` removal in `panthera.editor_script` was upstream's own
  commit `781087b`. Upstream 11 ships a new editor script (`panthera_editor.lua`, install and
  run the Panthera editor from Defold), the fork keeps it.

## Syncing with upstream

```bash
git fetch upstream --tags
git merge upstream/main
```

A merge needs no force push. Resolve the conflicts against the upstream change and keep the
table above true. Run the tests before pushing: build with Bob with `--settings test/test.ini`
and run the engine on the result, as `.github/workflows/ci_workflow.yml` does.

The autobattle prototype that used to live in this fork moved out; its last state here is the
tag `archive/autobattle-rework`.
