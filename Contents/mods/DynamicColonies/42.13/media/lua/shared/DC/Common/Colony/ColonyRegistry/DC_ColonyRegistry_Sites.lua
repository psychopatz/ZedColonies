DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry

function Registry.UpsertSite(site)
    local owner = Config.GetOwnerUsername(site and site.ownerUsername)
    if owner == "" and site and site.workerID then
        owner = Registry.GetWorkerOwner(site.workerID)
    end
    owner = Config.GetOwnerUsername(owner)
    local colonyID = Registry.GetColonyIDForOwner(owner, true)
    local colonyData = Registry.GetColonyData(colonyID, true)
    local sitesData = Registry.GetSitesData(colonyID, true)

    if not site.siteID then
        site.siteID = Registry.NextID("site", colonyID)
    end

    site.ownerUsername = owner
    site.colonyID = colonyID
    sitesData.sites[site.siteID] = site
    Registry.Internal.Runtime.siteToColonyID[site.siteID] = colonyID
    colonyData.versions.colony = colonyData.versions.colony + 1
    Registry.TouchSitesVersion(colonyID)
    return site
end

function Registry.GetSite(siteID)
    local colonyID = Registry.GetSiteColonyID(siteID)
    if not colonyID then
        return nil
    end

    local sitesData = Registry.GetSitesData(colonyID, false)
    return siteID and sitesData and sitesData.sites[siteID] or nil
end

function Registry.AssignSiteToWorker(worker, site)
    if not worker or not site then return end
    Registry.UpsertSite(site)
    worker.assignedSiteID = site.siteID
    worker.workX = site.x
    worker.workY = site.y
    worker.workZ = site.z or 0
    worker.radius = site.radius or Config.DEFAULT_SITE_RADIUS
    worker.siteType = site.siteType
end

function Registry.ClearWorkerSite(worker)
    if not worker then return end
    worker.assignedSiteID = nil
    worker.workX = nil
    worker.workY = nil
    worker.workZ = nil
    worker.siteState = "Deferred"
    worker.scavengeSiteProfileID = nil
    worker.scavengeSiteProfileLabel = nil
    worker.scavengeSiteRoomName = nil
    worker.scavengeSiteZoneType = nil
end

return Registry
