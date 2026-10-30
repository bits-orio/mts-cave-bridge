-- MTS Cave Teams - scripts/teams.lua
-- Author: bits-orio
-- License: MIT
--
-- The few facts about MTS teams the bridge needs, asked through mts-v1.

local teams = {}

--- True for an MTS team force name (team-<N>).
function teams.is_team(force_name)
    return type(force_name) == "string" and force_name:match("^team%-%d+$") ~= nil
end

--- The force a player plays for: their own team even while spectating another.
--- @return string|nil force name
function teams.effective_force(player_index)
    return remote.call("mts-v1", "get_effective_force", player_index)
end

--- A team that is claimed and whose clock runs (staged start: the leader has
--- pressed Start Playing). nil for a force that is not an MTS team.
function teams.is_ready(force_name)
    if not teams.is_team(force_name) then return nil end
    local info = remote.call("mts-v1", "get_team_info", force_name)
    return info ~= nil and info.is_occupied and info.clock_start_tick ~= nil
end

function teams.is_paused(force_name)
    if not teams.is_team(force_name) then return nil end
    return remote.call("mts-v1", "is_team_paused", force_name)
end

--- The team's chat tag (name and leader), for announcements.
function teams.label(force_name)
    return remote.call("mts-v1", "get_team_label", force_name) or force_name
end

return teams
