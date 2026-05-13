require "ISUI/ISPanel"
require "DC/Common/Colony/ColonyConfig/DC_ColonyConfig"
require "DC/Common/Colony/ColonySkills/DC_ColonySkills"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_Bootstrap"
require "DC/UI/Colony/MainWindow/MainWindowCore/DC_MainWindowCore_WorkerPresentation"
require "DC/Common/Colony/Common/DC_ColonySkillPanel_FlavorText"

DC_ColonySkillPanel = ISPanel:derive("DC_ColonySkillPanel")
DC_ColonySkillPanel.Internal = DC_ColonySkillPanel.Internal or {}

require "DC/UI/Colony/ColonySkillPanel/DC_ColonySkillPanel_Core"
require "DC/UI/Colony/ColonySkillPanel/DC_ColonySkillPanel_Skills"
require "DC/UI/Colony/ColonySkillPanel/DC_ColonySkillPanel_Subject"
require "DC/UI/Colony/ColonySkillPanel/DC_ColonySkillPanel_Lifecycle"
require "DC/UI/Colony/ColonySkillPanel/DC_ColonySkillPanel_Render"

return DC_ColonySkillPanel