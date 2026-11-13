-- MTS Cave Bridge - scripts/interiors.lua
-- Author: bits-orio
-- License: MIT
--
-- Registers the surfaces The Cave makes for a team (train interiors, shelters,
-- gardens, child caves) as that team's MTS surfaces: MTS then bounces other
-- teams' players, counts their production, freezes them in a pause and
-- deletes them with the team. They are exempt from /mts-trim, whose entity
-- buffer cannot see a room built by script far from any team entity, and they
-- carry no MTS spawn label.

local cave_api = require("scripts.cave_api")
local teams    = require("scripts.teams")

local interiors = {}

function interiors.register(force_index, surface_name)
    local force = game.forces[force_index]
    if not (force and force.valid and teams.is_team(force.name)) then return end
    if not game.surfaces[surface_name] then return end
    local spec = { name = surface_name, allow_chunk_trim = false }
    if remote.call("mts-v1", "create_team_surface", force.name, spec) then
        remote.call("mts-v1", "set_spawn_label_enabled", surface_name, false)
    else
        log("[MTS Cave Bridge] MTS refused " .. surface_name .. " for " .. force.name .. " (another team owns it)")
    end
end

function interiors.register_force(force)
    for _, name in pairs(cave_api.owned_surfaces(force.index)) do
        interiors.register(force.index, name)
    end
end

--- Every team's Cave surfaces; for a new game, a mod update or an older Cave.
function interiors.sweep()
    for _, force in pairs(game.forces) do
        if teams.is_team(force.name) then interiors.register_force(force) end
    end
end

--- The Cave's on_owned_surface_changed. A deleted surface needs nothing: MTS
--- ends ownership when a surface is deleted.
function interiors.on_owned_surface_changed(event)
    if event.change == "created" then interiors.register(event.force_index, event.surface_name) end
end

--- Fallback for a Cave without on_owned_surface_changed: a team player arriving
--- on a surface may have just made The Cave build one.
function interiors.on_player_changed_surface(event)
    local player = game.get_player(event.player_index)
    if player and teams.is_team(player.force.name) then interiors.register_force(player.force) end
end

return interiors
