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
local configNames = {}

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
		frame:SetAllPoints(self);
	end

	local OnDragStop = function(self)
		self:StopMovingOrSizing()
		LibWin.SavePosition(self.obj)

		self:ClearAllPoints()
		self:SetAllPoints(self.obj)
	end

	getBackdrop = function(obj)
		if(not obj:GetCenter()) then return end
		if(backdropPool[obj]) then return backdropPool[obj] end

		local backdrop = CreateFrame"Frame"
		backdrop:SetParent(UIParent)
		backdrop:Hide()

		backdrop:SetBackdrop(_BACKDROP)
		backdrop:SetFrameStrata"TOOLTIP"
		backdrop:SetAllPoints(obj)

		backdrop:EnableMouse(true)
		backdrop:SetMovable(true)
		backdrop:RegisterForDrag"LeftButton"

		local name = backdrop:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		name:SetPoint"CENTER"
		name:SetJustifyH"CENTER"
		name:SetFont(GameFontNormal:GetFont(), 12)
		name:SetTextColor(1, 1, 1)

		backdrop.name = name
		backdrop.obj = obj

		backdrop:SetBackdropBorderColor(0, .9, 0)
		backdrop:SetBackdropColor(0, .9, 0)

		backdrop:SetScript("OnShow", OnShow)
		backdrop:SetScript("OnDragStart", OnDragStart)
		backdrop:SetScript("OnDragStop", OnDragStop)

		backdropPool[obj] = backdrop

		return backdrop
	end
end --}}}

function Module:ProfileChanged()
	profile = Core.db.profile
	-- TODO: LibWin is supposed to need help here.
end

function Module:RegisterMovable(object, configName)
	configNames[object] = configName
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
	self:ProfileChanged()
	Core:RegisterForProfileChange(self, "ProfileChanged")
end

function Module:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

function Module:OnDisable()
end
