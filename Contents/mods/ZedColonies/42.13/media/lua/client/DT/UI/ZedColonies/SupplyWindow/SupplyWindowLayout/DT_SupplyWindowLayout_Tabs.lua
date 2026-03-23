DT_SupplyWindow = DT_SupplyWindow or {}
DT_SupplyWindow.Internal = DT_SupplyWindow.Internal or {}

local Internal = DT_SupplyWindow.Internal

function DT_SupplyWindow:refreshTabButtons()
    if not self.btnTabProvisions then
        return
    end

    self.btnTabProvisions:setTitle(Internal.getTabButtonTitle(self, Internal.Tabs.Provisions))
    self.btnTabOutput:setTitle(Internal.getTabButtonTitle(self, Internal.Tabs.Output))
    self.btnTabEquipment:setTitle(Internal.getTabButtonTitle(self, Internal.Tabs.Equipment))

    local buttonEntries = {
        { id = Internal.Tabs.Provisions, button = self.btnTabProvisions },
        { id = Internal.Tabs.Output, button = self.btnTabOutput },
        { id = Internal.Tabs.Equipment, button = self.btnTabEquipment },
    }

    for _, entry in ipairs(buttonEntries) do
        local isActive = (self.activeTab or Internal.Tabs.Provisions) == entry.id
        entry.button.backgroundColor = isActive
            and { r = 0.18, g = 0.28, b = 0.46, a = 0.9 }
            or { r = 0.08, g = 0.08, b = 0.08, a = 0.75 }
        entry.button.borderColor = isActive
            and { r = 1, g = 1, b = 1, a = 0.3 }
            or { r = 1, g = 1, b = 1, a = 0.1 }
    end
end

function DT_SupplyWindow:onSelectProvisionsTab()
    self:setActiveTab(Internal.Tabs.Provisions)
end

function DT_SupplyWindow:onSelectOutputTab()
    self:setActiveTab(Internal.Tabs.Output)
end

function DT_SupplyWindow:onSelectEquipmentTab()
    self:setActiveTab(Internal.Tabs.Equipment)
end
