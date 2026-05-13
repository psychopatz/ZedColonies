DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}

local EventSync = DC_MainWindow.Internal.Events or {}

function EventSync.mergeWorkerSummaryWithDetail(summary, detail)
    if type(summary) ~= "table" then
        return summary
    end
    if type(detail) ~= "table" then
        return summary
    end

    local merged = EventSync.copyTable(summary) or {}
    if detail.skills ~= nil then
        merged.skills = detail.skills
    end
    if detail.skillModelVersion ~= nil then
        merged.skillModelVersion = detail.skillModelVersion
    end
    if detail.primarySkillID ~= nil then
        merged.primarySkillID = detail.primarySkillID
    end
    if detail.jobSkillID ~= nil then
        merged.jobSkillID = detail.jobSkillID
    end
    if detail.jobSkillLabel ~= nil then
        merged.jobSkillLabel = detail.jobSkillLabel
    end
    if detail.jobSkillLevel ~= nil then
        merged.jobSkillLevel = detail.jobSkillLevel
    end
    if detail.jobSkillSpeedMultiplier ~= nil then
        merged.jobSkillSpeedMultiplier = detail.jobSkillSpeedMultiplier
    end
    return merged
end

function EventSync.syncCachedWorkerSummaryFromDetails(workerID)
    if not workerID or type(DC_MainWindow.cachedWorkers) ~= "table" then
        return
    end

    local detail = DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[workerID] or nil
    if type(detail) ~= "table" then
        return
    end

    for index, worker in ipairs(DC_MainWindow.cachedWorkers) do
        if worker and worker.workerID == workerID then
            DC_MainWindow.cachedWorkers[index] = EventSync.mergeWorkerSummaryWithDetail(worker, detail)
            return
        end
    end
end

function EventSync.hydrateWorkerSummariesFromDetails(workers)
    if type(workers) ~= "table" then
        return workers
    end

    for index, worker in ipairs(workers) do
        local workerID = worker and worker.workerID or nil
        local detail = workerID and DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[workerID] or nil
        if type(detail) == "table" then
            workers[index] = EventSync.mergeWorkerSummaryWithDetail(worker, detail)
        end
    end

    return workers
end

function EventSync.replaceCachedWorkerSummary(summary)
    if type(summary) ~= "table" or not summary.workerID then
        return
    end

    summary = EventSync.mergeWorkerSummaryWithDetail(summary, DC_MainWindow.cachedDetails and DC_MainWindow.cachedDetails[summary.workerID] or nil)
    DC_MainWindow.cachedWorkers = DC_MainWindow.cachedWorkers or {}
    for index, worker in ipairs(DC_MainWindow.cachedWorkers) do
        if worker and worker.workerID == summary.workerID then
            DC_MainWindow.cachedWorkers[index] = summary
            return
        end
    end

    DC_MainWindow.cachedWorkers[#DC_MainWindow.cachedWorkers + 1] = summary
end

return EventSync