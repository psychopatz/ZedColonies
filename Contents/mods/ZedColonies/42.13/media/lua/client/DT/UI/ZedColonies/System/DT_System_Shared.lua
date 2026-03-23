DT_System = DT_System or DT_LabourUI or {}
DT_System.Internal = DT_System.Internal or {}

local System = DT_System
local Internal = System.Internal

DT_LabourUI = System
System.recruitResultCache = System.recruitResultCache or {}

Internal.Config = Internal.Config or ((DT_Labour and DT_Labour.Config) or {})

function Internal.GetConfig()
    Internal.Config = (DT_Labour and DT_Labour.Config) or Internal.Config or {}
    return Internal.Config
end

function Internal.GetCommandModule()
    local config = Internal.GetConfig()
    if type(config) == "table" and config.COMMAND_MODULE and config.COMMAND_MODULE ~= "" then
        return config.COMMAND_MODULE
    end
    return "DynamicTrading_V2"
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
