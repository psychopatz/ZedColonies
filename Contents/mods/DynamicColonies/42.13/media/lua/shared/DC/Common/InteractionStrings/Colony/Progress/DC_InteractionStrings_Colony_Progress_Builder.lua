require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Colony", "Progress", {
    Builder = {
        Active = {
            stateLabel = "Building",
            activeText = "Building {project}",
            captionText = "{progress} / {total} work points | ETA {eta}",
            color = { r = 0.28, g = 0.72, b = 0.32 }
        }
    }
})
