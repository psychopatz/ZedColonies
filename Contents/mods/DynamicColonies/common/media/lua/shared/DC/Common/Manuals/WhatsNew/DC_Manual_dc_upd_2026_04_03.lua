-- DT_MANUAL_EDITOR_BEGIN
-- {
--   "manual_id": "dc_upd_2026_04_03",
--   "module": "DynamicColonies",
--   "title": "Update: 03/30 - 04/03",
--   "description": "Colony Revamp: Recruitment, Trading, and UI. Updated internal documentation and asset references for future mod development.",
--   "start_page_id": "cat_features",
--   "audiences": [
--     "DynamicColonies"
--   ],
--   "sort_order": 1,
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
--       "description": "Resolved critical bugs and stability issues to ensure a smoother gameplay experience."
--     }
--   ],
--   "pages": [
--     {
--       "id": "cat_features",
--       "chapter_id": "release_notes",
--       "title": "Features",
--       "keywords": [],
--       "blocks": [
--         {
--           "type": "heading",
--           "id": "item_item_2026_03_30_dynamiccolonies",
--           "level": 2,
--           "text": "Dynamic Colonies Recruitment & Trading Overhaul"
--         },
--         {
--           "type": "paragraph",
--           "text": "- **Recruitment system overhauled** with dynamic success chances and archetype restrictions for better realism.\n- New modular equipment system allows job-specific gear requirements and improved worker management.\n- Mod renamed to Dynamic Trading - Colonies with a fresh UI for picking worker equipment."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Recruiting survivors is now smarter, with new gear management and trading features."
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
--           "text": "Updated internal documentation and asset references for future mod development."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_04_03_dynamiccolonies",
--           "level": 2,
--           "text": "Resource UI Overhaul and Code Cleanup"
--         },
--         {
--           "type": "paragraph",
--           "text": "- Added a custom resource category list UI featuring **visual progress bars** for better tracking.\n- Fixed issues where missing text values caused errors during formatting and normalization.\n- Reorganized core modules and UI panels to improve stability and future development speed."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Enhanced resource tracking with new visual progress bars and improved text handling."
--         },
--         {
--           "type": "heading",
--           "id": "item_item_2026_03_31_dynamiccolonies",
--           "level": 2,
--           "text": "Colony Resource Management & UI Overhaul"
--         },
--         {
--           "type": "paragraph",
--           "text": "- **New resource management system** allows players to track and allocate colony supplies efficiently.\n- Updated building configurations now integrate directly with the enhanced colony user interface.\n- Streamlined construction workflows reduce micromanagement while improving colony growth potential."
--         },
--         {
--           "type": "callout",
--           "tone": "success",
--           "title": "Impact",
--           "text": "Gain full control over colony supplies and construction through a new dedicated management interface."
--         }
--       ]
--     }
--   ],
--   "raw_lua": null
-- }
-- DT_MANUAL_EDITOR_END
if DynamicTrading and DynamicTrading.RegisterManual then
    DynamicTrading.RegisterManual("dc_upd_2026_04_03", {
        title = "Update: 03/30 - 04/03",
        description = "Colony Revamp: Recruitment, Trading, and UI. Updated internal documentation and asset references for future mod development.",
        startPageId = "cat_features",
        audiences = { "DynamicColonies" },
        sortOrder = 1,
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
                description = "Resolved critical bugs and stability issues to ensure a smoother gameplay experience.",
            },
        },
        pages = {
            {
                id = "cat_features",
                chapterId = "release_notes",
                title = "Features",
                keywords = {  },
                blocks = {
                    { type = "heading", id = "item_item_2026_03_30_dynamiccolonies", level = 2, text = "Dynamic Colonies Recruitment & Trading Overhaul" },
                    { type = "paragraph", text = "- **Recruitment system overhauled** with dynamic success chances and archetype restrictions for better realism.\n- New modular equipment system allows job-specific gear requirements and improved worker management.\n- Mod renamed to Dynamic Trading - Colonies with a fresh UI for picking worker equipment." },
                    { type = "callout", tone = "success", title = "Impact", text = "Recruiting survivors is now smarter, with new gear management and trading features." },
                },
            },
            {
                id = "cat_misc",
                chapterId = "release_notes",
                title = "Misc",
                keywords = {  },
                blocks = {
                    { type = "callout", tone = "info", title = "Misc Highlights", text = "Updated internal documentation and asset references for future mod development." },
                    { type = "heading", id = "item_item_2026_04_03_dynamiccolonies", level = 2, text = "Resource UI Overhaul and Code Cleanup" },
                    { type = "paragraph", text = "- Added a custom resource category list UI featuring **visual progress bars** for better tracking.\n- Fixed issues where missing text values caused errors during formatting and normalization.\n- Reorganized core modules and UI panels to improve stability and future development speed." },
                    { type = "callout", tone = "success", title = "Impact", text = "Enhanced resource tracking with new visual progress bars and improved text handling." },
                    { type = "heading", id = "item_item_2026_03_31_dynamiccolonies", level = 2, text = "Colony Resource Management & UI Overhaul" },
                    { type = "paragraph", text = "- **New resource management system** allows players to track and allocate colony supplies efficiently.\n- Updated building configurations now integrate directly with the enhanced colony user interface.\n- Streamlined construction workflows reduce micromanagement while improving colony growth potential." },
                    { type = "callout", tone = "success", title = "Impact", text = "Gain full control over colony supplies and construction through a new dedicated management interface." },
                },
            },
        },
    })
end
