require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Colony", "Outcome", {
    Fish = {
        Recovered = "Caught {count} {item_word} at {place}.",
        Empty = "No bites at {place}."
    }
})
