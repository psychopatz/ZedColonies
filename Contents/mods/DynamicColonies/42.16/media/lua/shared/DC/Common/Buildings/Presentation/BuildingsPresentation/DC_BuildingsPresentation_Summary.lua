DC_Buildings = DC_Buildings or {}
DC_Buildings.Internal = DC_Buildings.Internal or {}

local Buildings = DC_Buildings
local Presentation = Buildings.Internal.Presentation or {}
local modules = Presentation.Modules or {}
local helpers = Presentation.Helpers or {}

Buildings.Internal.Presentation = Presentation
Presentation.Modules = modules
Presentation.Helpers = helpers

if modules.Summary then
    return
end

modules.Summary = true

function Buildings.GetOwnerSummary(ownerUsername)
    local snapshot = Buildings.BuildOwnerSnapshot(ownerUsername)
    return {
        ownerUsername = snapshot.ownerUsername,
        housing = helpers.ShallowCopy(snapshot.housing),
        medical = helpers.ShallowCopy(snapshot.medical),
        activeProjectCount = #snapshot.activeProjects,
        buildingCounts = (function()
            local counts = {}
            for _, entry in ipairs(snapshot.buildings or {}) do
                counts[entry.buildingType] = entry.currentCount
            end
            return counts
        end)()
    }
end
