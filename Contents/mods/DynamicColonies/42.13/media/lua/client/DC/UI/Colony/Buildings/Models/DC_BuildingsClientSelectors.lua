DC_BuildingsClientSelectors = DC_BuildingsClientSelectors or {}

local function getColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

function DC_BuildingsClientSelectors.FindPlot(snapshot, plotKey)
    for _, plot in ipairs(snapshot and snapshot.map and snapshot.map.plots or {}) do
        if tostring(plot.key or "") == tostring(plotKey or "") then
            return plot
        end
    end
    return nil
end

function DC_BuildingsClientSelectors.GetDefaultPlotKey(snapshot)
    local centerKey = "0:0"
    if DC_BuildingsClientSelectors.FindPlot(snapshot, centerKey) then
        return centerKey
    end
    local firstPlot = snapshot and snapshot.map and snapshot.map.plots and snapshot.map.plots[1] or nil
    return firstPlot and firstPlot.key or nil
end

function DC_BuildingsClientSelectors.GetBuilderConstructionLevel(builder)
    local level = tonumber(builder and builder.jobSkillLevel)
    if level == nil and type(builder and builder.skills) == "table" and type(builder.skills.Construction) == "table" then
        level = tonumber(builder.skills.Construction.level)
    end
    return math.max(0, math.floor(level or 0))
end

local function getBuilderAvailability(worker, options)
    options = type(options) == "table" and options or {}
    local allowedProjectID = tostring(options.allowedProjectID or "")
    local assignedProjectID = tostring(worker and worker.assignedProjectID or "")
    local assignedProjectMaterialState = tostring(worker and worker.assignedProjectMaterialState or "")

    if assignedProjectID == "" then
        return "Available"
    end
    if allowedProjectID ~= "" and assignedProjectID == allowedProjectID then
        return "Assigned"
    end
    if assignedProjectMaterialState == "Stalled" then
        return "Available"
    end

    return "Busy"
end

function DC_BuildingsClientSelectors.GetBuilderOptions()
    local options = {}
    local workers = DC_MainWindow and DC_MainWindow.cachedWorkers or {}
    local labourConfig = getColonyConfig()
    local deadState = tostring(labourConfig.States and labourConfig.States.Dead or "Dead")
    local builderJobType = tostring(labourConfig.JobTypes and labourConfig.JobTypes.Builder or "Builder")

    for _, worker in ipairs(workers or {}) do
        local normalizedJob = labourConfig.NormalizeJobType and labourConfig.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
        if tostring(worker.state or "") ~= deadState and normalizedJob == builderJobType then
            options[#options + 1] = worker
        end
    end

    table.sort(options, function(a, b)
        local aReady = tostring(a and a.toolState or "") == "Ready" and 1 or 0
        local bReady = tostring(b and b.toolState or "") == "Ready" and 1 or 0
        if aReady ~= bReady then
            return aReady > bReady
        end

        local aLevel = DC_BuildingsClientSelectors.GetBuilderConstructionLevel(a)
        local bLevel = DC_BuildingsClientSelectors.GetBuilderConstructionLevel(b)
        if aLevel ~= bLevel then
            return aLevel > bLevel
        end

        return tostring(a.name or a.workerID or "") < tostring(b.name or b.workerID or "")
    end)
    return options
end

function DC_BuildingsClientSelectors.BuildBuilderLabel(worker, options)
    options = type(options) == "table" and options or {}
    local label = tostring(worker.name or worker.workerID or "Builder")
    label = label .. " | Const Lv " .. tostring(DC_BuildingsClientSelectors.GetBuilderConstructionLevel(worker))
    label = label .. " | Tool: " .. tostring(worker.toolState or "Missing")
    label = label .. " | " .. getBuilderAvailability(worker, options)
    if worker.housingState then
        label = label .. " | " .. tostring(worker.housingState)
    end
    return label
end

function DC_BuildingsClientSelectors.GetBuilderRequirementState(builder, options)
    options = type(options) == "table" and options or {}
    local allowedProjectID = tostring(options.allowedProjectID or "")
    if not builder then
        return {
            ready = false,
            reason = "Assign a Builder first."
        }
    end
    local availability = getBuilderAvailability(builder, options)
    if availability == "Busy" then
        return {
            ready = false,
            reason = tostring(builder.name or builder.workerID or "That builder")
                .. " is already assigned to "
                .. tostring(builder.assignedProjectBuildingType or "another project")
                .. " L"
                .. tostring(builder.assignedProjectTargetLevel or 1)
                .. "."
        }
    end
    if DC_BuildingsClientSelectors.GetBuilderConstructionLevel(builder) <= 0 then
        return {
            ready = false,
            reason = "That worker has no Construction skill."
        }
    end
    if tostring(builder.toolState or "") ~= "Ready" then
        return {
            ready = false,
            reason = "That builder is missing the required hammer and saw."
        }
    end
    return {
        ready = true,
        reason = nil
    }
end

return DC_BuildingsClientSelectors
