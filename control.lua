

-- on_tick
-- on_built_entity
-- on_entity_destroyed
-- on_post_entity_died
-- on_player_mined_entity

-- https://forums.factorio.com/viewtopic.php?p=559560#p559560
-- https://github.com/benjaminjackman/factorio-mods/blob/master/rso-mod_1.5.0/control.lua

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

local function add(pos1, pos2)
    return {x=(pos1.x + pos2.x), y=(pos1.y + pos2.y)}
end
local function sub(pos1, pos2)
    return {x=(pos1.x - pos2.x), y=(pos1.y - pos2.y)}
end


local function find_adjacent_ocs(entity)
    local ocs_potential_area = {x=OCS_WIDE_SIDE, y=OCS_WIDE_SIDE}
    local entity_area = entity.selection_box
    local top_left = sub(entity_area.left_top, ocs_potential_area)
    local bot_right = add(entity_area.right_bottom, ocs_potential_area)

    local adjacent_ocs_candidates = surface.find_entities_filtered({
        area={top_left, bot_right},
        name="ocs"
    })
    local adjacent_ocs = {}
    for i, ocs in ipairs(adjacent_ocs_candidates) do
        local x = ocs.position.x
        local y = ocs.position.y
        local isAdjacentHori = entity_area.left_top.x < x and x < entity_area.right_bottom.x
        local isAdjacentVert = entity_area.left_top.y < y and y < entity_area.right_bottom.y
        if isAdjacentHori or isAdjacentVert then
            table.insert(adjacent_ocs, ocs)
        end
    end
    return adjacent_ocs
end


local function on_crafting_machine_built(entity)

    -- find adjacent ocs
    local adjacent_ocs = find_adjacent_ocs(entity)

    if #adjacent_ocs > 0 then
        
        -- local unit_number = entity.unit_number
        local pos = entity.position
    
        -- spawn helper beacon
        local helper_pos = {pos.x + 0, pos.y + 0}
        -- print("OCS: Helper position: " .. serpent.line(helper_pos))
        local helper = surface.create_entity{
            name = "ocs-helper",
            position = helper_pos,
            force = force_neutral
        }
        global.machines[entity.unit_number] = helper

        -- copy modules from all ocs into helper
        -- TODO make sure those modules to not count in player production statistics and cannot be removed by bots
        local helper_inventory = helper.get_module_inventory()
        for j, ocs in ipairs(adjacent_ocs) do
            local ocs_inventory = ocs.get_module_inventory()
            for k = 1, ocs_inventory.get_item_count(), 1 do
                local module = ocs_inventory[k]
                helper_inventory.insert(module)
            end
        end
    end
end


local function on_crafting_machine_removed(entity)

    local helper = global.machines[entity.unit_number]
    if helper then
        helper.destroy()
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
    end
)  

script.on_load(
  function()
    force_neutral = global.force_neutral
    surface = global.surface
  end
)

script.on_event(defines.events.on_built_entity,
  function(event)
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



