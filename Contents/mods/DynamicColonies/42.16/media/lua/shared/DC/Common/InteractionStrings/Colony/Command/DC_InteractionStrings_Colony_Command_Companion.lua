require "DT/Common/InteractionStrings/DT_InteractionStrings"

DynamicTrading.RegisterInteractionStrings("Colony", "Command", {
    Companion = {
        OrderMeta = {
            Follow = {
                label = "Follow Me",
                state = "Follow",
                visualEmote = "followme",
                activityText = "Responded to your call and fell in behind you.",
                summarySingle = "{name} is moving in behind you.",
                summaryPlural = "{count} companions are moving in behind you.",
                emptyText = "No commanded companions are close enough to follow you.",
            },
            Stay = {
                label = "Wait Here",
                state = "Stay",
                visualEmote = "freeze",
                activityText = "Held position on your command.",
                summarySingle = "{name} is holding position.",
                summaryPlural = "{count} companions are holding position.",
                emptyText = "No commanded companions are close enough to hold here.",
            },
            ProtectAuto = {
                label = "Defend (Auto)",
                state = "ProtectAuto",
                visualEmote = "signalok",
                activityText = "Shifted to defensive escort duty on your command.",
                summarySingle = "{name} is covering you.",
                summaryPlural = "{count} companions are covering you.",
                emptyText = "No commanded companions are close enough to cover you.",
            },
            ProtectMelee = {
                label = "Defend (Melee)",
                state = "ProtectMelee",
                visualEmote = "comefront",
                activityText = "Took up melee guard duty on your command.",
                summarySingle = "{name} is screening with melee weapons.",
                summaryPlural = "{count} companions are screening with melee weapons.",
                emptyText = "No melee-capable companions are close enough to guard you.",
            },
            ProtectRanged = {
                label = "Defend (Ranged)",
                state = "ProtectRanged",
                visualEmote = "signalfire",
                activityText = "Took up ranged overwatch on your command.",
                summarySingle = "{name} is taking ranged overwatch.",
                summaryPlural = "{count} companions are taking ranged overwatch.",
                emptyText = "No ranged-capable companions are close enough to cover you.",
            },
            Dismiss = {
                label = "Go Home",
                state = "Dismiss",
                visualEmote = "moveout",
                activityText = "Broke off companion duty and started heading home on your command.",
                summarySingle = "{name} is heading home.",
                summaryPlural = "{count} companions are heading home.",
                emptyText = "No commanded companions are close enough to send home.",
            },
        },
        PlayerThought = {
            Follow = {
                "On me. Tight spacing.",
                "Move with me. No drifting.",
                "Stay on my shoulder and keep up.",
                "Close ranks. You're with me.",
            },
            Stay = {
                "Hold here. Don't wander.",
                "Stay sharp and lock this spot down.",
                "Stop here. Eyes up.",
                "Anchor here until I move you.",
            },
            ProtectAuto = {
                "Cover me and pick your fights.",
                "Guard formation. React as needed.",
                "Defensive posture. Watch my flanks.",
                "Stay ready and cover the gaps.",
            },
            ProtectMelee = {
                "Front line on me. Melee screen.",
                "Blades up. Keep them off me.",
                "Close defense only. Hold the line.",
                "Push in and protect the formation.",
            },
            ProtectRanged = {
                "Range support. Watch the approach.",
                "Take distance and cover me.",
                "Guns up. Ranged overwatch.",
                "Hold back and shoot clean lanes.",
            },
            Dismiss = {
                "Break off. Head home.",
                "We're done here. Return to base.",
                "Back to the colony. Move.",
                "Companion duty's over. Go home.",
            },
        },
        CompanionAck = {
            Follow = {
                "Right behind you.",
                "Moving with you.",
                "On your shoulder.",
                "Keeping pace.",
            },
            Stay = {
                "Holding here.",
                "Position locked.",
                "I'll keep watch.",
                "Staying put.",
            },
            ProtectAuto = {
                "I'll cover you.",
                "Watching your back.",
                "Guarding the formation.",
                "Ready to defend.",
            },
            ProtectMelee = {
                "I'll keep them off you.",
                "Front line's mine.",
                "I'll take the close ones.",
                "Melee guard ready.",
            },
            ProtectRanged = {
                "Taking overwatch.",
                "I'll cover from range.",
                "Ranged guard ready.",
                "I've got the long sightlines.",
            },
            Dismiss = {
                "Returning home.",
                "Heading back.",
                "I'll report home.",
                "Breaking off now.",
            },
        },
        Notices = {
            NoAuthority = "You don't currently hold command authority over those companions.",
            NoTargets = "No commanded companions answered the order.",
            Unsupported = "Travel Companion requires Dynamic Trading V2.",
        },
    }
})
