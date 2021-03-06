

-- https://forums.factorio.com/viewtopic.php?p=559560#p559560
-- https://github.com/benjaminjackman/factorio-mods/blob/master/rso-mod_1.5.0/control.lua

local util = require("util")

-- TODO share types with data-updates.lua
local machine_types = {
    "assembling-machine",
    "mining-drill",
    "rocket-silo",
    "furnace",
    "lab"
}

local entity_event_filter = {
    {filter="name", name="ocs"}
}
for _, type in ipairs(machine_types) do
    local filter = {filter="type", type=type}
    table.insert(entity_event_filter, filter)
end

local force_neutral
local surface


-- #################################################################
-- Functions
-- #################################################################


-- type_filter and name_fiter are optional
local function find_adjacent_entities(entity, type_filter, name_filter)
    -- create area that collides with any entity that touches the given entity (including diagonally)
    local collision_radius = {x=1, y=1}
    local entity_area = entity.selection_box
    local top_left = util.sub(entity_area.left_top, collision_radius)
    local bot_right = util.add(entity_area.right_bottom, collision_radius)

    local find_entities_args = {
        area={top_left, bot_right}
    }
    if type_filter then
        find_entities_args.type = type_filter
    end
    if name_filter then
        find_entities_args.name = name_filter
    end
    local adjacent_candidates = surface.find_entities_filtered(find_entities_args)

    -- filter out entities that only diagonally touch at a single corner point
    -- TODO this algorithm only works for square entites, implement different algo that checks for 
    -- overlapping selection_boxes in at least one dimension for each comparison
    local adjacent = {}
    for i, candidate in ipairs(adjacent_candidates) do
        -- local x = ocs.position.x
        -- local y = ocs.position.y
        -- local is_adjacent_hori = entity_area.left_top.x < x and x < entity_area.right_bottom.x
        -- local is_adjacent_vert = entity_area.left_top.y < y and y < entity_area.right_bottom.y
        local pos_relative = util.sub(entity.position, candidate.position)
        if math.abs(pos_relative.x) ~= math.abs(pos_relative.y) then
            table.insert(adjacent, candidate)
        end
    end
    return adjacent
end


-- sync helper inventory with connected OCS inventories, does not update connection data
-- returns number of currently connected OCS
-- TODO make sure helper modules do not count in player production statistics and cannot be removed by bots
local function update_helper_modules(helper)
    local helper_inventory = helper.get_module_inventory()
    helper_inventory.clear()

    local connected_ocs = global.helpers[helper.unit_number].connected_ocs
    local connected_ocs_count = 0

    for _, ocs in pairs(connected_ocs) do
        local ocs_inventory = ocs.get_module_inventory()
        for k = 1, ocs_inventory.get_item_count(), 1 do
            local module = ocs_inventory[k]
            helper_inventory.insert(module)
        end
        connected_ocs_count = connected_ocs_count + 1
    end
    return connected_ocs_count
end


local function connect_helper_to_ocs(helper, ocs)
    global.helpers[helper.unit_number].connected_ocs[ocs.unit_number] = ocs
    if not global.ocss[ocs.unit_number] then
        global.ocss[ocs.unit_number] = {}
    end
    global.ocss[ocs.unit_number][helper.unit_number] = helper
end


local function on_crafting_machine_built(entity)
    -- find adjacent ocs
    local adjacent_ocs = find_adjacent_entities(entity, nil, "ocs")

    if #adjacent_ocs > 0 then
        
        -- local unit_number = entity.unit_number
        local pos = entity.position
    
        -- spawn helper beacon
        local helper_pos = {pos.x, pos.y}
        -- print("OCS: Helper position: " .. serpent.line(helper_pos))
        local prototype = game.entity_prototypes[entity.name]
        local helper = surface.create_entity{
            name = "ocs-helper-" .. util.serialize_area_box(prototype.collision_box),
            position = helper_pos,
            direction = entity.direction, -- TODO test with non-rectangular machines? btw non-square buildings cannot be rotated, so we don't need to update this
            force = force_neutral,
        }
        
        global.machines[entity.unit_number] = helper
        global.helpers[helper.unit_number] = {
            machine = entity,
            connected_ocs = {}
        }

        for _, ocs in ipairs(adjacent_ocs) do
            connect_helper_to_ocs(helper, ocs)
        end
        
        -- copy modules from all ocs into helper
        update_helper_modules(helper)
    end
end


local function on_crafting_machine_removed(entity)
    -- TODO test if cleanup works properly
    local helper = global.machines[entity.unit_number]
    if helper then
        local connected_ocs = global.helpers[helper.unit_number].connected_ocs
        for ocs_id, _ in pairs(connected_ocs) do
            -- sync ocss or remove if this machine was the only machine connected to ocs
            global.ocss[ocs_id][helper.unit_number] = nil
            if table_size(global.ocss[ocs_id]) == 0 then
                global.ocss[ocs_id] = nil
            end
        end
        global.helpers[helper.unit_number] = nil
        global.machines[entity.unit_number] = nil
        helper.destroy()
    end
end


-- can be called on potential changes as well
local function on_ocs_inventory_changed(entity)
    local helpers = global.ocss[entity.unit_number]
    if helpers then
        for _, helper in pairs(helpers) do
            update_helper_modules(helper)
        end
    end
end


local function on_ocs_built(entity)
    local adjacent_machines = find_adjacent_entities(entity, machine_types)
    for _, machine in ipairs(adjacent_machines) do
        local helper = global.machines[machine.unit_number]
        -- TODO maybe this could be done more elegantly?
        if not helper then
            on_crafting_machine_built(machine)
        else
            connect_helper_to_ocs(helper, entity)
            update_helper_modules(helper)
        end
    end
end


local function on_ocs_removed(entity)
    -- TODO test if cleanup works properly
    local helpers = global.ocss[entity.unit_number]
    -- for all machines affected by this ocs, get corresponding helper and disconnect it from this ocs
    if helpers then
        for helper_id, helper in pairs(helpers) do
            local helper_info = global.helpers[helper_id]
            helper_info.connected_ocs[entity.unit_number] = nil
            
            -- sync helper and remove it if no more connected ocs left
            local connected_ocs_count = update_helper_modules(helper)
            if connected_ocs_count == 0 then
                local machine = helper_info.machine
                global.helpers[helper.unit_number] = nil
                global.machines[machine.unit_number] = nil
                helper.destroy()
            end
        end
        global.ocss[entity.unit_number] = nil
    end
end

local function cleanup_helpers(destroy_helpers_without_state)
    local detached_count = 0
    local find_entities_args = {
        type = "beacon"
    }
    local beacons = surface.find_entities_filtered(find_entities_args)
    for i, beacon in ipairs(beacons) do
        local is_helper = util.starts_with(beacon.name, "ocs-helper")
        if is_helper then
            local helper = global.helpers[beacon.unit_number]
            if helper == nil then
                if destroy_helpers_without_state then
                    beacon.destroy()
                end
                detached_count = detached_count + 1
            end
        end
    end
    if destroy_helpers_without_state then
        print("Destroyed "..detached_count.." ocs-helper entities!")
    else
        assert(detached_count == 0, "State entries for "..detached_count.." ocs-helper entities are missing!")
    end
end

function test_global_state_integrity()

    local count_machines = table_size(global.machines)
    local count_helpers = table_size(global.helpers)
    local count_ocss = table_size(global.ocss)
    print("Affected Machines: "..count_machines)
    print("Affected OCSs: "..count_ocss)
    print("Helpers: "..count_helpers)

    assert(count_machines == count_helpers, "There must be as many crafting machines as helpers. Machines: "..count_machines..", Helpers: "..count_helpers)

    -- find distinct helpers references by ocss, and make sure all references exist
    local referenced_helpers = {}
    for ocs_id, helpers in pairs(global.ocss) do
        for helper_id, _ in pairs(helpers) do
            referenced_helpers[helper_id] = true
            assert(global.helpers[helper_id] ~= nil, "The helper "..helper_id.." referenced by OCS "..ocs_id.." is missing in helpers!")
        end
    end
    local count_helper_references = table_size(referenced_helpers)
    assert(count_helpers == count_helper_references, "There must be as many helpers as OCS helper references. Helpers: "..count_helpers..", References: "..count_helper_references)

    -- find distinct ocss referenced by helpers, and make sure all references exist
    local referenced_ocss = {}
    for helper_id, helper in pairs(global.helpers) do
        for ocs_id, _ in pairs(helper.connected_ocs) do
            referenced_ocss[ocs_id] = true
            assert(global.ocss[ocs_id] ~= nil, "The OCS "..ocs_id.." referenced by helper "..helper_id.." is missing in ocss!")
        end
    end
    local count_ocs_references = table_size(referenced_ocss)
    assert(count_ocss == count_ocs_references, "There must be as many OCSs as helper OCS references. OCSs: "..count_ocss..", References: "..count_ocs_references)

    -- TODO:
    -- all helpers have machine reference and all machines have helper reference
    -- machines: referenced helpers are valid entities
    -- helpers: referenced machines and ocss are valid entities
end


-- #################################################################
-- Event Handlers
-- #################################################################

script.on_init(
    function()
        force_neutral = game.forces["neutral"]
        surface = game.surfaces["nauvis"]

        global.force_neutral = force_neutral
        global.surface = surface

        --[[
            
            All crafting machines that are connected to at least one OCS via their personal helper beacon.
            Needed when:
                - machine is built (insert if connected to OCS)
                - machine is removed (check if helper must be cleaned up)
            Example:

            machines[742] = <LuaEntity(743)>
        ]]--
        global.machines = {}


        --[[
            Helper beacons that each control module effects of one machine, synchronized to any OCS connected to that machine.
            Needed when:
            Example:

            helpers[743] = {
                machine = <LuaEntity(742)>
                connected_ocs = {
                    354 = <LuaEntity(354)>,
                    456 = <LuaEntity(456)>
                }
            }
        ]]--
        global.helpers = {}


        --[[
            OCSs that only affect machines sitting adjacent to them by affecting that machines personal helper beacon.
            Needed when:
            Example:

            ocss[354] = {
                743 = <LuaEntity(743)>,
                745 = <LuaEntity(745)>
            }
        ]]--
        global.ocss = {}


        --[[
            OCSs might have an open module request proxy after being built (usually from blueprint that contained module configuration).
            Needed when:
                - OCS is built (if proxy at was created at same position, remember proxies event id)
                - OCS's proxy is destroyed (expect changed OCS module configuration, remove from this table)
            Example:

            ocs_module_proxies[1807] = 354
        ]]--
        global.ocs_module_proxies = {}


        --[[
            Remember OCS inventory while inside OCS GUI to better detect module changes, see event handler on_player_cursor_stack_changed
        ]]--
        global.opened_ocs = nil
        global.opened_ocs_modules = nil
    end
)  

script.on_load(
  function()
    force_neutral = global.force_neutral
    surface = global.surface

    -- global.machines = {}
    -- global.helpers = {}
    -- global.ocss = {}
  end
)


-- Changes to placement of affected machines and OCSs

local function on_ocs_created_register_proxies(ocs)
    -- we simply assume that this filter only catches modules
    local proxy_filter = {
        type = "item-request-proxy",
        position = ocs.position
    }
    for _, proxy in pairs(surface.find_entities_filtered(proxy_filter)) do
        global.ocs_module_proxies[proxy.unit_number] = ocs.unit_number
        script.register_on_entity_destroyed(proxy)
    end
end

local function on_building_created(event)
    if (event.created_entity.name == "ocs") then
        on_ocs_created_register_proxies(event.created_entity)
        on_ocs_built(event.created_entity)
    else
        on_crafting_machine_built(event.created_entity)
    end
    -- test_global_state_integrity()
end
script.on_event(defines.events.on_built_entity, on_building_created, entity_event_filter)
script.on_event(defines.events.on_robot_built_entity, on_building_created, entity_event_filter)

local function on_building_removed(event)
    if (event.entity.name == "ocs") then
        on_ocs_removed(event.entity)
    else
        on_crafting_machine_removed(event.entity)
    end
    -- test_global_state_integrity()
end
script.on_event(defines.events.on_player_mined_entity, on_building_removed, entity_event_filter)
script.on_event(defines.events.on_robot_mined_entity, on_building_removed, entity_event_filter)
script.on_event(defines.events.on_entity_died, on_building_removed, entity_event_filter)

local function on_proxy_destroyed(event)
    local proxy_id = event.unit_number
    local ocs_id = global.ocs_module_proxies[proxy_id]
    if ocs_id ~= nil then
        -- robot has delivered module to one of our OCSs
        for _, helper in pairs(global.ocss[ocs_id]) do
            update_helper_modules(helper)
        end
        global.ocs_module_proxies[proxy_id] = nil
    end
end
script.on_event(defines.events.on_entity_destroyed, on_proxy_destroyed)


-- Changes to OCS inventory

script.on_event(defines.events.on_player_fast_transferred,
  function(event)
    local entity = event.entity
    if entity.name == "ocs" then
        on_ocs_inventory_changed(entity)
    end
  end
)

-- does not trigger on instant move (ctrl/shift + left click)
script.on_event(defines.events.on_player_cursor_stack_changed,
  function(event)
    local player = game.get_player(event.player_index)
    if player.opened_gui_type == defines.gui_type.entity then
        local opened = player.opened
        local stack = player.cursor_stack
        if opened.name == "ocs" and stack ~= nil then
            if stack.valid_for_read then
                if stack.type == "module" then
                    -- module may have been moved from ocs into stack
                    on_ocs_inventory_changed(opened)
                else
                    -- otherwise something unimportant was moved into stack, remember ocs inventory for later
                    global.opened_ocs = opened
                    global.opened_ocs_modules = opened.get_module_inventory().get_item_count()
                    return -- return to not clear global
                end
            else
                -- stack was emptied
                if not opened == global.opened_ocs then
                    -- we do not know what was in ocs inventory before, so we have to assume change in ocs inventory
                    on_ocs_inventory_changed(opened)
                else
                    -- check if ocs inventory changed
                    local opened_ocs_modules_new = opened.get_module_inventory().get_item_count()
                    if global.opened_ocs_modules ~= opened_ocs_modules_new then
                        on_ocs_inventory_changed(opened)
                    end
                end
            end
        end
    end
    global.opened_ocs = nil
    global.opened_ocs_modules = nil
  end
)

-- detect instant move between inventories (ctrl/shift + left click)
script.on_event(defines.events.on_player_main_inventory_changed,
  function(event)
    local player = game.get_player(event.player_index)
    if player.opened_gui_type == defines.gui_type.entity then
        local opened = player.opened
        if opened.name == "ocs" then
            on_ocs_inventory_changed(opened)
        end
    end
  end
)



-- script.on_event(defines.events.on_entity_destroyed,
--   function(event)
--     local destroyed_entity_number = event.unit_number
--     print("OCS: Entity was destroyed!")
--     print(destroyed_entity_number)
--   end
-- )


-- script.on_event(defines.events.on_post_entity_died,
--   function(event)
--     local destroyed_entity_number = event.unit_number
--     print("OCS: Entity was destroyed!")
--     print(destroyed_entity_number)
--   end
-- )



