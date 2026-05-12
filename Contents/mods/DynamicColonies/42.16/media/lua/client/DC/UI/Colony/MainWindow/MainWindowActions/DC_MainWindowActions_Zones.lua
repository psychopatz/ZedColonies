function DC_MainWindow:onOpenZones()
    if DC_ZoneWindow and DC_ZoneWindow.Open then
        DC_ZoneWindow.Open(self.player or getPlayer(), self.colonyId or "player_colony")
        self:updateStatus("Opening Base Zones...")
    end
end
