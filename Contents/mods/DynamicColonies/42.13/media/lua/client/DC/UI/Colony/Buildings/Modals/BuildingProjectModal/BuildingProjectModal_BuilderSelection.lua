function DC_BuildingProjectModal:refreshBuilderOptions()
    self.builderOptions = DC_BuildingsClientSelectors.GetBuilderOptions()
    self.builderCombo:clear()
    for _, worker in ipairs(self.builderOptions or {}) do
        self.builderCombo:addOption(DC_BuildingsClientSelectors.BuildBuilderLabel(worker, {
            allowedProjectID = self.preview and self.preview.projectID or nil
        }), worker)
    end
    local selectedIndex = self.requireBuilder == true and (#(self.builderOptions or {}) > 0 and 1 or 0) or 0
    local previewProjectID = tostring(self.preview and self.preview.projectID or "")
    local assignedBuilderID = tostring(self.preview and self.preview.assignedBuilderID or "")
    if previewProjectID ~= "" and assignedBuilderID ~= "" then
        for index, worker in ipairs(self.builderOptions or {}) do
            if tostring(worker and worker.workerID or "") == assignedBuilderID then
                selectedIndex = index
                break
            end
        end
    end
    self.builderCombo.selected = selectedIndex
end

function DC_BuildingProjectModal:getSelectedBuilder()
    local index = self.builderCombo and self.builderCombo.selected or 0
    if not index or index <= 0 then
        return nil
    end
    return self.builderOptions[index]
end

function DC_BuildingProjectModal:onBuilderChanged()
    self:updateText()
end
