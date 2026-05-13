DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

DC_Colony.Network.ColonyNetRecruitmentFlavorText = DC_Colony.Network.ColonyNetRecruitmentFlavorText or {
    goodbyeLines = {
        "I'll head to your base now.",
        "I'll meet you back at base.",
        "I'll get moving. See you at the base.",
        "Alright. I'll make my way there.",
    },
    successTestingArrived = "For testing, I made it to base and joined your labour roster.",
    successTestingImmediate = "For testing, I'll join your labour roster.",
    successArrived = "I made it to base and joined your labour roster.",
    successImmediate = "Alright. You've earned it. I'll join your labour roster.",
    missingTarget = "I can't sort out who you're trying to recruit right now.",
    debugUnavailable = "Debug recruit is unavailable.",
    alreadyRecruited = "I'm already part of your labour roster.",
    departureStarted = "I'm already heading to your base.",
    nonRecruitable = "That kind of trader won't join a colony labour roster.",
    lowReputation = "We aren't close enough for that yet. Earn more trust first.",
    nagPenalty = "I already answered you. Keep pushing and you'll lose my trust. Ask again tomorrow.",
    cooldown = "I've already given you my answer for today. Ask me again tomorrow.",
    rolledFailed = "You've earned the right to ask, but not today. Give me until tomorrow and ask again.",
    departureStartedTesting = "For testing, I'll head to your base now.",
    departureStartedSuccess = "Alright. You've earned it. I'll head to your base now.",
    recruitFailed = "I can't join your labour roster right now.",
}

return DC_Colony.Network.ColonyNetRecruitmentFlavorText