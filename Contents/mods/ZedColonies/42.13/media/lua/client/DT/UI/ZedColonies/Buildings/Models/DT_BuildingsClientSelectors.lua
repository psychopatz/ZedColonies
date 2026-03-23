DT_BuildingsClientSelectors = DT_BuildingsClientSelectors or {}

local function getLabourConfig()
    return DT_Labour and DT_Labour.Config or {}
end

function DT_BuildingsClientSelectors.FindPlot(snapshot, plotKey)
    for _, plot in ipairs(snapshot and snapshot.map and snapshot.map.plots or {}) do
        if tostring(plot.key or "") == tostring(plotKey or "") then
            return plot
        end
    end
    return nil
end

function DT_BuildingsClientSelectors.GetDefaultPlotKey(snapshot)
    local centerKey = "0:0"
    if DT_BuildingsClientSelectors.FindPlot(snapshot, centerKey) then
        return centerKey
    end
    local firstPlot = snapshot and snapshot.map and snapshot.map.plots and snapshot.map.plots[1] or nil
    return firstPlot and firstPlot.key or nil
end

function DT_BuildingsClientSelectors.GetBuilderConstructionLevel(builder)
    local level = tonumber(builder and builder.jobSkillLevel)
    if level == nil and type(builder and builder.skills) == "table" and type(builder.skills.Construction) == "table" then
        level = tonumber(builder.skills.Construction.level)
    end
    return math.max(0, math.floor(level or 0))
end

function DT_BuildingsClientSelectors.GetBuilderOptions()
    local options = {}
    local workers = DT_MainWindow and DT_MainWindow.cachedWorkers or {}
    local labourConfig = getLabourConfig()
    local deadState = tostring(labourConfig.States and labourConfig.States.Dead or "Dead")
    local builderJobType = tostring(labourConfig.JobTypes and labourConfig.JobTypes.Builder or "Builder")

    for _, worker in ipairs(workers or {}) do
        local normalizedJob = labourConfig.NormalizeJobType and labourConfig.NormalizeJobType(worker.jobType) or tostring(worker.jobType or "")
        if tostring(worker.state or "") ~= deadState and normalizedJob == builderJobType then
            options[#options + 1] = worker
        end
    end

    table.sort(options, function(a, b)
        return tostring(a.name or a.workerID or "") < tostring(b.name or b.workerID or "")
    end)
    return options
end

function DT_BuildingsClientSelectors.BuildBuilderLabel(worker)
    local label = tostring(worker.name or worker.workerID or "Builder")
    label = label .. " | Const Lv " .. tostring(DT_BuildingsClientSelectors.GetBuilderConstructionLevel(worker))
    label = label .. " | Tool: " .. tostring(worker.toolState or "Missing")
    if worker.assignedProjectID then
        label = label .. " | Busy"
    end
    if worker.housingState then
        label = label .. " | " .. tostring(worker.housingState)
    end
    return label
end

function DT_BuildingsClientSelectors.GetBuilderRequirementState(builder)
    if not builder then
        return {
            ready = false,
            reason = "Assign a Builder first."
        }
    end
    if builder.assignedProjectID then
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
    if DT_BuildingsClientSelectors.GetBuilderConstructionLevel(builder) <= 0 then
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

return DT_BuildingsClientSelectors
