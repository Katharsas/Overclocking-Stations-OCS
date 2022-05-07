-- print("OCS data")
-- print(serpent.block(data.raw.item["beacon"]))
-- print(serpent.block(data.raw["beacon"]["beacon"]))
-- print(serpent.block(data.raw["constant-combinator"]["constant-combinator"]))

local config = require("config")

-- TODO Balance Options:
-- Opt-In to additional power consumer helper entity for power balancing (240kw per active module)

data:extend(
{
  -- OCS receipe (and inventory?) item
  {
    type = "item",
    name = "ocs",
    icon = "__ocs__/graphics/icon-constant-combinator.png",
    icon_size = 64, icon_mipmaps = 4,
    subgroup = "module",
    order = "a[beacon]-2",
    place_result = "ocs",
    stack_size = 10
  },

  -- OCS building
  -- Does not actually affect any buildings because supply_area_distance = 0, invisible ocs-helper is used to apply
  -- effect instead (see data-updates.lua)
  {
    name = "ocs",
    type = "beacon",
    minable = {result = "ocs"},
    max_health = 300,
    minable = {
      mining_time = 0.2,
      result = "ocs"
    },
    -- Right now, power is irrelevant for this building, beacuse ocs-helper is doing all the module effects anyway.
    -- The only effect that making it draw power would have is that player gets tooltip about power usage that could
    -- be used to explain and calculate power draw of the helper building.
    -- If synchronize could be triggered on power loss / regain, this building could use power for balancing without
    -- players being able to exploit by not suppolying power to these buildings.
    energy_source =
    {
      type = "void"
    },
    energy_usage = "1W",
    supply_area_distance = 0,
    distribution_effectivity = config.ocs_effectivity,
    module_specification = {
      module_info_icon_shift = {0, 0},
      module_info_max_icons_per_row = 2,
      module_info_multi_row_initial_height_modifier = 0,
      module_slots = config.ocs_module_slots
    },
    allowed_effects = {"consumption", "speed", "pollution"},
    collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},

    icon = "__ocs__/graphics/icon-constant-combinator.png",
    icon_size = 64, icon_mipmaps = 4,
    -- Calculate image translations: https://codepen.io/jazziebgd/full/jvwmEj/
    base_picture =
    {
      filename = "__ocs__/graphics/my-beacon-b.png",
      width = 256,
      height = 256,
      scale = 0.23,
      shift = { 0, 0.1 }
    },
    -- hr_version = {
    --   filename = "__ocs__/graphics/my-beacon-b.png",
    --   width = 256,
    --   height = 256,
    --   scale = 0.23,
    --   shift = { 0, 0.1 },
    -- },
    corpse = "decider-combinator-remnants",
    dying_explosion = "decider-combinator-explosion",
  },

  -- OCS Crafting recipe
  {
    type = "recipe",
    name = "ocs",
    enabled = false,
    energy_required = 15,
    ingredients =
    {

      {"electronic-circuit", 20},
      {"advanced-circuit", 20},
      {"processing-unit", 10},
      {"steel-plate", 10},
      {"copper-cable", 20},
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
      count = config.ocs_tech_sp_cost,
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


