DC_BuildingProjectModal = ISCollapsableWindow:derive("DC_BuildingProjectModal")
DC_BuildingProjectModal.instance = DC_BuildingProjectModal.instance or nil

function DC_BuildingProjectModal:new(x, y, width, height)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

function DC_BuildingProjectModal.Open(args)
    args = args or {}
    if DC_BuildingProjectModal.instance then
        DC_BuildingProjectModal.instance:close()
    end

    local width = 760
    local height = 470
    local x = (getCore():getScreenWidth() - width) / 2
    local y = (getCore():getScreenHeight() - height) / 2
    local modal = DC_BuildingProjectModal:new(x, y, width, height)
    modal.title = tostring(args.title or "Project")
    modal.preview = args.preview or {}
    modal.onConfirmCallback = args.onConfirm
    modal.onSupplyCallback = args.onSupply
    modal.onDebugMaterialsCallback = args.onDebugMaterials
    modal.confirmLabelOverride = args.confirmLabel
    modal.requireBuilder = args.requireBuilder == true
    modal.debugEnabled = modal:canUseDebug()
    modal.builderOptions = {}
    modal:initialise()
    modal:instantiate()
    modal:addToUIManager()
    modal:bringToTop()
    DC_BuildingProjectModal.instance = modal
    return modal
end
