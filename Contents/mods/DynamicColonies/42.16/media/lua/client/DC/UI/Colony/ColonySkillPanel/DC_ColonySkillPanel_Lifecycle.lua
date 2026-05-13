local Panel = DC_ColonySkillPanel

function Panel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.22 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 0.08 }
    o.subject = nil
    o.loading = false
    o.headerHeight = 120
    return o
end

function Panel:initialise()
    ISPanel.initialise(self)
end

return Panel