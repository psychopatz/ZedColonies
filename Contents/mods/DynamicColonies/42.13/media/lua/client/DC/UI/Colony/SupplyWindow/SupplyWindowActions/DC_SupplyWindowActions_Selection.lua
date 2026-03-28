DC_SupplyWindow = DC_SupplyWindow or {}
DC_SupplyWindow.Internal = DC_SupplyWindow.Internal or {}

function DC_SupplyWindow.onPlayerListMouseDown(target, item)
    if not target or not item then
        return
    end

    local entry = item.item or item
    target.selectedPlayerEntry = entry
    target.activeSelectionSide = "player"
    target:updateItemDetail(entry, "player")
end

function DC_SupplyWindow.onWorkerListMouseDown(target, item)
    if not target or not item then
        return
    end

    local entry = item.item or item
    target.selectedWorkerEntry = entry
    target.activeSelectionSide = "worker"
    target:updateItemDetail(entry, "worker")

    if target.openEquipmentPickerForEntry and target:openEquipmentPickerForEntry(entry) then
        return
    end
end
