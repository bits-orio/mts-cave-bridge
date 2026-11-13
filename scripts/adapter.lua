-- MTS Cave Bridge - scripts/adapter.lua
-- Author: bits-orio
-- License: MIT
--
-- Answers The Cave's three team questions from MTS. The Cave caches the
-- answers per tick, so each is asked straight from MTS with no copy of MTS's
-- state kept here.
--   effective_force(player_index) -> force index or nil
--   force_ready(force_index)      -> false while a team cannot start yet, nil for non-teams
--   force_paused(force_index)     -> true while MTS has the team paused

local teams = require("scripts.teams")

local adapter = {}

adapter.INTERFACE = "mts-cave-bridge-adapter"

local function force_name(force_index)
    local force = game.forces[force_index]
    return force and force.valid and force.name or nil
end

remote.add_interface(adapter.INTERFACE, {
    effective_force = function(player_index)
        local name = teams.effective_force(player_index)
        local force = name and game.forces[name]
        return force and force.valid and force.index or nil
    end,
    force_ready = function(force_index)
        return teams.is_ready(force_name(force_index))
    end,
    force_paused = function(force_index)
        return teams.is_paused(force_name(force_index))
    end,
})

return adapter
