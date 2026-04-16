DC_Colony = DC_Colony or {}
DC_Colony.Companion = DC_Colony.Companion or {}

local Internal = DC_Colony.Companion.Internal

function Internal.GetRegistry()
    return DC_Colony and DC_Colony.Registry or nil
end

function Internal.GetInteraction()
    return DC_Colony and DC_Colony.Interaction or nil
end

function Internal.GetHealth()
    return DC_Colony and DC_Colony.Health or nil
end

function Internal.SaveRegistry()
    local registry = Internal.GetRegistry()
    if registry and registry.Save then
        registry.Save()
    end
end

function Internal.GetRosterRegistry()
    if not DynamicTrading_Roster or not DynamicTrading_Roster.MOD_DATA_KEY then
        return nil
    end
    if not ModData or not ModData.get then
        return nil
    end
    return ModData.get(DynamicTrading_Roster.MOD_DATA_KEY)
end