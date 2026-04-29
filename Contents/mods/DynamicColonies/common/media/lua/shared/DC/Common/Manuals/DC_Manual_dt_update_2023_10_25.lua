-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dt_update_2023_10_25",
--   "module": "DynamicColonies",
--   "title": "April 7, 2026 Update",
--   "description": "travel companions, health and combat system.",
--   "start_page_id": "overview",
--   "audiences": [
--     "DynamicColonies"
--   ],
--   "sort_order": 10,
--   "release_version": "1.5.1",
--   "popup_version": "1.5.1",
--   "auto_open_on_update": true,
--   "is_whats_new": true,
--   "manual_type": "whats_new",
--   "show_in_library": false,
--   "support_url": "",
--   "banner_title": "",
--   "banner_text": "",
--   "banner_action_label": "",
--   "source_folder": "WhatsNew",
--   "chapters": [
--     {
--       "id": "release_notes",
--       "title": "Release Notes",
--       "description": "Recent changes and additions to DynamicTrading"
--     }
--   ],
--   "pages": [
--     {
--       "id": "overview",
--       "chapter_id": "release_notes",
--       "title": "Overview",
--       "keywords": [
--         "update",
--         "release",
--         "npc",
--         "combat",
--         "health",
--         "companion"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "highlights",
--           "level": 1,
--           "text": "Highlights"
--         },
--         {
--           "type": "paragraph",
--           "text": "This update introduces a massive overhaul to NPC lifecycles, advanced combat AI, and a brand new companion system."
--         },
--         {
--           "type": "heading",
--           "id": "companions-and-health",
--           "level": 2,
--           "text": "Travel Companions & Health"
--         },
--         {
--           "type": "bullet_list",
--           "items": [
--             "Added Travel Companion job UI, order menu, and logic systems.",
--             "Implemented a custom NPC health system with configurable scaling and passive regeneration (including offline processing).",
--             "Added comprehensive bandaging system with animation sets, dynamic UI health bar indicators, and self-bandage capabilities."
--           ]
--         },
--         {
--           "type": "heading",
--           "id": "combat-ai",
--           "level": 2,
--           "text": "Combat & AI Overhaul"
--         },
--         {
--           "type": "bullet_list",
--           "items": [
--             "Introduced combat rhythm system featuring tactical recovery, kiting, and dynamic flavor text.",
--             "Added modular zombie aggro management and ambient auto-defense for stationary NPCs.",
--             "Implemented pursuit tracking, unreachable target timeout logic, and combat protection behavior."
--           ]
--         },
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Sandbox Options & Extras",
--           "text": "Server administrators can now adjust NPC weapon durability and custom health scaling via new sandbox options. Additionally, check out the new Supporter Carousel and Hall of Fame in the manual!"
--         }
--       ]
--     }
--   ]
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dt_update_2023_10_25", {
        title = "April 7, 2026 Update",
        description = "travel companions, health and combat system.",
        startPageId = "overview",
        audiences = { "DynamicColonies" },
        sortOrder = 10,
        releaseVersion = "1.5.1",
        popupVersion = "1.5.1",
        autoOpenOnUpdate = true,
        isWhatsNew = true,
        manualType = "whats_new",
        showInLibrary = false,
        supportUrl = "",
        bannerTitle = "",
        bannerText = "",
        bannerActionLabel = "",
        chapters = {
            {
                id = "release_notes",
                title = "Release Notes",
                description = "Recent changes and additions to DynamicTrading",
            },
        },
        pages = {
            {
                id = "overview",
                chapterId = "release_notes",
                title = "Overview",
                keywords = { "update", "release", "npc", "combat", "health", "companion" },
                blocks = {
                    { type = "heading", id = "highlights", level = 1, text = "Highlights" },
                    { type = "paragraph", text = "This update introduces a massive overhaul to NPC lifecycles, advanced combat AI, and a brand new companion system." },
                    { type = "heading", id = "companions-and-health", level = 2, text = "Travel Companions & Health" },
                    { type = "bullet_list", items = { "Added Travel Companion job UI, order menu, and logic systems.", "Implemented a custom NPC health system with configurable scaling and passive regeneration (including offline processing).", "Added comprehensive bandaging system with animation sets, dynamic UI health bar indicators, and self-bandage capabilities." } },
                    { type = "heading", id = "combat-ai", level = 2, text = "Combat & AI Overhaul" },
                    { type = "bullet_list", items = { "Introduced combat rhythm system featuring tactical recovery, kiting, and dynamic flavor text.", "Added modular zombie aggro management and ambient auto-defense for stationary NPCs.", "Implemented pursuit tracking, unreachable target timeout logic, and combat protection behavior." } },
                    { type = "callout", tone = "info", title = "Sandbox Options & Extras", text = "Server administrators can now adjust NPC weapon durability and custom health scaling via new sandbox options. Additionally, check out the new Supporter Carousel and Hall of Fame in the manual!" },
                },
            },
        },
    })
end
