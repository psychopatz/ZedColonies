DC_Colony = DC_Colony or {}
DC_Colony.Categories = DC_Colony.Categories or {}

local Categories = DC_Colony.Categories

Categories.TagRules = Categories.TagRules or {
    -- Food
    { tag = "Food.NonPerishable.Canned", category = "CannedFood", group = "Food" },
    { tag = "Food.NonPerishable", category = "PreservedFood", group = "Food" },
    { tag = "Food.Perishable.Meat", category = "CookableMeat", group = "Food" },
    { tag = "Food.Perishable.Fish", category = "CookableFish", group = "Food" },
    { tag = "Food.Perishable.Fruit", category = "CookableProduce", group = "Food" },
    { tag = "Food.Perishable.Vegetable", category = "CookableProduce", group = "Food" },
    { tag = "Food.Perishable", category = "RawFood", group = "Food" },
    { tag = "Food.Cooking.Spice", category = "Spice", group = "Food" },
    { tag = "Food.Drink.Alcohol", category = "Alcohol", group = "Food" },
    { tag = "Food.Drink.NonAlcoholic", category = "Drink", group = "Food" },
    { tag = "Food.Intoxicating", category = "Alcohol", group = "Food" },
    { tag = "Food.LowQuality", category = "LowQualityFood", group = "Food" },
    { tag = "Food", category = "RawFood", group = "Food" },

    -- Water / liquid storage
    { tag = "Resource.Water", category = "Water", group = "Water" },
    { tag = "Container.Liquid", category = "LiquidContainer", group = "Storage" },

    -- Power / fuel
    { tag = "Resource.Fuel.Solid", category = "SolidFuel", group = "Power" },
    { tag = "Resource.Fuel.Liquid", category = "LiquidFuel", group = "Power" },
    { tag = "Resource.Fuel.Gas", category = "GasFuel", group = "Power" },
    { tag = "Resource.Fuel", category = "SolidFuel", group = "Power" },
    { tag = "Electronics.Battery", category = "Battery", group = "Power" },
    { tag = "Electronics.PowerGenerator", category = "GeneratorParts", group = "Power" },
    { tag = "Electronics.Generator", category = "GeneratorParts", group = "Power" },
    { tag = "Electronics.PowerSource", category = "PowerSource", group = "Power" },

    -- Materials
    { tag = "Resource.Material.MetalForm.Scrap", category = "ScrapMetal", group = "Material" },
    { tag = "Resource.Material.MetalForm.Ore", category = "MetalOre", group = "Material" },
    { tag = "Resource.Material.MetalForm.Ingot", category = "MetalIngot", group = "Material" },
    { tag = "Resource.Material.MetalFamily.Gold", category = "PreciousMetal", group = "Material" },
    { tag = "Resource.Material.MetalFamily.Silver", category = "PreciousMetal", group = "Material" },
    { tag = "Resource.Material.Metal", category = "Metal", group = "Material" },
    { tag = "Resource.Material.Wood", category = "Wood", group = "Material" },
    { tag = "Resource.Material.Mineral", category = "Stone", group = "Material" },
    { tag = "Resource.Material.Glass", category = "Glass", group = "Material" },
    { tag = "Resource.Material.Textile", category = "Cloth", group = "Material" },
    { tag = "Resource.Material.Leather", category = "Leather", group = "Material" },
    { tag = "Resource.Material.Adhesive", category = "Adhesive", group = "Material" },
    { tag = "Resource.Material.Chemical", category = "Chemical", group = "Material" },
    { tag = "Resource.Material.Hardware", category = "Hardware", group = "Material" },
    { tag = "Resource.Material.Paper", category = "Books", group = "Research" },
    { tag = "Resource.Material", category = "BuildingMaterials", group = "Material" },
    { tag = "Resource.Construction", category = "BuildingMaterials", group = "Material" },
    { tag = "Resource.Parts", category = "ToolParts", group = "Tool" },

    -- Electronics
    { tag = "Electronics.Radio", category = "RadioParts", group = "Electronics" },
    { tag = "Electronics.Communicator", category = "CommunicationEquipment", group = "Electronics" },
    { tag = "Electronics.Transmitter", category = "CommunicationEquipment", group = "Electronics" },
    { tag = "Electronics.LightSource", category = "LightParts", group = "Electronics" },
    { tag = "Electronics.Light", category = "LightParts", group = "Electronics" },
    { tag = "Electronics.Gadget", category = "ElectronicParts", group = "Electronics" },
    { tag = "Electronics.Portable", category = "ElectronicParts", group = "Electronics" },
    { tag = "Electronics.Television", category = "ElectronicParts", group = "Electronics" },
    { tag = "Electronics", category = "ElectronicScrap", group = "Electronics" },

    -- Tools
    { tag = "Tool.Medical.Surgical", category = "SurgicalTools", group = "Tool" },
    { tag = "Tool.Medical", category = "MedicalTools", group = "Tool" },
    { tag = "Tool.Cookware", category = "Cookware", group = "Tool" },
    { tag = "Tool.Farming", category = "FarmingTools", group = "Tool" },
    { tag = "Tool.Fishing", category = "FishingTools", group = "Tool" },
    { tag = "Tool.Crafting", category = "CraftingTools", group = "Tool" },
    { tag = "Tool.Utility", category = "UtilityTools", group = "Tool" },
    { tag = "Tool.Resource.Parts", category = "ToolParts", group = "Tool" },
    { tag = "Tool.General", category = "BasicTools", group = "Tool" },
    { tag = "Tool", category = "BasicTools", group = "Tool" },

    -- Medical
    { tag = "Medical.Healthcare.Botanical", category = "HerbalMedicine", group = "Medical" },
    { tag = "Medical.General.Pills", category = "Pills", group = "Medical" },
    { tag = "Medical.General.Drug", category = "Drugs", group = "Medical" },
    { tag = "Medical.Healthcare", category = "MedicalSupplies", group = "Medical" },
    { tag = "Medical.Consumable", category = "MedicalSupplies", group = "Medical" },
    { tag = "Medical.General", category = "Medicine", group = "Medical" },
    { tag = "Medical", category = "MedicalSupplies", group = "Medical" },

    -- Clothing / storage
    { tag = "Clothing.Armor.Torso", category = "Armor", group = "Clothing" },
    { tag = "Clothing.Armor", category = "Armor", group = "Clothing" },
    { tag = "Clothing.Insulated", category = "InsulatedClothing", group = "Clothing" },
    { tag = "Clothing.Outerwear", category = "Outerwear", group = "Clothing" },
    { tag = "Clothing.Feet", category = "Footwear", group = "Clothing" },
    { tag = "Clothing.Hands", category = "Gloves", group = "Clothing" },
    { tag = "Clothing.Head", category = "Headwear", group = "Clothing" },
    { tag = "Clothing.Face", category = "FaceProtection", group = "Clothing" },
    { tag = "Clothing.Accessory.Jewelry", category = "Jewelry", group = "Clothing" },
    { tag = "Clothing.Accessory", category = "Accessories", group = "Clothing" },
    { tag = "Clothing", category = "BasicClothing", group = "Clothing" },

    { tag = "Container.Bag.Backpack", category = "Backpack", group = "Storage" },
    { tag = "Container.Bag.Duffel", category = "DuffelBag", group = "Storage" },
    { tag = "Container.Bag.Satchel", category = "Satchel", group = "Storage" },
    { tag = "Container.Bag.Cooler", category = "Cooler", group = "Storage" },
    { tag = "Container.Stash.Case", category = "SmallCase", group = "Storage" },
    { tag = "Container.Bag", category = "StorageContainer", group = "Storage" },
    { tag = "Container.General", category = "SupplyCrate", group = "Storage" },
    { tag = "Container", category = "StorageContainer", group = "Storage" },

    -- Defense
    { tag = "Weapon.Melee.Axe", category = "Axes", group = "Defense" },
    { tag = "Weapon.Melee.Blade", category = "BladedWeapons", group = "Defense" },
    { tag = "Weapon.Melee", category = "MeleeWeapons", group = "Defense" },
    { tag = "Weapon.Ranged.Firearm", category = "Firearms", group = "Defense" },
    { tag = "Weapon.Ranged.Ammo", category = "Ammo", group = "Defense" },
    { tag = "Weapon.Ranged", category = "RangedWeapons", group = "Defense" },
    { tag = "Weapon.Explosive", category = "Explosives", group = "Defense" },
    { tag = "Weapon.Part.Accessory", category = "WeaponParts", group = "Defense" },
    { tag = "Weapon.Part", category = "WeaponParts", group = "Defense" },
    { tag = "Weapon", category = "MeleeWeapons", group = "Defense" },

    -- Research / trade
    { tag = "Literature.SkillBook", category = "SkillBooks", group = "Research" },
    { tag = "Literature.Recipe", category = "Schematics", group = "Research" },
    { tag = "Literature.Book", category = "Books", group = "Research" },
    { tag = "Literature.Media", category = "Books", group = "Research" },
    { tag = "Literature", category = "Books", group = "Research" },
    { tag = "Misc.Cosmetic", category = "TradeGoods", group = "Trade" },

    -- Waste
    { tag = "Quality.Waste", category = "Waste", group = "Waste" },
}

return Categories
