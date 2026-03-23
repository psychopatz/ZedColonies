DT_Labour = DT_Labour or {}
DT_Labour.Registry = DT_Labour.Registry or {}
DT_Labour.Registry.Internal = DT_Labour.Registry.Internal or {}

local Config = DT_Labour.Config
local Registry = DT_Labour.Registry

function Registry.Init()
    if not ModData.exists(Config.MOD_DATA_KEY) then
        ModData.add(Config.MOD_DATA_KEY, {
            Workers = {},
            Owners = {},
            Warehouses = {},
            Sites = {},
            Counters = { worker = 0, site = 0 }
        })
    end

    local data = ModData.get(Config.MOD_DATA_KEY)
    data.Workers = data.Workers or {}
    data.Owners = data.Owners or {}
    data.Warehouses = data.Warehouses or {}
    data.Sites = data.Sites or {}
    data.Counters = data.Counters or { worker = 0, site = 0 }
end

Events.OnInitGlobalModData.Add(Registry.Init)

function Registry.GetData()
    if not ModData.exists(Config.MOD_DATA_KEY) then
        Registry.Init()
    end
    return ModData.get(Config.MOD_DATA_KEY)
end

function Registry.Save()
    if GlobalModData and GlobalModData.save then
        GlobalModData.save()
    end
end

function Registry.NextID(kind)
    local data = Registry.GetData()
    local key = kind == "site" and "site" or "worker"
    data.Counters[key] = (data.Counters[key] or 0) + 1
    return data.Counters[key]
end

function Registry.EnsureOwner(ownerUsername)
    local owner = Config.GetOwnerUsername(ownerUsername)
    local data = Registry.GetData()
    if not data.Owners[owner] then
        data.Owners[owner] = { workerIDs = {}, recruitAttempts = {} }
    end
    data.Owners[owner].workerIDs = data.Owners[owner].workerIDs or {}
    data.Owners[owner].recruitAttempts = data.Owners[owner].recruitAttempts or {}
    return data.Owners[owner]
end

return Registry
