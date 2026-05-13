DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegWorkerState or {}

function Data.applyGathererPresentation(worker)
    local gatherer = DC_Colony and DC_Colony.Gatherer or nil
    local flavorText = Registry.ColonyRegWorkerStateFlavorText or {}
    if gatherer and gatherer.GetLoadout then
        local loadout = gatherer.GetLoadout(worker)
        local selectedResources = {}
        for _, def in ipairs(gatherer.GetSelectedResourceList and gatherer.GetSelectedResourceList(worker) or {}) do
            selectedResources[#selectedResources + 1] = tostring(def.label or def.id)
        end

        worker.gathererLoadout = loadout
        worker.gathererHasAxe = loadout.hasAxe == true
        worker.gathererHasPickaxe = loadout.hasPickaxe == true
        worker.gathererHasSack = loadout.hasSack == true
        worker.gathererWaterContainerCount = math.max(0, tonumber(loadout.waterContainerCount) or 0)
        worker.gathererWaterCapacity = math.max(0, tonumber(loadout.waterCapacity) or 0)
        worker.gathererWaterFreeCapacity = math.max(0, tonumber(loadout.waterFreeCapacity) or 0)
        worker.gathererWaterStorageCapacity = math.max(0, tonumber(loadout.waterStorageCapacity) or 0)
        worker.gathererWaterStorageStored = math.max(0, tonumber(loadout.waterStorageStored) or 0)
        worker.gathererWaterStorageAvailable = math.max(0, tonumber(loadout.waterStorageAvailable) or 0)
        worker.gathererWaterCollectableCapacity = math.max(0, tonumber(loadout.waterCollectableCapacity) or 0)
        worker.gathererSelectedResourceCount = #selectedResources
        worker.gathererResourceSummary = #selectedResources > 0 and table.concat(selectedResources, ", ") or tostring(flavorText.gathererNothing or "Nothing")
        worker.gathererRunnableResourceCount = #(loadout.runnableResourceIDs or {})
    else
        worker.gathererLoadout = nil
        worker.gathererHasAxe = nil
        worker.gathererHasPickaxe = nil
        worker.gathererHasSack = nil
        worker.gathererWaterContainerCount = nil
        worker.gathererWaterCapacity = nil
        worker.gathererWaterFreeCapacity = nil
        worker.gathererWaterStorageCapacity = nil
        worker.gathererWaterStorageStored = nil
        worker.gathererWaterStorageAvailable = nil
        worker.gathererWaterCollectableCapacity = nil
        worker.gathererSelectedResourceCount = nil
        worker.gathererResourceSummary = nil
        worker.gathererRunnableResourceCount = nil
    end
end

return Data