DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.GetAmmoTypeForWeapon(fullType)
    local scriptItem = fullType and getScriptManager and getScriptManager():getItem(fullType) or nil
    if scriptItem and scriptItem.getAmmoType then
        local ammoType = scriptItem:getAmmoType()
        if ammoType and ammoType ~= "" then
            return tostring(ammoType)
        end
    end
    return nil
end

function Internal.GetFallbackAmmoCount(weaponType)
    local scriptItem = weaponType and getScriptManager and getScriptManager():getItem(weaponType) or nil
    local clipSize = scriptItem and scriptItem.getClipSize and tonumber(scriptItem:getClipSize()) or 0
    clipSize = math.max(1, math.floor(clipSize or 0))
    return clipSize * 3
end