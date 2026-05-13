DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Validation = Buildings.Internal.ProjectValidation or {}

Validation.Config = Buildings.Config
Buildings.Internal.ProjectValidation = Validation

require "DC/Common/Buildings/Projects/BuildingsProjectValidation/BuildingsProjectValidation_Common"
require "DC/Common/Buildings/Projects/BuildingsProjectValidation/BuildingsProjectValidation_TargetQueries"
require "DC/Common/Buildings/Projects/BuildingsProjectValidation/BuildingsProjectValidation_TargetResolution"
require "DC/Common/Buildings/Projects/BuildingsProjectValidation/BuildingsProjectValidation_ProjectQueries"
require "DC/Common/Buildings/Projects/BuildingsProjectValidation/BuildingsProjectValidation_WorkerRules"
require "DC/Common/Buildings/Projects/BuildingsProjectValidation/BuildingsProjectValidation_Destroy"

return Buildings