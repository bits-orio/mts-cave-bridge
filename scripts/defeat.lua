-- MTS Cave Bridge - scripts/defeat.lua
-- Author: bits-orio
-- License: MIT
--
-- The Cave resets a defeated team in place. With the map setting on, the
-- team is disbanded instead: its players go back to MTS's landing pen and the
-- slot is free for a new team. One chat line says why; MTS's own disband
-- lines are skipped. A server-wide reset (only one team in The Cave) is left
-- to The Cave.

local teams = require("scripts.teams")

local defeat = {}

local SETTING = "mts-cave-bridge-disband-on-defeat"

local REASON = {
    ["main-train-destroyed"] = "mts-cave-bridge.reason-main-train",
    ["shelter-destroyed"]    = "mts-cave-bridge.reason-shelter",
}

function defeat.on_force_defeated(event)
    if event.scope ~= "force" then return end
    if not settings.global[SETTING].value then return end
    local name = event.force_name
    if not teams.is_team(name) then return end
    local info = remote.call("mts-v1", "get_team_info", name)
    if not (info and info.is_occupied) then return end
    game.print({ "mts-cave-bridge.team-defeated", teams.label(name), { REASON[event.reason] or "mts-cave-bridge.reason-other" } })
    remote.call("mts-v1", "disband_team", name, { quiet = true })
end

return defeat
