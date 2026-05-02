-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dc_upd_2026_04_20",
--   "module": "DynamicColonies",
--   "title": "Update: 04/16 - 04/20",
--   "description": "Companions Refined: UI, Loot, and Travel. Resolved issues with companion ammo consumption and loot distribution logic. — General code refactoring was performed to support the new companion systems.",
--   "start_page_id": "cat_fixes",
--   "audiences": [
--     "DynamicColonies"
--   ],
--   "sort_order": 4,
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
--       "description": "Resolved issues with companion ammo consumption and loot distribution logic."
--     }
--   ],
--   "pages": [
--     {
--       "id": "cat_fixes",
--       "chapter_id": "release_notes",
--       "title": "Fixes",
--       "keywords": [],
--       "blocks": [
--         {
--           "type": "callout",
--           "tone": "info",
--           "title": "Fixes Highlights",
--           "text": "Resolved issues with companion ammo consumption and loot distribution logic."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_16_dynamiccolonies",
--           "level": 2,
--           "text": "Companion Loot Control & Ammo Fixes"
--         },
--         {
--           "type": "paragraph",
--           "text": "- **Companion loot settings** are now fully configurable via a new UI modal with network synchronization.\n- World loot toggles are granularized to separately control loose items, ground bags, and furniture containers.\n- Fixed a critical issue where ammunition failed to equip or get consumed during combat encounters.\n- Worker recruitment and departure logic has been unified for more stable colony management."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Players gain precise control over companion looting behavior while critical ammo consumption bugs are resolved."
--         }
--       ]
--     },
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
--           "text": "General code refactoring was performed to support the new companion systems."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_20_dynamiccolonies",
--           "level": 2,
--           "text": "Companion Command System & Radius Control"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Added a system to issue commands to nearby companions with a **configurable radius**.\n- Improved companion control by allowing you to direct allies within a set distance."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "You can now issue direct commands to nearby companions with adjustable range."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_17_dynamiccolonies",
--           "level": 2,
--           "text": "Companion UI Overhaul and Travel Logic"
--         },
--         {
--           "type": "paragraph",
--           "text": "* **Companion travel logic is refined** to prevent order failures during movement.\n* Job selection now displays skill levels and uses color-coded labels for clarity.\n* Companion loot configuration is simplified by removing complex profile systems."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Companions now follow orders more reliably with clearer job selection tools."
--         }
--       ]
--     }
--   ],
--   "raw_lua": null
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dc_upd_2026_04_20", {
        title = "Update: 04/16 - 04/20",
        description = "Companions Refined: UI, Loot, and Travel. Resolved issues with companion ammo consumption and loot distribution logic. — General code refactoring was performed to support the new companion systems.",
        startPageId = "cat_fixes",
        audiences = { "DynamicColonies" },
        sortOrder = 4,
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
                description = "Resolved issues with companion ammo consumption and loot distribution logic.",
            },
        },
        pages = {
            {
                id = "cat_fixes",
                chapterId = "release_notes",
                title = "Fixes",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Fixes Highlights", text = "Resolved issues with companion ammo consumption and loot distribution logic." },
                    { type = "heading", id = "item_item_2026_04_16_dynamiccolonies", level = 2, text = "Companion Loot Control & Ammo Fixes" },
                    { type = "paragraph", text = "- **Companion loot settings** are now fully configurable via a new UI modal with network synchronization.\n- World loot toggles are granularized to separately control loose items, ground bags, and furniture containers.\n- Fixed a critical issue where ammunition failed to equip or get consumed during combat encounters.\n- Worker recruitment and departure logic has been unified for more stable colony management." },
                    { type = "callout", tone = "success", title = "Impact", text = "Players gain precise control over companion looting behavior while critical ammo consumption bugs are resolved." },
                },
            },
            {
                id = "cat_misc",
                chapterId = "release_notes",
                title = "Misc",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Misc Highlights", text = "General code refactoring was performed to support the new companion systems." },
                    { type = "heading", id = "item_item_2026_04_20_dynamiccolonies", level = 2, text = "Companion Command System & Radius Control" },
                    { type = "paragraph", text = "- Added a system to issue commands to nearby companions with a **configurable radius**.\n- Improved companion control by allowing you to direct allies within a set distance." },
                    { type = "callout", tone = "success", title = "Impact", text = "You can now issue direct commands to nearby companions with adjustable range." },
                    { type = "heading", id = "item_item_2026_04_17_dynamiccolonies", level = 2, text = "Companion UI Overhaul and Travel Logic" },
                    { type = "paragraph", text = "* **Companion travel logic is refined** to prevent order failures during movement.\n* Job selection now displays skill levels and uses color-coded labels for clarity.\n* Companion loot configuration is simplified by removing complex profile systems." },
                    { type = "callout", tone = "success", title = "Impact", text = "Companions now follow orders more reliably with clearer job selection tools." },
                },
            },
        },
    })
end
