-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dc_upd_2026_04_15",
--   "module": "DynamicColonies",
--   "title": "Update: 04/08 - 04/15",
--   "description": "The April Sprint: New Tools & Refinements. Included minor documentation updates and internal code refactoring for future stability.",
--   "start_page_id": "cat_misc",
--   "audiences": [
--     "DynamicColonies"
--   ],
--   "sort_order": 3,
--   "release_version": "",
--   "popup_version": "",
--   "auto_open_on_update": false,
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
--       "description": "Resolved existing bugs to ensure stable gameplay and fix reported issues."
--     }
--   ],
--   "pages": [
--     {
--       "id": "cat_misc",
--       "chapter_id": "release_notes",
--       "title": "Misc",
--       "keywords": [],
--       "blocks": [
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Misc Highlights",
--           "text": "Included minor documentation updates and internal code refactoring for future stability."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_15_dynamiccolonies",
--           "level": 2,
--           "text": "Dynamic Colonies Update & Equipment Feedback"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Added full support for Project Zomboid build 42.16.\n- **Equipment assignment feedback now shows detailed rejection reasons**.\n- Travel Companion feature is now gated behind Dynamic Trading V2.\n- Added debug tools for spawning equipment and migrated dependencies."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Players now receive clear reasons when equipment assignments fail."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_14_dynamiccolonies",
--           "level": 2,
--           "text": "Colony Worker Automation and Supply Tracking"
--         },
--         {
--           "type": "paragraph",
--           "text": "- **Automated worker generation** and faction-aware recruitment now handle colony staffing.\n- Supply transfers are tracked via ledgers for accurate inventory management.\n- Companion medical supplies and commander assignments are now visible in summaries.\n- Support icons in the Supply Window now respect dynamic capacity limits."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Streamlines colony management with automated hiring and better supply visibility."
--         }
--       ]
--     }
--   ],
--   "raw_lua": null
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dc_upd_2026_04_15", {
        title = "Update: 04/08 - 04/15",
        description = "The April Sprint: New Tools & Refinements. Included minor documentation updates and internal code refactoring for future stability.",
        startPageId = "cat_misc",
        audiences = { "DynamicColonies" },
        sortOrder = 3,
        releaseVersion = "",
        popupVersion = "",
        autoOpenOnUpdate = false,
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
                description = "Resolved existing bugs to ensure stable gameplay and fix reported issues.",
            },
        },
        pages = {
            {
                id = "cat_misc",
                chapterId = "release_notes",
                title = "Misc",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Misc Highlights", text = "Included minor documentation updates and internal code refactoring for future stability." },
                    { type = "heading", id = "item_item_2026_04_15_dynamiccolonies", level = 2, text = "Dynamic Colonies Update & Equipment Feedback" },
                    { type = "paragraph", text = "- Added full support for Project Zomboid build 42.16.\n- **Equipment assignment feedback now shows detailed rejection reasons**.\n- Travel Companion feature is now gated behind Dynamic Trading V2.\n- Added debug tools for spawning equipment and migrated dependencies." },
                    { type = "callout", tone = "success", title = "Impact", text = "Players now receive clear reasons when equipment assignments fail." },
                    { type = "heading", id = "item_item_2026_04_14_dynamiccolonies", level = 2, text = "Colony Worker Automation and Supply Tracking" },
                    { type = "paragraph", text = "- **Automated worker generation** and faction-aware recruitment now handle colony staffing.\n- Supply transfers are tracked via ledgers for accurate inventory management.\n- Companion medical supplies and commander assignments are now visible in summaries.\n- Support icons in the Supply Window now respect dynamic capacity limits." },
                    { type = "callout", tone = "success", title = "Impact", text = "Streamlines colony management with automated hiring and better supply visibility." },
                },
            },
        },
    })
end
