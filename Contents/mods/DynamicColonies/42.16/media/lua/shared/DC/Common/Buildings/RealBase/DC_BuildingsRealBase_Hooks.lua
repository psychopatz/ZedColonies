DC_Buildings = DC_Buildings or {}
DC_Buildings.RealBase = DC_Buildings.RealBase or {}

local Buildings = DC_Buildings
local RealBase = Buildings.RealBase

local function normalizeOwner(ownerUsername)
    local config = DC_Colony and DC_Colony.Config or nil
    if config and config.GetOwnerUsername then
        return config.GetOwnerUsername(ownerUsername)
    end
    return tostring(ownerUsername or "local")
end

local function buildFactionRenamePrompt(ownerUsername)
    if not DynamicTrading_Factions or not DynamicTrading_Factions.GetOwnedFactionStatus then
        return nil
    end

    local status = DynamicTrading_Factions.GetOwnedFactionStatus(ownerUsername)
    if not (status and status.faction and status.needsNamingPrompt == true) then
        return nil
    end

    return {
        defaultValue = tostring(status.faction.name or ""),
        status = status,
    }
end

function RealBase.OnProjectCompleted(project, instance)
    if not project or not instance or tostring(project.mode or "") == "install" then
        return nil
    end

    local owner = normalizeOwner(project.ownerUsername)
    local result = {
        shouldPromptName = false,
        defaultName = nil
    }

    if tostring(instance.buildingType or "") == "Headquarters" then
        if DC_ZoneRealBase and DC_ZoneRealBase.EnsureSystemZonesForOwner then
            DC_ZoneRealBase.EnsureSystemZonesForOwner(owner)
        elseif DC_ZoneRealBase and DC_ZoneRealBase.EnsureBaseZoneForOwner then
            DC_ZoneRealBase.EnsureBaseZoneForOwner(owner)
        end

        local ensureDetails = nil
        if DynamicTrading_Factions and DynamicTrading_Factions.EnsurePlayerFaction then
            local _, _, _, details = DynamicTrading_Factions.EnsurePlayerFaction(owner, {
                source = "headquarters_completed"
            })
            ensureDetails = details
        end

        if DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.RefreshOwnerWorkers then
            DC_Colony.ResidentBridge.RefreshOwnerWorkers(owner)
        end
        result.sendFactionStatus = true
        if ensureDetails and ensureDetails.created == true and ensureDetails.needsNamingPrompt == true then
            result.promptOwnedFactionRename = buildFactionRenamePrompt(owner)
        end
        return result
    end

    if not (DC_ZoneRealBase and DC_ZoneRealBase.ShouldCreateBuildingSlot and DC_ZoneRealBase.ShouldCreateBuildingSlot(instance.buildingType)) then
        return result
    end

    result.defaultName = RealBase.InitializeInstanceName(owner, instance)
    if DC_ZoneRealBase and DC_ZoneRealBase.CreateBuildingSlotForInstance then
        DC_ZoneRealBase.CreateBuildingSlotForInstance(owner, instance)
    end
    result.shouldPromptName = RealBase.ShouldManageNamedInstance(instance.buildingType)
    if DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.RefreshOwnerWorkers then
        DC_Colony.ResidentBridge.RefreshOwnerWorkers(owner)
    end
    return result
end

function RealBase.OnBuildingDestroyed(ownerUsername, building)
    if not building then
        return
    end

    if DC_ZoneRealBase and DC_ZoneRealBase.RemoveBuildingSlot then
        DC_ZoneRealBase.RemoveBuildingSlot(ownerUsername, building.buildingID)
    end
    if DC_Colony and DC_Colony.ResidentBridge and DC_Colony.ResidentBridge.RefreshOwnerWorkers then
        DC_Colony.ResidentBridge.RefreshOwnerWorkers(ownerUsername)
    end
end

function RealBase.CanDestroyBuilding(ownerUsername, building)
    if not building or tostring(building.buildingType or "") ~= "Barricade" then
        return true, nil
    end

    if DC_ZoneRealBase and DC_ZoneRealBase.CanDestroyBarricade then
        return DC_ZoneRealBase.CanDestroyBarricade(ownerUsername, {})
    end

    return true, nil
end

return RealBase
