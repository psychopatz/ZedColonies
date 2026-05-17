require "DC/UI/Faction/DC_PlayerFactionNameModal"
require "DC/UI/Faction/FactionInfoWindow/DC_FactionInfoWindow"

local System = DC_System

local function buildBlockedMessage(status)
    status = status or {}
    if status.faction then
        return "You already control a faction."
    end
    if status.canCreate == true or status.createBlockedReason == "syncing" then
        return "Headquarters ready. Colony claim is syncing."
    end
    if status.createBlockedReason == "needs_recruit" then
        return "Recruit at least one labour worker first."
    end
    if status.createBlockedReason == "headquarters_required" then
        return "Finish your headquarters before claiming the colony."
    end
    return "Faction eligibility is still syncing."
end

local function buildRenamePromptKey(status)
    local faction = status and status.faction or nil
    return table.concat({
        tostring(status and (status.authorityOwner or status.ownerUsername) or ""),
        tostring(faction and faction.id or ""),
        tostring(faction and faction.name or ""),
        tostring(status and status.needsNamingPrompt == true),
    }, "|")
end

local function getPromptNowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    if getTimestamp then
        return math.floor((tonumber(getTimestamp()) or 0) * 1000)
    end
    return math.floor(os.clock() * 1000)
end

function System.GetOwnedFactionStatus()
    if (not isClient() or isServer()) and DynamicTrading_Factions and DynamicTrading_Factions.GetOwnedFactionStatus then
        local player = System.Internal and System.Internal.GetLocalPlayer and System.Internal.GetLocalPlayer() or nil
        System.ownedFactionStatusCache = DynamicTrading_Factions.GetOwnedFactionStatus(player)
    end
    return System.ownedFactionStatusCache or nil
end

function System.RequestOwnedFactionStatus()
    return System.SendFactionCommand("RequestOwnedFactionStatus", {})
end

function System.OpenOwnedFactionManagement()
    local status = System.GetOwnedFactionStatus()
    if status and status.faction then
        if not DC_FactionInfoWindow or not DC_FactionInfoWindow.Open then
            return false, "Faction management window is not available yet."
        end
        local ok, message = DC_FactionInfoWindow.Open()
        if ok ~= true then
            return false, message or "Faction Intelligence is unavailable right now."
        end
        if DC_FactionInfoWindow.Refresh then
            DC_FactionInfoWindow.Refresh()
        elseif DC_FactionInfoWindow.instance and DC_FactionInfoWindow.instance.refreshList then
            DC_FactionInfoWindow.instance:refreshList()
        end
        return true, nil
    end
    if status and (status.canCreate == true or status.createBlockedReason == "syncing") then
        System.RequestOwnedFactionStatus()
        return false, "Headquarters ready. Colony claim is syncing."
    end
    return System.PromptCreateFaction()
end

function System.PromptCreateFaction()
    local status = System.GetOwnedFactionStatus()
    if not status or status.canCreate ~= true then
        return false, buildBlockedMessage(status)
    end

    if not DC_PlayerFactionNameModal or not DC_PlayerFactionNameModal.Open then
        return false, "Faction name prompt is unavailable."
    end

    DC_PlayerFactionNameModal.Open({
        title = "Faction Name",
        promptText = "Enter a faction name.",
        confirmLabel = "Create",
        onConfirm = function(name)
            if name == "" then
                if DC_MainWindow.instance and DC_MainWindow.instance.updateStatus then
                    DC_MainWindow.instance:updateStatus("Faction name cannot be empty.")
                end
                return
            end
            System.SendFactionCommand("CreatePlayerFaction", {
                name = name
            })
        end
    })

    return true, nil
end

function System.PromptRenameOwnedFaction(args)
    args = args or {}
    local status = args.status or System.GetOwnedFactionStatus()
    if args.status then
        System.ownedFactionStatusCache = args.status
    end
    if not (status and status.faction) then
        return false, "Owned faction status is unavailable."
    end
    if not ((status.permissions and status.permissions.canRenameFaction == true) or status.isLeader == true) then
        return false, "Only the faction leader can rename this faction."
    end
    if not DC_PlayerFactionNameModal or not DC_PlayerFactionNameModal.Open then
        return false, "Faction name prompt is unavailable."
    end

    local promptKey = buildRenamePromptKey(status)
    System.lastOwnedFactionRenamePromptKey = System.lastOwnedFactionRenamePromptKey or nil
    System.lastOwnedFactionRenamePromptAt = tonumber(System.lastOwnedFactionRenamePromptAt) or 0
    if args.force ~= true and System.lastOwnedFactionRenamePromptKey == promptKey then
        local elapsed = math.max(0, getPromptNowMs() - System.lastOwnedFactionRenamePromptAt)
        if elapsed < 30000 then
            return false, nil
        end
    end
    System.lastOwnedFactionRenamePromptKey = promptKey
    System.lastOwnedFactionRenamePromptAt = getPromptNowMs()

    DC_PlayerFactionNameModal.Open({
        title = "Rename Faction",
        promptText = "Choose a permanent name for your faction.",
        confirmLabel = "Rename",
        defaultValue = tostring(args.defaultValue or status.faction.name or ""),
        onConfirm = function(name)
            System.SendFactionCommand("RenamePlayerFaction", {
                name = name
            })
        end
    })

    return true, nil
end

function System.MaybePromptOwnedFactionRename(status, args)
    status = status or System.GetOwnedFactionStatus()
    if not (status and status.needsNamingPrompt == true and status.faction) then
        System.lastOwnedFactionRenamePromptKey = nil
        return false
    end

    args = args or {}
    args.status = status
    return System.PromptRenameOwnedFaction(args)
end
