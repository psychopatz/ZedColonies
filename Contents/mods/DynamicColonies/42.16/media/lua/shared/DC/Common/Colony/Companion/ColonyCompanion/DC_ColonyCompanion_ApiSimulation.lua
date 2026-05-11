DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
local Internal = Companion.Internal

Companion.RecordCombatAttack = Internal.RecordCombatAttack
Companion.UpdateTravelCompanionWorker = Internal.UpdateTravelCompanionWorker

if DC_Colony.Config.JobProfiles and DC_Colony.Config.JobProfiles.TravelCompanion then
    DC_Colony.Config.JobProfiles.TravelCompanion.processHandler = Internal.UpdateTravelCompanionWorker
end
