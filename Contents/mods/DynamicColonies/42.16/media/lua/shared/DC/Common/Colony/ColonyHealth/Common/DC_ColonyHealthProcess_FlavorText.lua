DC_Colony = DC_Colony or {}
DC_Colony.Health = DC_Colony.Health or {}

DC_Colony.Health.ProcessFlavorText = DC_Colony.Health.ProcessFlavorText or {
    selfTreatmentLabels = {
        clean_rag = "clean rag",
        sterilized_rag = "sterilized rag",
        bandage = "bandage",
    },
    selfTreatmentFallbackLabel = "bandage",
    selfTreatmentAppliedMessage = "Applied a %s while resting to recover.",
}

return DC_Colony.Health.ProcessFlavorText