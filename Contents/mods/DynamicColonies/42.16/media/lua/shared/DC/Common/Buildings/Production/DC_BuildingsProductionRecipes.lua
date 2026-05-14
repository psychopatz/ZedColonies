DC_Buildings = DC_Buildings or {}
DC_Buildings.Production = DC_Buildings.Production or {}

local Production = DC_Buildings.Production

Production.Recipes = Production.Recipes or {
    Kitchen = {
        {
            id = "cook_meal",
            requiredLevel = 1,
            inputs = {
                { category = "CookableMeat", count = 1 },
                { category = "CookableProduce", count = 1 },
                { category = "Water", count = 1 },
            },
            outputs = {
                { category = "Meal", count = 2 },
            }
        },
        {
            id = "cook_fine_meal",
            requiredLevel = 1,
            inputs = {
                { category = "Meal", count = 1 },
                { category = "Spice", count = 1 },
            },
            outputs = {
                { category = "FineMeal", count = 1 },
            }
        },
        {
            id = "emergency_rations",
            requiredLevel = 1,
            inputs = {
                { category = "PreservedFood", count = 1 },
            },
            outputs = {
                { category = "EmergencyRation", count = 1 },
            }
        }
    },
    Greenhouse = {
        {
            id = "grow_produce",
            requiredLevel = 1,
            inputs = {
                { category = "Water", count = 1 },
                { category = "OrganicWaste", count = 1 },
            },
            outputs = {
                { category = "CookableProduce", count = 2 },
            }
        },
        {
            id = "grow_herbs",
            requiredLevel = 1,
            inputs = {
                { category = "Water", count = 1 },
            },
            outputs = {
                { category = "HerbalMedicine", count = 1 },
                { category = "OrganicWaste", count = 1 },
            }
        }
    },
    Infirmary = {
        {
            id = "sterile_supplies",
            requiredLevel = 1,
            inputs = {
                { category = "Cloth", count = 1 },
                { category = "Alcohol", count = 1 },
            },
            outputs = {
                { category = "SterileSupplies", count = 1 },
            }
        },
        {
            id = "treatment_kits",
            requiredLevel = 1,
            inputs = {
                { category = "MedicalSupplies", count = 1 },
                { category = "SterileSupplies", count = 1 },
                { category = "Water", count = 1 },
            },
            outputs = {
                { category = "TreatmentKit", count = 1 },
            }
        }
    },
    Workshop = {
        {
            id = "refine_metal",
            requiredLevel = 1,
            inputs = {
                { category = "ScrapMetal", count = 2 },
            },
            outputs = {
                { category = "Metal", count = 1 },
            }
        },
        {
            id = "recover_electronics",
            requiredLevel = 1,
            inputs = {
                { category = "ElectronicScrap", count = 2 },
            },
            outputs = {
                { category = "ElectronicParts", count = 1 },
            }
        },
        {
            id = "pack_materials",
            requiredLevel = 1,
            inputs = {
                { category = "Wood", count = 2 },
                { category = "Hardware", count = 1 },
            },
            outputs = {
                { category = "BuildingMaterials", count = 2 },
            }
        }
    },
    Armory = {
        {
            id = "assemble_defense_gear",
            requiredLevel = 1,
            inputs = {
                { category = "WeaponParts", count = 1 },
                { category = "Metal", count = 1 },
                { category = "Cloth", count = 1 },
            },
            outputs = {
                { category = "DefenseGear", count = 1 },
            }
        }
    },
    ElectricityGenerator = {
        {
            id = "burn_solid_fuel",
            requiredLevel = 1,
            inputs = {
                { category = "SolidFuel", count = 1 },
                { category = "GeneratorParts", count = 1 },
            },
            outputs = {
                { category = "StoredPower", count = 2 },
            }
        }
    },
    Laboratory = {
        {
            id = "advanced_electronics",
            requiredLevel = 1,
            inputs = {
                { category = "Chemical", count = 1 },
                { category = "ElectronicParts", count = 2 },
            },
            outputs = {
                { category = "AdvancedElectronics", count = 1 },
                { category = "ResearchData", count = 1 },
            }
        },
        {
            id = "compound_medicine",
            requiredLevel = 1,
            inputs = {
                { category = "HerbalMedicine", count = 1 },
                { category = "Chemical", count = 1 },
            },
            outputs = {
                { category = "Medicine", count = 1 },
            }
        }
    },
    TradeStand = {
        {
            id = "sell_trade_goods",
            requiredLevel = 1,
            inputs = {
                { category = "TradeGoods", count = 1 },
            },
            outputs = {
                { category = "Currency", count = 1 },
            }
        }
    }
}

function Production.GetRecipesForBuilding(buildingType)
    return Production.Recipes[tostring(buildingType or "")] or {}
end

return Production
