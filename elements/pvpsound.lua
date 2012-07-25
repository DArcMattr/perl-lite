--[[-------------------------------------------------------------------------
	PvPSound module for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.
---------------------------------------------------------------------------]]
local parent, ns = ...
local oUF = ns.oUF

local PlaySound = PlaySound
local UnitIsPVP = UnitIsPVP
local UnitIsPVPFreeForAll = UnitIsPVPFreeForAll

local Update = function(self, event, unit)
	if unit ~= self.unit then return end
	local pvpsound = self.PvPSound
	local isPvP = UnitIsPVPFreeForAll(self.unit) or UnitIsPVP(self.unit)
	if isPvP ~= pvpsound.wasPvP then
		if isPvP then
			pvpsound.Play(pvpsound.sound, pvpsound.channel)
		end
		pvpsound.wasPvP = isPvP
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local pvpsound = self.PvPSound
	if pvpsound then
		pvpsound.__owner = self
		pvpsound.ForceUpdate = ForceUpdate

		pvpsound.Play = pvpsound.Play or PlaySound
		pvpsound.channel = pvpsound.channel or "SFX"
		pvpsound.sound = pvpsound.sound or "igPVPUpdate"
		pvpsound.wasPvP = UnitIsPVPFreeForAll(self.unit) or UnitIsPVP(self.unit)
		self:RegisterEvent("UNIT_FACTION", Update)
		return true
	end
end

local Disable = function(self)
	local pvpsound = self.PvPSound
	if pvpsound then
		self:UnregisterEvent("UNIT_FACTION", Update)
	end
end

oUF:AddElement("PvPSound", Update, Enable, Disable)