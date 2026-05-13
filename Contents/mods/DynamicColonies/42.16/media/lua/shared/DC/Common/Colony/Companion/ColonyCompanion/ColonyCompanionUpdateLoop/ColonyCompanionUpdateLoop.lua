DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
Companion.Internal = Companion.Internal or {}

local Internal = Companion.Internal
Internal.UpdateLoop = Internal.UpdateLoop or {}

local UpdateLoop = Internal.UpdateLoop
local Config = Internal.Config

require "DC/Common/Colony/Companion/ColonyCompanion/ColonyCompanionUpdateLoop/ColonyCompanionUpdateLoop_Travel"
require "DC/Common/Colony/Companion/ColonyCompanion/ColonyCompanionUpdateLoop/ColonyCompanionUpdateLoop_Home"
require "DC/Common/Colony/Companion/ColonyCompanion/ColonyCompanionUpdateLoop/ColonyCompanionUpdateLoop_ToPlayer"
require "DC/Common/Colony/Companion/ColonyCompanion/ColonyCompanionUpdateLoop/ColonyCompanionUpdateLoop_Returning"
require "DC/Common/Colony/Companion/ColonyCompanion/ColonyCompanionUpdateLoop/ColonyCompanionUpdateLoop_Active"

function Internal.UpdateTravelCompanionWorker(worker, ctx)
	if not worker or not Internal.IsTravelCompanionWorker(worker) then
		return false
	end

	local deltaHours = math.max(0, tonumber(ctx and ctx.deltaHours) or 0)
	local currentHour = tonumber(ctx and ctx.currentHour) or Internal.GetCurrentWorldHours()
	local forcedRest = ctx and ctx.forcedRest == true or false
	local hasCalories = ctx and ctx.hasCalories ~= false
	local hasHydration = ctx and ctx.hasHydration ~= false
	local profile = ctx and ctx.profile or Config.GetJobProfile(worker.jobType)
	local presenceState = tostring(worker.presenceState or "")

	ctx = ctx or {}
	ctx.deltaHours = deltaHours
	ctx.currentHour = currentHour
	ctx.forcedRest = forcedRest
	ctx.hasCalories = hasCalories
	ctx.hasHydration = hasHydration
	ctx.profile = profile

	if presenceState == Config.PresenceStates.Home then
		return UpdateLoop.UpdateTravelCompanionHomeState(worker, ctx)
	end

	if presenceState == Config.PresenceStates.CompanionToPlayer then
		return UpdateLoop.UpdateTravelCompanionToPlayerState(worker, ctx)
	end

	if presenceState == Config.PresenceStates.CompanionReturning then
		return UpdateLoop.UpdateTravelCompanionReturningState(worker, ctx)
	end

	if presenceState == Config.PresenceStates.CompanionActive then
		return UpdateLoop.UpdateTravelCompanionActiveState(worker, ctx)
	end

	return false
end

return Companion