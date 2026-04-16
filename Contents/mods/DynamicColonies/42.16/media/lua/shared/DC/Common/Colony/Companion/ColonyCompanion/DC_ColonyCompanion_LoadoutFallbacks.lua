DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.GetFallbackLoadoutPreset(loadoutType)
    if DTNPCProtect and DTNPCProtect.GetWorldLoadoutPreset then
        local ok, preset = pcall(DTNPCProtect.GetWorldLoadoutPreset, loadoutType)
        if ok and type(preset) == "table" then
            return Internal.CopyLoadout(preset)
        end
    end

    local preset = Internal.Defaults.CompanionLoadouts[loadoutType] or Internal.Defaults.CompanionLoadouts.melee
    return Internal.CopyLoadout(preset)
end

function Internal.GetPreferredFallbackLoadoutType(worker)
    local melee = Internal.GetWorkerSkillLevel(worker, "Melee")
    local shooting = Internal.GetWorkerSkillLevel(worker, "Shooting")

    if shooting > 0 and melee > 0 then
        return "hybrid"
    end
    if shooting > 0 then
        return "ranged"
    end
    return "melee"
end

function Internal.MergeFallbackCombatLoadout(worker, loadout)
    loadout = Internal.CopyLoadout(loadout)

    local preferredType = Internal.GetPreferredFallbackLoadoutType(worker)
    local fallback = Internal.GetFallbackLoadoutPreset(preferredType)
    local appliedFallback = false

    if (not loadout.meleeWeapon or loadout.meleeWeapon == "")
        and (preferredType == "melee" or preferredType == "hybrid")
        and fallback.meleeWeapon and fallback.meleeWeapon ~= "" then
        loadout.meleeWeapon = fallback.meleeWeapon
        loadout.meleeCondition = fallback.meleeCondition
        appliedFallback = true
    end

    if (not loadout.rangedWeapon or loadout.rangedWeapon == "")
        and (preferredType == "ranged" or preferredType == "hybrid")
        and fallback.rangedWeapon and fallback.rangedWeapon ~= "" then
        loadout.rangedWeapon = fallback.rangedWeapon
        loadout.rangedCondition = fallback.rangedCondition
        appliedFallback = true
    end

    if loadout.rangedWeapon and (not loadout.rangedAmmoType or loadout.rangedAmmoType == "") then
        loadout.rangedAmmoType = fallback.rangedAmmoType or Internal.GetAmmoTypeForWeapon(loadout.rangedWeapon)
        appliedFallback = true
    end

    if loadout.rangedWeapon and (tonumber(loadout.ammoCount) or 0) <= 0 then
        local fallbackAmmo = math.max(0, tonumber(fallback.ammoCount) or 0)
        loadout.ammoCount = fallbackAmmo > 0 and fallbackAmmo or Internal.GetFallbackAmmoCount(loadout.rangedWeapon)
        appliedFallback = true
    end

    return loadout, appliedFallback, preferredType
end