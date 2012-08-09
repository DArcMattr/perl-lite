--[[-------------------------------------------------------------------------
	This is derived from oUF_MovableFrames by haste:
	http://www.wowinterface.com/downloads/info15425-oUFMovableFrames.html

	Honestly there isn't much left except getBackdrop(). This is more of a
	front-end to LibWindow-1.1 now, except I like the backdrops and kept them.
---------------------------------------------------------------------------]]
--{{{ top
local _addonName = ...

local Core = LibStub("AceAddon-3.0"):GetAddon(_addonName)
local Module = Core:NewModule("Movable", "AceEvent-3.0")
Core.Movable = Module
local L = Core.L
local LibWin = LibStub("LibWindow-1.1")
local FIXME_OPTIONS_CATEGORY = select(2, GetAddOnInfo(_addonName)).." - Positions"
local profile
local _MOVING
local backdropPool = {}
local configNames = {} -- object --> name
local configObjects = {} -- name --> object

local LibWin_names = {
	x = "attachX",
	y = "attachY",
	scale = "scale",
	point = "attachPoint",
}

local _BACKDROP = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background";
}
--}}}
--{{{ upvalues
local CreateFrame = CreateFrame
local GameFontNormal = GameFontNormal
local InCombatLockdown = InCombatLockdown
local UIParent = UIParent
local error = error
local next = next
--}}}

local getBackdrop --{{{
do
	local OnShow = function(self)
		return self.name:SetText(configNames[self.obj])
	end

	local OnDragStart = function(self)
		self:StartMoving()

		local frame = self.obj
		frame:ClearAllPoints();
		frame:SetPoint("TOPLEFT", self)
	end

	local OnDragStop = function(self)
		self:StopMovingOrSizing()
		self.obj:SetAllPoints(self)
		LibWin.SavePosition(self.obj)

		self:Resize()
	end

	local backdropResize = function(backdrop)
		local obj = backdrop.obj
		local w,h = obj:GetSize()
		local s = obj:GetScale()
		backdrop:SetScale(1)
		backdrop:SetSize(w*s, h*s)
		backdrop:ClearAllPoints()
		local point, _, _, x, y = obj:GetPoint(1)
		backdrop:SetPoint(point, x*s, y*s)
	end

	getBackdrop = function(obj)
		if(backdropPool[obj]) then return backdropPool[obj] end

		local backdrop = CreateFrame"Frame"
		backdrop.obj = obj
		obj.anchor = backdrop
		backdrop:SetParent(UIParent)
		backdrop:Hide()

		backdrop:SetBackdrop(_BACKDROP)
		backdrop:SetFrameStrata"DIALOG"
		backdrop.Resize = backdropResize
		backdrop:Resize()

		backdrop:EnableMouse(true)
		backdrop:SetMovable(true)
		backdrop:SetClampedToScreen()
		backdrop:RegisterForDrag"LeftButton"

		local name = backdrop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		backdrop.name = name
		name:SetPoint"CENTER"
		name:SetJustifyH"CENTER"
		name:SetFont(GameFontNormal:GetFont(), 12)
		name:SetTextColor(1, 1, 1)

		backdrop:SetBackdropBorderColor(0, .9, 0)
		backdrop:SetBackdropColor(0, .9, 0)

		backdrop:SetScript("OnShow", OnShow)
		backdrop:SetScript("OnDragStart", OnDragStart)
		backdrop:SetScript("OnDragStop", OnDragStop)

		backdropPool[obj] = backdrop

		return backdrop
	end
end --}}}

function Module:UpdateSettingsPointer(newSettings)
	profile = newSettings
	-- We give LibWin references to bits of profile for it to save positions in. Update them.
	for name,object in next, configObjects do
		LibWin.RegisterConfig(object, profile[name], LibWin_names)
	end
end

function Module:LoadSettings()
	for _,object in next, configObjects do
		LibWin.RestorePosition(object)
	end
	for _,backdrop in next, backdropPool do
		backdrop:Resize()
	end
end

function Module:RestorePosition(configName)
	LibWin.RestorePosition(configObjects[configName])
end

function Module:RegisterMovable(object, configName)
	configNames[object] = configName
	configObjects[configName] = object
	LibWin.RegisterConfig(object, profile[configName], LibWin_names)
	LibWin.RestorePosition(object)
end

function Module:IsLocked()
	return (not _MOVING)
end

function Module:Unlock()
	if(InCombatLockdown()) then
		error("Can't unlock frames in combat. This is a bug; the option to unlock should be disabled in combat.")
		return
	end
	if(not _MOVING) then
		for obj, _ in next, configNames do
			local backdrop = getBackdrop(obj)
			if(backdrop) then backdrop:Show() end
		end

		_MOVING = true
	end
end

function Module:Lock()
	if(_MOVING) then
		for k, bdrop in next, backdropPool do
			bdrop:Hide()
		end

		_MOVING = nil
	end
end

function Module:PLAYER_REGEN_DISABLED()
	if(_MOVING) then
		Core:Print("Entering combat. Frames locked.")
		return self:Lock()
	end
end

function Module:OnInitialize()
	self.OnInitialize = nil
end

function Module:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function Module:OnDisable()
end
--@do-not-package@ --{{{

Module.backdropPool = backdropPool
Module.configNames = configNames
Module.configObjects = configObjects

--}}} --@end-do-not-package@
