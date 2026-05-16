local Internal = DC_ResearchStationModalInternal

local function onServerCommand(module, command, args)
    if module ~= Internal.GetCommandModule() then
        return
    end

    local modal = DC_ResearchStationModal.instance
    if not modal or not modal.getIsVisible or not modal:getIsVisible() then
        return
    end

    if command == "SyncResearchSnapshot" then
        if args and args.unchanged ~= true then
            DC_ResearchStationModal.cachedSnapshot = args.snapshot or {
                queue = {},
                blueprints = {},
                queueCount = 0,
                unlockedCount = 0,
            }
            modal.snapshotVersion = args.version or modal.snapshotVersion
            modal:rebuildCandidateList()
            modal:refreshFromSnapshot()
            modal:updateStatus("Research data synced.")
            if modal.pendingBuildingRefresh == true then
                modal.pendingBuildingRefresh = false
                if modal.onRefreshBuildings then
                    modal.onRefreshBuildings()
                end
            end
        else
            modal.snapshotVersion = args and args.version or modal.snapshotVersion
            modal:updateStatus("Research data already up to date.")
        end
    elseif command == "ColonyNotice" and args and args.message then
        modal:updateStatus(args.message)
    end
end

if not DC_ResearchStationModal.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    DC_ResearchStationModal.EventsAdded = true
end
