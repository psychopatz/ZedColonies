local Internal = DC_ResearchStationModalInternal

function DC_ResearchStationModal:rebuildCandidateList()
    self.candidates = Internal.BuildCandidateList()
    if not self.candidateList then
        return
    end

    self.candidateList:clear()
    for _, entry in ipairs(self.candidates or {}) do
        self.candidateList:addItem(
            tostring(entry.displayName or entry.fullType or "Item")
                .. " x"
                .. tostring(entry.count or 0)
                .. " -> "
                .. tostring(entry.blueprint and entry.blueprint.buildingDisplayName or entry.blueprint and entry.blueprint.buildingType or "Unknown"),
            entry
        )
    end

    local selectedIndex = nil
    local wantedFullType = tostring(self.selectedCandidate and self.selectedCandidate.fullType or "")
    if wantedFullType ~= "" then
        for index, entry in ipairs(self.candidates or {}) do
            if tostring(entry and entry.fullType or "") == wantedFullType then
                selectedIndex = index
                self.selectedCandidate = entry
                break
            end
        end
    end

    if selectedIndex == nil and self.candidates[1] and not self.selectedQueue then
        selectedIndex = 1
        self.selectedCandidate = self.candidates[1]
    end

    if selectedIndex then
        self.candidateList.selected = selectedIndex
    else
        self.selectedCandidate = nil
        self.candidateList.selected = -1
    end
end

function DC_ResearchStationModal:refreshQueueList()
    local snapshot = self.snapshot or DC_ResearchStationModal.cachedSnapshot or nil
    if not self.queueList then
        return
    end

    self.queueList:clear()
    for _, entry in ipairs(snapshot and snapshot.queue or {}) do
        self.queueList:addItem(Internal.FormatQueueLabel(entry), entry)
    end

    local wanted = tostring(self.selectedQueue and self.selectedQueue.jobID or "")
    if self.selectedQueue and self.queueList.items and #self.queueList.items > 0 then
        for index, row in ipairs(self.queueList.items) do
            if tostring(row and row.item and row.item.jobID or "") == wanted then
                self.queueList.selected = index
                self.selectedQueue = row.item
                return
            end
        end
    end

    if #self.queueList.items > 0 and not self.selectedCandidate then
        self.queueList.selected = 1
        self.selectedQueue = self.queueList.items[1] and self.queueList.items[1].item or nil
    else
        self.selectedQueue = nil
    end
end

function DC_ResearchStationModal:updateStatus(text)
    self.statusText = tostring(text or "")
    if self.statusButton then
        self.statusButton:setTitle(self.statusText ~= "" and self.statusText or " ")
    end
end

function DC_ResearchStationModal:refreshFromSnapshot()
    self.snapshot = DC_ResearchStationModal.cachedSnapshot or self.snapshot or {
        queue = {},
        blueprints = {},
        queueCount = 0,
        unlockedCount = 0,
    }
    self:refreshQueueList()
    self:updateDetailText()
    if self.progressPanel and self.progressPanel.repaintStencilRect then
        self.progressPanel:repaintStencilRect(0, 0, self.progressPanel.width, self.progressPanel.height)
    end
end

function DC_ResearchStationModal:requestSnapshot(forceRefresh)
    local knownVersion = forceRefresh == true and nil or (self.snapshotVersion or nil)
    if Internal.SendColonyCommand(self.ownerWindow, "RequestResearchSnapshot", {
        knownVersion = knownVersion,
    }) then
        self:updateStatus(forceRefresh == true and "Refreshing research data..." or "Requesting research data...")
    end
end

function DC_ResearchStationModal:onSubmitClicked()
    if not self.selectedCandidate then
        self:updateStatus("Select a research specimen first.")
        return
    end

    local firstRef = self.selectedCandidate.itemRefs and self.selectedCandidate.itemRefs[1] or nil
    if not firstRef or not firstRef.itemID then
        self:updateStatus("That specimen is no longer available.")
        self:rebuildCandidateList()
        self:updateDetailText()
        return
    end

    if Internal.SendColonyCommand(self.ownerWindow, "SubmitResearchSpecimen", {
        buildingID = self.buildingID,
        itemID = firstRef.itemID,
        fullType = self.selectedCandidate.fullType,
    }) then
        self.pendingBuildingRefresh = true
        self:updateStatus("Submitting " .. tostring(self.selectedCandidate.displayName or self.selectedCandidate.fullType or "item") .. " for research...")
        self:requestSnapshot(true)
    else
        self:updateStatus("Unable to submit that specimen right now.")
    end
end

function DC_ResearchStationModal:onRefreshClicked()
    self:rebuildCandidateList()
    self:requestSnapshot(true)
end
