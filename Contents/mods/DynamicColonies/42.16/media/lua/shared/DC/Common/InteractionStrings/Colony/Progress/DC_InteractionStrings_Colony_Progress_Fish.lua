require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("DynamicColonies", "Progress", {
    Fish = {
        Active = {
            stateLabel = "Fishing",
            activeText = "Waiting for fish to bite",
            captionText = "{eta} to land the next catch",
            color = { r = 0.36, g = 0.74, b = 1.00 }
        }
    }
})
