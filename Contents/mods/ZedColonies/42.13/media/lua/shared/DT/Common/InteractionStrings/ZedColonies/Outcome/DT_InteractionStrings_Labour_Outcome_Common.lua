require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Labour", "Outcome", {
    Common = {
        TravelStarted = "Set out for {place}.",
        ArrivedAtSite = "Arrived at {place}.",
        ReturnedHome = "Returned home.",
        ReturnedHomeWithItems = "Returned home and stowed {count} {item_word} from {place}.",
        ReturnReasons = {
            FullHaul = "Pack is full, heading home.",
            LowTiredness = "Too tired to keep going, heading home.",
            LowFood = "Running low on food, heading home.",
            LowDrink = "Running low on water, heading home.",
            MissingTool = "Missing the right tool, heading home.",
            MissingSite = "Lost the work site, heading home.",
            Manual = "Heading home on command."
        }
    }
})
