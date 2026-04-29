-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dc_surveyor",
--   "module": "DynamicColonies",
--   "title": "Surveyor's Planning",
--   "description": "Notes on plotting structures, resource recipes, and power",
--   "start_page_id": "building_projects",
--   "audiences": [
--     "DynamicColonies"
--   ],
--   "sort_order": 200000,
--   "release_version": "",
--   "popup_version": "",
--   "auto_open_on_update": false,
--   "is_whats_new": false,
--   "manual_type": "manual",
--   "show_in_library": true,
--   "support_url": "",
--   "banner_title": "",
--   "banner_text": "",
--   "banner_action_label": "",
--   "source_folder": "DynamicColonies",
--   "chapters": [
--     {
--       "id": "construction_logistics",
--       "title": "Structural Planning",
--       "description": "Managing building projects, work points, and material recipes."
--     },
--     {
--       "id": "energy_infrastructure",
--       "title": "Power & Logistics",
--       "description": "Fueling the colony and managing energy consumption."
--     }
--   ],
--   "pages": [
--     {
--       "id": "building_projects",
--       "chapter_id": "construction_logistics",
--       "title": "Projects & Progress",
--       "keywords": [
--         "projects",
--         "construction",
--         "work",
--         "points",
--         "builder"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "building-the-foundation",
--           "level": 1,
--           "text": "Raising the Walls"
--         },
--         {
--           "type": "paragraph",
--           "text": "Construction in a colony isn't an instant process. Every 'Building Project' requires two things: raw materials (Recipes) and labor (Work Points). Once a project is queued at a plot, your assigned Builders will begin investing their hourly effort into the structure."
--         },
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Surveyor's Tip",
--           "text": "Better tools and high construction skills allow workers to generate more Work Points per hour, significantly reducing the time required to finish complex structures like Infirmaries or Workshops."
--         }
--       ]
--     },
--     {
--       "id": "material_recipes",
--       "chapter_id": "construction_logistics",
--       "title": "Resource Recipes",
--       "keywords": [
--         "materials",
--         "recipes",
--         "stalled",
--         "warehouse"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "stalled-projects",
--           "level": 1,
--           "text": "The Material Check"
--         },
--         {
--           "type": "paragraph",
--           "text": "A project will 'Stall' if the required materials aren't available in your Warehouse. Your Scavengers must constantly keep the bins full of planks, nails, and specialized hardware. If a project is stalled, your Builders will remain idle until the supplies arrive."
--         }
--       ]
--     },
--     {
--       "id": "energy_grid",
--       "chapter_id": "energy_infrastructure",
--       "title": "Powering the Colony",
--       "keywords": [
--         "energy",
--         "fuel",
--         "power",
--         "grid",
--         "consumption"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "the-energy-grid",
--           "level": 1,
--           "text": "Fueling Civilization"
--         },
--         {
--           "type": "paragraph",
--           "text": "Advanced buildings—like refrigerated warehouses and illuminated barracks—require 'Energy'. This is provided by your global fuel reserve. If your fuel runs dry, these structures will lose their effectiveness, impacting everything from food preservation to worker morale."
--         },
--         {
--           "type": "image",
--           "path": "media/ui/Backgrounds/sunrise.png",
--           "caption": "Keep the generators humming.",
--           "width": 400,
--           "height": 200,
--           "keep_aspect_ratio": true,
--           "aspect_ratio": 2.0
--         },
--         {
--           "type": "callout",
--           "tone": "warn",
--           "title": "Field Note",
--           "text": "High-tier structures consume more fuel. Monitor your hourly consumption rate in the Logistics tab to avoid a dark, starving colony."
--         }
--       ]
--     }
--   ]
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dc_surveyor", {
        title = "Surveyor's Planning",
        description = "Notes on plotting structures, resource recipes, and power",
        startPageId = "building_projects",
        audiences = { "DynamicColonies" },
        sortOrder = 200000,
        releaseVersion = "",
        popupVersion = "",
        autoOpenOnUpdate = false,
        isWhatsNew = false,
        manualType = "manual",
        showInLibrary = true,
        supportUrl = "",
        bannerTitle = "",
        bannerText = "",
        bannerActionLabel = "",
        chapters = {
            {
                id = "construction_logistics",
                title = "Structural Planning",
                description = "Managing building projects, work points, and material recipes.",
            },
            {
                id = "energy_infrastructure",
                title = "Power & Logistics",
                description = "Fueling the colony and managing energy consumption.",
            },
        },
        pages = {
            {
                id = "building_projects",
                chapterId = "construction_logistics",
                title = "Projects & Progress",
                keywords = { "projects", "construction", "work", "points", "builder" },
                blocks = {
                    { type = "heading", id = "building-the-foundation", level = 1, text = "Raising the Walls" },
                    { type = "paragraph", text = "Construction in a colony isn't an instant process. Every 'Building Project' requires two things: raw materials (Recipes) and labor (Work Points). Once a project is queued at a plot, your assigned Builders will begin investing their hourly effort into the structure." },
                    { type = "callout", tone = "info", title = "Surveyor's Tip", text = "Better tools and high construction skills allow workers to generate more Work Points per hour, significantly reducing the time required to finish complex structures like Infirmaries or Workshops." },
                },
            },
            {
                id = "material_recipes",
                chapterId = "construction_logistics",
                title = "Resource Recipes",
                keywords = { "materials", "recipes", "stalled", "warehouse" },
                blocks = {
                    { type = "heading", id = "stalled-projects", level = 1, text = "The Material Check" },
                    { type = "paragraph", text = "A project will 'Stall' if the required materials aren't available in your Warehouse. Your Scavengers must constantly keep the bins full of planks, nails, and specialized hardware. If a project is stalled, your Builders will remain idle until the supplies arrive." },
                },
            },
            {
                id = "energy_grid",
                chapterId = "energy_infrastructure",
                title = "Powering the Colony",
                keywords = { "energy", "fuel", "power", "grid", "consumption" },
                blocks = {
                    { type = "heading", id = "the-energy-grid", level = 1, text = "Fueling Civilization" },
                    { type = "paragraph", text = "Advanced buildings—like refrigerated warehouses and illuminated barracks—require 'Energy'. This is provided by your global fuel reserve. If your fuel runs dry, these structures will lose their effectiveness, impacting everything from food preservation to worker morale." },
                    { type = "image", path = "media/ui/Backgrounds/sunrise.png", caption = "Keep the generators humming.", width = 400, height = 200 },
                    { type = "callout", tone = "warn", title = "Field Note", text = "High-tier structures consume more fuel. Monitor your hourly consumption rate in the Logistics tab to avoid a dark, starving colony." },
                },
            },
        },
    })
end
