

-- on_tick
-- on_built_entity
-- on_entity_destroyed
-- on_post_entity_died
-- on_player_mined_entity

-- https://forums.factorio.com/viewtopic.php?p=559560#p559560
-- https://github.com/benjaminjackman/factorio-mods/blob/master/rso-mod_1.5.0/control.lua

local util = require("util")

-- use types defined in data-updates instead (maybe move to config or rename util to shared.lua)
local filter = {
    {
        filter="crafting-machine"
    }
}

local force_neutral
local surface

local OCS_SHORT_SIDE = 1
local OCS_WIDE_SIDE = 1

-- #################################################################
-- Functions
-- #################################################################

local function find_adjacent_ocs(entity)
    local ocs_potential_area = {x=OCS_WIDE_SIDE, y=OCS_WIDE_SIDE}
    local entity_area = entity.selection_box
    local top_left = util.sub(entity_area.left_top, ocs_potential_area)
    local bot_right = util.add(entity_area.right_bottom, ocs_potential_area)

    local adjacent_ocs_candidates = surface.find_entities_filtered({
        area={top_left, bot_right},
        name="ocs"
    })
    local adjacent_ocs = {}
    for i, ocs in ipairs(adjacent_ocs_candidates) do
        local x = ocs.position.x
        local y = ocs.position.y
        local is_adjacent_hori = entity_area.left_top.x < x and x < entity_area.right_bottom.x
        local is_adjacent_vert = entity_area.left_top.y < y and y < entity_area.right_bottom.y
        if is_adjacent_hori or is_adjacent_vert then
            table.insert(adjacent_ocs, ocs)
        end
    end
    return adjacent_ocs
end


-- sync helper inventory with connected OCS inentories
-- TODO make sure helper modules do not count in player production statistics and cannot be removed by bots
local function update_helper_modules(helper)
    local helper_inventory = helper.get_module_inventory()
    helper_inventory.clear()

    local connected_ocs = global.helpers[helper.unit_number].connected_ocs

    for ocs, _ in pairs(connected_ocs) do
        local ocs_inventory = ocs.get_module_inventory()
        for k = 1, ocs_inventory.get_item_count(), 1 do
            local module = ocs_inventory[k]
            helper_inventory.insert(module)
        end
    end
end


local function on_crafting_machine_built(entity)
    -- find adjacent ocs
    local adjacent_ocs = find_adjacent_ocs(entity)

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

        -- connect helper to ocs
        for _, ocs in ipairs(adjacent_ocs) do
            global.helpers[helper.unit_number].connected_ocs[ocs] = true
            if not global.ocss[ocs.unit_number] then
                global.ocss[ocs.unit_number] = {}
            end
            global.ocss[ocs.unit_number][helper] = true
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
        for ocs, _ in pairs(connected_ocs) do
            global.ocss[ocs.unit_number][helper] = nil
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
        for helper, _ in pairs(helpers) do
            print("MACHINE AFFECTED BY MODULE CHANGE!")
            update_helper_modules(helper)
        end
    end
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

            machines[742] = 743
        ]]--
        global.machines = {}

        --[[
            Helper beacons that each control module effects of one machine, synchronized to any OCS connected to that machine.
            Needed when:
            Example:

            helpers[743] = {
                machine = 742
                connected_ocs = { 354, 456 }
            }
        ]]--
        global.helpers = {}

        --[[
            Overclocking stations that only affect machines sitting adjacent to them by affecting that machines personal helper beacon.
            Needed when:
            Example:

            ocss[354] = { 743, 745 }
        ]]--
        global.ocss = {}

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
  end
)

-- Changes to placement of affected machine 

script.on_event(defines.events.on_built_entity,
  function(event)
    -- global.machines = {}
    -- global.helpers = {}
    -- global.ocss = {}
    on_crafting_machine_built(event.created_entity)
  end,
  filter
)

script.on_event(defines.events.on_player_mined_entity,
  function(event)
    on_crafting_machine_removed(event.entity)
  end,
  filter
)

-- Changes to placement of OCSs
-- TODO

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



