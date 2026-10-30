-- Dev-only headless checks for MTS Cave Teams; dev/run-tests.sh reads the
-- MCT_TEST lines. Needs no player, so it covers the adapter and interior
-- registration; defeats and arrivals need a client (dev/run-mp.sh).

local ADAPTER = "mts-cave-teams-adapter"

local function check(name, ok, detail)
    log("MCT_TEST " .. (ok and "PASS " or "FAIL ") .. name .. (ok and "" or (": " .. tostring(detail))))
end

local function adapter(fn, ...) return remote.call(ADAPTER, fn, ...) end

local STEPS = {
    [2] = function()
        check("adapter interface", remote.interfaces[ADAPTER] ~= nil)
        local team1 = game.forces["team-1"].index
        check("unclaimed team is not ready", adapter("force_ready", team1) == false, adapter("force_ready", team1))
        check("non-team force has no answer", adapter("force_ready", game.forces.player.index) == nil)
        check("unknown player has no force", adapter("effective_force", 9999) == nil)
        remote.call("mts-v1", "pause_team", "team-2")
        check("paused team reads paused", adapter("force_paused", game.forces["team-2"].index) == true)
        remote.call("mts-v1", "unpause_team", "team-2")
        check("resumed team reads running", adapter("force_paused", game.forces["team-2"].index) == false)
    end,
    [4] = function()
        local id = remote.call("the-cave-v1", "get_event_id", "on_owned_surface_changed")
        check("The Cave publishes on_owned_surface_changed", id ~= nil)
        if not id then return end
        local room = game.create_surface("the-cave-mct-room")
        script.raise_event(id, { surface_index = room.index, surface_name = room.name,
            force_index = game.forces["team-3"].index, change = "created" })
        check("interior registered to its team",
            remote.call("mts-v1", "get_surface_owner", room.name) == "team-3",
            remote.call("mts-v1", "get_surface_owner", room.name))
    end,
    [6] = function() log("MCT_TEST DONE") end,
}

script.on_event(defines.events.on_tick, function(event)
    local step = STEPS[event.tick]
    if step then step() end
end)
