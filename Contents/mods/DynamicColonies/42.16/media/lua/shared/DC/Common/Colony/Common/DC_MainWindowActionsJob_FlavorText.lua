DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

DC_Colony.UI.MainWindowActionsJobFlavorText = DC_Colony.UI.MainWindowActionsJobFlavorText or {
    fallbackWorkerName = "this worker",
    companionFallbackName = "Companion",
    selectWorkerFirst = "Select a worker first.",
    selectCompanionWorkerFirst = "Select a companion worker first.",
    removeDeceasedWorkerRecord = "Removing deceased worker record...",
    unemployedChooseRole = "This worker is unemployed. Choose a role first.",
    incapacitatedRecover = "This worker is incapacitated and must recover before returning to duty.",
    autoRepeatAlwaysOnStop = "Continuous work is always on. Use Stop Job when you want a worker to stop.",
    autoRepeatAlwaysOnActiveJobs = "Continuous work is always on for active jobs.",
    noLabourJobsAvailable = "No labour jobs are currently available.",
    currentJobAlreadySet = "%s is already set to that job.",
    changingWorkerJob = "Changing worker job...",
    changingWorkerJobTo = "Changing worker job to %s...",
    changingGathererJob = "Changing worker job to Gatherer for %s...",
    savingGathererSetup = "Saving gatherer setup for %s...",

    startJob = "Starting job...",
    stopJob = "Stopping job...",
    sendWorkerOut = "Sending worker out from home...",
    callWorkerHome = "Calling worker home...",
    cancelScavengingTrip = "Cancelling the scavenging trip...",
    callCompanionToPlayer = "Calling your companion to your location...",
    stopCompanionAndSendHome = "Stopping companion duty and sending them home...",
    stopCompanionDuty = "Stopping companion duty...",

    commandAuthorityTravelCompanionOnly = "Command authority only applies to Travel Companion workers.",
    startCompanionDutyFirst = "Start companion duty before assigning command.",
    claimCompanionCommand = "Trying to claim companion command. Stand within 6 tiles of the companion.",
    noTransferCandidates = "No other colony members are available for command transfer.",
    transferCompanionHeading = "Transfer companion command to...",
    transferCompanionStatus = "Transferring companion command to %s...",

    lootSetupTravelCompanionOnly = "Loot setup is only available for Travel Companion workers.",
    lootSetupUnavailable = "The companion loot setup modal is unavailable right now.",
    companionLootSetupTitle = "Companion Loot Setup",
    companionLootSetupPrompt = "Configure how %s should filter nearby loot sources.",
    companionLootSaveStatus = "Saving loot setup for %s with %s...",
    companionLootStatus = "radius %s, %s sources",

    scavengeWarningDefault = "Make sure they have enough food and water before leaving.",
    scavengeWarningNoProvisions = "This worker has no stored provisions and may turn back quickly.",
    scavengeWarningLowReserve = "This worker has less than one day of total reserves and may return early.",
    scavengeProvisionText = "Start scavenging run for %s?\n\nBe sure to give the NPC provisions first. Scavengers can head back home when calories or hydration run low.\n\nStored provisions:\nCalories: %s\nHydration: %s\n\nTotal reserve:\nCalories: %s\nHydration: %s\n\nWork mode: Continuous until stopped\n\n%s\n\nPress Yes to start anyway, or No to provision them first.",
    scavengeStartCancelled = "Scavenging start cancelled. Add provisions first if needed.",

    stopScavengeReturnHome = "Call %s back home?\n\nThey will stop the current scavenging trip, return home, and stay there until you start them again.\n\nPress Yes to recall them, or No to keep them scavenging.",
    stopScavengeCancelJob = "Cancel the scavenging job for %s?\n\nThis prevents them from heading out until you start the job again.\n\nPress Yes to cancel, or No to keep the job active.",
    stopCompanionSendHome = "Send %s home from companion duty?\n\nThey will leave your position, despawn, and finish the trip home on the colony travel timer.\n\nPress Yes to send them home, or No to keep them with you.",
    stopCompanionCancelDuty = "Cancel companion duty for %s?\n\nThis keeps them at home until you call them to you again.\n\nPress Yes to cancel, or No to leave the job active.",
    stopGenericJob = "Stop the current job for %s?\n\nPress Yes to stop working, or No to leave the job running.",
    stopCompanionDutyCancelled = "Companion duty stop cancelled.",
    stopJobCancelled = "Job stop cancelled.",

    changeJobTitle = "Change Job",
    changeJobPrompt = "Choose a new job for %s.",
}

return DC_Colony.UI.MainWindowActionsJobFlavorText