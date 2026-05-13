DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

local Config = DC_Colony.Config
local Registry = DC_Colony.Registry
local Internal = Registry.Internal
local Data = Internal.ColonyRegInternal or {}

function Internal.BuildToolLedgerFromLoadout(loadout)
    if type(loadout) ~= "table" then
        return {}
    end

    local ledger = {}
    local function append(fullType, requirementKey, condition, qty)
        local itemType = tostring(fullType or "")
        if itemType == "" then
            return
        end
        local entry = Internal.NormalizeEquipmentEntry({
            fullType = itemType,
            displayName = Internal.GetDisplayNameForFullType(itemType),
            tags = (Config.GetItemCombinedTags and Config.GetItemCombinedTags(itemType)) or {},
            qty = qty,
            condition = condition,
            assignedRequirementKey = requirementKey,
        })
        if entry then
            ledger[#ledger + 1] = entry
        end
    end

    append(loadout.meleeWeapon or loadout.primaryMeleeWeapon or loadout.weapon, "Colony.Combat.Melee", loadout.meleeCondition)
    append(loadout.rangedWeapon or loadout.firearm or loadout.gun, "Colony.Combat.Ranged", loadout.rangedCondition)
    append(loadout.rangedAmmoType or loadout.ammoType or loadout.ammo, "Colony.Combat.Ammo", nil, loadout.ammoCount)

    return ledger
end

function Internal.NormalizeSourceLoadout(loadout)
    if type(loadout) ~= "table" then
        return {}
    end

    return {
        meleeWeapon = loadout.meleeWeapon or loadout.primaryMeleeWeapon or loadout.weapon,
        meleeCondition = loadout.meleeCondition,
        rangedWeapon = loadout.rangedWeapon or loadout.firearm or loadout.gun,
        rangedCondition = loadout.rangedCondition,
        rangedAmmoType = loadout.rangedAmmoType or loadout.ammoType or loadout.ammo,
        ammoCount = loadout.ammoCount,
    }
end

return Data