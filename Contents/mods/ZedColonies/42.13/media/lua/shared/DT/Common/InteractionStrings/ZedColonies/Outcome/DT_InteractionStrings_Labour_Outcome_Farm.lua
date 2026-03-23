require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Labour", "Outcome", {
    Farm = {
        Recovered = "Harvested {count} {item_word} from {place}.",
        Empty = "No harvest ready at {place}."
    }
})
