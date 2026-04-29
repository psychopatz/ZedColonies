-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dc_founders",
--   "module": "DynamicColonies",
--   "title": "Founder's Handbook",
--   "description": "Guide to establishing your site, recruiting labor, and t",
--   "start_page_id": "founding_intro",
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
--       "id": "site_management",
--       "title": "Establishing a Site",
--       "description": "Finding the right ground and claiming it for your people."
--     },
--     {
--       "id": "roster_jobs",
--       "title": "Managing the Roster",
--       "description": "Assigning roles and overseeing the daily simulation cycle."
--     }
--   ],
--   "pages": [
--     {
--       "id": "founding_intro",
--       "chapter_id": "site_management",
--       "title": "The First Stake",
--       "keywords": [
--         "founding",
--         "colony",
--         "site",
--         "hq",
--         "headquarters"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "founding-your-colony",
--           "level": 1,
--           "text": "Claiming the Exclusion Zone"
--         },
--         {
--           "type": "paragraph",
--           "text": "A colony isn't just a group of tents; it's a statement of survival. Every colony begins with a 'Headquarters' (HQ). This central hub acts as the anchor for your expansion, providing a secure location for your warehouse and a gathering point for your workers."
--         },
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Founder's Tip",
--           "text": "The first HQ project is free, but choose your location wisely. You'll need nearby resources and defensible terrain to thrive in the long run."
--         }
--       ]
--     },
--     {
--       "id": "site_expansion",
--       "chapter_id": "site_management",
--       "title": "Expansion Plots",
--       "keywords": [
--         "plots",
--         "expansion",
--         "growth",
--         "territory"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "territorial-growth",
--           "level": 1,
--           "text": "Mapping Your Success"
--         },
--         {
--           "type": "paragraph",
--           "text": "As your influence grows, you'll need more space. Your colony is divided into 'Plots'—specific zones where you can construct specialized buildings. Expanding your perimeter requires both materials and the labor of your founder."
--         },
--         {
--           "type": "image",
--           "path": "media/ui/Backgrounds/sunrise.png",
--           "caption": "Plan your plots to maximize efficiency.",
--           "width": 400,
--           "height": 200,
--           "keep_aspect_ratio": true,
--           "aspect_ratio": 2.0
--         }
--       ]
--     },
--     {
--       "id": "job_assignments",
--       "chapter_id": "roster_jobs",
--       "title": "Labor & Logistics",
--       "keywords": [
--         "jobs",
--         "labor",
--         "assignment",
--         "builder",
--         "scavenger",
--         "doctor"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "putting-them-to-work",
--           "level": 1,
--           "text": "Roles of the Roster"
--         },
--         {
--           "type": "paragraph",
--           "text": "Your colony is only as strong as its workers. Each individual can be assigned a specific 'Job Profile'—from Builders who raise structures to Scavengers who bring in raw supplies. When assigned a task, they'll work through the 'Simulation Cycle' each hour, consuming resources and gaining experience."
--         },
--         {
--           "type": "bullet_list",
--           "items": [
--             "Builders: Essential for construction projects and structural repairs.",
--             "Scavengers: The lifeblood of your warehouse, bringing in food and materials from the field.",
--             "Doctors: Critical for maintaining colony health and managing medical priority plans."
--           ]
--         },
--         {
--           "type": "callout",
--           "tone": "warn",
--           "title": "Field Note",
--           "text": "An unemployed worker is a wasted resource. Always ensure your roster has active assignments to keep the simulation moving forward."
--         }
--       ]
--     }
--   ]
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dc_founders", {
        title = "Founder's Handbook",
        description = "Guide to establishing your site, recruiting labor, and t",
        startPageId = "founding_intro",
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
                id = "site_management",
                title = "Establishing a Site",
                description = "Finding the right ground and claiming it for your people.",
            },
            {
                id = "roster_jobs",
                title = "Managing the Roster",
                description = "Assigning roles and overseeing the daily simulation cycle.",
            },
        },
        pages = {
            {
                id = "founding_intro",
                chapterId = "site_management",
                title = "The First Stake",
                keywords = { "founding", "colony", "site", "hq", "headquarters" },
                blocks = {
                    { type = "heading", id = "founding-your-colony", level = 1, text = "Claiming the Exclusion Zone" },
                    { type = "paragraph", text = "A colony isn't just a group of tents; it's a statement of survival. Every colony begins with a 'Headquarters' (HQ). This central hub acts as the anchor for your expansion, providing a secure location for your warehouse and a gathering point for your workers." },
                    { type = "callout", tone = "info", title = "Founder's Tip", text = "The first HQ project is free, but choose your location wisely. You'll need nearby resources and defensible terrain to thrive in the long run." },
                },
            },
            {
                id = "site_expansion",
                chapterId = "site_management",
                title = "Expansion Plots",
                keywords = { "plots", "expansion", "growth", "territory" },
                blocks = {
                    { type = "heading", id = "territorial-growth", level = 1, text = "Mapping Your Success" },
                    { type = "paragraph", text = "As your influence grows, you'll need more space. Your colony is divided into 'Plots'—specific zones where you can construct specialized buildings. Expanding your perimeter requires both materials and the labor of your founder." },
                    { type = "image", path = "media/ui/Backgrounds/sunrise.png", caption = "Plan your plots to maximize efficiency.", width = 400, height = 200 },
                },
            },
            {
                id = "job_assignments",
                chapterId = "roster_jobs",
                title = "Labor & Logistics",
                keywords = { "jobs", "labor", "assignment", "builder", "scavenger", "doctor" },
                blocks = {
                    { type = "heading", id = "putting-them-to-work", level = 1, text = "Roles of the Roster" },
                    { type = "paragraph", text = "Your colony is only as strong as its workers. Each individual can be assigned a specific 'Job Profile'—from Builders who raise structures to Scavengers who bring in raw supplies. When assigned a task, they'll work through the 'Simulation Cycle' each hour, consuming resources and gaining experience." },
                    { type = "bullet_list", items = { "Builders: Essential for construction projects and structural repairs.", "Scavengers: The lifeblood of your warehouse, bringing in food and materials from the field.", "Doctors: Critical for maintaining colony health and managing medical priority plans." } },
                    { type = "callout", tone = "warn", title = "Field Note", text = "An unemployed worker is a wasted resource. Always ensure your roster has active assignments to keep the simulation moving forward." },
                },
            },
        },
    })
end
