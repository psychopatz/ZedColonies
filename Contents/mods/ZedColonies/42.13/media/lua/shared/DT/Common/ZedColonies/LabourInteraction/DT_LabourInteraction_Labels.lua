DT_Labour = DT_Labour or {}
DT_Labour.Interaction = DT_Labour.Interaction or {}

local Config = DT_Labour.Config
local Interaction = DT_Labour.Interaction

Interaction.getRoomLabel = function(roomName)
    if type(roomName) == "table" then
        return nil
    end

    local roomKey = Interaction.normalizeText(roomName)
    if roomKey == "" or string.find(roomKey, "^table0x") then
        return nil
    end

    local lookup = DynamicTrading.ResolveInteractionString("Labour", "Locations", "ScavengeRooms." .. roomKey)
    if lookup then
        return tostring(lookup)
    end

    local text = tostring(roomName or "")
    if text == "" or string.find(text, "^table:") or string.find(text, "^table 0x") then
        return nil
    end

    text = string.gsub(text, "_", " ")
    text = string.gsub(text, "(%a)([%w_']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest)
    end)
    return text
end

Interaction.getZoneLabel = function(zoneType)
    if type(zoneType) == "table" then
        return nil
    end

    local zoneKey = Interaction.normalizeText(zoneType)
    if zoneKey == "" or zoneKey == "nav" or zoneKey == "zone" then
        return nil
    end

    local mapped = DynamicTrading.ResolveInteractionString("Labour", "Locations", "ZoneTypes." .. zoneKey)
    if mapped then
        return tostring(mapped)
    end

    if zoneKey == "townzone" or zoneKey == "vegitation" then
        return nil
    end

    local rawText = tostring(zoneType or "")
    if rawText == "" or string.find(rawText, "^table:") or string.find(rawText, "^table 0x") then
        return nil
    end

    return Interaction.prettifyContextLabel(rawText)
end

function Interaction.GetScavengeFallbackProfileLabel(roomName, zoneType)
    local roomLabel = Interaction.getRoomLabel(roomName)
    if roomLabel and roomLabel ~= "" then
        return roomLabel
    end

    local zoneLabel = Interaction.getZoneLabel(zoneType)
    if zoneLabel and zoneLabel ~= "" then
        return zoneLabel
    end

    return tostring(DynamicTrading.ResolveInteractionString("Labour", "Locations", "JobPlaces.Scavenge.Default") or "Assigned Site")
end

function Interaction.GetPlaceLabel(worker)
    local jobKey = Interaction.getJobKey(worker)

    if jobKey == tostring((Config.JobTypes or {}).Scavenge or "Scavenge") then
        local profileLabel = tostring(worker and worker.scavengeSiteProfileLabel or "")
        if profileLabel == "" or profileLabel == "Unsorted Location" then
            profileLabel = Interaction.GetScavengeFallbackProfileLabel(
                worker and worker.scavengeSiteRoomName,
                worker and worker.scavengeSiteZoneType
            )
        end

        local roomLabel = Interaction.getRoomLabel(worker and worker.scavengeSiteRoomName)
        if roomLabel and roomLabel ~= "" then
            if profileLabel == roomLabel then
                return roomLabel
            end
            return profileLabel .. " " .. roomLabel
        end

        local zoneLabel = Interaction.getZoneLabel(worker and worker.scavengeSiteZoneType)
        if zoneLabel and zoneLabel ~= "" and zoneLabel ~= profileLabel then
            return profileLabel .. " " .. zoneLabel
        end

        return profileLabel
    end

    local locationKey = jobKey ~= "" and ("JobPlaces." .. jobKey .. ".Default") or nil
    if locationKey then
        local place = DynamicTrading.ResolveInteractionString("Labour", "Locations", locationKey)
        if place then
            return tostring(place)
        end
    end

    return "Work Site"
end

function Interaction.GetDisplayStateLabel(worker)
    local jobKey = Interaction.getJobKey(worker)
    local presenceState = tostring(worker and worker.presenceState or "")
    local states = Config.PresenceStates or {}

    if jobKey == tostring((Config.JobTypes or {}).Scavenge or "Scavenge") then
        if presenceState == tostring(states.AwayToSite or "AwayToSite") then
            return tostring(Interaction.getInteractionEntry("Progress", "Common.TravelToSite.stateLabel") or "Walking")
        end
        if presenceState == tostring(states.AwayToHome or "AwayToHome") then
            return tostring(Interaction.getInteractionEntry("Progress", "Common.TravelToHome.stateLabel") or "Walking")
        end
    end

    return tostring(worker and worker.state or "Idle")
end

return DT_Labour.Interaction
