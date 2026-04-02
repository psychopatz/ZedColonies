require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DT/Common/InteractionStrings/DT_InteractionStrings"

DC_Colony = DC_Colony or {}
DC_Colony.Interaction = DC_Colony.Interaction or {}

require "DC/Common/Colony/ColonyInteraction/DC_ColonyInteraction_Formatting"
require "DC/Common/Colony/ColonyInteraction/DC_ColonyInteraction_Helpers"
require "DC/Common/Colony/ColonyInteraction/DC_ColonyInteraction_Labels"
require "DC/Common/Colony/ColonyInteraction/DC_ColonyInteraction_Progress"
require "DC/Common/Colony/ColonyInteraction/DC_ColonyInteraction_Messages"

return DC_Colony.Interaction
