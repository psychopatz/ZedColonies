local System = DC_System
local Internal = System.Internal

local function getConversationUI()
    if DT_ConversationUI and DT_ConversationUI.instance then
        return DT_ConversationUI.instance
    end
    if DC_ConversationUI and DC_ConversationUI.instance then
        return DC_ConversationUI.instance
    end
    return nil
end

local function isIndependentFactionID(factionID)
    return string.lower(tostring(factionID or "")) == "independent"
end

local function onServerCommand(module, command, args)
    local isFactionCommand = command == "SyncOwnedFactionStatus" or command == "OwnedFactionActionResult"
    if module ~= Internal.GetCommandModule()
        and not (isFactionCommand and module == Internal.GetFactionCommandModule()) then
        return
    end

    if command ~= "SyncRecruitAttemptResult" then
        if command == "SyncOwnedFactionStatus" then
            System.ownedFactionStatusCache = args and args.status or nil

            local ui = getConversationUI()
            if ui then
                ui:updateOptions(ui.baseOptions or {})
            end
            return
        end

        if command == "OwnedFactionActionResult" then
            if args and args.success and args.discoverTrader and args.traderID
                and DynamicTrading and DynamicTrading.Manager and DynamicTrading.Manager.DiscoverTrader then
                local player = getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
                if player then
                    DynamicTrading.Manager.DiscoverTrader(args.traderID, player)
                end
            end

            local ui = getConversationUI()
            if ui and args and args.message and args.message ~= "" then
                ui:speak(args.message)
                ui:updateOptions(ui.baseOptions or {})
            end
            return
        end

        return
    end

    args = args or {}
    local sourceNPCID = args.sourceNPCID and tostring(args.sourceNPCID) or nil
    if sourceNPCID then
        System.recruitResultCache[sourceNPCID] = args
    end

    local ui = getConversationUI()
    if not ui then
        return
    end

    local currentSourceNPCID = System.GetConversationSourceNPCID(ui)
    if sourceNPCID and currentSourceNPCID and sourceNPCID ~= tostring(currentSourceNPCID) then
        return
    end

    if args.reasonCode == "nag_penalty"
        and args.penalty
        and DT_Reputation
        and ui.target then
        local penalty = tonumber(args.penalty) or 0
        local traderUUID = tostring(args.traderUUID or ui.target.uuid or ui.target.traderID or ui.target.id or "")
        if isIndependentFactionID(ui.target.factionID) and traderUUID ~= "" and DT_Reputation.ModifyPersonalRep then
            DT_Reputation.ModifyPersonalRep(traderUUID, ui.target.factionID, penalty, "colony_recruit_nag")
        elseif ui.target.factionID and DT_Reputation.ModifyFactionBias then
            DT_Reputation.ModifyFactionBias(ui.target.factionID, penalty, "colony_recruit_nag")
        end
    end

    if ui.target and args.reputation ~= nil then
        ui.target.reputation = tonumber(args.reputation) or ui.target.reputation
    end

    if args.message and args.message ~= "" then
        ui:speak(args.message)
    end
    if ui.refreshFactionInfo then
        ui:refreshFactionInfo()
    end
    if args.success then
        local recruitedTraderUUID = args.recruitedTraderUUID and tostring(args.recruitedTraderUUID) or nil
        if recruitedTraderUUID then
            if DC_V2_RadarManager then
                if DC_V2_RadarManager.ClientRoster and DC_V2_RadarManager.ClientRoster.Souls then
                    DC_V2_RadarManager.ClientRoster.Souls[recruitedTraderUUID] = nil
                end
                DC_V2_RadarManager.FoundTraders[recruitedTraderUUID] = nil
                if DC_V2_RadarManager.RequestRoster then
                    DC_V2_RadarManager.RequestRoster()
                end
            end

            if DynamicTrading_Client and DynamicTrading_Client.Cache and DynamicTrading_Client.Cache.Traders then
                DynamicTrading_Client.Cache.Traders[recruitedTraderUUID] = nil
            end

            if DC_V2_RadarWindow and DC_V2_RadarWindow.instance and DC_V2_RadarWindow.instance.refresh then
                DC_V2_RadarWindow.instance:refresh()
            end
        end
        System.OpenWindow()
    end
    ui:updateOptions(ui.baseOptions or {})
end

if not System.EventsAdded then
    Events.OnServerCommand.Add(onServerCommand)
    System.EventsAdded = true
end

local function requestStarterWorkers()
    if not (System and System.SendCommand) then
        return
    end
    System.SendCommand("EnsureStarterWorkers", {})
end

if not System.StarterWorkerEventsAdded then
    Events.OnGameStart.Add(requestStarterWorkers)
    Events.OnCreatePlayer.Add(function(playerIndex)
        if playerIndex == nil or playerIndex == 0 then
            requestStarterWorkers()
        end
    end)
    System.StarterWorkerEventsAdded = true
end
