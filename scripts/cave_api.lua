-- MTS Cave Bridge - scripts/cave_api.lua
-- Author: bits-orio
-- License: MIT
--
-- The Cave's public interface, the-cave-v1. Every call checks the function is
-- there, so an older or newer Cave degrades instead of erroring.

local cave_api = {}

local INTERFACE = "the-cave-v1"

function cave_api.has(fn)
    local cave = remote.interfaces[INTERFACE]
    return cave ~= nil and cave[fn] == true
end

--- The id of one of The Cave's custom events, or nil. Legal in on_load.
function cave_api.event_id(name)
    if not cave_api.has("get_event_id") then return nil end
    return remote.call(INTERFACE, "get_event_id", name)
end

--- Surface names The Cave created for a force (interiors, child caves).
function cave_api.owned_surfaces(force_index)
    if not cave_api.has("get_owned_surfaces") then return {} end
    return remote.call(INTERFACE, "get_owned_surfaces", force_index) or {}
end

--- Tell The Cave which interface answers its team questions. Writes The Cave's
--- storage, so never from on_load.
function cave_api.register_adapter(interface_name)
    if not cave_api.has("register_adapter") then return false end
    return remote.call(INTERFACE, "register_adapter", interface_name)
end

return cave_api
