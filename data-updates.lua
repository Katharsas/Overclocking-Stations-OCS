-- Generate helper ocs for all crafting station sizes

local util = require("util")


local function ocsHelperTemplate()
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
    }
end


local affectedBuildingTypes = {
    ["assembling-machine"] = true,
    ["mining-drill"] = true,
    ["rocket-silo"] = true,
    ["furnace"] = true,
    ["lab"] = true,
}

entitySizes = {}

for _, entities in pairs(data.raw) do
	for name, data in pairs(entities) do
        if affectedBuildingTypes[data.type] then
            local size = util.serializeBoundingBox(data.selection_box)
            entitySizes[size] = data.selection_box
            -- print("    affected by OCS: " .. name .. "  " .. size)
        end
	end
end

local sizesCount = 0
for size, selection_box in pairs(entitySizes) do
    -- print("    OCS helper size: " .. size)
    local helper = ocsHelperTemplate();
    helper.selection_box = selection_box
    helper.name = helper.name .. "-" .. size
	data:extend({helper})

    sizesCount = sizesCount + 1
end
print("    " .. sizesCount .. " OCS helper sizes created!")

-- TODO remove eventually
local template = ocsHelperTemplate();
template.selection_box = {{-1.5, -1.5}, {1.5, 1.5}}
data:extend({template})