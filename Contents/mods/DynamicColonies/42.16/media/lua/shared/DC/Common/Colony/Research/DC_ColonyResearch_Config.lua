DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}

local Research = DC_Colony.Research
local ColonyConfig = DC_Colony and DC_Colony.Config or nil

Research.Config = Research.Config or {
    BaseHours = 8,
    BaseWork = 1000,
    BaseWorkPerHour = 125,
    IntelligenceWorkSpeedPerLevel = 0.05,
    MaxQueueSize = 24,
}

function Research.Config.GetBaseWork()
    local configured = ColonyConfig and ColonyConfig.GetSandboxNumberAny
        and ColonyConfig.GetSandboxNumberAny({ "ColonyResearchWorkAmount" }, nil) or nil
    if configured ~= nil then
        return math.max(1, math.floor(tonumber(configured) or 0))
    end
    return math.max(1, math.floor(tonumber(Research.Config.BaseWork) or 1000))
end

function Research.Config.GetBaseWorkPerHour()
    return math.max(1, tonumber(Research.Config.BaseWorkPerHour) or 125)
end

function Research.Config.GetIntelligenceWorkMultiplier(level)
    local safeLevel = math.max(0, math.min(20, math.floor(tonumber(level) or 0)))
    local perLevel = math.max(0, tonumber(Research.Config.IntelligenceWorkSpeedPerLevel) or 0.05)
    return 1 + (safeLevel * perLevel)
end

function Research.Config.GetSampleMultiplier(sampleCount)
    return math.max(1, math.floor(tonumber(sampleCount) or 1))
end

function Research.Config.GetMaxQueueSize()
    return math.max(1, math.floor(tonumber(Research.Config.MaxQueueSize) or 1))
end

return Research
