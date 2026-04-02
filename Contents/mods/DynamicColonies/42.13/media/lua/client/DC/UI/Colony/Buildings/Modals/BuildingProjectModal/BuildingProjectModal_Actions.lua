function DC_BuildingProjectModal:onConfirmClicked()
    local builder = self:getSelectedBuilder()
    local builderState = DC_BuildingsClientSelectors.GetBuilderRequirementState(builder, {
        allowedProjectID = self.preview and self.preview.projectID or nil
    })
    local requireBuilder = self.requireBuilder == true
    if not self.onConfirmCallback then
        return
    end
    if requireBuilder == true and builderState.ready ~= true then
        return
    end

    self.onConfirmCallback({
        workerID = builderState.ready == true and builder and builder.workerID or nil,
        projectID = self.preview.projectID,
        buildingType = self.preview.buildingType,
        mode = self.preview.mode,
        plotX = self.preview.plotX,
        plotY = self.preview.plotY,
        buildingID = self.preview.buildingID,
        installKey = self.preview.installKey
    })
    self:close()
end

function DC_BuildingProjectModal:onDebugMaterialsClicked()
    if not self.onDebugMaterialsCallback then
        return
    end

    self.onDebugMaterialsCallback({
        projectID = self.preview.projectID,
        buildingType = self.preview.buildingType,
        mode = self.preview.mode,
        plotX = self.preview.plotX,
        plotY = self.preview.plotY,
        buildingID = self.preview.buildingID,
        installKey = self.preview.installKey
    })
end

function DC_BuildingProjectModal:onSupplyClicked()
    if not self.onSupplyCallback or not self.preview or not self.preview.projectID then
        return
    end

    self.onSupplyCallback({
        projectID = self.preview.projectID,
        buildingType = self.preview.buildingType,
        mode = self.preview.mode,
        plotX = self.preview.plotX,
        plotY = self.preview.plotY,
        buildingID = self.preview.buildingID,
        installKey = self.preview.installKey
    })
    self:close()
end

function DC_BuildingProjectModal:onCancelClicked()
    self:close()
end
