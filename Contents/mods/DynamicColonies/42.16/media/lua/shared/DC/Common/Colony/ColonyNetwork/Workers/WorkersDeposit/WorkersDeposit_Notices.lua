DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}
DC_Colony.Network.Workers = DC_Colony.Network.Workers or {}

local Nutrition = DC_Colony.Nutrition
local Network = DC_Colony.Network
local Internal = Network.Internal or {}
local Deposit = Network.Workers.Deposit or {}

function Deposit.isRottenProvisionRejection(reason)
    local nutritionInternal = Nutrition and Nutrition.Internal or nil
    return tostring(reason or "") ~= ""
        and nutritionInternal
        and tostring(reason) == tostring(nutritionInternal.ROTTEN_PROVISION_MESSAGE or "")
end

function Deposit.syncRottenProvisionNotice(player, rottenCount)
    local FlavorText = Deposit.FlavorText or {}
    if rottenCount <= 0 then
        return
    end

    Internal.syncNotice(
        player,
        string.format(
            tostring(FlavorText.rottenProvisionRejected or "Rotten items cannot be used as colony provisions. Rejected %s item%s."),
            tostring(rottenCount),
            rottenCount == 1 and "" or "s"
        ),
        "error",
        true
    )
end

return Deposit