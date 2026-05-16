DC_Buildings = DC_Buildings or {}
DC_Buildings.Production = DC_Buildings.Production or {}

local Production = DC_Buildings.Production

Production.Config = Production.Config or {
    IntervalHours = 1,
    MaxCyclesPerPass = 4,
}

Production.Config.ColonyProductionStations = Production.Config.ColonyProductionStations or {
    FabricationBench = {
        "Resource.Craftable",
        "Resource.Material.General",
        "Tool.Crafting",
        "Tool.Utility",
    },
    Forge = {
        "Resource.Material.Metal",
        "Resource.Material.MetalForm.Ingot",
        "Resource.Material.MetalForm.Ore",
        "Resource.Material.MetalForm.Scrap",
        "Resource.Material.Hardware",
    },
    Cookhouse = {
        "Food.Cooking",
        "Food.Drink",
        "Food.NonPerishable",
        "Food.Perishable",
        "Tool.Cookware",
        "Container.Liquid",
    },
    TextileRoom = {
        "Clothing",
        "Resource.Material.Textile",
        "Resource.Material.Leather",
        "Container.Bag",
    },
    Woodshop = {
        "Resource.Material.Wood",
        "Tool.Durable",
        "Container.General",
    },
    Infirmary = {
        "Medical.Consumable",
        "Medical.Healthcare",
        "Medical.Healthcare.Botanical",
        "Tool.Medical",
        "Tool.Medical.Surgical",
    },
    TinkerBench = {
        "Electronics.Battery",
        "Electronics.PowerSource",
        "Electronics.Radio",
        "Electronics.Generator",
        "Electronics.LightSource",
        "Electronics.Gadget",
    },
    Armory = {
        "Weapon.Melee",
        "Weapon.Ranged.Ammo",
        "Weapon.Ranged.Firearm",
        "Weapon.Part.Accessory",
        "Weapon.Explosive",
        "Resource.Material.Chemical",
    },
    ProvisionYard = {
        "Tool.Farming",
        "Tool.Fishing",
        "Resource.Fishing",
        "Food.Perishable.Fish",
        "Food.Perishable.Vegetable",
        "Food.Perishable.Fruit",
    },
    FuelDepot = {
        "Resource.Fuel",
        "Resource.Fuel.Gas",
        "Resource.Fuel.Liquid",
        "Resource.Fuel.Solid",
    },
}

return Production
