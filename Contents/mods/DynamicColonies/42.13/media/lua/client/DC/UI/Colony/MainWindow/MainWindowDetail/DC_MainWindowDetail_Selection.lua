DC_MainWindow = DC_MainWindow or {}
DC_MainWindow.Internal = DC_MainWindow.Internal or {}
local Internal = DC_MainWindow.Internal

function DC_MainWindow:applyWorkerSelection(summary, requestDetail)
    if not summary then
        return
    end

    self.selectedWorkerSummary = summary

    local detail = Internal.resolveWorkerDetail(summary.workerID) or summary
    self:updateWorkerDetail(detail)

    if requestDetail and isClient() and not isServer() then
        self:updateStatus("Requesting worker details for " .. tostring(summary.name or summary.workerID) .. "...")
        self:sendColonyCommand("RequestWorkerDetails", {
            workerID = summary.workerID,
            knownVersion = DC_MainWindow.cachedDetailVersions and DC_MainWindow.cachedDetailVersions[summary.workerID] or nil,
            includeWorkerLedgers = false
        })
    end
end
