DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

function DT_SupplyWindow.onPlayerListMouseDown(target, item)
    if not target or not item then
        return
    end

    local entry = item.item or item
    target.selectedPlayerEntry = entry
    target.activeSelectionSide = "player"
    target:updateItemDetail(entry, "player")
end

function DT_SupplyWindow.onWorkerListMouseDown(target, item)
    if not target or not item then
        return
    end

    local entry = item.item or item
    target.selectedWorkerEntry = entry
    target.activeSelectionSide = "worker"
    target:updateItemDetail(entry, "worker")
end
