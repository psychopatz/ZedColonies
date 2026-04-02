require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Colony", "Outcome", {
    Scavenge = {
        Recovered = "Recovered {count} {item_word} from {place}.",
        Empty = "Came back empty-handed from {place}."
    }
})
