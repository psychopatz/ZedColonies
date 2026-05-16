local Internal = DC_ResearchStationModalInternal

function DC_ResearchStationModal:getProgressSource()
    if self.selectedQueue then
        return self.selectedQueue
    end

    local snapshot = self.snapshot or DC_ResearchStationModal.cachedSnapshot or {}
    return snapshot and snapshot.queue and snapshot.queue[1] or nil
end

function DC_ResearchStationModal:updateDetailText()
    if not self.detailText then
        return
    end

    local snapshot = self.snapshot or DC_ResearchStationModal.cachedSnapshot or {}
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> Research Station <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Queue: <RGB:1,1,1> " .. tostring(snapshot.queueCount or 0) .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Unlocked Blueprints: <RGB:1,1,1> " .. tostring(snapshot.unlockedCount or 0) .. " <LINE> "

    if self.selectedCandidate then
        local blueprint = self.selectedCandidate.blueprint or {}
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Selected Specimen <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Item: <RGB:1,1,1> " .. tostring(self.selectedCandidate.displayName or self.selectedCandidate.fullType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Category: <RGB:1,1,1> " .. tostring(self.selectedCandidate.category or "") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> In Inventory: <RGB:1,1,1> " .. tostring(self.selectedCandidate.count or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Station: <RGB:1,1,1> " .. tostring(blueprint.buildingDisplayName or blueprint.buildingType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Recipe: <RGB:1,1,1> " .. tostring(blueprint.recipeName or "Unknown Recipe") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Research Work: <RGB:1,1,1> " .. tostring(math.floor((tonumber(blueprint.workCost) or 0) + 0.5)) .. " WP <LINE> "
        if #(blueprint.inputs or {}) > 0 then
            text = text .. " <RGB:0.72,0.72,0.72> Recipe Inputs: <LINE> "
            for _, input in ipairs(blueprint.inputs or {}) do
                text = text .. " <RGB:0.82,0.82,0.82> - " .. Internal.FormatInputEntry(input) .. " <LINE> "
            end
        end
        text = text .. " <RGB:0.82,0.82,0.82> Submit more samples of the same item to multiply research speed. Colony Intelligence also accelerates the work rate. <LINE> "
    elseif self.selectedQueue then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Active Queue Entry <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Item: <RGB:1,1,1> " .. tostring(self.selectedQueue.displayName or self.selectedQueue.fullType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Station: <RGB:1,1,1> " .. tostring(self.selectedQueue.buildingDisplayName or self.selectedQueue.buildingType or "Unknown") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Recipe: <RGB:1,1,1> " .. tostring(self.selectedQueue.recipeName or "Unknown Recipe") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Progress: <RGB:1,1,1> "
            .. tostring(math.floor((tonumber(self.selectedQueue.progressWork) or 0) + 0.5))
            .. " / "
            .. tostring(math.floor((tonumber(self.selectedQueue.requiredWork) or 0) + 0.5))
            .. " WP <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Samples: <RGB:1,1,1> " .. tostring(self.selectedQueue.sampleCount or 1) .. "x <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Work Rate: <RGB:1,1,1> " .. tostring(math.floor((tonumber(self.selectedQueue.workPerHour) or 0) + 0.5)) .. " WP / hour <LINE> "
        if tostring(self.selectedQueue.leadResearcherName or "") ~= "" then
            text = text .. " <RGB:0.72,0.72,0.72> Lead Researcher: <RGB:1,1,1> "
                .. tostring(self.selectedQueue.leadResearcherName)
                .. " (Int "
                .. tostring(self.selectedQueue.leadResearcherLevel or 0)
                .. ") <LINE> "
        end
        if #(self.selectedQueue.inputs or {}) > 0 then
            text = text .. " <RGB:0.72,0.72,0.72> Recipe Inputs: <LINE> "
            for _, input in ipairs(self.selectedQueue.inputs or {}) do
                text = text .. " <RGB:0.82,0.82,0.82> - " .. Internal.FormatInputEntry(input) .. " <LINE> "
            end
        end
    end

    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Unlocked Blueprint Preview <LINE> "
    if #(snapshot.blueprints or {}) <= 0 then
        text = text .. " <RGB:0.62,0.62,0.62> No blueprints unlocked yet. <LINE> "
    else
        for index = 1, math.min(12, #(snapshot.blueprints or {})) do
            local blueprint = snapshot.blueprints[index]
            text = text .. " <RGB:0.82,0.82,0.82> - "
                .. tostring(blueprint.displayName or blueprint.fullType or "Blueprint")
                .. " <RGB:0.72,0.72,0.72>("
                .. tostring(blueprint.buildingDisplayName or blueprint.buildingType or "Workshop")
                .. ") <LINE> "
        end
    end

    self.detailText:setText(text)
    self.detailText:paginate()
end
