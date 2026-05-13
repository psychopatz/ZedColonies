local Panel = DC_ColonySkillPanel
local Internal = Panel.Internal

Internal.MainWindow = DC_MainWindow and DC_MainWindow.Internal or {}
Internal.FlavorText = DC_Colony and DC_Colony.UI and DC_Colony.UI.ColonySkillPanelFlavorText or {}
Internal.DISPLAY_ORDER = {
    "Shooting",
    "Melee",
    "Construction",
    "Mining",
    "Cooking",
    "Plants",
    "Animals",
    "Crafting",
    "Maintenance",
    "Medical",
    "Social",
    "Intellectual"
}

function Internal.isFunction(value)
    return type(value) == "function"
end

function Internal.clamp(value, minimum, maximum)
    local number = tonumber(value) or 0
    if number < minimum then
        return minimum
    end
    if number > maximum then
        return maximum
    end
    return number
end

return Panel