DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

local Internal = DC_SupplyWindow.Internal

function Internal.populateCompanionWorkerEntries(window, targetEntries, worker, activeTab)
    local startedAt = Internal.getPerfNowMs and Internal.getPerfNowMs() or nil
    local entries = targetEntries or {}
    local config = Internal.Config or {}
    local normalizedJob = config.NormalizeJobType and config.NormalizeJobType(worker and worker.jobType) or tostring(worker and worker.jobType or "")

    if activeTab == Internal.Tabs.Equipment then
        local ledger = worker and worker.toolLedger or {}
        local realEquipmentSignatures = {}
        for _, ledgerEntry in ipairs(ledger) do
            if ledgerEntry and ledgerEntry.pending ~= true then
                realEquipmentSignatures[Internal.getEquipmentPendingDedupeSignature(ledgerEntry)] = true
            end
        end
        for index, ledgerEntry in ipairs(ledger) do
            local skipPendingDuplicate = ledgerEntry
                and ledgerEntry.pending == true
                and realEquipmentSignatures[Internal.getEquipmentPendingDedupeSignature(ledgerEntry)] == true
            local entry = not skipPendingDuplicate and Internal.buildWorkerToolEntry(ledgerEntry, index) or nil
            if entry then
                entries[#entries + 1] = entry
            end
        end

        for _, placeholderEntry in ipairs(Internal.getMissingEquipmentPlaceholderEntries(worker)) do
            entries[#entries + 1] = placeholderEntry
        end
    elseif activeTab == Internal.Tabs.Output then
        local ledger = nil
        if normalizedJob == ((config.JobTypes or {}).Scavenge) then
            ledger = worker and worker.haulLedger or {}
        else
            ledger = worker and worker.outputLedger or {}
        end
        for index, ledgerEntry in ipairs(ledger) do
            local entry = Internal.buildWorkerOutputEntry(ledgerEntry, index)
            if entry then
                entries[#entries + 1] = entry
            end
        end
    else
        local moneyEntry = Internal.buildWorkerMoneyEntry(worker)
        if moneyEntry then
            entries[#entries + 1] = moneyEntry
        end
        local ledger = worker and worker.nutritionLedger or {}
        for index, ledgerEntry in ipairs(ledger) do
            local entry = Internal.buildWorkerSupplyEntry(ledgerEntry, index)
            if entry then
                entries[#entries + 1] = entry
            end
        end
    end

    if Internal.debugPerf then
        Internal.debugPerf("CompanionEntriesPopulate", startedAt, 5, {
            token = window and window.debugOpenToken or "nil",
            activeTab = activeTab,
            count = #entries,
            workerID = worker and worker.workerID or "nil",
        })
    end
    return entries
end

