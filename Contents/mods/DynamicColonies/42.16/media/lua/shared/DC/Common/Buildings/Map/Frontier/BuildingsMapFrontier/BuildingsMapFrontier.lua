DC_Buildings = DC_Buildings or {}

local Buildings = DC_Buildings
Buildings.Internal = Buildings.Internal or {}

local Frontier = Buildings.Internal.Frontier or {}
Frontier.Config = Buildings.Config
Buildings.Internal.Frontier = Frontier

require "DC/Common/Buildings/Map/Frontier/BuildingsMapFrontier/BuildingsMapFrontier_Helpers"
require "DC/Common/Buildings/Map/Frontier/BuildingsMapFrontier/BuildingsMapFrontier_Security"
require "DC/Common/Buildings/Map/Frontier/BuildingsMapFrontier/BuildingsMapFrontier_Candidates"
require "DC/Common/Buildings/Map/Frontier/BuildingsMapFrontier/BuildingsMapFrontier_Summary"

return Buildings
