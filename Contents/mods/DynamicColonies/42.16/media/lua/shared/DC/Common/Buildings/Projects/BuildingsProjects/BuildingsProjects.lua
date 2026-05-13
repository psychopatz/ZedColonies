DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Projects = Buildings.Internal.Projects or {}

Projects.Config = Buildings.Config
Buildings.Internal.Projects = Projects

require "DC/Common/Buildings/Projects/BuildingsProjects/BuildingsProjects_Common"
require "DC/Common/Buildings/Projects/BuildingsProjects/BuildingsProjects_Queue"
require "DC/Common/Buildings/Projects/BuildingsProjects/BuildingsProjects_Lifecycle"
require "DC/Common/Buildings/Projects/BuildingsProjects/BuildingsProjects_WorkerFlow"
require "DC/Common/Buildings/Projects/BuildingsProjects/BuildingsProjects_Owner"

return Buildings