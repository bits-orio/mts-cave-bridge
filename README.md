# MTS Bridge for The Cave

Plays [The Cave](https://mods.factorio.com/mod/the-cave) with [Multi-Team Support (MTS)](https://mods.factorio.com/mod/multi-team-support): every team digs its own copy of the cave. Neither mod knows the other; this one connects them.

## What it does

- Answers The Cave's team questions from MTS: which team a player plays for (also while spectating), whether a team may start yet (MTS staged start), and whether it is paused.
- Registers the surfaces The Cave builds for a team (train interiors, shelters, gardens, child caves) as that team's MTS surfaces. MTS then keeps other teams out, counts their production, freezes them in a pause and deletes them with the team. They are exempt from `/mts-trim` and carry no MTS spawn label.
- Optionally disbands a team that The Cave defeats while other teams play on (map setting "Disband a defeated team", off by default). One chat line says why. Without it, The Cave resets the team in place.

## Needs

- Factorio 2.1.23 or newer; Space Age is optional.
- Multi-Team Support 0.7.10 or newer.
- The Cave 3.3.6 or newer. When The Cave publishes `on_owned_surface_changed` through `the-cave-v1`, interiors are registered the moment The Cave builds them; with 3.3.6 they are registered when their first chunk generates or when a team player next changes surface, which is at the latest when someone steps inside.

## Credits

[The Cave](https://mods.factorio.com/mod/the-cave) is made by [behroozzx](https://mods.factorio.com/user/behroozzx). Thank you, behroozzx, for building The Cave and for keeping it open to other mods through its `the-cave-v1` interface. All of the cave gameplay is their work, and the thumbnail uses The Cave's art. This bridge contains none of The Cave's code.

## Development

- `dev/run-tests.sh`: headless checks of the adapter and interior registration, base and Space Age.
- `dev/run-scenarios.sh`: a real server and a joined client, eight sessions. Teams claim slots through the landing pen, get their Main Train or shelter, are paused, defeated, reset or disbanded, and start under MTS Staged Start. `CAVE_REV=<git rev>` runs them against that revision of the Cave checkout.
- `tools/release.sh` tags a release; the GitHub workflow packages it and uploads it to the mod portal. The portal page text is `docs/portal.md`.

Developed with AI coding assistants alongside human review and in-game testing.

MIT licence.
