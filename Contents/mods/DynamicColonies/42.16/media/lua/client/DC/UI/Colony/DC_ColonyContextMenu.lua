require "DC/UI/Colony/System/DC_System"

local function openColonyWindow()
    if DynamicTrading and DynamicTrading.LogDebug then
        DynamicTrading.LogDebug("DynamicColonies", "UI", "ContextMenu", "Context menu requested Colony Management window.")
    elseif DynamicTrading and DynamicTrading.Log then
        DynamicTrading.Log("DynamicColonies", "UI", "ContextMenu", "Context menu requested Colony Management window.")
    end
    DC_System.OpenWindow()
end

-- The Colony Management right-click option has been moved to the Radio UI.
-- local function OnFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
--     if test then return end
-- 
--     local player = getSpecificPlayer(playerNum)
--     if not player then return end
-- 
--     context:addOption("Colony Management", nil, openColonyWindow)
-- end
-- 
-- Events.OnFillWorldObjectContextMenu.Add(OnFillWorldObjectContextMenu)
