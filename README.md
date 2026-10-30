# MTS Cave Teams

Plays [The Cave](https://mods.factorio.com/mod/the-cave) with [Multi-Team Support (MTS)](https://mods.factorio.com/mod/multi-team-support): every team digs its own copy of the cave. Neither mod knows the other; this one connects them.

## What it does

- Answers The Cave's team questions from MTS: which team a player plays for (also while spectating), whether a team may start yet (MTS staged start), and whether it is paused.
- Registers the surfaces The Cave builds for a team (train interiors, shelters, gardens, child caves) as that team's MTS surfaces. MTS then keeps other teams out, counts their production, freezes them in a pause and deletes them with the team. They are exempt from `/mts-trim` and carry no MTS spawn label.
- Optionally disbands a team that The Cave defeats while other teams play on (map setting "Disband a defeated team", off by default). One chat line says why. Without it, The Cave resets the team in place.

## Needs

- Multi-Team Support with `allow_chunk_trim`, the quiet `disband_team` option and pause holders.
- The Cave with `the-cave-v1` (`register_adapter`, `get_owned_surfaces`, `on_force_defeated`). With `on_owned_surface_changed`, interiors are registered the moment The Cave builds them; without it, when a team player arrives on a surface.
- Do not install it together with The Cave MTS Compat (`the-cave-mts-compat`): both would answer The Cave's adapter.

## Development

Tests: `dev/run-tests.sh` (headless, base and Space Age). See the `dev/` folder.

Developed with AI coding assistants alongside human review and in-game testing.

MIT licence.
