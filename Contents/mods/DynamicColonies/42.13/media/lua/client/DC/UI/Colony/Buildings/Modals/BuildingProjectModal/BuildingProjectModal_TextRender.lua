function DC_BuildingProjectModal:updateText()
    local preview = self.preview or {}
    local builder = self:getSelectedBuilder()
    local builderState = DC_BuildingsClientSelectors.GetBuilderRequirementState(builder, {
        allowedProjectID = preview.projectID
    })
    local requireBuilder = self.requireBuilder == true
    local willStartImmediately = preview.canStart == true and builderState.ready == true
    local willQueue = requireBuilder ~= true and willStartImmediately ~= true
    local recipeEntries = preview.recipeAvailability and preview.recipeAvailability.entries or preview.materialEntries or {}
    local hasAvailableUnsuppliedMaterials = false
    local hasMissingMaterials = false
    for _, entry in ipairs(recipeEntries) do
        local remaining = math.max(0, tonumber(entry and entry.remaining) or 0)
        local available = math.max(0, tonumber(entry and entry.available) or 0)
        if remaining > 0 then
            if available > 0 then
                hasAvailableUnsuppliedMaterials = true
            else
                hasMissingMaterials = true
            end
        end
    end
    local text = ""
    text = text .. " <RGB:1,1,1> <SIZE:Medium> " .. tostring(preview.displayName or preview.buildingType or "Project") .. " <LINE> "
    text = text .. " <RGB:0.72,0.72,0.72> Mode: <RGB:1,1,1> " .. tostring(preview.mode or "build") .. " <LINE> "
    if preview.mode == "install" then
        text = text .. " <RGB:0.72,0.72,0.72> Building Level: <RGB:1,1,1> " .. tostring(preview.targetLevel or 0) .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Installed: <RGB:1,1,1> "
            .. tostring(preview.currentInstallCount or 0)
            .. " / "
            .. tostring(preview.maxInstallCount or 0)
            .. " <LINE> "
        if tonumber(preview.capacityPerInstall) and tonumber(preview.capacityPerInstall) > 0 then
            text = text .. " <RGB:0.72,0.72,0.72> Capacity Gain: <RGB:1,1,1> +" .. tostring(preview.capacityPerInstall or 0) .. " <LINE> "
        end
    else
        text = text .. " <RGB:0.72,0.72,0.72> Target Level: <RGB:1,1,1> " .. tostring(preview.targetLevel or 0) .. " <LINE> "
    end
    text = text .. " <RGB:0.72,0.72,0.72> Work Points: <RGB:1,1,1> " .. tostring(preview.workPoints or preview.requiredWorkPoints or 0) .. " <LINE> "
    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Materials <LINE> "
    for _, line in ipairs(DC_BuildingsUIUtils.BuildRecipeLines(recipeEntries)) do
        text = text .. " " .. line .. " <LINE> "
    end
    if preview.canStart == true then
        text = text .. " <RGB:0.72,0.9,0.72> Materials ready. Construction can begin immediately. <LINE> "
    elseif hasMissingMaterials then
        text = text .. " <RGB:0.92,0.84,0.45> Missing materials will stall the project until supplies are added. <LINE> "
    elseif hasAvailableUnsuppliedMaterials then
        text = text .. " <RGB:0.92,0.84,0.45> Required materials are available to supply, but this project is not fully supplied yet. Use Supply for player inventory items or wait for warehouse stock to be pulled in. <LINE> "
    else
        text = text .. " <RGB:0.92,0.84,0.45> Materials still need to be supplied before work can continue. <LINE> "
    end
    if preview.projectID then
        text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Current Builder <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Assigned: <RGB:1,1,1> "
            .. tostring(preview.assignedBuilderName or preview.assignedBuilderID or "Unassigned")
            .. " <LINE> "
        text = text .. " <RGB:0.82,0.82,0.82> Select another Builder below and press Save to apply changes without resetting progress. <LINE> "
    end
    text = text .. " <LINE> <RGB:1,1,1> <SIZE:Medium> Builder <LINE> "
    if builder then
        text = text .. " <RGB:0.72,0.72,0.72> Name: <RGB:1,1,1> " .. tostring(builder.name or builder.workerID or "Builder") .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Construction: <RGB:1,1,1> Lv "
            .. tostring(DC_BuildingsClientSelectors.GetBuilderConstructionLevel(builder))
            .. " <LINE> "
        text = text .. " <RGB:0.72,0.72,0.72> Tools: <RGB:1,1,1> " .. tostring(builder.toolState or "Missing") .. " <LINE> "
    end
    if builderState.ready == true then
        text = text .. " <RGB:0.72,0.9,0.72> Builder Ready <LINE> "
    elseif requireBuilder ~= true and builder == nil then
        text = text .. " <RGB:0.82,0.82,0.82> No builder assigned yet. Confirming will queue this project until you assign one. <LINE> "
    elseif requireBuilder ~= true then
        text = text .. " <RGB:0.92,0.84,0.45> "
            .. tostring(builderState.reason or "Selected builder is not ready.")
            .. " The project can still be queued without assigning them yet. <LINE> "
    else
        text = text .. " <RGB:0.9,0.65,0.65> " .. tostring(builderState.reason or "Builder is not ready.") .. " <LINE> "
    end
    if willStartImmediately then
        text = text .. " <RGB:0.72,0.9,0.72> Confirming will start work immediately. <LINE> "
    elseif willQueue then
        text = text .. " <RGB:0.82,0.82,0.82> Confirming will queue this project. It will wait for materials and/or a builder before work begins. <LINE> "
    end

    self.textPanel:setText(text)
    self.textPanel:paginate()
    if self.confirmLabelOverride and self.confirmLabelOverride ~= "" then
        self.btnConfirm:setTitle(self.confirmLabelOverride)
    else
        self.btnConfirm:setTitle(willStartImmediately and "Start" or "Queue")
    end
    self.btnConfirm.backgroundColor = { r = 0.12, g = 0.42, b = 0.16, a = 1 }
    self.btnConfirm.backgroundColorMouseOver = { r = 0.16, g = 0.56, b = 0.22, a = 1 }
    self.btnConfirm.borderColor = { r = 0.28, g = 0.72, b = 0.34, a = 0.9 }
    self.btnConfirm:setEnable(preview.available == true and (builderState.ready == true or requireBuilder ~= true))
    if self.btnSupplyProject then
        self.btnSupplyProject:setEnable(preview.projectID ~= nil and preview.canStart ~= true)
    end
end
