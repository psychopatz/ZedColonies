DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.BuildLoadoutFromWorker(worker)
    local chosen = Internal.SelectEquipmentEntries(worker)
    local rangedWeapon = chosen.ranged and chosen.ranged.fullType or nil
    local meleeWeapon = chosen.melee and chosen.melee.fullType or nil
    local ammoType = Internal.GetAmmoTypeForWeapon(rangedWeapon) or (chosen.ammo and chosen.ammo.fullType or nil)
    local ammoCount = math.max(0, tonumber(chosen.ammo and chosen.ammo.qty or 0) or 0)

    local loadout = {
        rangedWeapon = rangedWeapon,
        rangedAmmoType = ammoType,
        ammoCount = math.max(0, tonumber(ammoCount) or 0),
        meleeWeapon = meleeWeapon,
        bag = chosen.bag and chosen.bag.fullType or nil,
        rangedCondition = chosen.ranged and chosen.ranged.condition or nil,
        meleeCondition = chosen.melee and chosen.melee.condition or nil,
    }

    local resolvedLoadout, appliedFallback, fallbackType = Internal.MergeFallbackCombatLoadout(worker, loadout)
    if appliedFallback then
        Internal.Debug(
            "Applied fallback combat loadout workerID=" .. tostring(worker and worker.workerID)
                .. " type=" .. tostring(fallbackType)
                .. " melee=" .. tostring(resolvedLoadout.meleeWeapon or "nil")
                .. " ranged=" .. tostring(resolvedLoadout.rangedWeapon or "nil")
                .. " ammo=" .. tostring(resolvedLoadout.ammoCount or 0)
        )
    end

    return resolvedLoadout
end