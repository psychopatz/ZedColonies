require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_Bootstrap"
require "DT/UI/ZedColonies/MainWindow/MainWindowCore/DT_MainWindowCore_WorkerPresentation"

DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal
local LabourWorkerList = ISScrollingListBox:derive("LabourWorkerList")

local function formatWorkerListSubtitle(worker)
    if type(Internal.formatWorkerListSubtitle) == "function" then
        return Internal.formatWorkerListSubtitle(worker)
    end
    return tostring(worker and worker.state or "Idle")
        .. " | "
        .. tostring(worker and worker.jobType or "Unassigned")
        .. " | "
        .. tostring(worker and worker.presenceState or "Home")
end

function LabourWorkerList:new(x, y, width, height)
    local o = ISScrollingListBox:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.itemheight = 60
    o.selected = 1
    o.drawBorder = true
    o.font = UIFont.Medium
    return o
end

function LabourWorkerList:doDrawItem(y, item, alt)
    local worker = item.item
    if not worker then
        return y + self.itemheight
    end

    if item.selected then
        self:drawRect(0, y, self.width, self.itemheight, 0.25, 0.18, 0.38, 0.62)
    elseif alt then
        self:drawRect(0, y, self.width, self.itemheight, 0.08, 1, 1, 1)
    else
        self:drawRect(0, y, self.width, self.itemheight, 0.08, 0, 0, 0)
    end

    self:drawText(tostring(worker.name or worker.workerID), 10, y + 7, 0.88, 0.92, 1, 1, UIFont.Medium)
    self:drawText(
        formatWorkerListSubtitle(worker),
        10,
        y + 33,
        0.72,
        0.72,
        0.72,
        0.95,
        UIFont.Small
    )
    self:drawRectBorder(0, y, self.width, self.itemheight, 0.08, 1, 1, 1)
    return y + self.itemheight
end

Internal.LabourWorkerList = LabourWorkerList

function DT_MainWindow.onWorkerListMouseDown(target, item)
    if not item then
        return
    end

    local win = target or DT_MainWindow.instance
    if not win or not win.applyWorkerSelection then
        return
    end

    win:applyWorkerSelection(item, true)
end
