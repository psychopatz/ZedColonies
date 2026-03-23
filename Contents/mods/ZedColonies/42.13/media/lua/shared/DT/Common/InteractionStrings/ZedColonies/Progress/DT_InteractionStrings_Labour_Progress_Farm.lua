require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Labour", "Progress", {
    Farm = {
        Active = {
            stateLabel = "Farming",
            activeText = "Working the plot at {place}",
            captionText = "{eta} to finish field work",
            color = { r = 0.34, g = 0.68, b = 0.30 }
        }
    }
})
