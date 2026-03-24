require "DC/UI/Colony/Buildings/Utils/DC_BuildingsUIUtils"

DC_BuildingsDetailsFormatter = DC_BuildingsDetailsFormatter or {}

function DC_BuildingsDetailsFormatter.BuildPlotText(plot)
    if not plot then
        return " <RGB:0.65,0.65,0.65>Select a plot to inspect it. "
    end

    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> Plot " .. tostring(plot.x or 0) .. "," .. tostring(plot.y or 0) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Type: <RGB:1,1,1> " .. tostring(plot.kind or "Standard") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> State: <RGB:1,1,1> " .. tostring(plot.state or "Unknown") .. " <LINE> "
    if plot.territory then
        text = text .. " <RGB:0.72,0.72,0.72> Barricades: <RGB:1,1,1> "
            .. tostring(plot.territory.activeBarricadeCount or 0)
            .. " / "
            .. tostring(plot.territory.maxActiveBarricades or 0)
            .. " <LINE> "
    end

    if plot.project then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Active Project <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Project: <RGB:1,1,1> " .. tostring(plot.project.displayName or plot.project.buildingType or "Project") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Mode: <RGB:1,1,1> " .. tostring(plot.project.mode or "build") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Material State: <RGB:1,1,1> " .. tostring(plot.project.materialState or "Ready") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Builder: <RGB:1,1,1> " .. tostring(plot.project.assignedBuilderName or "Unassigned") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Progress: <RGB:1,1,1> "
            .. tostring(math.floor((tonumber(plot.project.progressWorkPoints) or 0) + 0.5))
            .. " / "
            .. tostring(plot.project.requiredWorkPoints or 0)
            .. " WP <LINE> "
        text = text .. " <RGB:0.82,0.82,0.82> Use Manage to supply materials or assign another Builder without losing progress. <LINE> "
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Project Materials <LINE> "
        for _, line in ipairs(DC_BuildingsUIUtils.BuildRecipeLines(plot.project.materialEntries or {})) do
            text = text .. " " .. line .. " <LINE> "
        end
        if tostring(plot.project.materialState or "") == "Stalled" then
            text = text .. " <RGB:0.92,0.84,0.45> This project is stalled. Use inventory materials or wait for warehouse stock to refill it automatically. <LINE> "
        end
    end

    if plot.building then
        local building = plot.building
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> " .. tostring(building.displayName or building.buildingType or "Building") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Level: <RGB:1,1,1> " .. tostring(building.level or 0) .. " <LINE> "

        if building.buildingType == "Headquarters" and plot.territory then
            text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Unsafe Zone Control <LINE> "
            text = text .. " <RGB:0.72,0.72,0.72> Active Barricades: <RGB:1,1,1> "
                .. tostring(plot.territory.activeBarricadeCount or 0)
                .. " / "
                .. tostring(plot.territory.maxActiveBarricades or 0)
                .. " <LINE> "
            text = text .. " <RGB:0.72,0.72,0.72> Unlocked Plots: <RGB:1,1,1> " .. tostring(plot.territory.unlockedPlotCount or 0) .. " <LINE> "
        elseif building.buildingType == "Barricade" then
            text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Unsafe Zone Control <LINE> "
            text = text .. " <RGB:0.72,0.72,0.72> Role: <RGB:1,1,1> Claims and secures one unsafe zone tile. <LINE> "
            if building.barricadeHP then
                text = text .. " <RGB:0.72,0.72,0.72> HP Placeholder: <RGB:1,1,1> " .. tostring(building.barricadeHP) .. " <LINE> "
            end
        end

        if building.buildingType == "Warehouse" then
            local installs = building.installs or {}
            local rackCount = tonumber(installs.rack) or 0
            local boxCount = tonumber(installs.storage_boxes) or 0
            text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Storage <LINE> "
            text = text .. " <RGB:0.72,0.72,0.72> Contribution: <RGB:1,1,1> +" .. tostring(building.warehouseCapacityContribution or 0) .. " capacity <LINE> "
            text = text .. " <RGB:0.72,0.72,0.72> Racks: <RGB:1,1,1> " .. tostring(rackCount) .. " / 10 <LINE> "
            text = text .. " <RGB:0.72,0.72,0.72> Storage Boxes: <RGB:1,1,1> " .. tostring(boxCount) .. " / 10 <LINE> "
            if tonumber(building.level or 0) < 2 then
                text = text .. " <RGB:0.82,0.74,0.58> Upgrade this Warehouse to level 2 to unlock Storage Boxes. <LINE> "
            end

            text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Installations <LINE> "
            local installOptions = building.installOptions or {}
            if #installOptions <= 0 then
                text = text .. " <RGB:0.62,0.62,0.62> No installations available for this building. <LINE> "
            else
                for _, option in ipairs(installOptions) do
                    local statusText = option.enabled == true and "Ready to install" or tostring(option.disabledReason or "Unavailable")
                    text = text .. " <RGB:0.82,0.82,0.82> - " .. tostring(option.displayName or option.installKey or "Install")
                        .. ": "
                        .. tostring(option.currentCount or 0)
                        .. " / "
                        .. tostring(option.maxCount or 0)
                        .. " | +"
                        .. tostring(option.capacityGain or 0)
                        .. " each <LINE> "
                    text = text .. " <RGB:0.72,0.72,0.72>   " .. statusText .. " <LINE> "
                end
            end
        end

        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Occupants <LINE> "
        local occupants = building.occupants or {}
        if #occupants <= 0 then
            text = text .. " <RGB:0.62,0.62,0.62> No occupants assigned. <LINE> "
        else
            for _, occupant in ipairs(occupants) do
                text = text .. " <RGB:0.82,0.82,0.82> - " .. tostring(occupant.name or occupant.workerID or "Worker") .. " <LINE> "
            end
        end

        local upgradePreview = building.upgradePreview
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Upgrade <LINE> "
        if not upgradePreview or upgradePreview.available ~= true then
            text = text .. " <RGB:0.9,0.65,0.65> " .. tostring(upgradePreview and upgradePreview.reason or "No upgrade available.") .. " <LINE> "
        else
            text = text .. " <RGB:0.72,0.72,0.72> Target Level: <RGB:1,1,1> " .. tostring(upgradePreview.targetLevel or 0) .. " <LINE> "
            for _, line in ipairs(DC_BuildingsUIUtils.BuildRecipeLines(upgradePreview.recipeAvailability and upgradePreview.recipeAvailability.entries or {})) do
                text = text .. " " .. line .. " <LINE> "
            end
        end

        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Destroy <LINE> "
        if building.canDestroy == true then
            text = text .. " <RGB:0.88,0.72,0.72> This building can be destroyed after confirmation. <LINE> "
        else
            text = text .. " <RGB:0.72,0.62,0.62> " .. tostring(building.destroyReason or "This building cannot be destroyed.") .. " <LINE> "
        end
    elseif plot.state == "Empty" then
        text = text .. " <LINE> <RGB:0.82,0.82,0.82> This plot is available for construction. <LINE> "
    elseif plot.state == "Locked" then
        if plot.frontierCandidate == true and plot.buildOptions and plot.buildOptions[1] then
            text = text .. " <LINE> <RGB:0.88,0.82,0.72> This unsafe zone tile can be claimed by building a Barricade. <LINE> "
            for _, line in ipairs(DC_BuildingsUIUtils.BuildRecipeLines(plot.buildOptions[1].preview and plot.buildOptions[1].preview.recipeAvailability and plot.buildOptions[1].preview.recipeAvailability.entries or {})) do
                text = text .. " " .. line .. " <LINE> "
            end
        else
            text = text .. " <LINE> <RGB:0.72,0.62,0.62> Expand outward from adjacent unlocked plots to reveal new unsafe zone tiles. <LINE> "
        end
    end

    return text
end

return DC_BuildingsDetailsFormatter
