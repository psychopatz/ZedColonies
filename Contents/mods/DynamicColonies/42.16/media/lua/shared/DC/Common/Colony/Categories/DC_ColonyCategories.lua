require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"

DC_Colony = DC_Colony or {}
DC_Colony.Categories = DC_Colony.Categories or {}
DC_Colony.Categories.Internal = DC_Colony.Categories.Internal or {}

require "DC/Common/Colony/Categories/DC_ColonyCategories_Registry"
require "DC/Common/Colony/Categories/DC_ColonyCategories_TagRules"
require "DC/Common/Colony/Categories/DC_ColonyCategories_Modifiers"
require "DC/Common/Colony/Categories/DC_ColonyCategories_Converter"

return DC_Colony.Categories
