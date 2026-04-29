-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dt_update_2026_04_04",
--   "module": "DynamicColonies",
--   "title": "April 5, 2026 Update",
--   "description": "Colony management, UI updates",
--   "start_page_id": "overview",
--   "audiences": [
--     "DynamicColonies"
--   ],
--   "sort_order": 10,
--   "release_version": "0.0.2",
--   "popup_version": "0.0.2",
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
--       "description": "What changed"
--     }
--   ],
--   "pages": [
--     {
--       "id": "overview",
--       "chapter_id": "release_notes",
--       "title": "Overview",
--       "keywords": [
--         "update",
--         "release"
--       ],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "highlights",
--           "level": 1,
--           "text": "Highlights"
--         },
--         {
--           "type": "bullet_list",
--           "items": [
--             "Fix: handle nil values in string formatting for text normalization.",
--             "UI: custom resource category list with progress bars and parsing logic.",
--             "UI: colony resource management system with new building configurations.",
--             "Recruitment: dynamic success chances and improved UI feedback.",
--             "Init: workshop metadata and mod info assets for Dynamic Colonies.",
--             "Modular: equipment requirements with job-specific definitions.",
--             "Rename: Dynamic Trading - Colonies; added equipment picker UI.",
--             "Manuals: Founder's, Surveyor's, and Vitality added.",
--             "Colony: tools and sandbox options for equipment requirements.",
--             "Backpack: equipment system and carry capacity updates.",
--             "Provisions: rotten blocking, durability display, and item data propagation."
--           ]
--         },
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Note",
--           "text": "These changes are experimental in unstable builds."
--         }
--       ]
--     }
--   ]
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dt_update_2026_04_04", {
        title = "April 5, 2026 Update",
        description = "Colony management, UI updates",
        startPageId = "overview",
        audiences = { "DynamicColonies" },
        sortOrder = 10,
        releaseVersion = "0.0.2",
        popupVersion = "0.0.2",
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
                description = "What changed",
            },
        },
        pages = {
            {
                id = "overview",
                chapterId = "release_notes",
                title = "Overview",
                keywords = { "update", "release" },
                blocks = {
                    { type = "heading", id = "highlights", level = 1, text = "Highlights" },
                    { type = "bullet_list", items = { "Fix: handle nil values in string formatting for text normalization.", "UI: custom resource category list with progress bars and parsing logic.", "UI: colony resource management system with new building configurations.", "Recruitment: dynamic success chances and improved UI feedback.", "Init: workshop metadata and mod info assets for Dynamic Colonies.", "Modular: equipment requirements with job-specific definitions.", "Rename: Dynamic Trading - Colonies; added equipment picker UI.", "Manuals: Founder's, Surveyor's, and Vitality added.", "Colony: tools and sandbox options for equipment requirements.", "Backpack: equipment system and carry capacity updates.", "Provisions: rotten blocking, durability display, and item data propagation." } },
                    { type = "callout", tone = "info", title = "Note", text = "These changes are experimental in unstable builds." },
                },
            },
        },
    })
end
