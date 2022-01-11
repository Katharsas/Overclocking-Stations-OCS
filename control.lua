

-- on_tick
-- on_built_entity
-- on_entity_destroyed
-- on_post_entity_died
-- on_player_mined_entity

-- https://forums.factorio.com/viewtopic.php?p=559560#p559560

filter = {
    {
        filter="crafting-machine"
    }
}

script.on_event(defines.events.on_built_entity,
  function(event)
    local player = game.get_player(event.player_index)
    local created_entity = event.created_entity
    local created_entity_number = created_entity.unit_number
    local pos = created_entity.position

    -- test spawning helper beacon
    local helper_pos = {pos.x + 0, pos.y + 0}
    print("OCS: Helper position: " .. serpent.line(helper_pos))
    local surface = game.surfaces["nauvis"]
    surface.create_entity{ name = "ocs-helper", position = helper_pos, force = "neutral" } -- TODO we should get and reuse a single reference to the neutral(?) force instead of using string

    print("OCS: Crafting machine was built")
    print(created_entity_number)
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

