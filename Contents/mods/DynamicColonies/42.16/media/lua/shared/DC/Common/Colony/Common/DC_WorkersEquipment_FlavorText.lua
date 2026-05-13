DC_Colony = DC_Colony or {}
DC_Colony.Network = DC_Colony.Network or {}

DC_Colony.Network.WorkersEquipmentFlavorText = DC_Colony.Network.WorkersEquipmentFlavorText or {
    workerNotFound = "That worker could not be found.",
    selectedRequirement = "the selected requirement",
    npcInventoryLabel = "NPC inventory",
    warehouseLabel = "warehouse",
    workerCapacityDetail = "NPC inventory does not have enough carry capacity (item weight %s, remaining %s)",
    warehouseCapacityDetail = "warehouse storage does not have enough capacity (item weight %s, remaining %s)",
    workerCapacityRejected = "NPC inventory is full or the item exceeds remaining carry capacity",
    warehouseCapacityRejected = "warehouse storage is full or the item exceeds remaining warehouse capacity",
    brokenRejected = "the selected equipment is broken or unusable",
    notRequiredRejected = "the selected item does not match the %s requirement for this worker",
    missingRejected = "the item is no longer in your inventory",
    genericRejected = "the item was rejected",
    storedVerb = "Stored",
    assignedVerb = "Assigned",
    noEquipmentStored = "No equipment stored",
    noEquipmentAssigned = "No equipment assigned",
    noEquipmentSelected = "No equipment was selected.",
    npcNoSpace = "NPC inventory is full. No space for that equipment.",
    autoEquipped = "Auto-equipped %s warehouse item%s.",
    noMatchingAutoEquip = "No matching warehouse equipment was available for this worker.",
}

return DC_Colony.Network.WorkersEquipmentFlavorText