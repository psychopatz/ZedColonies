require "DC/UI/Colony/DebugArchive/DebugArchiveRender/DC_DebugArchiveRender_Common"

DC_DebugArchiveSections_Items = DC_DebugArchiveSections_Items or {}

local Render = DC_DebugArchiveRender
local Section = DC_DebugArchiveSections_Items

local function appendLedger(lines, title, ledger)
    Render.AppendSubHeader(lines, title)
    Render.AppendLine(lines, "Stacks", Render.FormatInt(ledger and ledger.stackCount or 0))
    Render.AppendLine(lines, "Items", Render.FormatInt(ledger and ledger.itemCount or 0))
    Render.AppendLine(lines, "Weight", Render.FormatWeight(ledger and ledger.totalWeight or 0))
    if tonumber(ledger and ledger.totalCalories or 0) > 0 then
        Render.AppendLine(lines, "Calories", Render.FormatInt(ledger and ledger.totalCalories or 0))
    end
    if tonumber(ledger and ledger.totalHydration or 0) > 0 then
        Render.AppendLine(lines, "Hydration", Render.FormatInt(ledger and ledger.totalHydration or 0))
    end

    if #(ledger and ledger.entries or {}) <= 0 then
        Render.AppendMuted(lines, "No entries.")
        return
    end

    for _, entry in ipairs(ledger.entries or {}) do
        local suffix = " x" .. Render.FormatInt(entry and entry.count or 0)
        suffix = suffix .. " | " .. Render.FormatWeight(entry and entry.totalWeight or 0)
        if tonumber(entry and entry.totalCalories or 0) > 0 then
            suffix = suffix .. " | " .. Render.FormatInt(entry and entry.totalCalories or 0) .. " cal"
        end
        if tonumber(entry and entry.totalHydration or 0) > 0 then
            suffix = suffix .. " | " .. Render.FormatInt(entry and entry.totalHydration or 0) .. " hyd"
        end
        Render.AppendMuted(lines, tostring(entry and entry.displayName or entry and entry.fullType or "Entry") .. suffix)
    end
end

function Section.Build(window, snapshot)
    local lines = {}
    local warehouse = snapshot and snapshot.warehouse or {}
    local inventory = snapshot and snapshot.abstractInventory or {}

    Render.AppendHeader(lines, "Items And Stock")

    appendLedger(lines, "Warehouse Provisions", warehouse and warehouse.provisions or {})
    appendLedger(lines, "Warehouse Equipment", warehouse and warehouse.equipment or {})
    appendLedger(lines, "Warehouse Legacy Output", warehouse and warehouse.output or {})

    Render.AppendSubHeader(lines, "Abstract Inventory Summary")
    Render.AppendLine(lines, "Categories", Render.FormatInt(inventory and inventory.summary and inventory.summary.totalCategoryCount or 0))
    Render.AppendLine(lines, "Items", Render.FormatInt(inventory and inventory.summary and inventory.summary.totalItemCount or 0))
    Render.AppendLine(lines, "Weight", Render.FormatWeight(inventory and inventory.summary and inventory.summary.totalWeight or 0))
    Render.AppendLine(lines, "Calories", Render.FormatInt(inventory and inventory.summary and inventory.summary.totalCalories or 0))
    Render.AppendLine(lines, "Hydration", Render.FormatInt(inventory and inventory.summary and inventory.summary.totalHydration or 0))

    Render.AppendSubHeader(lines, "Abstract Categories")
    if #(inventory and inventory.rows or {}) <= 0 then
        Render.AppendMuted(lines, "No abstract inventory categories.")
    else
        for _, row in ipairs(inventory.rows or {}) do
            local summary = tostring(row and row.displayName or row and row.category or "Category")
                .. " | Group " .. tostring(row and row.group or "Waste")
                .. " | Qty " .. Render.FormatInt(row and row.count or 0)
                .. " | " .. Render.FormatWeight(row and row.totalWeight or 0)
            if tonumber(row and row.totalCalories or 0) > 0 then
                summary = summary .. " | " .. Render.FormatInt(row and row.totalCalories or 0) .. " cal"
            end
            if tonumber(row and row.totalHydration or 0) > 0 then
                summary = summary .. " | " .. Render.FormatInt(row and row.totalHydration or 0) .. " hyd"
            end
            Render.AppendMuted(lines, summary)
        end
    end

    Render.AppendSubHeader(lines, "Literal Special Stock")
    if #(inventory and inventory.literalSpecialEntries or {}) <= 0 then
        Render.AppendMuted(lines, "No literal special stock.")
    else
        for _, entry in ipairs(inventory.literalSpecialEntries or {}) do
            local summary = tostring(entry and entry.displayName or entry and entry.fullType or "Special")
                .. " x" .. Render.FormatInt(entry and entry.qty or 0)
                .. " | " .. Render.FormatWeight(entry and entry.totalWeight or 0)
            if tostring(entry and entry.specialStockType or "") ~= "" then
                summary = summary .. " | " .. tostring(entry and entry.specialStockType or "")
            end
            Render.AppendMuted(lines, summary)
        end
    end

    return table.concat(lines)
end

return Section
