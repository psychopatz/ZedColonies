require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Colony", "Progress", {
    Scavenge = {
        Active = {
            stateLabel = "Scavenging",
            activeText = "Searching in {place}",
            captionText = "{eta} to finish current work",
            color = { r = 0.94, g = 0.72, b = 0.18 }
        }
    }
})
