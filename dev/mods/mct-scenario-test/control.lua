-- mct-scenario-test: the dev-only driver behind dev/run-scenarios.sh.
--
-- Steps arrive as "/mctt <step> [arg]" on the server console. Every check
-- logs one line,
--   MCT_TEST PASS <name>: <detail>    or    MCT_TEST FAIL <name>: <detail>
-- and every step ends with "MCT_TEST STEP <name>", which the runner waits for.
--
-- Handlers are registered unconditionally at parse time, and the other mods'
-- events from their ids on every session, so a joining client always matches
-- the server.

local TAG = "MCT_TEST "
local ADAPTER = "mts-cave-teams-adapter"
local TRAIN = settings.startup["the-cave-train-interiors"].value == "enabled"
local SHELTER = settings.startup["the-cave-shelter-defense"].value == "enabled"

local function say(kind, name, detail)
    log(TAG .. kind .. " " .. name .. (detail ~= nil and (": " .. tostring(detail)) or ""))
end
local function check(name, ok, detail)
    if ok then say("PASS", name) else say("FAIL", name, detail) end
    return ok
end
local function step(name, detail) say("STEP", name, detail) end
local function mts(fn, ...) return remote.call("mts-v1", fn, ...) end
local function cave(fn, ...) return remote.call("the-cave-v1", fn, ...) end
local function adapter(fn, ...) return remote.call(ADAPTER, fn, ...) end

local STEPS = {}

local function init_storage()
    storage.queue   = storage.queue or {}
    storage.waiting = storage.waiting or {}   -- team name -> tick it was claimed, until its base stands
    storage.defeats = storage.defeats or {}
end

local function later(ticks, name, args)
    storage.queue[#storage.queue + 1] = { at = game.tick + ticks, name = name, args = args or {} }
end

local function run(name, args)
    local fn = STEPS[name]
    if not fn then say("FAIL", "unknown-step", name); step(name); return end
    local ok, err = pcall(fn, args or {})
    if not ok then say("FAIL", name, "test step error: " .. tostring(err)); step(name) end
end

-- ─── Facts ──────────────────────────────────────────────────────────────

--- The Cave's starter base of a team: its Main Train or its shelter. In the
--- plain mode there is none.
local function base_entity(team)
    for _, surface in pairs(game.surfaces) do
        local found
        if SHELTER then
            found = surface.find_entities_filtered { force = team, name = "the-cave-shelter", limit = 1 }
        elseif TRAIN then
            found = surface.find_entities_filtered { force = team, type = "locomotive", limit = 1 }
        end
        if found and found[1] then return found[1] end
    end
end

local function owned(team)
    local names = cave("get_owned_surfaces", game.forces[team].index)
    table.sort(names)
    return names
end

local function member(team)
    for _, player in pairs(game.forces[team].players) do return player end
end

local function is_occupied(team)
    local info = mts("get_team_info", team)
    return info ~= nil and info.is_occupied == true
end

-- ─── Events ─────────────────────────────────────────────────────────────

local MTS_HANDLERS = {
    on_team_created = function(e)
        storage.waiting[e.force_name] = game.tick
        step("team-created", e.force_name)
    end,
    on_team_released = function(e) step("team-released", e.force_name) end,
    on_team_clock_started = function(e) step("clock-started", e.force_name) end,
}

local CAVE_HANDLERS = {
    on_force_defeated = function(e)
        storage.defeats[#storage.defeats + 1] = { force = e.force_name, scope = e.scope, reason = e.reason, tick = game.tick }
        step("defeated", e.force_name .. " scope=" .. tostring(e.scope) .. " reason=" .. tostring(e.reason))
    end,
}

local function subscribe()
    for name, handler in pairs(MTS_HANDLERS) do
        local id = remote.call("mts-v1", "get_event_id", name)
        if id then script.on_event(id, handler) end
    end
    for name, handler in pairs(CAVE_HANDLERS) do
        local id = remote.call("the-cave-v1", "get_event_id", name)
        if id then script.on_event(id, handler) end
    end
end

--- A claimed team's base: logged once it stands (plain mode: 5 s after the claim).
script.on_nth_tick(30, function(event)
    for team, since in pairs(storage.waiting) do
        local base = base_entity(team)
        local plain = not (TRAIN or SHELTER)
        if base or (plain and event.tick - since >= 300) then
            storage.waiting[team] = nil
            local player = member(team)
            step("base", string.format("team=%s base=%s on %s, member on %s, after %d ticks", team,
                base and base.name or "none", base and base.surface.name or "-",
                player and player.physical_surface.name or "-", event.tick - since))
        elseif event.tick - since > 90 * 60 then
            storage.waiting[team] = nil
            say("FAIL", "base", team .. " got no base in 90 s")
            step("base", "team=" .. team .. " none")
        end
    end
end)

-- ─── Steps ──────────────────────────────────────────────────────────────

--- A player waiting in MTS's landing pen: The Cave must leave them alone.
STEPS["pen"] = function()
    local player = game.connected_players[1]
    local surface = player.physical_surface
    check("pen-not-a-team-surface", not mts("is_team_surface", surface.name), surface.name)
    check("pen-no-effective-team", adapter("effective_force", player.index) == nil,
        tostring(adapter("effective_force", player.index)))
    local names = cave("get_owned_surfaces", player.force.index)
    check("pen-no-cave-surfaces", #names == 0, table.concat(names, ","))
    check("pen-no-base", base_entity(player.force.name) == nil, "a base stands for " .. player.force.name)
    step("pen", "player " .. player.name .. " on " .. surface.name .. " force " .. player.force.name)
end

--- The team's world is its MTS surface, and every surface The Cave made for
--- the team is the team's in MTS.
STEPS["owned"] = function(a)
    local team = a.arg
    local player = member(team)
    local home = player.physical_surface.name
    check("home-is-team-surface " .. team, mts("get_surface_owner", home) == team,
        home .. " owner " .. tostring(mts("get_surface_owner", home)))
    check("team-ready " .. team, adapter("force_ready", game.forces[team].index) == true,
        tostring(adapter("force_ready", game.forces[team].index)))
    check("effective-force " .. team, adapter("effective_force", player.index) == game.forces[team].index,
        tostring(adapter("effective_force", player.index)))
    local names = owned(team)
    if TRAIN or SHELTER then check("cave-made-surfaces " .. team, #names > 0, "none listed") end
    for _, name in ipairs(names) do
        check("interior-owner " .. name, mts("get_surface_owner", name) == team, tostring(mts("get_surface_owner", name)))
    end
    step("owned", team .. " home=" .. home .. " cave surfaces={" .. table.concat(names, ",") .. "}")
end

--- MTS staged start: a claimed team that has not pressed Start Playing is not
--- ready, and The Cave has built it nothing.
STEPS["staged"] = function(a)
    local team = a.arg
    check("staged-not-ready " .. team, adapter("force_ready", game.forces[team].index) == false,
        tostring(adapter("force_ready", game.forces[team].index)))
    local base = base_entity(team)
    check("staged-no-base-yet " .. team, base == nil, base and (base.name .. " on " .. base.surface.name))
    local names = owned(team)
    check("staged-no-cave-surfaces-yet " .. team, #names == 0, table.concat(names, ","))
    step("staged", team)
end

--- MTS pauses the team; two seconds later The Cave must not have relit it.
STEPS["pause"] = function(a)
    local team = a.arg
    check("pause-call " .. team, mts("pause_team", team, { holder = "mct-test" }) == true)
    check("adapter-reads-paused " .. team, adapter("force_paused", game.forces[team].index) == true)
    later(120, "pause-held", { arg = team })
end

STEPS["pause-held"] = function(a)
    local team = a.arg
    for _, name in pairs(mts("list_team_surfaces", team)) do
        local surface = game.surfaces[name]
        if surface then
            check("paused-solar-zero " .. name, surface.solar_power_multiplier == 0, surface.solar_power_multiplier)
        end
    end
    step("pause", team)
end

STEPS["resume"] = function(a)
    local team = a.arg
    mts("unpause_team", team, { holder = "mct-test" })
    check("adapter-reads-running " .. team, adapter("force_paused", game.forces[team].index) == false)
    check("mts-resumed " .. team, mts("is_team_paused", team) == false)
    step("resume", team)
end

--- Destroy a team's base. The runner then waits for The Cave's defeat event.
STEPS["defeat"] = function(a)
    local team = a.arg
    local base = base_entity(team)
    if not check("defeat-has-base " .. team, base ~= nil, "no base") then step("defeat", team); return end
    local force = game.forces[team]
    force.technologies["automation"].researched = true
    storage.before = { team = team, defeats = #storage.defeats, surfaces = owned(team), others = {} }
    for _, info in pairs(mts("get_team_list")) do
        local other = info.force_name
        if other ~= team and is_occupied(other) then
            game.forces[other].technologies["automation"].researched = true
            storage.before.others[other] = { surfaces = owned(other), base = base_entity(other) }
        end
    end
    base.die()
    step("defeat", team .. " base destroyed, others: " .. serpent.line(storage.before.others, { comment = false }))
end

--- After the defeat: <team> <reset|disband|server>.
STEPS["after-defeat"] = function(a)
    local team, want = a.arg:match("^(%S+)%s+(%S+)$")
    local before = storage.before
    local event = storage.defeats[before.defeats + 1]
    if not check("defeat-event " .. team, event ~= nil and event.force == team, "no on_force_defeated for " .. team) then
        step("after-defeat", team); return
    end
    local scope = want == "server" and "server" or "force"
    check("defeat-scope " .. team, event.scope == scope, tostring(event.scope))
    local force = game.forces[team]
    check("research-reset " .. team, not force.technologies["automation"].researched, "automation still researched")
    for other, was in pairs(before.others) do
        check("other-team-keeps-research " .. other, game.forces[other].technologies["automation"].researched)
        check("other-team-still-claimed " .. other, is_occupied(other))
        if TRAIN or SHELTER then
            check("other-team-keeps-base " .. other, was.base and was.base.valid, "base gone")
        end
        local now = table.concat(owned(other), ",")
        check("other-team-keeps-surfaces " .. other, now == table.concat(was.surfaces, ","), now)
    end
    if want == "disband" then
        check("team-disbanded " .. team, not is_occupied(team), "still claimed")
        for _, player in pairs(game.connected_players) do
            check("member-back-in-pen " .. player.name, not mts("is_team_surface", player.physical_surface.name),
                player.physical_surface.name .. " force " .. player.force.name)
        end
        for _, name in ipairs(before.surfaces) do
            local owner = mts("get_surface_owner", name)
            check("disbanded-interior-gone " .. name, game.surfaces[name] == nil or owner == nil,
                "still there, owner " .. tostring(owner))
        end
    else
        check("team-still-claimed " .. team, is_occupied(team), "released")
        local player = member(team)
        if player and player.connected then
            check("member-on-own-surface " .. team, mts("get_surface_owner", player.physical_surface.name) == team,
                player.physical_surface.name)
        end
        -- The Cave rebuilds the base when the team is back on its world.
        storage.waiting[team] = game.tick
    end
    step("after-defeat", team .. " " .. want)
end

STEPS["done"] = function() say("DONE", "") end

-- ─── Wiring ─────────────────────────────────────────────────────────────

script.on_event(defines.events.on_player_joined_game, function(e)
    local p = game.get_player(e.player_index)
    p.admin = true
    step("joined", p.name .. " index=" .. p.index)
end)

script.on_event(defines.events.on_player_left_game, function(e)
    step("left", tostring(e.player_index))
end)

script.on_event(defines.events.on_tick, function(e)
    local q = storage.queue
    if #q == 0 then return end
    local due, keep = {}, {}
    for _, item in ipairs(q) do
        if item.at <= e.tick then due[#due + 1] = item else keep[#keep + 1] = item end
    end
    if #due == 0 then return end
    storage.queue = keep
    for _, item in ipairs(due) do run(item.name, item.args) end
end)

commands.add_command("mctt", "dev test steps (mct-scenario-test)", function(c)
    local name, rest = (c.parameter or ""):match("^(%S+)%s*(.*)$")
    run(name or "", { arg = rest })
end)

script.on_init(function() init_storage(); subscribe() end)
script.on_load(subscribe)
script.on_configuration_changed(function() init_storage(); subscribe() end)
