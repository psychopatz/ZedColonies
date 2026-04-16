DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

Internal.Defaults.CompanionLoadouts = {
    melee = {
        rangedWeapon = nil,
        rangedAmmoType = nil,
        ammoCount = 0,
        meleeWeapon = "Base.BaseballBat",
        bag = nil,
    },
    ranged = {
        rangedWeapon = "Base.Pistol",
        rangedAmmoType = "Base.Bullets9mm",
        ammoCount = 24,
        meleeWeapon = nil,
        bag = nil,
    },
    hybrid = {
        rangedWeapon = "Base.Pistol",
        rangedAmmoType = "Base.Bullets9mm",
        ammoCount = 24,
        meleeWeapon = "Base.BaseballBat",
        bag = nil,
    },
}

function Internal.CopyLoadout(loadout)
    local source = type(loadout) == "table" and loadout or {}
    return {
        rangedWeapon = source.rangedWeapon or nil,
        rangedAmmoType = source.rangedAmmoType or nil,
        ammoCount = math.max(0, tonumber(source.ammoCount) or 0),
        meleeWeapon = source.meleeWeapon or nil,
        bag = source.bag or nil,
        rangedCondition = source.rangedCondition ~= nil and tonumber(source.rangedCondition) or nil,
        meleeCondition = source.meleeCondition ~= nil and tonumber(source.meleeCondition) or nil,
    }
end