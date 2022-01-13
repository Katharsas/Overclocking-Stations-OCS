print("OCS")
-- print(serpent.block(data.raw.item["beacon"]))
-- print(serpent.block(data.raw.beacon["beacon"]))

ocs_effectivity = 0.5

data:extend(
{
  -- OCS receipe (and inventory?) item
  {
    type = "item",
    name = "ocs",
    icon = "__base__/graphics/icons/beacon.png",
    icon_size = 64,
    icon_mipmaps = 4,
    subgroup = "module",
    order = "a[beacon]-2",
    place_result = "ocs",
    stack_size = 10
  },

  -- OCS building
  util.merge{
    data.raw.beacon.beacon,
    {
      name = "ocs",
      minable = {result = "ocs"},
      max_health = 300,
      supply_area_distance = 1,
      distribution_effectivity = ocs_effectivity,
      module_specification = { module_slots = 2 },
    }
  },

  -- Invisivle helper beacon that is spawned for every crafting machine connected to a OCS building
  -- util.merge
  {
    -- data.raw.beacon.beacon,
    -- {
      type = "beacon",
      name = "ocs-helper",
      -- minable = nil, -- todo does this set minable to default?
      -- selection_box =  {{0, 0}, {0, 0}} -- default (unselectable)
      flags = { "not-repairable", "not-on-map", "not-blueprintable", "not-deconstructable", "hidden", "hide-alt-info", "no-automated-item-removal", "no-automated-item-insertion", "no-copy-paste", "not-in-kill-statistics" },
      energy_usage = "1W", -- apparently setting it to 0 is not allowed for beacons
      energy_source =
      {
        type = "void"
      },
      supply_area_distance = 1,
      distribution_effectivity = ocs_effectivity,
      module_specification = { module_slots = 12 },
      allowed_effects = {"consumption", "speed", "pollution"},
      base_picture =
      {
        filename = "__base__/graphics/entity/beacon/beacon-bottom.png",
        width = 40,
        height = 40,
        shift = { 0, 0 }
      },
    -- }
  },

  -- OCS Crafting recipe
  {
    type = "recipe",
    name = "ocs",
    enabled = false,
    energy_required = 30,
    ingredients =
    {

      {"electronic-circuit", 20},
      {"advanced-circuit", 20},
      -- {"processing-unit", 20},
      {"steel-plate", 10},
      {"copper-cable", 10},
    },
    result = "ocs"
  },

 -- OCS Technology
 {
    type = "technology",
    name = "effect-transfer",
    icon = "__base__/graphics/technology/effect-transmission.png",
    icon_size = 256,
    icon_mipmaps = 4,
    effects =
    {
      {
        type = "unlock-recipe",
        recipe = "ocs"
      }
    },
    prerequisites =
    {
      "advanced-electronics-2",
      "production-science-pack"
    },
    unit =
    {
      count = 100,
      ingredients =
      {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"chemical-science-pack", 1},
        {"production-science-pack", 1},
      },
      time = 30
    },
    order = "i-i-2"
  },

    -- {
  --   type = "beacon",
  --   name = "ocs",
  --   icon = "__base__/graphics/icons/beacon.png",
  --   icon_size = 32,
  --   flags = {"placeable-player", "player-creation"},
  --   minable = {mining_time = 1, result = "ocs"},
  --   max_health = 300,
  --   corpse = "big-remnants",
  --   dying_explosion = "medium-explosion",
  --   collision_box = {{-1.2, -1.2}, {1.2, 1.2}},
  --   selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
  --   allowed_effects = {"consumption", "speed", "pollution"},
  --   base_picture =
  --   {
  --     filename = "__base__/graphics/entity/beacon/beacon-base.png",
  --     width = 116,
  --     height = 93,
  --     shift = { 0.34, 0.06}
  --   },
  --   animation =
  --   {
  --     filename = "__base__/graphics/entity/beacon/beacon-antenna.png",
  --     width = 54,
  --     height = 50,
  --     line_length = 8,
  --     frame_count = 32,
  --     shift = { -0.03, -1.72},
  --     animation_speed = 0.5
  --   },
  --   animation_shadow =
  --   {
  --     filename = "__base__/graphics/entity/beacon/beacon-antenna-shadow.png",
  --     width = 63,
  --     height = 49,
  --     line_length = 8,
  --     frame_count = 32,
  --     shift = { 3.12, 0.5},
  --     animation_speed = 0.5
  --   },
  --   radius_visualisation_picture =
  --   {
  --     filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
  --     width = 10,
  --     height = 10
  --   },
  --   supply_area_distance = 6,
  --   energy_source =
  --   {
  --     type = "electric",
  --     usage_priority = "secondary-input"
  --   },
  --   energy_usage = "480kW",
  --   distribution_effectivity = 0.75,
  --   module_specification =
  --   {
  --     module_slots = 4,
  --     module_info_icon_shift = {0, 0.5},
  --     module_info_multi_row_initial_height_modifier = -0.3
  --   }
  -- },

}
)


