require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonySkills/DC_ColonySkills"
require "DC/Common/Colony/ColonyNutrition/DC_ColonyNutrition"
require "DC/Common/Colony/ColonyEnergy/DC_ColonyEnergy"

DC_Colony = DC_Colony or {}
DC_Colony.Registry = DC_Colony.Registry or {}
DC_Colony.Registry.Internal = DC_Colony.Registry.Internal or {}

-- Keep explicit load order so registry foundations are available before higher-level APIs.
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Internal"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Data"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_WorkerState"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Workers"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Recruitment"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Presentation"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Ledgers"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_WorkerCommands"
require "DC/Common/Colony/ColonyRegistry/DC_ColonyRegistry_Sites"
require "DC/Common/Colony/Warehouse/DC_ColonyWarehouse"

return DC_Colony.Registry
