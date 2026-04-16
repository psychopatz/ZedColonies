DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Companion = DC_Colony.Companion
local Internal = Companion.Internal

Companion.CanPlayerCommandCompanion = Internal.CanPlayerCommandCompanion
Companion.AssignWorkerCompanionCommander = Internal.AssignWorkerCompanionCommander
Companion.RefreshCompanionCommanderValidity = Internal.RefreshCompanionCommanderValidity
Companion.ClaimWorkerCompanionCommand = Internal.ClaimWorkerCompanionCommand
Companion.TransferWorkerCompanionCommand = Internal.TransferWorkerCompanionCommand
Companion.StartWorkerCompanion = Internal.StartWorkerCompanion
Companion.IssueWorkerCompanionOrder = Internal.IssueWorkerCompanionOrder
Companion.BeginWorkerCompanionReturn = Internal.BeginWorkerCompanionReturn
Companion.MarkCompanionActive = Internal.MarkCompanionActive