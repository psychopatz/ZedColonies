DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal or {}

Internal.Constants = Internal.Constants or {}

Internal.Constants.TRAVEL_STAGE_OUTBOUND = "Outbound"
Internal.Constants.TRAVEL_STAGE_ACTIVE = "Active"
Internal.Constants.TRAVEL_STAGE_DEPARTING = "Departing"
Internal.Constants.TRAVEL_STAGE_RETURNING = "Returning"
Internal.Constants.COMMAND_CLAIM_RANGE_TILES = 6
Internal.Constants.COMMAND_INVALID_GRACE_MS = 5 * 60 * 1000

DC_Colony.Companion.Internal = Internal