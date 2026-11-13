# MTS Bridge for The Cave

> Every team digs its own cave.

[![Discord](https://img.shields.io/badge/Discord-join%20the%20server-5865F2?logo=discord&logoColor=white)](https://discord.gg/tWz4FT74pH) [![GitHub](https://img.shields.io/badge/GitHub-source-181717?logo=github&logoColor=white)](https://github.com/bits-orio/mts-cave-bridge)

This bridge requires [Multi-Team Support](https://mods.factorio.com/mod/multi-team-support) and [The Cave](https://mods.factorio.com/mod/the-cave), and lets a server run them together. Each team claims a slot in the MTS landing pen and lands in its own copy of the cave, with its own Main Train or shelter, its own research and its own enemies. Teams race on the same map without ever meeting underground.

## Status

Work in progress: this is an early release (0.1.0), so expect rough edges and keep a backup of any long-running map. Tested on a server with joined clients on Factorio 2.1.23, with Multi-Team Support 0.7.10 and The Cave 3.3.6: the default mode, Train Interiors and Shelter Defense, with and without Space Age. CAVETORIO is a single-force mode of The Cave and stays that way. Report anything odd on [Discord](https://discord.gg/tWz4FT74pH) or in the [issue tracker](https://github.com/bits-orio/mts-cave-bridge/issues).

## Quick start

1. Install [Multi-Team Support](https://mods.factorio.com/mod/multi-team-support), [The Cave](https://mods.factorio.com/mod/the-cave) and this mod.
2. Pick The Cave's mode in Settings, Mod settings, Startup, as you would without teams.
3. Start a new multiplayer map.
4. Each player clicks "Start a new team" in the landing pen, or joins a team that is recruiting.

## Features

- Every team gets its own copy of the cave, generated from the same map, so the race is fair.
- A team's train interiors, shelter, gardens and child caves are that team's surfaces in MTS: other teams are kept out and their production counts for the team.
- A team that loses its Main Train or shelter is reset on its own. The other teams play on.
- Map setting "Disband a defeated team" sends the losing team back to the landing pen and frees its slot, with one chat line saying why.
- MTS pauses, staged starts and spectating work with The Cave: a paused team is frozen, interiors included, and a team that has not pressed Start Playing gets no base yet.

## Compatibility

Needs Factorio 2.1.23 or newer. Space Age is optional.

## Credits

[The Cave](https://mods.factorio.com/mod/the-cave) is made by [behroozzx](https://mods.factorio.com/user/behroozzx). Thank you, behroozzx, for building The Cave and for keeping it open to other mods through its `the-cave-v1` interface. All of the cave gameplay is their work, and the thumbnail uses The Cave's art.

This bridge is a separate mod, written with the author's knowledge and agreement, and contains none of The Cave's code.

## Works with

Part of the MTS family:

- [Multi-Team Support](https://mods.factorio.com/mod/multi-team-support) runs the teams, the landing pen, pauses and spectating.
- [Diggy](https://mods.factorio.com/mod/diggy) is another underground game that plays per team with MTS.
- [Open Discord Bridge](https://mods.factorio.com/mod/open-discord-bridge) sends team events to your Discord channel.

## Links

- [README](https://github.com/bits-orio/mts-cave-bridge/blob/main/README.md)
- [Community Discord](https://discord.gg/tWz4FT74pH)

## Development

Developed with AI coding assistants alongside human review and in-game testing. Issues and pull requests are welcome on [GitHub](https://github.com/bits-orio/mts-cave-bridge).

License: MIT
