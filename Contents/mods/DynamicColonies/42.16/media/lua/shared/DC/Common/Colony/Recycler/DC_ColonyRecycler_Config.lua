DC_Colony = DC_Colony or {}
DC_Colony.Recycler = DC_Colony.Recycler or {}

local Recycler = DC_Colony.Recycler

Recycler.Config = Recycler.Config or {
    BaseRecoveryChance = 0.20,
    RecoveryChancePerCraftingLevel = 0.03,
    MaxRecoveryChance = 0.85,
}

function Recycler.Config.GetRecoveryChance(level)
    local safeLevel = math.max(0, math.min(20, math.floor(tonumber(level) or 0)))
    local base = math.max(0, tonumber(Recycler.Config.BaseRecoveryChance) or 0.20)
    local perLevel = math.max(0, tonumber(Recycler.Config.RecoveryChancePerCraftingLevel) or 0.03)
    local maximum = math.max(base, tonumber(Recycler.Config.MaxRecoveryChance) or 0.85)
    local chance = base + (safeLevel * perLevel)
    if chance > maximum then
        chance = maximum
    end
    if chance < 0 then
        chance = 0
    end
    return chance
end

return Recycler
