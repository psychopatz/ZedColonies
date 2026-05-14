DC_BuildingsRealBaseUI = DC_BuildingsRealBaseUI or {}

local UI = DC_BuildingsRealBaseUI

local function getCommandModule()
    return ((DC_Colony and DC_Colony.Config and DC_Colony.Config.COMMAND_MODULE) or "DColony")
end

local function handlePrompt(args)
    if not args or not args.buildingID then
        return
    end

    DC_BuildingNameModal.Open({
        title = "Name Building",
        promptText = "Choose a world-area label for this new building.",
        defaultValue = tostring(args.defaultValue or ""),
        buildingID = tostring(args.buildingID or ""),
        onConfirm = function(name, buildingID)
            UI.SendCommand("SetBuildingCustomName", {
                buildingID = buildingID,
                customName = name
            })
        end
    })
end

local function handleCustomNameSync(args)
    if DC_BuildingNameModal.instance
        and tostring(DC_BuildingNameModal.instance.buildingID or "") == tostring(args and args.buildingID or "") then
        DC_BuildingNameModal.instance:close()
    end
end

if not UI.EventsAdded then
    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= getCommandModule() then
            return
        end
        if command == "PromptBuildingName" then
            handlePrompt(args)
            return
        end
        if command == "SyncBuildingCustomName" then
            handleCustomNameSync(args)
        end
    end)
    UI.EventsAdded = true
end

return UI
