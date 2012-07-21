--[[-------------------------------------------------------------------------
	ClassIcon module for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.
---------------------------------------------------------------------------]]
local parent, ns = ...
local oUF = ns.oUF

local UnitClass = UnitClass

local textureCoords = CLASS_ICON_TCOORDS
local noClassCoords = { 0.75, 1, 0.75, 1, }
local previouslySet = {} -- remember what we set to avoid redundant overwrites

local Update = function(self, event)
	local classIcon = self.ClassIcon
	local _, class = UnitClass(self.unit)
	if previouslySet[classIcon] ~= class then
		previouslySet[classIcon] = class
		local c = textureCoords[class] or noClassCoords
		classIcon:SetTexCoord(c[1], c[2], c[3], c[4])
	end
end

local Path = function(self, ...)
	return (self.ClassIcon.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local classIcon = self.ClassIcon
	if classIcon then
		classIcon.__owner = self
		classIcon.ForceUpdate = ForceUpdate

		if not classIcon:GetTexture() then
			print("classIcon w/ no texture")
			classIcon:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]])
		end
		classIcon:SetTexCoord(noClassCoords[1], noClassCoords[2], noClassCoords[3], noClassCoords[4])
		return true
	end
end

local Disable = function(self)
	local classIcon = self.ClassIcon
	if classIcon then
		previouslySet[classIcon] = nil
	end
end

oUF:AddElement("ClassIcon", Path, Enable, Disable)