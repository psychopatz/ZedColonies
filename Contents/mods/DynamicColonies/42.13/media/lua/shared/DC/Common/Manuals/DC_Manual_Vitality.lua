-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dc_vitality",
--   "title": "Colony Vitality & Needs",
--   "description": "A medical officer's briefing on caloric intake, medical priority plans, and managing faction attrition.",
--   "start_page_id": "nutrition_survival",
--   "chapters": [
--     { "id": "metabolic_needs", "title": "Health & Nutrition", "description": "Managing calories, hydration, and the impact of starvation." },
--     { "id": "medical_logistics", "title": "Medical Care & Priority", "description": "Setting priority plans and managing colony-wide health." }
--   ],
--   "pages": [
--     {
--       "id": "nutrition_survival",
--       "chapter_id": "metabolic_needs",
--       "title": "Feeding the Group",
--       "keywords": ["nutrition", "calories", "hydration", "starvation", "thirst"],
--       "blocks": [
--         { "type": "heading", "id": "nutritional-baseline", "level": 1, "text": "The Metabolic Cost" },
--         { "type": "paragraph", "text": "Every worker in your colony has a metabolic baseline. They require 'Calories' and 'Hydration' to remain effective. If a worker goes for more than 24 hours without a meal, they'll begin to suffer from Starvation, which severely impacts their work speed and eventually leads to a loss of health." },
--         { "type": "callout", "tone": "info", "title": "Medical Note", "text": "High-intensity jobs (like Building or Scavenging) burn calories faster. Ensure your warehouse is stocked with nutrient-dense foods to keep the simulation running smoothly." }
--       ]
--     },
--     {
--       "id": "attrition_warning",
--       "chapter_id": "metabolic_needs",
--       "title": "The Threat of Attrition",
--       "keywords": ["attrition", "death", "stockpiles", "neglect"],
--       "blocks": [
--         { "type": "heading", "id": "attrition-mechanics", "level": 1, "text": "The Human Cost of Neglect" },
--         { "type": "paragraph", "text": "If a faction's total stockpiles hit zero, 'Attrition' sets in. This isn't just one person going hungry; it's a systemic failure. Members will randomly begin to die off every few hours until the supplies are restored. Monitoring your 'Logistics' tab is the only way to prevent a total colony collapse." },
--         { "type": "image", "path": "media/ui/Icon_MarketInfo.png", "caption": "Red stockpiles mean death is coming.", "width": 64, "height": 64 }
--       ]
--     },
--     {
--       "id": "medical_planning",
--       "chapter_id": "medical_logistics",
--       "title": "Priority Care",
--       "keywords": ["medical", "plans", "priority", "doctors", "healing"],
--       "blocks": [
--         { "type": "heading", "id": "medical-priority-plans", "level": 1, "text": "Triage & Treatment" },
--         { "type": "paragraph", "text": "When space and medicine are limited, you must choose who lives. 'Medical Priority Plans' allow you to designate which workers receive care first. Your colony's Doctors will follow these plans during each simulation cycle, applying bandages and medication based on your settings." },
--         { "type": "callout", "tone": "warn", "title": "Field Note", "text": "Healing takes time and resources. A worker on 'Forced Rest' will recover faster but won't contribute to projects or scavenging until they're back on their feet." }
--       ]
--     }
--   ]
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dc_vitality", {
        title = "Colony Vitality & Needs",
        description = "A medical officer's briefing on caloric intake, medical priority plans, and managing faction attrition.",
        startPageId = "nutrition_survival",
        chapters = {
            { id = "metabolic_needs", title = "Health & Nutrition", description = "Managing calories, hydration, and the impact of starvation." },
            { id = "medical_logistics", title = "Medical Care & Priority", description = "Setting priority plans and managing colony-wide health." },
        },
        pages = {
            {
                id = "nutrition_survival",
                chapterId = "metabolic_needs",
                title = "Feeding the Group",
                keywords = { "nutrition", "calories", "hydration", "starvation", "thirst" },
                blocks = {
                    { type = "heading", id = "nutritional-baseline", level = 1, text = "The Metabolic Cost" },
                    { type = "paragraph", text = "Every worker in your colony has a metabolic baseline. They require 'Calories' and 'Hydration' to remain effective. If a worker goes for more than 24 hours without a meal, they'll begin to suffer from Starvation, which severely impacts their work speed and eventually leads to a loss of health." },
                    { type = "callout", tone = "info", title = "Medical Note", text = "High-intensity jobs (like Building or Scavenging) burn calories faster. Ensure your warehouse is stocked with nutrient-dense foods to keep the simulation running smoothly." },
                },
            },
            {
                id = "attrition_warning",
                chapterId = "metabolic_needs",
                title = "The Threat of Attrition",
                keywords = { "attrition", "death", "stockpiles", "neglect" },
                blocks = {
                    { type = "heading", id = "attrition-mechanics", level = 1, text = "The Human Cost of Neglect" },
                    { type = "paragraph", text = "If a faction's total stockpiles hit zero, 'Attrition' sets in. This isn't just one person going hungry; it's a systemic failure. Members will randomly begin to die off every few hours until the supplies are restored. Monitoring your 'Logistics' tab is the only way to prevent a total colony collapse." },
                    { type = "image", path = "media/ui/Icon_MarketInfo.png", caption = "Red stockpiles mean death is coming.", width = 64, height = 64 },
                },
            },
            {
                id = "medical_planning",
                chapterId = "medical_logistics",
                title = "Priority Care",
                keywords = { "medical", "plans", "priority", "doctors", "healing" },
                blocks = {
                    { type = "heading", id = "medical-priority-plans", level = 1, text = "Triage & Treatment" },
                    { type = "paragraph", text = "When space and medicine are limited, you must choose who lives. 'Medical Priority Plans' allow you to designate which workers receive care first. Your colony's Doctors will follow these plans during each simulation cycle, applying bandages and medication based on your settings." },
                    { type = "callout", tone = "warn", title = "Field Note", text = "Healing takes time and resources. A worker on 'Forced Rest' will recover faster but won't contribute to projects or scavenging until they're back on their feet." },
                },
            },
        },
    })
end
