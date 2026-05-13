DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Housing = Buildings.Internal.Housing or {}

Housing.Config = Buildings.Config
Buildings.Internal.Housing = Housing

require "DC/Common/Buildings/Presentation/BuildingsHousing/BuildingsHousing_Common"
require "DC/Common/Buildings/Presentation/BuildingsHousing/BuildingsHousing_Medical"
require "DC/Common/Buildings/Presentation/BuildingsHousing/BuildingsHousing_Housing"
require "DC/Common/Buildings/Presentation/BuildingsHousing/BuildingsHousing_Infirmary"
require "DC/Common/Buildings/Presentation/BuildingsHousing/BuildingsHousing_Queries"

return Buildings