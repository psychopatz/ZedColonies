require "ISUI/ISModalDialog"

DC_UIStringUtils = DC_UIStringUtils or {}
DC_Colony = DC_Colony or {}
DC_Colony.UI = DC_Colony.UI or {}

local DEFAULT_FONT = UIFont.Small
local DEFAULT_LINE_GAP = 3
local NOTICE_WIDTH = 420
local NOTICE_MIN_HEIGHT = 180
local NOTICE_TEXT_PAD = 26

local DC_ColonyNoticeModal = ISModalDialog:derive("DC_ColonyNoticeModal")

local function getTextManagerSafe()
    return getTextManager and getTextManager() or nil
end

local function measureText(font, text)
    local manager = getTextManagerSafe()
    if manager and manager.MeasureStringX then
        return manager:MeasureStringX(font or DEFAULT_FONT, tostring(text or ""))
    end
    return string.len(tostring(text or "")) * 7
end

local function getFontHeight(font)
    local manager = getTextManagerSafe()
    if manager and manager.getFontHeight then
        return manager:getFontHeight(font or DEFAULT_FONT)
    end
    return 14
end

local function splitLongWord(word, font, maxWidth)
    local chunks = {}
    local remaining = tostring(word or "")
    if remaining == "" then
        return chunks
    end

    maxWidth = math.max(1, tonumber(maxWidth) or 1)
    while remaining ~= "" do
        if measureText(font, remaining) <= maxWidth then
            chunks[#chunks + 1] = remaining
            break
        end

        local low = 1
        local high = string.len(remaining)
        local best = 1
        while low <= high do
            local mid = math.floor((low + high) / 2)
            local candidate = string.sub(remaining, 1, mid)
            if measureText(font, candidate) <= maxWidth then
                best = mid
                low = mid + 1
            else
                high = mid - 1
            end
        end

        chunks[#chunks + 1] = string.sub(remaining, 1, best)
        remaining = string.sub(remaining, best + 1)
    end

    return chunks
end

function DC_UIStringUtils.WrapText(text, font, maxWidth)
    local source = tostring(text or ""):gsub("\\n", "\n")
    local lines = {}
    font = font or DEFAULT_FONT
    maxWidth = math.max(1, tonumber(maxWidth) or 1)

    for paragraph in string.gmatch(source .. "\n", "([^\n]*)\n") do
        local current = ""
        if paragraph == "" then
            lines[#lines + 1] = ""
        else
            for word in string.gmatch(paragraph, "%S+") do
                if measureText(font, word) > maxWidth then
                    if current ~= "" then
                        lines[#lines + 1] = current
                        current = ""
                    end
                    for _, chunk in ipairs(splitLongWord(word, font, maxWidth)) do
                        lines[#lines + 1] = chunk
                    end
                else
                    local candidate = current == "" and word or (current .. " " .. word)
                    if measureText(font, candidate) <= maxWidth then
                        current = candidate
                    else
                        if current ~= "" then
                            lines[#lines + 1] = current
                        end
                        current = word
                    end
                end
            end
            if current ~= "" then
                lines[#lines + 1] = current
            end
        end
    end

    if #lines <= 0 then
        lines[#lines + 1] = ""
    end
    return lines
end

function DC_UIStringUtils.GetWrappedTextHeight(lines, font, lineGap)
    local count = #(lines or {})
    if count <= 0 then
        return 0
    end
    local fontHeight = getFontHeight(font or DEFAULT_FONT)
    local gap = math.max(0, tonumber(lineGap) or DEFAULT_LINE_GAP)
    return (count * fontHeight) + ((count - 1) * gap)
end

function DC_UIStringUtils.DrawCenteredWrappedText(panel, text, x, y, width, font, color, lineGap)
    if not panel then
        return y, {}
    end

    font = font or DEFAULT_FONT
    local lines = DC_UIStringUtils.WrapText(text, font, width)
    local fontHeight = getFontHeight(font)
    local gap = math.max(0, tonumber(lineGap) or DEFAULT_LINE_GAP)
    local palette = color or {}
    local r = palette.r or 1
    local g = palette.g or 1
    local b = palette.b or 1
    local a = palette.a or 1
    local centerX = x + (width / 2)
    local cursorY = y

    for _, line in ipairs(lines) do
        panel:drawTextCentre(tostring(line or ""), centerX, cursorY, r, g, b, a, font)
        cursorY = cursorY + fontHeight + gap
    end

    return cursorY, lines
end

function DC_UIStringUtils.BuildEscapedWrappedText(text, font, maxWidth)
    return table.concat(DC_UIStringUtils.WrapText(text, font or DEFAULT_FONT, maxWidth), "\\n")
end

function DC_ColonyNoticeModal:prerender()
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    local font = UIFont.Small
    local pad = NOTICE_TEXT_PAD
    local textWidth = math.max(1, self:getWidth() - (pad * 2))
    local lines = DC_UIStringUtils.WrapText(self.text or "", font, textWidth)
    local textHeight = DC_UIStringUtils.GetWrappedTextHeight(lines, font, DEFAULT_LINE_GAP)
    local buttonY = self.yes and self.yes:getY() or self.ok and self.ok:getY() or (self:getHeight() - 34)
    local topY = 18
    local bottomY = math.max(topY, buttonY - 14)
    local y = topY + math.floor(math.max(0, (bottomY - topY - textHeight) / 2))

    DC_UIStringUtils.DrawCenteredWrappedText(self, self.text or "", pad, y, textWidth, font, { r = 1, g = 1, b = 1, a = 1 }, DEFAULT_LINE_GAP)
end

function DC_ColonyNoticeModal:new(x, y, width, height, text, yesno, target, onclick, player, param1, param2)
    return ISModalDialog.new(self, x, y, width, height, text, yesno, target, onclick, player, param1, param2)
end

function DC_Colony.UI.ShowNoticeModal(message)
    local text = tostring(message or "")
    if text == "" then
        return
    end

    if DC_Colony.UI.activeNoticeText == text then
        return
    end

    DC_Colony.UI.activeNoticeText = text

    local function onClose()
        DC_Colony.UI.activeNoticeText = nil
    end

    local wrappedText = DC_UIStringUtils.BuildEscapedWrappedText(text, UIFont.Small, NOTICE_WIDTH - (NOTICE_TEXT_PAD * 2))
    local modal = DC_ColonyNoticeModal:new(0, 0, NOTICE_WIDTH, NOTICE_MIN_HEIGHT, wrappedText, true, nil, onClose, nil)
    modal:initialise()
    modal:addToUIManager()
    modal:setX((getCore():getScreenWidth() - modal:getWidth()) / 2)
    modal:setY((getCore():getScreenHeight() - modal:getHeight()) / 2)
    modal:bringToTop()
end

return DC_UIStringUtils
