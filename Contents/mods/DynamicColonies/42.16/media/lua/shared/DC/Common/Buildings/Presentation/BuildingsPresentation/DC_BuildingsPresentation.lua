DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Presentation = Buildings.Internal.Presentation or {}

Buildings.Internal.Presentation = Presentation

if Presentation.EntryLoaded then
    return Buildings
end

Presentation.EntryLoaded = true
Presentation.Modules = Presentation.Modules or {}
Presentation.Helpers = Presentation.Helpers or {}

require "DC/Common/Buildings/Presentation/BuildingsPresentation/DC_BuildingsPresentation_Common"
require "DC/Common/Buildings/Presentation/BuildingsPresentation/DC_BuildingsPresentation_Snapshots"
require "DC/Common/Buildings/Presentation/BuildingsPresentation/DC_BuildingsPresentation_Summary"
require "DC/Common/Buildings/Presentation/BuildingsPresentation/DC_BuildingsPresentation_WorkerState"

return Buildings
