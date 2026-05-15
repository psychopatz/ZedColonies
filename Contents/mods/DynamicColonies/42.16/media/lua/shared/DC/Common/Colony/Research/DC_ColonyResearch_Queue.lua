DC_Colony = DC_Colony or {}
DC_Colony.Research = DC_Colony.Research or {}
DC_Colony.Research.Internal = DC_Colony.Research.Internal or {}

local Research = DC_Colony.Research
local Internal = Research.Internal
local AbstractInventory = DC_Colony.AbstractInventory

local function canResearchConvertedItem(converted)
    local group = tostring(converted and converted.group or "")
    local category = tostring(converted and converted.category or "")
    if converted == nil or converted.isFallback == true then
        return false
    end
    if group == "Research" or group == "Trade" then
        return false
    end
    if group == "Waste" or category == "Junk" or category == "QuestGoods" or category == "ContaminatedMaterial" then
        return false
    end
    if category == "ResearchData" or category == "Blueprints" or category == "Currency" then
        return false
    end
    return true
end

function Research.SubmitResearchItem(ownerUsername, fullType, itemMeta)
    local normalizedFullType = tostring(fullType or "")
    if normalizedFullType == "" then
        return false, "Missing item fullType."
    end
    if Research.IsBlueprintUnlocked(ownerUsername, normalizedFullType) then
        return false, "Blueprint already unlocked."
    end

    local data = Internal.EnsureOwnerData(ownerUsername)
    if #data.queue >= math.max(1, math.floor(tonumber(Research.Config and Research.Config.MaxQueueSize) or 1)) then
        return false, "Research queue is full."
    end

    local converted = DC_Colony and DC_Colony.Config and DC_Colony.Config.GetItemCategoryData
        and DC_Colony.Config.GetItemCategoryData(normalizedFullType) or nil
    if not canResearchConvertedItem(converted) then
        return false, "That item cannot be reverse engineered yet."
    end

    local jobID = Internal.NextJobID(ownerUsername)
    if itemMeta == nil or itemMeta.storeSpecimen ~= false then
        local added = AbstractInventory and AbstractInventory.AddLiteralSpecial and AbstractInventory.AddLiteralSpecial(ownerUsername, {
            fullType = normalizedFullType,
            qty = 1,
            forceLiteral = true,
            literalSpecial = true,
            specialStockType = "research_specimen",
            researchJobID = jobID,
        }) or 0
        if added <= 0 then
            return false, "No storage space for the research specimen."
        end
    end

    data.queue[#data.queue + 1] = {
        jobID = jobID,
        fullType = normalizedFullType,
        submittedAt = itemMeta and itemMeta.submittedAt or 0,
        progressHours = 0,
        requiredHours = math.max(1, math.floor(tonumber(Research.Config and Research.Config.BaseHours) or 8)),
        category = converted.category,
        group = converted.group,
    }
    Internal.Touch(ownerUsername)
    return true, nil
end

return Research
