DC_Colony = DC_Colony or {}
DC_Colony.Resources = DC_Colony.Resources or {}
DC_Colony.Resources.Internal = DC_Colony.Resources.Internal or {}

local Resources = DC_Colony.Resources
local Internal = Resources.Internal

function Resources.EnsureOwner(ownerUsername)
    local shardKey = Internal.GetShardKey(ownerUsername)
    local ownerData = Internal.EnsureModDataTable(shardKey, Internal.BuildEmptyOwnerData(ownerUsername))
    return Internal.NormalizeOwnerData(ownerUsername, ownerData)
end

function Resources.TouchVersion(ownerUsername)
    local ownerData = Resources.EnsureOwner(ownerUsername)
    ownerData.version = ownerData.version + 1
    return ownerData.version
end

function Resources.Save(ownerUsername)
    if ownerUsername then
        Resources.TouchVersion(ownerUsername)
    end

    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

function Resources.GetCropCatalog()
    local list = {}
    for _, crop in pairs(Resources.CROP_CATALOG or {}) do
        list[#list + 1] = Internal.CopyTable(crop)
    end
    table.sort(list, function(a, b)
        return tostring(a.displayName or a.cropID or "") < tostring(b.displayName or b.cropID or "")
    end)
    return list
end

function Resources.GetCropForSeedType(seedFullType)
    local cropID = Internal.BuildSeedLookup()[tostring(seedFullType or "")]
    if not cropID then
        return nil
    end
    return Resources.CROP_CATALOG[cropID]
end