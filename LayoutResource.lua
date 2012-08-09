--[[-------------------------------------------------------------------------
	"PerlLite" - a Perl layout for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.

	Attaches the default UI's "resources" like Soul Shards, DK Runes, etc.,
	to the Player frame. Can also restore their original positions, used when
	the option for a resource is toggled off.
---------------------------------------------------------------------------]]
--{{{ top
local _addonName = ...

local Core = LibStub("AceAddon-3.0"):GetAddon(_addonName)
local Module = Core:NewModule("LayoutResource", "AceEvent-3.0")
Module:SetEnabledState(false)
Core.LayoutResource = Module
local L = Core.L
local oUF
local profile

local undo = {}
--}}}
--{{{ upvalues
local BEAR_FORM = BEAR_FORM
local CAT_FORM = CAT_FORM
local EclipseBarFrame = EclipseBarFrame
local GetPrimaryTalentTree = GetPrimaryTalentTree -- FIXME: broken in MoP
local GetShapeshiftFormID = GetShapeshiftFormID
local MOONKIN_FORM = MOONKIN_FORM
local PaladinPowerBar = PaladinPowerBar
local RuneFrame = RuneFrame
local ShardBarFrame = ShardBarFrame
local TotemFrame = TotemFrame
local UnitClass = UnitClass
local assert = assert
local getmetatable = getmetatable
local hooksecurefunc = hooksecurefunc
local unpack = unpack
local wipe = wipe
--}}}

function Module:UpdateSettingsPointer(newSettings)
	profile = newSettings
end

function Module:LoadSettings()
	if not self:IsEnabled() then return end
	local c = profile.resource
	local _,class = UnitClass("player")
	if class == "PALADIN" then
		if c.holypower then self:FixHolyPower() else self:UnfixHolyPower() end
	elseif class == "WARLOCK" then
		if c.soulshards then self:FixSoulShards() else self:UnfixSoulShards() end
	elseif class == "DEATHKNIGHT" then
		if c.runes then self:FixRunes() else self:UnfixRunes() end
	elseif class == "DRUID" then
		if c.eclipse then self:FixEclipse() else self:UnfixEclipse() end
	elseif class == "SHAMAN" then
		-- do nothing; this case is just so we don't return
	else
		return -- class has no totems
	end
	if c.totems then
		self:FixTotems()
		if class == "DRUID" then
			self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "FixTotems")
			self:RegisterEvent("PLAYER_TALENT_UPDATE", "FixTotems")
		end
	else
		self:UnfixTotems()
		if class == "DRUID" then
			self:UnregisterEvent("UPDATE_SHAPESHIFT_FORM")
			self:UnregisterEvent("PLAYER_TALENT_UPDATE")
		end
	end
end

local function _locked_SetPoint(frame, p1, p2, p3, p4, p5)
	-- A hook that undoes SetPoint calls by immediately doing another SetPoint
	-- with our desired (u.lockedPoint) values. Also stores the attempted
	-- SetPoint (in u.originalPoint), so that releasing the frame will use the
	-- most recent position.
	-- print("_locked_SetPoint", frame:GetName(), p1, p2:GetName(), p3, p4, p5)
	local u = undo[frame]

	local op = u.originalPoint
	op[1], op[2], op[3], op[4], op[5] = p1, p2, p3, p4, p5

	frame:ClearAllPoints()
	local lp = u.lockedPoint
	u.SetPoint(frame, lp[1], lp[2], lp[3], lp[4], lp[5])
end

local function takeoverFrame(self, child, layerDiff, p1, p2, p3, p4, p5)
	-- Take control of the frame, and undo any attempts to move it with SetPoint.
	-- But remember its original settings, so we can restore it if we want.
	local u = undo[child]
	if not u then
		undo[child] = {}
		u = undo[child]

		u.originalParent = child:GetParent()
		child:SetParent(self)

		u.originalFrameLevel = child:GetFrameLevel()
		child:SetFrameLevel(self:GetFrameLevel() + layerDiff)

		u.originalScale = child:GetScale()
		local defaultScale = self:GetScale()
		if self.settings then
			defaultScale = getmetatable(self.settings).__index.scale
		end
		child:SetScale(1 / defaultScale)

		u.originalPoint = {child:GetPoint(1)}
		u.SetPoint = child.SetPoint
		hooksecurefunc(child, "SetPoint", _locked_SetPoint)
		u.lockedPoint = { p1, p2, p3, p4, p5 }
	else
		local lp = u.lockedPoint
		lp[1], lp[2], lp[3], lp[4], lp[5] = p1, p2, p3, p4, p5
	end
	child:ClearAllPoints()
	u.SetPoint(child, p1, p2, p3, p4, p5)
end

local function releaseFrame(child)
	-- Undoes takeoverFrame.
	local u = undo[child]
	if u then
		undo[child] = nil
		child:SetParent(u.originalParent)
		child:SetFrameLevel(u.originalFrameLevel)
		child:SetScale(u.originalScale)
		child.SetPoint = nil
		child:ClearAllPoints()
		child:SetPoint(unpack(u.originalPoint))
	end
end

function Module:FixHolyPower()
	local pallybar = PaladinPowerBar
	local player = oUF.units.player
	takeoverFrame(player, pallybar, -1, "TOP", player.StatsFrame, "BOTTOM", 0, 8)
end

function Module:UnfixHolyPower()
	local pallybar = PaladinPowerBar
	releaseFrame(pallybar)
end

function Module:FixSoulShards()
	local shards = ShardBarFrame
	local player = oUF.units.player
	takeoverFrame(player, shards, 0, "TOP", player.StatsFrame, "BOTTOM", 0, 1)
end

function Module:UnfixSoulShards()
	local shards = ShardBarFrame
	releaseFrame(shards)
end

function Module:FixRunes()
	local runes = RuneFrame
	local player = oUF.units.player
	takeoverFrame(player, runes, 0, "TOPRIGHT", player.StatsFrame, "BOTTOMRIGHT", 4, 0)
end

function Module:UnfixRunes()
	local runes = RuneFrame
	releaseFrame(runes)
end

function Module:FixEclipse()
	local eclipse = EclipseBarFrame
	local player = oUF.units.player
	takeoverFrame(player, eclipse, -1, "TOP", player.StatsFrame, "BOTTOM", 0, 6)
end

function Module:UnfixEclipse()
	local eclipse = EclipseBarFrame
	releaseFrame(eclipse)
end

function Module:FixTotems()
	local c = profile.resource
	local totem = TotemFrame
	local player = oUF.units.player

	local _,class = UnitClass("player")
	if class == "PALADIN" or class == "WARLOCK" or class == "DEATHKNIGHT" then
		-- I don't think Warlocks and DKs use this, but the default UI has code for it, so we should too.
		takeoverFrame(player, totem, 1, "TOPLEFT", player.StatsFrame, "BOTTOM", -92, 6)
	elseif class == "DRUID" then
		local form  = GetShapeshiftFormID()
		if c.eclipse and (form == MOONKIN_FORM or (form == nil and GetPrimaryTalentTree() == 1)) then
			local eclipse = EclipseBarFrame
			takeoverFrame(player, totem, 0, "TOP", eclipse, "BOTTOM", 12, 8)
		else
			takeoverFrame(player, totem, 0, "TOP", player.StatsFrame, "BOTTOM", 12, 4)
		end
	elseif class == "SHAMAN" then
		takeoverFrame(player, totem, 1, "TOP", player.StatsFrame, "BOTTOM", -4, 4)
	end
end

function Module:UnfixTotems()
	local totem = TotemFrame
	releaseFrame(totem)
end

function Module:OnInitialize()
	self.OnInitialize = nil
	oUF = Core.oUF
end

function Module:OnEnable()
	assert(oUF.units.player)
	self:LoadSettings()
end

function Module:OnDisable()
	self:UnfixHolyPower()
	self:UnfixSoulShards()
	self:UnfixRunes()
	self:UnfixEclipse()
	self:UnfixTotems()
end
