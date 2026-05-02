-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dc_upd_2026_04_07",
--   "module": "DynamicColonies",
--   "title": "Update: 04/04 - 04/07",
--   "description": "Companions, Colonies, and Smarter Travel. No miscellaneous changes were included in this specific update cycle.",
--   "start_page_id": "cat_misc",
--   "audiences": [
--     "DynamicColonies"
--   ],
--   "sort_order": 2,
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
--       "description": "No bug fixes were included in this specific update cycle."
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
--           "text": "No miscellaneous changes were included in this specific update cycle."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_07_dynamiccolonies",
--           "level": 2,
--           "text": "Companion, Health, and Combat Manual Added"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Added a comprehensive in-game manual covering the 1.5.1 update features.\n- New guides explain *companion mechanics*, health systems, and combat changes.\n- Access the manual directly in-game to learn about recent system improvements."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Players can now access a new in-game guide explaining the latest companion, health, and combat updates."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_06_dynamiccolonies",
--           "level": 2,
--           "text": "Colony Health, Self-Treatment & Travel Companions"
--         },
--         {
--           "type": "paragraph",
--           "text": "- **Configurable colony health regeneration** and active treatment status are now visible in the updated UI.\n- Workers can **self-treat injuries** and recover significantly faster through enhanced sleep mechanics.\n- A new **travel companion system** features dynamic health scaling and seamless interface integration.\n- Version 0.0.2 includes a manual for colony management and internal job logging improvements."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Workers now heal faster through sleep and self-care while new travel companions scale with your health."
--         }
--       ]
--     }
--   ],
--   "raw_lua": null
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dc_upd_2026_04_07", {
        title = "Update: 04/04 - 04/07",
        description = "Companions, Colonies, and Smarter Travel. No miscellaneous changes were included in this specific update cycle.",
        startPageId = "cat_misc",
        audiences = { "DynamicColonies" },
        sortOrder = 2,
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
                description = "No bug fixes were included in this specific update cycle.",
            },
        },
        pages = {
            {
                id = "cat_misc",
                chapterId = "release_notes",
                title = "Misc",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Misc Highlights", text = "No miscellaneous changes were included in this specific update cycle." },
                    { type = "heading", id = "item_item_2026_04_07_dynamiccolonies", level = 2, text = "Companion, Health, and Combat Manual Added" },
                    { type = "paragraph", text = "- Added a comprehensive in-game manual covering the 1.5.1 update features.\n- New guides explain *companion mechanics*, health systems, and combat changes.\n- Access the manual directly in-game to learn about recent system improvements." },
                    { type = "callout", tone = "success", title = "Impact", text = "Players can now access a new in-game guide explaining the latest companion, health, and combat updates." },
                    { type = "heading", id = "item_item_2026_04_06_dynamiccolonies", level = 2, text = "Colony Health, Self-Treatment & Travel Companions" },
                    { type = "paragraph", text = "- **Configurable colony health regeneration** and active treatment status are now visible in the updated UI.\n- Workers can **self-treat injuries** and recover significantly faster through enhanced sleep mechanics.\n- A new **travel companion system** features dynamic health scaling and seamless interface integration.\n- Version 0.0.2 includes a manual for colony management and internal job logging improvements." },
                    { type = "callout", tone = "success", title = "Impact", text = "Workers now heal faster through sleep and self-care while new travel companions scale with your health." },
                },
            },
        },
    })
end
