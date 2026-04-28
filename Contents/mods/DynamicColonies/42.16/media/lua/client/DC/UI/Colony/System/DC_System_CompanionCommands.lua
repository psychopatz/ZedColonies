require "ISUI/ISEmoteRadialMenu"

local System = DC_System
local Internal = System.Internal

System.CompanionCommands = System.CompanionCommands or {}

local CompanionCommands = System.CompanionCommands

local MENU_KEY = "DC_CompanionSignals"
local MENU_LABEL = "Companions"
local ORDER_PREFIX = "DC_Command_"
local COMMAND_ICON_PATH = "media/ui/Icon_MarketInfo.png"
local ORDER_ICON_PATHS = {
    Follow = COMMAND_ICON_PATH,
    Stay = COMMAND_ICON_PATH,
    ProtectAuto = COMMAND_ICON_PATH,
    ProtectMelee = COMMAND_ICON_PATH,
    ProtectRanged = COMMAND_ICON_PATH,
    Dismiss = COMMAND_ICON_PATH,
}
local ORDER_BASE_EMOTES = {
    Follow = "followme",
    Stay = "freeze",
    ProtectAuto = "signalok",
    ProtectMelee = "comefront",
    ProtectRanged = "signalfire",
    Dismiss = "moveout",
}
local LEGACY_VISUAL_EMOTES = {
    Wave = "wavehi",
    wave = "wavehi",
    Halt = "freeze",
    halt = "freeze",
    Yes = "yes",
}
local DEFAULT_ORDER_META = {
    Follow = { label = "Follow Me", visualEmote = "followme", emptyText = "No commanded companions are close enough to follow you." },
    Stay = { label = "Wait Here", visualEmote = "freeze", emptyText = "No commanded companions are close enough to hold here." },
    ProtectAuto = { label = "Defend (Auto)", visualEmote = "signalok", emptyText = "No commanded companions are close enough to cover you." },
    ProtectMelee = { label = "Defend (Melee)", visualEmote = "comefront", emptyText = "No melee-capable companions are close enough to guard you." },
    ProtectRanged = { label = "Defend (Ranged)", visualEmote = "signalfire", emptyText = "No ranged-capable companions are close enough to cover you." },
    Dismiss = { label = "Go Home", visualEmote = "moveout", emptyText = "No commanded companions are close enough to send home." },
}

local originalInit = ISEmoteRadialMenu.init
local originalEmote = ISEmoteRadialMenu.emote

local function getLocalPlayer()
    return Internal.GetLocalPlayer and Internal.GetLocalPlayer() or getSpecificPlayer and getSpecificPlayer(0) or getPlayer and getPlayer() or nil
end

local function getCommandRegistry()
    if DynamicTrading and DynamicTrading.GetInteractionStrings then
        return DynamicTrading.GetInteractionStrings("Colony", "Command")
    end
    return nil
end

local function getCompanionStrings()
    local registry = getCommandRegistry()
    return registry and registry.Companion or {}
end

local function getOrderMeta(order)
    local strings = getCompanionStrings()
    local fromRegistry = strings.OrderMeta and strings.OrderMeta[order] or nil
    local fallback = DEFAULT_ORDER_META[order] or { label = tostring(order or "Command"), visualEmote = "Wave", emptyText = "No commanded companions answered that order." }
    local meta = {}
    for key, value in pairs(fallback) do
        meta[key] = value
    end
    for key, value in pairs(fromRegistry or {}) do
        meta[key] = value
    end
    return meta
end

local function getOrderLines(bucketName, order)
    local strings = getCompanionStrings()
    local bucket = strings and strings[bucketName] or nil
    local values = bucket and bucket[order] or nil
    return type(values) == "table" and values or nil
end

local function resolveBaseVisualEmote(order, visualEmote)
    local raw = tostring(visualEmote or "")
    if raw ~= "" then
        local mapped = LEGACY_VISUAL_EMOTES[raw] or LEGACY_VISUAL_EMOTES[string.lower(raw)]
        if mapped then
            return mapped
        end

        if raw == string.lower(raw) then
            return raw
        end
    end

    return ORDER_BASE_EMOTES[order] or "wavehi"
end

local function chooseRandomLine(lines, fallback)
    if type(lines) == "table" and #lines > 0 then
        return tostring(lines[ZombRand(#lines) + 1])
    end
    return tostring(fallback or "")
end

local function getPlayerUsername(playerObj)
    return playerObj and playerObj.getUsername and tostring(playerObj:getUsername() or "") or "local"
end

local function getCommandRadius()
    local config = Internal.GetConfig and Internal.GetConfig() or DC_Colony and DC_Colony.Config or nil
    if config and config.GetCompanionCommandRadius then
        return math.max(1, tonumber(config.GetCompanionCommandRadius()) or 20)
    end
    return 20
end

local function isTravelCompanionSupported()
    local config = Internal.GetConfig and Internal.GetConfig() or DC_Colony and DC_Colony.Config or nil
    if config and config.IsTravelCompanionSupported then
        return config.IsTravelCompanionSupported() == true
    end
    return true
end

local function updateVisibleStatus(message)
    local text = tostring(message or "Colony update received.")
    if DC_MainWindow and DC_MainWindow.instance and DC_MainWindow.instance.getIsVisible and DC_MainWindow.instance:getIsVisible() then
        DC_MainWindow.instance:updateStatus(text)
    end
    return text
end

local function formatCommandTargets(snapshot)
    local companions = snapshot and snapshot.companions or {}
    local count = #companions
    if count <= 0 then
        return ""
    end
    if count == 1 then
        return tostring(companions[1].name or "Companion")
    end
    if count == 2 then
        return tostring(companions[1].name or "Companion") .. " and " .. tostring(companions[2].name or "Companion")
    end

    return tostring(companions[1].name or "Companion")
        .. ", "
        .. tostring(companions[2].name or "Companion")
        .. ", and "
        .. tostring(count - 2)
        .. " more"
end

local function buildPlayerCommandLine(order, snapshot)
    local meta = getOrderMeta(order)
    local targetNames = formatCommandTargets(snapshot)
    if targetNames == "" then
        return tostring(meta.emptyText or "No commanded companions answered that order.")
    end

    if order == "Follow" then
        return targetNames .. ", on me."
    end
    if order == "Stay" then
        return targetNames .. ", hold here."
    end
    if order == "ProtectAuto" then
        return targetNames .. ", cover me."
    end
    if order == "ProtectMelee" then
        return targetNames .. ", front line. Keep them off me."
    end
    if order == "ProtectRanged" then
        return targetNames .. ", ranged cover."
    end
    if order == "Dismiss" then
        return targetNames .. ", head home."
    end

    return chooseRandomLine(getOrderLines("PlayerThought", order), meta.label)
end

local function showPlayerThought(playerObj, order, snapshot)
    if not playerObj then
        return
    end
    local thought = buildPlayerCommandLine(order, snapshot)
    if playerObj.setHaloNote then
        playerObj:setHaloNote(thought, 220, 220, 180, 240)
    end
    if playerObj.setSpeakTime then
        playerObj:setSpeakTime(0)
    end
    pcall(function()
        playerObj:Say(thought)
    end)
end

local function tryActorFeedback(actor, text)
    if not actor or not text or text == "" then
        return false
    end
    if actor.setSpeakTime then
        actor:setSpeakTime(0)
    end
    local ok = pcall(function()
        actor:Say(text)
    end)
    if ok then
        return true
    end
    return pcall(function()
        actor:setHaloNote(text, 180, 220, 180, 180)
    end)
end

local function buildNearbySnapshot(playerObj)
    local snapshot = {
        companions = {},
        canMelee = false,
        canRanged = false,
        radius = getCommandRadius(),
    }

    if not playerObj or playerObj:isDead() then
        return snapshot
    end

    local cache = DTNPCClient and DTNPCClient.NPCCache or nil
    if type(cache) ~= "table" then
        return snapshot
    end

    local config = Internal.GetConfig and Internal.GetConfig() or DC_Colony and DC_Colony.Config or nil
    local companionJob = tostring((config and config.JobTypes and config.JobTypes.TravelCompanion) or "TravelCompanion")
    local px = playerObj:getX()
    local py = playerObj:getY()
    local username = getPlayerUsername(playerObj)

    for uuid, cached in pairs(cache) do
        local npcData = cached and cached.npcData or cached
        if type(npcData) == "table" and tostring(npcData.dcCommanderUsername or "") == username then
            local npcJob = tostring(npcData.dcCompanionJob or "")
            if npcJob == "" or npcJob == companionJob then
                local zombie = DTNPCClient and DTNPCClient.FindZombieByUUID and DTNPCClient.FindZombieByUUID(uuid) or nil
                if zombie then
                    local distance = IsoUtils.DistanceTo(px, py, zombie:getX(), zombie:getY())
                    if distance <= snapshot.radius then
                        local skills = npcData.skills or {}
                        local meleeLevel = tonumber(skills.Melee) or 0
                        local shootingLevel = tonumber(skills.Shooting) or 0
                        snapshot.canMelee = snapshot.canMelee or meleeLevel > 0
                        snapshot.canRanged = snapshot.canRanged or shootingLevel > 0
                        snapshot.companions[#snapshot.companions + 1] = {
                            uuid = tostring(uuid),
                            name = tostring(npcData.name or npcData.displayName or npcData.forename or npcData.nickname or "Companion"),
                            distance = distance,
                        }
                    end
                end
            end
        end
    end

    table.sort(snapshot.companions, function(a, b)
        if a.distance == b.distance then
            return tostring(a.name) < tostring(b.name)
        end
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0)
    end)

    return snapshot
end

local function addCommandSlice(subMenu, order)
    local meta = getOrderMeta(order)
    subMenu[ORDER_PREFIX .. order] = meta.label
    ISEmoteRadialMenu.icons[ORDER_PREFIX .. order] = getTexture(ORDER_ICON_PATHS[order])
end

function CompanionCommands.BuildMenuDefinition(playerObj)
    local snapshot = buildNearbySnapshot(playerObj)
    local subMenu = {}
    addCommandSlice(subMenu, "Follow")
    addCommandSlice(subMenu, "Stay")
    addCommandSlice(subMenu, "ProtectAuto")
    if snapshot.canMelee then
        addCommandSlice(subMenu, "ProtectMelee")
    end
    if snapshot.canRanged then
        addCommandSlice(subMenu, "ProtectRanged")
    end
    addCommandSlice(subMenu, "Dismiss")
    return subMenu
end

function CompanionCommands.SendBulkOrder(order)
    local playerObj = getLocalPlayer()
    if not playerObj or playerObj:isDead() then
        return false
    end

    local snapshot = buildNearbySnapshot(playerObj)

    local ok = System.SendCommand and System.SendCommand("IssueCompanionOrderToAllNearby", {
        order = order,
        args = {},
        radius = snapshot.radius or getCommandRadius(),
    }) or false

    if ok then
        showPlayerThought(playerObj, order, snapshot)
    end
    return ok
end

function CompanionCommands.HandleResult(args)
    args = args or {}
    local playerObj = getLocalPlayer()
    local message = updateVisibleStatus(args.message)

    if args.popup == true and DC_Colony and DC_Colony.UI and DC_Colony.UI.ShowNoticeModal then
        DC_Colony.UI.ShowNoticeModal(message)
    elseif playerObj and playerObj.setHaloNote and (tonumber(args.affectedCount) or 0) <= 0 and message ~= "" then
        playerObj:setHaloNote(message, 220, 170, 170, 240)
    end

    local fallbackLines = {}
    for _, entry in ipairs(args.results or {}) do
        local ackText = tostring(entry and entry.ackText or "")
        local uuid = entry and entry.uuid and tostring(entry.uuid) or ""
        local actor = uuid ~= "" and DTNPCClient and DTNPCClient.FindZombieByUUID and DTNPCClient.FindZombieByUUID(uuid) or nil
        if not tryActorFeedback(actor, ackText) and ackText ~= "" then
            local name = tostring(entry and entry.name or "Companion")
            fallbackLines[#fallbackLines + 1] = name .. ": " .. ackText
        end
    end

    if #fallbackLines > 0 and playerObj and playerObj.setHaloNote then
        playerObj:setHaloNote(fallbackLines[1], 180, 220, 180, 240)
    end
end

function ISEmoteRadialMenu:init()
    originalInit(self)

    if not isTravelCompanionSupported() then
        return
    end

    ISEmoteRadialMenu.menu = ISEmoteRadialMenu.menu or {}
    ISEmoteRadialMenu.icons = ISEmoteRadialMenu.icons or {}

    ISEmoteRadialMenu.menu[MENU_KEY] = {
        name = MENU_LABEL,
        subMenu = CompanionCommands.BuildMenuDefinition(self.character or getLocalPlayer()),
    }
    ISEmoteRadialMenu.icons[MENU_KEY] = getTexture(COMMAND_ICON_PATH)
end

function ISEmoteRadialMenu:emote(emote)
    local emoteName = tostring(emote or "")
    if string.sub(emoteName, 1, string.len(ORDER_PREFIX)) ~= ORDER_PREFIX then
        return originalEmote(self, emote)
    end

    local order = string.sub(emoteName, string.len(ORDER_PREFIX) + 1)
    local meta = getOrderMeta(order)
    CompanionCommands.SendBulkOrder(order)
    return originalEmote(self, resolveBaseVisualEmote(order, meta.visualEmote))
end

return CompanionCommands
