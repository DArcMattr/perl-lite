--[[-------------------------------------------------------------------------
	SoundOnSelect module for oUF
	Copyright (C) 2012  Morsk
	This file is available under the MIT license. Look for LICENSE.txt in its folder.
---------------------------------------------------------------------------]]
local parent, ns = ...
local oUF = ns.oUF

local PlaySound = PlaySound
local UnitGUID = UnitGUID
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend

local Update = function(self, event)
	local unit = self.unit
	local sos = self.SoundOnSelect
	local newGUID = UnitGUID(unit)
	if newGUID ~= sos.oldGUID then
		local sound
		if newGUID then
			if UnitIsEnemy(unit, "player") then
				sound = sos.aggro
			elseif UnitIsFriend("player", unit) then
				sound = sos.npc
			else
				sound = sos.neutral
			end
		else
			sound = sos.losttarget
		end
		sos.oldGUID = newGUID
		sos.Play(sound, sos.channel)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local sos = self.SoundOnSelect
	if sos then
		sos.__owner = self
		sos.ForceUpdate = ForceUpdate

		sos.Play = sos.Play or PlaySound
		sos.channel = sos.channel or "SFX"
		sos.aggro = sos.aggro or "igCreatureAggroSelect"
		sos.npc = sos.npc or "igCharacterNPCSelect"
		sos.neutral = sos.neutral or "igCreatureNeutralSelect"
		sos.losttarget = sos.losttarget or "INTERFACESOUND_LOSTTARGETUNIT"
		sos.oldGUID = UnitGUID(self.unit)
		if self.unit == "target" then
			self:RegisterEvent("PLAYER_TARGET_CHANGED", Update)
		elseif self.unit == "focus" then
			self:RegisterEvent("PLAYER_FOCUS_CHANGED", Update)
		end
		return true
	end
end

local Disable = function(self)
	local sos = self.SoundOnSelect
	if sos then
		if self.unit == "target" then
			self:UnregisterEvent("PLAYER_TARGET_CHANGED", Update)
		elseif self.unit == "focus" then
			self:UnregisterEvent("PLAYER_FOCUS_CHANGED", Update)
		end
	end
end

oUF:AddElement("SoundOnSelect", Update, Enable, Disable)
