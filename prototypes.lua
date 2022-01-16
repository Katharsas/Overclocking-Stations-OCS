print("OCS")
-- print(serpent.block(data.raw.item["beacon"]))
-- print(serpent.block(data.raw["beacon"]["beacon"]))
-- print(serpent.block(data.raw["constant-combinator"]["constant-combinator"]))

ocs_effectivity = 0.333 -- module effect multiplier for modules from OCS
ocs_module_slots = 1 -- module slots per OCS
ocs_module_cap = 12 -- max number of modules that can affect a single machine
ocs_tech_sp_cost = 500 -- number of science packs required to research OCS

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
  {
    name = "ocs",
    type = "beacon",
    minable = {result = "ocs"},
    max_health = 300,
    minable = {
      mining_time = 0.2,
      result = "ocs"
    },
    -- Right now, power is irrelevant for this building, beacuse ocs_helper is doing all the module effects anyway.
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
    distribution_effectivity = ocs_effectivity,
    module_specification = {
      module_info_icon_shift = {0, 0},
      module_info_max_icons_per_row = 2,
      module_info_multi_row_initial_height_modifier = 0,
      module_slots = ocs_module_slots
    },
    allowed_effects = {"consumption", "speed", "pollution"},
    collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
    selection_box = {{-0.5, -0.5}, {0.5, 0.5}},

    icon = "__ocs__/graphics/icon-constant-combinator.png",
    icon_size = 64, icon_mipmaps = 4,
    base_picture =
    {
      filename = "__ocs__/graphics/constant-combinator.png",
      width = 58,
      height = 52,
      shift = { 0, 0 }
    },
    hr_version = {
      filename = "__ocs__/graphics/hr-constant-combinator.png",
      width = 114,
      height = 102,
      scale = 0.5,
      shift = { 0, 0 },
    },
    corpse = "decider-combinator-remnants",
    dying_explosion = "decider-combinator-explosion",
  },

  -- Invisible helper beacon that is spawned for every crafting machine connected to a OCS building
  {
    type = "beacon",
    name = "ocs-helper",
    icon = "__ocs__/graphics/icon-constant-combinator.png",
    icon_size = 64, icon_mipmaps = 4,
    flags = { "placeable-off-grid", "not-repairable", "not-on-map", "not-blueprintable", "not-deconstructable", "hidden", "hide-alt-info", "no-automated-item-removal", "no-automated-item-insertion", "no-copy-paste", "not-in-kill-statistics" },
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}}, -- TODO generate versions for all crafting machine sizes, maybe make slightly smaller to never be selectable
    selection_priority = 0, -- unselectable if placed under machine
    -- Just make sure that module effect is throttled when energy drops below 100%, not meant for balance.
    -- TODO
    -- This does not make any sense. If the machine does not have power, beacon will have no effect anyway.
    -- Just remove any power requirements from OCS or OCS helper and leave all of that mess behind. Or use another
    -- helper object based on ElectricEnergyInterface
    -- Note:
    -- Beacons have rediculous energy buffers (8.4 times usage?). Since machines always request enough energy to
    -- fill their buffer fully, this means that beacons will receive an extremely disproportionate amount of left-over
    -- energy when satisfaction is not 100%, so testing low energy conditions is basically impossible with beacons.
    -- In addition, charge rate seems to be instant (maybe constant based on Vanilla beacons?). See:
    -- https://forums.factorio.com/viewtopic.php?f=18&t=93276&p=528446&hilit=beacon+energy+bar#p528446
    -- energy_source =
    -- {
    --   type = "electric",
    --   usage_priority = "secondary-input",
    --   render_no_power_icon = false,
    --   render_no_network_icon = false
    -- },
    -- energy_usage = "1W",
    energy_source =
    {
      type = "void"
    },
    energy_usage = "1W",
    supply_area_distance = 1,
    distribution_effectivity = ocs_effectivity,
    module_specification = { module_slots = ocs_module_cap },
    allowed_effects = {"consumption", "speed", "pollution"},
    base_picture =
    {
      filename = "__ocs__/graphics/constant-combinator.png",
      width = 58,
      height = 52,
      shift = { 0, 0 }
    },
    hr_version = {
      filename = "__ocs__/graphics/hr-constant-combinator.png",
      width = 114,
      height = 102,
      scale = 0.5,
      shift = { 0, 0 },
    },
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
      count = ocs_tech_sp_cost,
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


