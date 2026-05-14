DC_Colony = DC_Colony or {}
DC_Colony.Categories = DC_Colony.Categories or {}
DC_Colony.Categories.Internal = DC_Colony.Categories.Internal or {}

local Categories = DC_Colony.Categories

local function addCategory(registry, id, group, displayName)
    registry[id] = {
        id = tostring(id or ""),
        group = tostring(group or "Waste"),
        displayName = tostring(displayName or id or "Unknown"),
    }
end

Categories.Groups = Categories.Groups or {
    Food = "Food",
    Water = "Water",
    Power = "Power",
    Material = "Material",
    Electronics = "Electronics",
    Tool = "Tool",
    Medical = "Medical",
    Clothing = "Clothing",
    Storage = "Storage",
    Defense = "Defense",
    Research = "Research",
    Trade = "Trade",
    Waste = "Waste",
}

local registry = {}

-- Food
addCategory(registry, "RawFood", "Food", "Raw Food")
addCategory(registry, "CookableMeat", "Food", "Cookable Meat")
addCategory(registry, "CookableFish", "Food", "Cookable Fish")
addCategory(registry, "CookableProduce", "Food", "Cookable Produce")
addCategory(registry, "PreservedFood", "Food", "Preserved Food")
addCategory(registry, "CannedFood", "Food", "Canned Food")
addCategory(registry, "LowQualityFood", "Food", "Low Quality Food")
addCategory(registry, "UnsafeFood", "Food", "Unsafe Food")
addCategory(registry, "Spice", "Food", "Spice")
addCategory(registry, "Meal", "Food", "Meal")
addCategory(registry, "FineMeal", "Food", "Fine Meal")
addCategory(registry, "EmergencyRation", "Food", "Emergency Ration")
addCategory(registry, "AnimalFeed", "Food", "Animal Feed")
addCategory(registry, "Drink", "Food", "Drink")
addCategory(registry, "Alcohol", "Food", "Alcohol")

-- Water
addCategory(registry, "Water", "Water", "Water")
addCategory(registry, "TaintedWater", "Water", "Tainted Water")
addCategory(registry, "WaterContainer", "Water", "Water Container")
addCategory(registry, "WaterFilter", "Water", "Water Filter")

-- Materials
addCategory(registry, "Wood", "Material", "Wood")
addCategory(registry, "Stone", "Material", "Stone")
addCategory(registry, "Glass", "Material", "Glass")
addCategory(registry, "Cloth", "Material", "Cloth")
addCategory(registry, "Leather", "Material", "Leather")
addCategory(registry, "Adhesive", "Material", "Adhesive")
addCategory(registry, "Chemical", "Material", "Chemical")
addCategory(registry, "Hardware", "Material", "Hardware")
addCategory(registry, "ScrapMetal", "Material", "Scrap Metal")
addCategory(registry, "Metal", "Material", "Metal")
addCategory(registry, "MetalOre", "Material", "Metal Ore")
addCategory(registry, "MetalIngot", "Material", "Metal Ingot")
addCategory(registry, "PreciousMetal", "Material", "Precious Metal")
addCategory(registry, "BuildingMaterials", "Material", "Building Materials")

-- Power
addCategory(registry, "SolidFuel", "Power", "Solid Fuel")
addCategory(registry, "LiquidFuel", "Power", "Liquid Fuel")
addCategory(registry, "GasFuel", "Power", "Gas Fuel")
addCategory(registry, "Battery", "Power", "Battery")
addCategory(registry, "PowerSource", "Power", "Power Source")
addCategory(registry, "GeneratorParts", "Power", "Generator Parts")
addCategory(registry, "StoredPower", "Power", "Stored Power")

-- Electronics
addCategory(registry, "ElectronicScrap", "Electronics", "Electronic Scrap")
addCategory(registry, "ElectronicParts", "Electronics", "Electronic Parts")
addCategory(registry, "RadioParts", "Electronics", "Radio Parts")
addCategory(registry, "CommunicationEquipment", "Electronics", "Communication Equipment")
addCategory(registry, "LightParts", "Electronics", "Light Parts")
addCategory(registry, "PowerParts", "Electronics", "Power Parts")
addCategory(registry, "AdvancedElectronics", "Electronics", "Advanced Electronics")

-- Tools
addCategory(registry, "BasicTools", "Tool", "Basic Tools")
addCategory(registry, "CraftingTools", "Tool", "Crafting Tools")
addCategory(registry, "FarmingTools", "Tool", "Farming Tools")
addCategory(registry, "FishingTools", "Tool", "Fishing Tools")
addCategory(registry, "Cookware", "Tool", "Cookware")
addCategory(registry, "MedicalTools", "Tool", "Medical Tools")
addCategory(registry, "SurgicalTools", "Tool", "Surgical Tools")
addCategory(registry, "UtilityTools", "Tool", "Utility Tools")
addCategory(registry, "ToolParts", "Tool", "Tool Parts")

-- Medical
addCategory(registry, "MedicalSupplies", "Medical", "Medical Supplies")
addCategory(registry, "Medicine", "Medical", "Medicine")
addCategory(registry, "Drugs", "Medical", "Drugs")
addCategory(registry, "Pills", "Medical", "Pills")
addCategory(registry, "HerbalMedicine", "Medical", "Herbal Medicine")
addCategory(registry, "SterileSupplies", "Medical", "Sterile Supplies")
addCategory(registry, "TreatmentKit", "Medical", "Treatment Kit")
addCategory(registry, "SurgicalKit", "Medical", "Surgical Kit")

-- Clothing
addCategory(registry, "BasicClothing", "Clothing", "Basic Clothing")
addCategory(registry, "InsulatedClothing", "Clothing", "Insulated Clothing")
addCategory(registry, "Outerwear", "Clothing", "Outerwear")
addCategory(registry, "Footwear", "Clothing", "Footwear")
addCategory(registry, "Gloves", "Clothing", "Gloves")
addCategory(registry, "Headwear", "Clothing", "Headwear")
addCategory(registry, "FaceProtection", "Clothing", "Face Protection")
addCategory(registry, "Armor", "Clothing", "Armor")
addCategory(registry, "Accessories", "Clothing", "Accessories")
addCategory(registry, "Jewelry", "Clothing", "Jewelry")

-- Storage
addCategory(registry, "StorageContainer", "Storage", "Storage Container")
addCategory(registry, "Backpack", "Storage", "Backpack")
addCategory(registry, "DuffelBag", "Storage", "Duffel Bag")
addCategory(registry, "Satchel", "Storage", "Satchel")
addCategory(registry, "Cooler", "Storage", "Cooler")
addCategory(registry, "LiquidContainer", "Storage", "Liquid Container")
addCategory(registry, "SmallCase", "Storage", "Small Case")
addCategory(registry, "SupplyCrate", "Storage", "Supply Crate")

-- Defense
addCategory(registry, "MeleeWeapons", "Defense", "Melee Weapons")
addCategory(registry, "Axes", "Defense", "Axes")
addCategory(registry, "BladedWeapons", "Defense", "Bladed Weapons")
addCategory(registry, "RangedWeapons", "Defense", "Ranged Weapons")
addCategory(registry, "Firearms", "Defense", "Firearms")
addCategory(registry, "Ammo", "Defense", "Ammo")
addCategory(registry, "Explosives", "Defense", "Explosives")
addCategory(registry, "WeaponParts", "Defense", "Weapon Parts")
addCategory(registry, "DefenseGear", "Defense", "Defense Gear")

-- Research / trade
addCategory(registry, "Books", "Research", "Books")
addCategory(registry, "SkillBooks", "Research", "Skill Books")
addCategory(registry, "Schematics", "Research", "Schematics")
addCategory(registry, "ResearchData", "Research", "Research Data")
addCategory(registry, "Blueprints", "Research", "Blueprints")
addCategory(registry, "TradeGoods", "Trade", "Trade Goods")
addCategory(registry, "LuxuryGoods", "Trade", "Luxury Goods")
addCategory(registry, "RareGoods", "Trade", "Rare Goods")
addCategory(registry, "LegendaryGoods", "Trade", "Legendary Goods")
addCategory(registry, "RecreationGoods", "Trade", "Recreation Goods")
addCategory(registry, "Currency", "Trade", "Currency")

-- Waste / special
addCategory(registry, "Junk", "Waste", "Junk")
addCategory(registry, "Waste", "Waste", "Waste")
addCategory(registry, "OrganicWaste", "Waste", "Organic Waste")
addCategory(registry, "RottenFood", "Waste", "Rotten Food")
addCategory(registry, "Corpse", "Waste", "Corpse")
addCategory(registry, "Recyclables", "Waste", "Recyclables")
addCategory(registry, "ContaminatedMaterial", "Waste", "Contaminated Material")
addCategory(registry, "QuestGoods", "Waste", "Quest Goods")

Categories.Registry = Categories.Registry or registry

function Categories.Get(categoryId)
    return Categories.Registry[tostring(categoryId or "")]
end

return Categories
