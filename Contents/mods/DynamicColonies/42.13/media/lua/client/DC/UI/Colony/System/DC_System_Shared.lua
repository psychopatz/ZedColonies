DC_System = DC_System or DC_ColonyUI or {}
DC_System.Internal = DC_System.Internal or {}

local System = DC_System
local Internal = System.Internal

DC_ColonyUI = System
System.recruitResultCache = System.recruitResultCache or {}

Internal.Config = Internal.Config or ((DC_Colony and DC_Colony.Config) or {})

function Internal.GetConfig()
    Internal.Config = (DC_Colony and DC_Colony.Config) or Internal.Config or {}
    return Internal.Config
end

function Internal.GetCommandModule()
    local config = Internal.GetConfig()
    if type(config) == "table" and config.COMMAND_MODULE and config.COMMAND_MODULE ~= "" then
        return config.COMMAND_MODULE
    end
    return "DColony"
end

function Internal.GetLocalPlayer()
    if getSpecificPlayer then
        return getSpecificPlayer(0)
    end
    if getPlayer then
        return getPlayer()
    end
    return nil
end
