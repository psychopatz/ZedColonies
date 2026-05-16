require "DC/UI/Colony/Buildings/Modals/DC_BuildingActionModal"
require "DC/UI/Colony/Buildings/Modals/DC_BuildingDestroyModal"
require "DC/UI/Colony/Buildings/Modals/DC_BuildingPickerModal"
require "DC/UI/Colony/Buildings/Modals/DC_BlueprintCraftModal"
require "DC/UI/Colony/Buildings/Modals/DC_RecyclerModal"
require "DC/UI/Colony/Buildings/Modals/DC_ResearchStationModal"
require "DC/UI/Colony/Buildings/Modals/BuildingProjectModal/BuildingProjectModal"
require "DC/UI/Colony/Greenhouse/DC_GreenhouseModal"

DC_BuildingsWindowActions = DC_BuildingsWindowActions or {}

local Actions = DC_BuildingsWindowActions

local function sendColonyCommand(window, command, payload)
    local ownerWindow = window and window.getOwnerWindow and window:getOwnerWindow() or nil
    if ownerWindow and ownerWindow.sendColonyCommand then
        ownerWindow:sendColonyCommand(command, payload)
        return true
    end
    return false
end

function Actions.Dispatch(actionName, window, plot)
    local handlers = {
        upgrade = Actions.OnUpgradePlot,
        install = Actions.OnInstallPlot,
        swapProjectBuilder = Actions.OnSwapProjectBuilder,
        manageGreenhouse = Actions.OnManageGreenhousePlot,
        manageResearch = Actions.OnManageResearchPlot,
        manageBlueprintCraft = Actions.OnManageBlueprintCraftPlot,
        manageRecycler = Actions.OnManageRecyclerPlot,
        destroy = Actions.OnDestroyPlot,
        debugComplete = Actions.OnDebugCompleteProject,
        plotSelected = Actions.OnPlotSelected
    }

    local handler = handlers[tostring(actionName or "")]
    if handler then
        return handler(window, plot)
    end

    return nil
end

function Actions.OpenProjectModal(window, preview, title)
    if not preview then
        return
    end

    DC_BuildingProjectModal.Open({
        title = title,
        preview = preview,
        onConfirm = function(payload)
            sendColonyCommand(window, "StartBuildingProject", payload)
        end,
        onDebugMaterials = function(payload)
            sendColonyCommand(window, "DebugGiveProjectMaterials", payload)
        end
    })
end

function Actions.OpenReassignProjectModal(window, plot)
    local project = plot and plot.project or nil
    if not project then
        return
    end

    DC_BuildingProjectModal.Open({
        title = "Manage Project",
        confirmLabel = "Save",
        requireBuilder = true,
        preview = {
            projectID = project.projectID,
            buildingType = project.buildingType,
            displayName = project.displayName,
            mode = project.mode,
            plotX = project.plotX,
            plotY = project.plotY,
            buildingID = project.buildingID,
            installKey = project.installKey,
            targetLevel = project.targetLevel,
            requiredWorkPoints = project.requiredWorkPoints,
            workPoints = project.requiredWorkPoints,
            materialEntries = project.materialEntries,
            materialState = project.materialState,
            canStart = tostring(project.materialState or "") ~= "Stalled",
            available = true,
            assignedBuilderID = project.assignedBuilderID,
            assignedBuilderName = project.assignedBuilderName
        },
        onSupply = function(payload)
            sendColonyCommand(window, "SupplyBuildingProjectFromInventory", {
                projectID = payload.projectID
            })
        end,
        onConfirm = function(payload)
            sendColonyCommand(window, "ReassignBuildingProject", {
                projectID = payload.projectID,
                workerID = payload.workerID
            })
        end,
        onDebugMaterials = function(payload)
            sendColonyCommand(window, "DebugGiveProjectMaterials", {
                projectID = payload.projectID,
                buildingType = payload.buildingType,
                mode = payload.mode,
                plotX = payload.plotX,
                plotY = payload.plotY,
                buildingID = payload.buildingID,
                installKey = payload.installKey
            })
        end
    })
end

function Actions.OpenBuildPicker(window, plot)
    DC_BuildingPickerModal.Open({
        title = "Choose Building",
        carouselHeaderText = "Browse Buildings",
        confirmLabel = "Build",
        options = plot and plot.buildOptions or {},
        onConfirm = function(option)
            Actions.OpenProjectModal(
                window,
                option.preview,
                "Build " .. tostring(option.displayName or option.buildingType or "Building")
            )
        end
    })
end

function Actions.OpenInstallPicker(window, plot)
    DC_BuildingPickerModal.Open({
        title = "Choose Installation",
        carouselHeaderText = "Browse Installations",
        confirmLabel = "Install",
        options = plot and plot.building and plot.building.installOptions or {},
        onConfirm = function(option)
            Actions.OpenProjectModal(
                window,
                option.preview,
                "Install " .. tostring(option.displayName or option.installKey or "Upgrade")
            )
        end
    })
end

function Actions.OnPlotSelected(window, plot)
    window:selectPlot(plot)
    if plot and plot.availableActions and plot.availableActions.canBuild == true then
        DC_BuildingActionModal.Open({
            plot = plot,
            onBuild = function(selectedPlot)
                Actions.OpenBuildPicker(window, selectedPlot)
            end
        })
    end
end

function Actions.OnUpgradePlot(window, plot)
    if not plot or not plot.building then
        return
    end

    Actions.OpenProjectModal(
        window,
        plot.building.upgradePreview,
        "Upgrade " .. tostring(plot.building.displayName or plot.building.buildingType or "Building")
    )
end

function Actions.OnInstallPlot(window, plot)
    if not plot or not plot.building then
        return
    end
    Actions.OpenInstallPicker(window, plot)
end

function Actions.OnSupplyProject(window, plot)
    if not plot or not plot.project then
        return
    end

    sendColonyCommand(window, "SupplyBuildingProjectFromInventory", {
        projectID = plot.project.projectID
    })
end

function Actions.OnSwapProjectBuilder(window, plot)
    if not plot or not plot.project then
        return
    end

    Actions.OpenReassignProjectModal(window, plot)
end

function Actions.OnDestroyPlot(window, plot)
    if not plot or not plot.building then
        return
    end

    DC_BuildingDestroyModal.Open({
        plot = plot,
        onConfirm = function(selectedPlot)
            if not selectedPlot or not selectedPlot.building then
                return
            end

            sendColonyCommand(window, "DestroyBuilding", {
                plotX = selectedPlot.x,
                plotY = selectedPlot.y,
                buildingID = selectedPlot.building.buildingID
            })
        end
    })
end

function Actions.OnManageGreenhousePlot(_, plot)
    local building = plot and plot.building or nil
    if not building or tostring(building.buildingType or "") ~= "Greenhouse" then
        return
    end

    DC_GreenhouseModal.Open({
        title = tostring(building.displayName or "Greenhouse") .. " Garden",
        buildingID = building.buildingID
    })
end

function Actions.OnManageResearchPlot(window, plot)
    local building = plot and plot.building or nil
    if not building or tostring(building.buildingType or "") ~= "ResearchStation" then
        return
    end

    DC_ResearchStationModal.Open({
        title = tostring(building.displayName or "Research Station") .. " Research",
        buildingID = building.buildingID,
        ownerWindow = window and window:getOwnerWindow() or nil,
        onRefreshBuildings = function()
            if window and window.requestSnapshot then
                window:requestSnapshot(false)
            end
        end
    })
end

function Actions.OnManageBlueprintCraftPlot(window, plot)
    local building = plot and plot.building or nil
    if not building then
        return
    end

    DC_BlueprintCraftModal.Open({
        title = tostring(building.displayName or building.buildingType or "Station") .. " Crafting",
        buildingID = building.buildingID,
        buildingType = tostring(building.buildingType or ""),
        ownerWindow = window and window:getOwnerWindow() or nil,
        onRefreshBuildings = function()
            if window and window.requestSnapshot then
                window:requestSnapshot(false)
            end
        end
    })
end

function Actions.OnManageRecyclerPlot(window, plot)
    local building = plot and plot.building or nil
    if not building or tostring(building.buildingType or "") ~= "Recycler" then
        return
    end

    DC_RecyclerModal.Open({
        title = tostring(building.displayName or "Recycler") .. " Recycling",
        buildingID = building.buildingID,
        ownerWindow = window and window:getOwnerWindow() or nil,
    })
end

function Actions.OnDebugCompleteProject(window, plot)
    if not plot or not plot.project then
        return
    end

    sendColonyCommand(window, "DebugCompleteBuildingProject", {
        projectID = plot.project.projectID
    })
end

return Actions
