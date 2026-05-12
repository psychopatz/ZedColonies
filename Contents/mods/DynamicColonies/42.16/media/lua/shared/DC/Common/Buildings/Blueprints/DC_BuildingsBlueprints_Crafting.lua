DC_Buildings = DC_Buildings or {}
DC_Buildings.Blueprints = DC_Buildings.Blueprints or {}
DC_Buildings.Blueprints.Internal = DC_Buildings.Blueprints.Internal or {}

local Buildings = DC_Buildings
local Blueprints = Buildings.Blueprints

local function getColonyConfig()
    return DC_Colony and DC_Colony.Config or {}
end

local function getOwnerUsername(playerOrUsername)
    local labourConfig = getColonyConfig()
    return labourConfig.GetOwnerUsername and labourConfig.GetOwnerUsername(playerOrUsername) or tostring(playerOrUsername or "local")
end

local function buildBlueprintGrantData(definition)
    return {
        actionType = "CraftBlueprint",
        blueprintID = tostring(definition.blueprintID or definition.buildingType or "Blueprint"),
        blueprintDisplayName = tostring(definition.displayName or "Blueprint"),
        craftLabel = tostring(definition.craftLabel or ("Craft " .. tostring(definition.displayName or "Blueprint"))),
        blueprintItemFullType = tostring(definition.itemFullType or ""),
        placementEntityType = tostring(definition.placementEntityType or ""),
        consumeFromInventoryOnly = definition.consumeFromInventoryOnly ~= false,
    }
end

function Blueprints.BuildPreview(ownerUsername, buildingType, mode, plotX, plotY, buildingID, installKey, target, projectDefinition, sourcePlayer)
    local definition = Blueprints.GetDefinition(buildingType, mode)
    if not definition then
        return nil
    end

    local owner = getOwnerUsername(ownerUsername)
    local inventoryCounts = Buildings.Internal.GetPlayerInventoryMaterialCounts
        and Buildings.Internal.GetPlayerInventoryMaterialCounts(owner, sourcePlayer)
        or nil
    local recipeAvailability = Buildings.Internal.BuildRecipeAvailability
        and Buildings.Internal.BuildRecipeAvailability(owner, projectDefinition and projectDefinition.recipe or {}, sourcePlayer, inventoryCounts)
        or { hasAll = false, entries = {} }

    return {
        ownerUsername = owner,
        actionType = "CraftBlueprint",
        buildingType = tostring(buildingType or ""),
        displayName = tostring((Buildings.Config and Buildings.Config.GetDefinition and Buildings.Config.GetDefinition(buildingType) or {}).displayName or buildingType or "Building"),
        iconPath = definition.iconPath,
        mode = tostring(mode or "build"),
        plotX = math.floor(tonumber(plotX) or 0),
        plotY = math.floor(tonumber(plotY) or 0),
        buildingID = buildingID,
        installKey = tostring(installKey or ""),
        available = target ~= nil,
        canStart = recipeAvailability.hasAll == true,
        reason = recipeAvailability.hasAll == true and nil or "You need every listed material in your inventory to craft this blueprint.",
        currentLevel = math.max(0, math.floor(tonumber(target and target.currentLevel) or 0)),
        targetLevel = math.max(1, math.floor(tonumber(target and target.targetLevel) or 1)),
        workPoints = 0,
        recipeAvailability = recipeAvailability,
        effects = {},
        currentInstallCount = 0,
        maxInstallCount = 0,
        capacityPerInstall = 0,
        blueprint = buildBlueprintGrantData(definition),
        confirmLabel = tostring(definition.craftLabel or "Craft Blueprint"),
        requireBuilder = false,
    }
end

function Blueprints.CraftFromPlayer(ownerUsername, player, buildingType, mode, plotX, plotY, buildingID, installKey)
    local definition = Blueprints.GetDefinition(buildingType, mode)
    if not definition then
        return false, "That building does not use a blueprint flow.", nil
    end

    local owner = getOwnerUsername(ownerUsername)
    local target, reason = Buildings.ResolveProjectTarget(owner, buildingType, mode, plotX, plotY, buildingID, installKey)
    if not target then
        return false, reason or "That blueprint cannot be crafted right now.", nil
    end

    local projectDefinition = Buildings.Internal.GetProjectDefinition
        and Buildings.Internal.GetProjectDefinition(buildingType, target.targetLevel, target.mode, target.installKey, target.plotX, target.plotY)
        or nil
    if not projectDefinition or projectDefinition.enabled == false then
        return false, "That blueprint is not available yet.", nil
    end

    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        local okCreate, testItem = pcall(InventoryItemFactory.CreateItem, tostring(definition.itemFullType or ""))
        if okCreate ~= true or not testItem then
            return false, "The blueprint item definition is missing.", nil
        end
    end

    local consumed = false
    local consumeReason = "Inventory crafting is unavailable."
    if Buildings.Internal.ConsumeRecipeFromPlayerInventory then
        consumed, consumeReason = Buildings.Internal.ConsumeRecipeFromPlayerInventory(owner, projectDefinition.recipe, player)
    end
    if consumed ~= true then
        return false, consumeReason or "Missing required materials in your inventory.", nil
    end

    local inventory = player and player.getInventory and player:getInventory() or nil
    if not inventory then
        return false, "No player inventory found.", nil
    end

    local addedItems = inventory:AddItems(tostring(definition.itemFullType or ""), 1)
    if not addedItems then
        return false, "Unable to add the crafted blueprint item.", nil
    end

    return true, nil, definition
end

Buildings.BuildBlueprintPreview = Blueprints.BuildPreview
Buildings.CraftBlueprintFromPlayer = Blueprints.CraftFromPlayer

return Blueprints
