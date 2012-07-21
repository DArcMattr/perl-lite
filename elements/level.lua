--[[-------------------------------------------------------------------------
	Level module for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.
	
	This is a FontString colored by target level.
	A skull texture will be generated with a skull icon for enemies of unknown levels.
---------------------------------------------------------------------------]]
local parent, ns = ...
local oUF = ns.oUF

local tonumber = tonumber
local rawset = rawset
local wipe = wipe
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitIsUnit = UnitIsUnit
local UnitLevel = UnitLevel

local skullTexture = [[Interface\TargetingFrame\UI-TargetingFrame-Skull]]

local hasSkull = {}
local skullPool = setmetatable({}, { -- lazy creation of skull icons
	__index = function(pool, frame)
		local skull = frame.Level:GetParent():CreateTexture(nil, "OVERLAY")
		skull:SetTexture(skullTexture)
		skull:SetSize(16, 16)
		skull:SetPoint("CENTER", frame.Level)
		rawset(pool, frame, skull)
		hasSkull[frame] = true
		return skull
	end,
})

local Update = function(self, event, arg1)
	local val
	if event == "PLAYER_LEVEL_UP" and UnitIsUnit(self.unit, "player") then
		val = tonumber(arg1)
	elseif self.unit == arg1 then
		val = UnitLevel(self.unit)
	else
		return
	end
	local level = self.Level
	if val > 0 then
		level:SetText(val)
		local color = GetQuestDifficultyColor(val)
		level:SetTextColor(color.r, color.g, color.b)
		level:SetAlpha(1)
		if hasSkull[self] then skullPool[self]:Hide() end
	else
		level:SetText("??")
		level:SetAlpha(0) -- If we hide, the skull won't follow our position.
		skullPool[self]:Show()
	end
end

local Path = function(self, ...)
	return (self.Level.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local level = self.Level
	if level then
		level.__owner = self
		level.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_LEVEL", Path)
		self:RegisterEvent("PLAYER_LEVEL_UP", Path)
		return true
	end
end

local Disable = function(self)
	local level = self.Level
	if level then
		if hasSkull[self] then skullPool[self]:Hide() end
		self:UnregisterEvent("UNIT_LEVEL", Path)
		self:UnregisterEvent("PLAYER_LEVEL_UP", Path)
	end
end

oUF:AddElement("Level", Path, Enable, Disable)