require "DT/UI/Faction/DT_PlayerFactionNameModal"
require "DT/UI/Faction/FactionInfoWindow/DT_FactionInfoWindow"

local System = DT_System

local function buildBlockedMessage(status)
    status = status or {}
    if status.faction then
        return "You already control a faction."
    end
    if status.createBlockedReason == "needs_recruit" then
        return "Recruit at least one labour worker first."
    end
    return "Faction eligibility is still syncing."
end

function System.GetOwnedFactionStatus()
    if (not isClient() or isServer()) and DynamicTrading_Factions and DynamicTrading_Factions.GetOwnedFactionStatus then
        local player = System.Internal and System.Internal.GetLocalPlayer and System.Internal.GetLocalPlayer() or nil
        System.ownedFactionStatusCache = DynamicTrading_Factions.GetOwnedFactionStatus(player)
    end
    return System.ownedFactionStatusCache or nil
end

function System.RequestOwnedFactionStatus()
    return System.SendCommand("RequestOwnedFactionStatus", {})
end

function System.OpenOwnedFactionManagement()
    local status = System.GetOwnedFactionStatus()
    if status and status.faction then
        DT_FactionInfoWindow.Open()
        if DT_FactionInfoWindow.instance and DT_FactionInfoWindow.instance.refreshList then
            DT_FactionInfoWindow.instance:refreshList()
        end
        return true, nil
    end
    return System.PromptCreateFaction()
end

function System.PromptCreateFaction()
    local status = System.GetOwnedFactionStatus()
    if not status or status.canCreate ~= true then
        return false, buildBlockedMessage(status)
    end

    DT_PlayerFactionNameModal.Open({
        title = "Create Faction",
        promptText = "Choose a name for your new faction.",
        onConfirm = function(name)
            if name == "" then
                if DT_MainWindow.instance and DT_MainWindow.instance.updateStatus then
                    DT_MainWindow.instance:updateStatus("Faction name cannot be empty.")
                end
                return
            end
            System.SendCommand("CreatePlayerFaction", {
                name = name
            })
        end
    })

    return true, nil
end
