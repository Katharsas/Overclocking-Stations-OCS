-- Generate helper ocs for all crafting station sizes

local util = require("util")
local config = require("config")

local function ocs_helper_template()
    -- Invisible helper beacon that is spawned for every crafting machine connected to a OCS building
    return {
        type = "beacon",
        name = "ocs-helper",
        localized_name = "Machine overclocking effect",
        icon = "__ocs__/graphics/icon-constant-combinator.png",
        icon_size = 64, icon_mipmaps = 4,
        flags = { "placeable-off-grid", "not-repairable", "not-on-map", "not-blueprintable", "not-deconstructable", "hidden", "hide-alt-info", "no-automated-item-removal", "no-automated-item-insertion", "no-copy-paste", "not-in-kill-statistics" },
        selectable_in_game = false,
        -- Just make sure that module effect is throttled when energy drops below 100%, not meant for balance.
        -- Not sure if this makes sense because if the machine does not have power, beacon will have no effect anyway.
        -- Maybe not having power requirements on this entity and only using ElectricEnergyInterface would be better.
        -- Note:
        -- Beacons have rediculous energy buffers (8.4 times usage?). Since machines always request enough energy to
        -- fill their buffer fully, this means that beacons will receive an extremely disproportionate amount of left-over
        -- energy when satisfaction is not 100%, so testing low energy conditions is basically impossible with beacons.
        -- In addition, charge rate seems to be instant (maybe constant based on Vanilla beacons?). See:
        -- https://forums.factorio.com/viewtopic.php?f=18&t=93276&p=528446&hilit=beacon+energy+bar#p528446
        energy_source =
        {
          type = "electric",
          usage_priority = "secondary-input",
          render_no_power_icon = false,
          render_no_network_icon = false
        },
        -- energy_source =
        -- {
        -- type = "void"
        -- },
        energy_usage = "1W",
        supply_area_distance = 1,
        distribution_effectivity = config.ocs_effectivity,
        module_specification = { module_slots = config.ocs_module_cap },
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
    }
end


local affected_building_types = {
    ["assembling-machine"] = true,
    ["mining-drill"] = true,
    ["rocket-silo"] = true,
    ["furnace"] = true,
    ["lab"] = true,
}

local entity_sizes = {}

for _, entities in pairs(data.raw) do
	for name, data in pairs(entities) do
        if affected_building_types[data.type] then
            local size = util.serialize_area_box(data.collision_box)
            entity_sizes[size] = data.collision_box
            -- print("    affected by OCS: " .. name .. "  " .. size)
            -- print("      collision_box: " .. serpent.line(data.collision_box))
        end
	end
end

local sizes_count = 0
for size, collision_box in pairs(entity_sizes) do
    -- print("    OCS helper size: " .. size)
    local helper = ocs_helper_template();
    helper.collision_box = collision_box
    helper.name = helper.name .. "-" .. size
    helper.localised_name = "Machine overclocking effect"
	data:extend({helper})

    sizes_count = sizes_count + 1
end
print("    " .. sizes_count .. " OCS helper sizes created!")

-- TODO remove eventually
local template = ocs_helper_template();
template.collision_box = {{-1.5, -1.5}, {1.5, 1.5}}
data:extend({template})