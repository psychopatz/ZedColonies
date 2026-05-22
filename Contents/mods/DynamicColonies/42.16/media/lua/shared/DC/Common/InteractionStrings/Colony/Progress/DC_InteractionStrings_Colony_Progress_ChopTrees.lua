require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("DynamicColonies", "Progress", {
    ChopTrees = {
        Active = {
            stateLabel = "Woodcutting",
            activeText = "Cutting a tree at {place}",
            captionText = "{eta} to finish the cut",
            color = { r = 0.46, g = 0.72, b = 0.28 }
        }
    }
})
