-- MTS Cave Bridge - control.lua
-- Author: bits-orio
-- License: MIT
--
-- Bridges The Cave and Multi-Team Support, so neither has to know the other.
-- The Cave asks its team questions through the adapter interface registered
-- here; its interiors become MTS team surfaces; its defeats can disband the
-- MTS team.

local adapter   = require("scripts.adapter")
local cave_api  = require("scripts.cave_api")
local interiors = require("scripts.interiors")
local defeat    = require("scripts.defeat")

-- Custom event ids are looked up every session, in on_init,
-- on_configuration_changed and on_load, and never kept in storage: they shift
-- when the mod set changes, and a stale one can stop a save from loading.
local function subscribe()
    local defeated = cave_api.event_id("on_force_defeated")
    if defeated then script.on_event(defeated, defeat.on_force_defeated) end
    local owned = cave_api.event_id("on_owned_surface_changed")
    if owned then
        script.on_event(owned, interiors.on_owned_surface_changed)
    else
        script.on_event(defines.events.on_player_changed_surface, interiors.on_player_changed_surface)
    end
end

local function configure()
    cave_api.register_adapter(adapter.INTERFACE)
    interiors.sweep()
    subscribe()
end

script.on_init(configure)
script.on_configuration_changed(configure)
script.on_load(subscribe)
