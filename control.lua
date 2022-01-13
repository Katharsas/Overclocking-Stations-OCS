

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
    local top_left = sub(entity.selection_box.left_top, ocs_potential_area)
    local bot_right = add(entity.selection_box.right_bottom, ocs_potential_area)
    
    -- print("Pos: " .. serpent.line(entity.position))
    -- print("selection_box: " .. serpent.line(entity.selection_box))
    -- print("top_left: " .. serpent.line(top_left))
    -- print("bot_right: " .. serpent.line(bot_right))
    -- surface.create_entity{
    --     name = "constant-combinator",
    --     position = top_left,
    --     force = force_neutral
    -- }
    -- surface.create_entity{
    --     name = "constant-combinator",
    --     position = sub(bot_right, {x=1,y=1}),
    --     force = force_neutral
    -- }

    print("Adjacent candidates:")
    -- TODO filter to find only ocs
    local adjacent_entity_candidates = surface.find_entities({top_left, bot_right})
    for i, entity in ipairs(adjacent_entity_candidates) do
        print(entity.name)
    end

end

local function on_crafting_machine_built(entity)

    local unit_number = entity.unit_number
    local pos = entity.position

    -- test spawning helper beacon
    local helper_pos = {pos.x + 0, pos.y + 0}
    print("OCS: Helper position: " .. serpent.line(helper_pos))
    local helper = surface.create_entity{
        name = "ocs-helper",
        position = helper_pos,
        force = force_neutral
    }

    -- TODO find out if there is an OCS station adjacent to this
    find_adjacent_ocs(entity)

    -- local helper_module = {name="speed-module-3", count=1}
    -- helper.get_module_inventory().insert(helper_module);

    -- print("OCS: Crafting machine was built")
    -- print(unit_number)
end

local function on_crafting_machine_removed(entity)
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
    local created_entity = event.entity
    local created_entity_number = created_entity.unit_number
    local player = game.get_player(event.player_index)

    print("OCS: Crafting machine was destroyed!")
    print(created_entity_number)
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



