DT_Labour = DT_Labour or {}
DT_Labour.Interaction = DT_Labour.Interaction or {}

local Config = DT_Labour.Config
local Interaction = DT_Labour.Interaction

function Interaction.BuildOutcomeMessage(worker, jobKey, outcomeKey, tokens)
    local scopedKey = tostring(jobKey or "") .. "." .. tostring(outcomeKey or "")
    local template = Interaction.getInteractionEntry("Outcome", scopedKey)
    if not template then
        template = Interaction.getInteractionEntry("Outcome", "Common." .. tostring(outcomeKey or ""))
    end
    if not template then
        return nil
    end

    return DynamicTrading.FormatInteractionString(template, tokens or {})
end

function Interaction.BuildReturnReasonMessage(reason)
    local normalizedReason = tostring(reason or "")
    local reasons = Config.ReturnReasons or {}
    if normalizedReason == tostring(reasons.FullHaul or "FullHaul") then
        return tostring(Interaction.getInteractionEntry("Outcome", "Common.ReturnReasons.FullHaul") or "Pack is full, heading home.")
    end
    if normalizedReason == tostring(reasons.LowTiredness or "LowTiredness") then
        return tostring(Interaction.getInteractionEntry("Outcome", "Common.ReturnReasons.LowTiredness") or "Too tired to keep going, heading home.")
    end
    if normalizedReason == tostring(reasons.LowFood or "LowFood") then
        return tostring(Interaction.getInteractionEntry("Outcome", "Common.ReturnReasons.LowFood") or "Running low on food, heading home.")
    end
    if normalizedReason == tostring(reasons.LowDrink or "LowDrink") then
        return tostring(Interaction.getInteractionEntry("Outcome", "Common.ReturnReasons.LowDrink") or "Running low on water, heading home.")
    end
    if normalizedReason == tostring(reasons.MissingTool or "MissingTool") then
        return tostring(Interaction.getInteractionEntry("Outcome", "Common.ReturnReasons.MissingTool") or "Missing the right tool, heading home.")
    end
    if normalizedReason == tostring(reasons.MissingSite or "MissingSite") then
        return tostring(Interaction.getInteractionEntry("Outcome", "Common.ReturnReasons.MissingSite") or "Lost the work site, heading home.")
    end
    return tostring(Interaction.getInteractionEntry("Outcome", "Common.ReturnReasons.Manual") or "Heading home on command.")
end

return DT_Labour.Interaction
