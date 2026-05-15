DC_Colony = DC_Colony or {}
DC_Colony.DebugArchive = DC_Colony.DebugArchive or {}
DC_Colony.DebugArchive.Internal = DC_Colony.DebugArchive.Internal or {}

local DebugArchive = DC_Colony.DebugArchive

require "DC/Common/Colony/DebugArchive/DebugArchiveData/DC_ColonyDebugArchive_Common"
require "DC/Common/Colony/DebugArchive/DebugArchiveData/DC_ColonyDebugArchive_Index"
require "DC/Common/Colony/DebugArchive/DebugArchiveData/DC_ColonyDebugArchive_Snapshots"

return DebugArchive
