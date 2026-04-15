require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry"
require "DC/Common/Colony/ColonySim/DC_Colony_Sim"
require "DC/Common/Colony/DC_Colony_Presentation"
require "DT/Common/Faction/TradingSys/DynamicTrading_Factions"

DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

local Network = DC_Colony.Network
local Internal = Network.Internal or {}

Network.Internal = Internal
Network.Handlers = Network.Handlers or {}

local function getConfig()
    return DC_Colony and DC_Colony.Config or nil
end

local function getRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

local function getSim()
    return DC_Colony and DC_Colony.Sim or nil
end

local function getPresentation()
    return DC_Colony and DC_Colony.Presentation or nil
end

local function canUseDebugRecruit(player)
    local accessLevel = nil
    if player and player.getAccessLevel then
        accessLevel = player:getAccessLevel()
    end
    local hasElevatedAccess = accessLevel and accessLevel ~= "" and accessLevel ~= "None"
    local isSinglePlayer = (not isClient or not isClient()) and not hasElevatedAccess

    if isSinglePlayer then
        return isDebugEnabled and isDebugEnabled() == true
    end

    if DynamicTrading and DynamicTrading.Debug then
        return true
    end

    if isDebugEnabled and isDebugEnabled() then
        return true
    end

    if hasElevatedAccess then
        return true
    end

    return false
end

local function isScriptItem(fullType)
    if not fullType or fullType == "" or not getScriptManager then
        return false
    end
    local scriptItem = getScriptManager():getItem(fullType)
    return scriptItem ~= nil
end

local function isDebugEquipmentFullType(Config, fullType, requirementKey)
    if not Config or not fullType or fullType == "" then
        return false
    end

    if requirementKey and requirementKey ~= ""
        and Config.ItemMatchesEquipmentRequirement
        and Config.ItemMatchesEquipmentRequirement(fullType, requirementKey) then
        return true
    end

    if Config.IsColonyToolFullType and Config.IsColonyToolFullType(fullType) then
        return true
    end

    return false
end

Network.Handlers.DebugGiveEquipmentItem = function(player, args)
    if not player then
        return
    end

    if not canUseDebugRecruit(player) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "Debug item spawning is unavailable for this player.", "error", true)
        end
        return
    end

    args = args or {}
    local Config = getConfig()
    local fullType = tostring(args.fullType or "")
    local requirementKey = tostring(args.requirementKey or "")
    local count = math.max(1, math.min(50, math.floor(tonumber(args.count) or 1)))

    if fullType == "" then
        if Internal.syncNotice then
            Internal.syncNotice(player, "No debug equipment item was selected.", "error", true)
        end
        return
    end

    if not isScriptItem(fullType) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "Debug equipment item does not exist: " .. fullType, "error", true)
        end
        return
    end

    if not isDebugEquipmentFullType(Config, fullType, requirementKey) then
        if Internal.syncNotice then
            Internal.syncNotice(player, "That item is not registered as colony equipment: " .. fullType, "error", true)
        end
        return
    end

    local inventory = player:getInventory()
    if not inventory then
        if Internal.syncNotice then
            Internal.syncNotice(player, "No player inventory found.", "error", true)
        end
        return
    end

    if Internal.addInventoryItem then
        Internal.addInventoryItem(inventory, fullType, count)
    else
        inventory:AddItems(fullType, count)
    end

    if Internal.syncNotice then
        local displayName = fullType
        local scriptItem = getScriptManager and getScriptManager():getItem(fullType) or nil
        if scriptItem and scriptItem.getDisplayName then
            displayName = scriptItem:getDisplayName()
        end
        Internal.syncNotice(
            player,
            "Debug added " .. tostring(count) .. " " .. tostring(displayName) .. ".",
            "info",
            false
        )
    end
end

Network.Handlers.DebugRecruitWorker = function(player, args)
    if not player or not canUseDebugRecruit(player) then return end
    args = args or {}

    local recruitArgs = {}
    for key, value in pairs(args) do
        recruitArgs[key] = value
    end
    recruitArgs.debugRecruitBypass = true

    if Network.Handlers.AttemptRecruitWorker then
        Network.Handlers.AttemptRecruitWorker(player, recruitArgs)
    elseif Internal.syncRecruitAttemptResult then
        Internal.syncRecruitAttemptResult(player, {
            success = false,
            sourceNPCID = recruitArgs.sourceNPCID or recruitArgs.traderUUID,
            reasonCode = "debug_unavailable",
            message = "Debug recruit is unavailable."
        })
    end
end

return Network
