DT_MainWindow = DT_MainWindow or {}
DT_MainWindow.Internal = DT_MainWindow.Internal or {}

local Internal = DT_MainWindow.Internal
local MainWindowLayout = Internal.MainWindowLayout or {}

function DT_MainWindow:updateStatus(text)
    if not self.statusText then
        return
    end

    self.statusText:setText(" <RGB:0.75,0.75,0.75> " .. tostring(text or "") .. " ")
    MainWindowLayout.refreshRichTextPanel(self.statusText)
end

