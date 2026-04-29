require "DC/UI/Colony/System/DC_System"

local function openColonyWindow()
    if DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DTCommons", "DynamicColonies", "UI", "Context menu requested Colony Management window.")
    end
    DC_System.OpenWindow()
end

local function OnFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then return end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    context:addOption("Colony Management", nil, openColonyWindow)
end

Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
