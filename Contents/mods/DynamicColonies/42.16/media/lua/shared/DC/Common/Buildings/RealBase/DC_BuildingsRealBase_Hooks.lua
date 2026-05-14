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
    return result
end

function RealBase.OnBuildingDestroyed(ownerUsername, building)
    if not building then
        return
    end

    if DC_ZoneRealBase and DC_ZoneRealBase.RemoveBuildingSlot then
        DC_ZoneRealBase.RemoveBuildingSlot(ownerUsername, building.buildingID)
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
