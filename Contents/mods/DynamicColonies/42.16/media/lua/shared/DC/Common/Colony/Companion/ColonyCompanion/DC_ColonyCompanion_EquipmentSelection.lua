DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.SelectEquipmentEntries(worker)
    local selected = {
        ranged = nil,
        melee = nil,
        ammo = nil,
        bag = nil,
    }

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        local requirementKey = tostring(entry and entry.assignedRequirementKey or "")
        if requirementKey == "Colony.Combat.Ranged" and not selected.ranged then
            selected.ranged = entry
        elseif requirementKey == "Colony.Combat.Melee" and not selected.melee then
            selected.melee = entry
        elseif requirementKey == "Colony.Combat.Ammo" and not selected.ammo then
            selected.ammo = entry
        elseif requirementKey == "Colony.Carry.Backpack" and not selected.bag then
            selected.bag = entry
        end
    end

    for _, entry in ipairs(worker and worker.toolLedger or {}) do
        if not selected.ranged and Internal.HasTag(entry, "Weapon.Ranged.Firearm") then
            selected.ranged = entry
        end
        if not selected.melee and Internal.HasTag(entry, "Weapon.Melee") then
            selected.melee = entry
        end
        if not selected.ammo and Internal.HasTag(entry, "Weapon.Ranged.Ammo") then
            selected.ammo = entry
        end
        if not selected.bag and Internal.HasTag(entry, "Colony.Carry.Backpack") then
            selected.bag = entry
        end
    end

    return selected
end