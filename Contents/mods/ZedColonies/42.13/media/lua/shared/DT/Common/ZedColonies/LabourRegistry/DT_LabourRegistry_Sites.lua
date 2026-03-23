DT_Labour = DT_Labour or {}
DT_Labour.Registry = DT_Labour.Registry or {}
DT_Labour.Registry.Internal = DT_Labour.Registry.Internal or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry

function Registry.UpsertSite(site)
    local data = Registry.GetData()
    if not site.siteID then
        site.siteID = "site_" .. tostring(Registry.NextID("site"))
    end
    data.Sites[site.siteID] = site
    return site
end

function Registry.GetSite(siteID)
    local data = Registry.GetData()
    return siteID and data.Sites[siteID] or nil
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
