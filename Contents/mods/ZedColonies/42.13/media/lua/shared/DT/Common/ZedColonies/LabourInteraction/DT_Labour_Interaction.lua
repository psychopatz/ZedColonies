require "DT/Common/ZedColonies/LabourConfig/DT_LabourConfig"
require "DT/Common/InteractionStrings/DT_InteractionStrings"

DT_Labour = DT_Labour or {}
DT_Labour.Interaction = DT_Labour.Interaction or {}

require "DT/Common/ZedColonies/LabourInteraction/DT_LabourInteraction_Formatting"
require "DT/Common/ZedColonies/LabourInteraction/DT_LabourInteraction_Helpers"
require "DT/Common/ZedColonies/LabourInteraction/DT_LabourInteraction_Labels"
require "DT/Common/ZedColonies/LabourInteraction/DT_LabourInteraction_Progress"
require "DT/Common/ZedColonies/LabourInteraction/DT_LabourInteraction_Messages"

return DT_Labour.Interaction
