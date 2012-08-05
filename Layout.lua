--[[-------------------------------------------------------------------------
	"PerlLite" - a Perl layout for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.
---------------------------------------------------------------------------]]
--{{{ top
local _addonName = ...

local Core = LibStub("AceAddon-3.0"):GetAddon(_addonName)
local Module = Core:NewModule("Layout", "AceEvent-3.0")
Core.Layout = Module
local L = Core.L
local oUF
local profile
--}}}
--{{{ upvalues
-- GLOBALS: CreateFrame
-- GLOBALS: GameFontNormal
-- GLOBALS: IsResting
-- GLOBALS: ToggleDropDownMenu
-- GLOBALS: UnitAffectingCombat
-- GLOBALS: UnitClass
-- GLOBALS: UnitClassification
-- GLOBALS: UnitCreatureFamily
-- GLOBALS: UnitCreatureType
-- GLOBALS: UnitFactionGroup
-- GLOBALS: UnitFrame_OnEnter
-- GLOBALS: UnitFrame_OnLeave
-- GLOBALS: UnitGetIncomingHeals
-- GLOBALS: UnitHealth
-- GLOBALS: UnitHealthMax
-- GLOBALS: UnitInRange
-- GLOBALS: UnitIsAFK
-- GLOBALS: UnitIsConnected
-- GLOBALS: UnitIsDead
-- GLOBALS: UnitIsEnemy
-- GLOBALS: UnitIsGhost
-- GLOBALS: UnitIsPlayer
-- GLOBALS: UnitIsTapped
-- GLOBALS: UnitIsTappedByPlayer
-- GLOBALS: UnitPlayerControlled
-- GLOBALS: UnitPower
-- GLOBALS: UnitPowerMax
-- GLOBALS: UnitPowerType
-- GLOBALS: UnitReaction
-- GLOBALS: error
local _G = _G
local assert = assert
local floor = floor
local format = format
local max = max
local next = next
local setmetatable = setmetatable
local strmatch = strmatch
local strupper = strupper
local tostring = tostring
local unpack = unpack
local wipe = wipe
--}}}

do -- styles
--{{{ style data
--[[
	basicStyle
		player
		pet
		target
			focus
		targettarget
			focustarget
		party
--]]
local basicStyle = {
	enabled = true,
	scale = 1,
	alpha = 216,
	nestedAlpha = true,
	rangeAlphaCoef = false,
	sounds = false,
	castbar = false,
	pvpSound = false,
	portrait = false,
	portraitW = 60,
	portraitH = 62,
	leftToRight = true,
	healPrediction = true,
	combatFeedback = false,
	level = true,
	embedLevelAndClassIcon = false,
	classIcon = true,
	eliteType = false,
	npcRace = false,
	pvpIcon = "LEFT",
	pvpIconSize = 26,
	pvpIconX = 7,
	pvpIconY = 0,
	pvpTimer = false,
	raidIcon = false,
	raidIconSize = 16,
	raidIconX = -5,
	raidIconY = 9,
	leaderIcon = false,
	leaderIconSize = 16,
	leaderIconX = 0,
	leaderIconY = -1,
	masterLooterIcon = false,
	masterLooterIconSize = 16,
	masterLooterIconX = 20,
	masterLooterIconY = -1,
	combatIcon = false,
	combatIconSize = 32,
	combatIconX = -14,
	combatIconY = 0,
	nameW = 160,
	nameH = 24,
	nameFontSize = 12,
	nameLeft = false,
	statsW = 160,
	statsTopPadding = -2,
	statTagWSpace = 35,
	statTagW = 50,
	statTagH = 12,
	tagFontSize = 10,
	healthH = 20,
	healthFontSize = 12,
	healthFormat = "val/max",
	powerH = 10,
	powerFontSize = 10,
	powerFormat = "val/max",
	portraitPadding = -3,
}
local stylePrototypes = {
	player = {
		nestedAlpha = false,
		pvpSound = "Master",
		portrait = "3d",
		combatFeedback = true,
		pvpIconSize = 30,
		pvpTimer = true,
		leaderIcon = "TOP",
		masterLooterIcon = "TOP",
		combatIcon = "RIGHT",
		powerFormat = "val/max full",
	},
	pet = {
		nestedAlpha = false,
		portrait = "3d",
		portraitW = 50,
		portraitH = 56,
		combatFeedback = true,
		classIcon = false,
		pvpIcon = false,
		nameW = 80,
		nameFontSize = 10,
		nameLeft = true,
		statsW = 80,
		healthH = 14,
		healthFontSize = 10,
		powerFormat = "val/max full",
	},
	target = {
		sounds = "Master",
		portrait = "3d",
		combatFeedback = true,
		leftToRight = false,
		eliteType = true,
		npcRace = true,
		raidIcon = "RIGHT",
		leaderIcon = "TOP",
		masterLooterIcon = "TOP",
	},
	targettarget = {
		level = false,
		classIcon = false,
		raidIcon = "RIGHT",
	},
	focus = {
		_inherits = "target",
	},
	focustarget = {
		_inherits = "targettarget",
	},
	party = {
		rangeAlphaCoef = 0.5,
		combatFeedback = true,
		embedLevelAndClassIcon = true,
		pvpIcon = "RIGHT",
		pvpIconSize = 24,
		pvpIconX = -7,
		leaderIcon = "TOPLEFT",
		leaderIconX = 18,
		masterLooterIcon = "TOPLEFT",
		masterLooterIconX = 33,
		nameW = 106,
		statsW = 142,
		statsTopPadding = -3,
		healthH = 21,
		portraitPadding = -2,
	},
}
--}}} style data
--{{{ style init
do
	local function shallowCopy(to, from)
		for k,v in next, from do
			to[k] = v
		end
	end
	-- Copy style properties into the "defaults" tables.
	for k,proto in next, stylePrototypes do
		local settings = Core.defaults.profile[k]
		settings._style = k -- so a style knows its own name
		shallowCopy(settings, basicStyle)
		if proto._inherits then
			shallowCopy(settings, stylePrototypes[proto._inherits])
			settings._inherits = nil
		end
		shallowCopy(settings, proto)
	end
	-- Drop the big style properites tables, but keep the names for code that wants to iterate on them.
	for k,_ in next, stylePrototypes do
		stylePrototypes[k] = k
	end
	Module.styleNames = stylePrototypes
--}}} style init
end
end

--{{{ textures & backdrops
local classIconsBg = [[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]] -- has black and some border around the image
local classIconsAlpha = [[Interface\WorldStateFrame\Icons-Classes]] -- has transparency around the image

local backdrop_gray125 = {
	bgFile = Core.texturePath..[[gray125_32px]], tile = true, tileSize = 32,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
}

local backdrop_black0 = {
	bgFile = Core.texturePath..[[black0_32px]], tile = true, tileSize = 32,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
}

local grad1r, grad1g, grad1b, grad1a, grad2r, grad2g, grad2b, grad2a
--}}} textures & backdrops

local complainsInvalidStyleProperty = {
	__index = function(self, key)
		error("invalid style property: "..(self._style or "???").."."..tostring(key))
	end
}
function Module:ProfileChanged()
	profile = Core.db.profile
	for styleName,_ in next, self.styleNames do
		setmetatable(profile[styleName], complainsInvalidStyleProperty)
	end
	do -- color upvalues
		local color = profile.color
		local s,e = color.gradientStart, color.gradientEnd
		grad1r, grad1g, grad1b, grad1a = s[1]/255, s[2]/255, s[3]/255, s[4]/255
		grad2r, grad2g, grad2b, grad2a = e[1]/255, e[2]/255, e[3]/255, e[4]/255
	end
	self:LayoutAll()
end

local menu = function(self)
	local unit = self.unit -- self.unit:sub(1, -2)
	local cunit = self.unit:gsub("^%l", strupper)

	if cunit == "Vehicle" then
		cunit = "Pet"
	end

	if unit == "party" or unit == "partypet" then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

Module.valMaxFormatters = {} --{{{
Module.valMaxFormatters["val/max"] = function(fontString, val, maxVal)
	-- I'm not happy with how similar this looks to XPerl_SetValuedText, but there's
	-- no other way to do it. I could throw the :SetFormattedText optimization out and
	-- use tags, but that's a silly thing to do just to make the function look different.
	--
	-- Regardless. It recognizes 3 sizes of numbers: 1-5 digits, 6 digits, and 7+
	-- digits, which I'll refer to as "flat", "K", and "M" formats. So there are 3 * 3
	-- = 9 combinations of formats for value / maxValue pairs, but really only 6 because
	-- values are always <= maxValues. The six cases appear below.
	-- The 3 formats:
	-- format("%d", val) -- "flat" format
	-- format("%.1fK", (val / 1e3)) -- "K" format
	-- format("%.1fM", (val / 1e6)) -- "M" format
	if val < 0 then assert(val >= 0) end
	if val < 1e5 then
		-- flat / ...
		if maxVal < 1e5 then
			-- flat / flat
			return fontString:SetFormattedText("%d/%d", val, maxVal)
		elseif maxVal < 1e6 then
			-- flat / K
			return fontString:SetFormattedText("%d/%1.fK", val, (maxVal / 1e3))
		else
			-- flat / M
			return fontString:SetFormattedText("%d/%1.fM", val, (maxVal / 1e6))
		end
	elseif val < 1e6 then
		-- K / ...
		if maxVal < 1e6 then
			-- K / K
			return fontString:SetFormattedText("%.1fK/%.1fK", (val / 1e3), (maxVal / 1e3))
		else
			-- K / M
			return fontString:SetFormattedText("%.1fK/%.1fM", (val / 1e3), (maxVal / 1e6))
		end
	else
		-- M / M
		return fontString:SetFormattedText("%.1fM/%.1fM", (val / 1e6), (maxVal / 1e6))
	end
end

Module.valMaxFormatters["val/max full"] = function(fontString, val, maxVal)
	return fontString:SetFormattedText("%d/%d", val, maxVal)
end

Module.valMaxFormatters["-missing or 0"] = function(fontString, val, maxVal)
	return fontString:SetFormattedText("%d", (val - maxVal))
end
--}}}

local HealthOverride = function(self, event, unit, powerType)
	if self.unit ~= unit then return end
	local name = self.Name
	local health = self.Health

	-- name color
	local nameColor
	local disconnected = not UnitIsConnected(unit)
	if UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		-- tapped
		nameColor = self.colors.tapped
	elseif UnitIsPlayer(unit) then
		-- class color
		local _, class = UnitClass(unit)
		nameColor = self.colors.class[class] or self.colors.nameDefault
	else
		local react = UnitReaction(unit, "player")
		-- note: UnitSelectionColor is a possible alternative to UnitReaction
		if not react then
			if UnitFactionGroup(unit) == UnitFactionGroup("player") then
				react = 5 -- friend
			elseif UnitIsEnemy("player", unit) then
				react = 1 -- enemy
			else
				react = 4 -- neutral
			end
		end
		nameColor = self.colors.reaction[react]
	end
	name:SetTextColor(nameColor[1], nameColor[2], nameColor[3])

	-- health bar fullness
	local val, maxVal = UnitHealth(unit), UnitHealthMax(unit)
	health:SetMinMaxValues(0, maxVal)
	health:SetValue(disconnected and maxVal or val) -- fill to maxVal when disconnected
	health.disconnected = disconnected

	-- health text
	health.text:formatValMax(val, maxVal)

	-- health tag
	local tag
	if disconnected then
		tag = "Offline"
	elseif UnitIsDead(unit) then
		health:SetValue(0)
		tag = "Dead"
	elseif UnitIsGhost(unit) then
		health:SetValue(0)
		tag = "Ghost"
	elseif UnitIsAFK(unit) then
		tag = "Away"
	end
	if tag then
		health.tag:SetText(tag)
	elseif maxVal ~= 0 then
		health.tag:SetFormattedText("%d%%", (100 * val / maxVal))
	else
		health.tag:SetText("")
	end

	-- health color
	local r, g, b
	if tag then
		local t = self.colors.gray
		r, g, b = t[1], t[2], t[3]
	elseif health.colorSmooth then
		local perc = (maxVal ~= 0) and (val / maxVal) or 0
		r, g, b = self.ColorGradient(perc, unpack(health.smoothGradient or self.colors.smooth))
	elseif health.colorHealth then
		local t = self.colors.health
		r, g, b = t[1], t[2], t[3]
	end
	if b then
		health:SetStatusBarColor(r, g, b)

		local bg = health.bg
		if bg then
			local mu = bg.multiplier or 1 -- FIXME: Remove if XPerl seems to have no analog of this mu.
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end
	if (not not tag) ~= (not not health.wasForcedGray) then
		-- Grayness status changed.
		health.wasForcedGray = (not not tag)
		self.Power:ForceUpdate()
	end
end

local PowerOverride = function(self, event, unit)
	if self.unit ~= unit then return end
	local power = self.Power

	-- bar fullness
	local powerType = UnitPowerType(unit)
	local val, maxVal = UnitPower(unit, powerType), UnitPowerMax(unit, powerType)
	if unit == "target" or unit == "focus" then
		-- Show Power iff unit has a real power bar. Units with 0 maxPower don't have a real bar.
		if not not (maxVal > 0) ~= not not power:IsShown() then
			local c = self.settings
			if maxVal > 0 then
				self.StatsFrame:SetHeight(c.healthH + c.powerH + 10)
				power:Show()
			else
				power:Hide()
				self.StatsFrame:SetHeight(c.healthH + 10)
			end
		end
	end
	power:SetMinMaxValues(0, maxVal)
	local disconnected = not UnitIsConnected(unit)
	power.disconnected = disconnected
	if disconnected then
		power:SetValue(maxVal)
	elseif UnitIsDead(unit) or UnitIsGhost(unit) then
		power:SetValue(0)
	else
		power:SetValue(val)
	end

	-- text & tag
	if maxVal == 0 then
		power.text:Hide()
		power.tag:Hide()
	else
		power.text:formatValMax(val, maxVal)
		power.tag:SetFormattedText("%d%%", (100 * val / maxVal))
		power.text:Show()
		power.tag:Show()
	end

	-- bar color
	local r, g, b, t
	if self.Health.wasForcedGray then
		t = self.colors.gray
	else
		-- color by power type
		local ptype, ptoken, altR, altG, altB = UnitPowerType(unit)
		t = self.colors.power[ptoken]
		if (not t) and altR then
			r, g, b = altR, altG, altB
		end
	end
	if t then
		r, g, b = t[1], t[2], t[3]
	end
	if b then
		power:SetStatusBarColor(r, g, b)

		local bg = power.bg
		if bg then
			local mu = bg.multiplier or 1
			bg:SetVertexColor(r * mu, g * mu, b * mu)
		end
	end
end

local PortraitPostUpdate3D = function(self, unit)
	if self:GetModel() == [[character\worgen\male\worgenmale.m2]] then
		self:SetCamera(1) -- male worgen face/full camera angles are swapped, for unknown reasons
	else
		self:SetCamera(0)
	end
end

local HealPredictionOverride = function (self, event, unit)
	if self.unit ~= unit then return end
	local hp = self.HealPrediction
	local incoming = UnitGetIncomingHeals(unit) or 0
	if incoming > 0 then
		local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
		if health + incoming > maxHealth then
			incoming = maxHealth - health
		end
		hp:SetMinMaxValues(0, maxHealth)
		hp:SetValue(health + incoming)
		hp:Show()
	else
		hp:Hide()
	end
end

local CombatOverride = function(self, event)
	if UnitAffectingCombat("player") then
		self.Combat:Show()
		self.Resting:Hide()
	else
		self.Combat:Hide()
		if IsResting() then
			self.Resting:Show()
		end
	end
end

local RestingOverride = function(self, event)
	if IsResting() and not UnitAffectingCombat("player") then
		self.Resting:Show()
	else
		self.Resting:Hide()
	end
end

local function CreateFrameSameLevel(frameType, name, parent, template)
	local newf = CreateFrame(frameType, name, parent, template)
	newf:SetFrameLevel(parent:GetFrameLevel())
	return newf
end

local function CreateStatusBar(parent)
	local bar = CreateFrameSameLevel("StatusBar", nil, parent)

	-- bg texture
	local bg = bar:CreateTexture(nil, "BORDER")
	bar.bg = bg
	bg:SetAllPoints()
	bg:SetAlpha(.25)

	-- text
	local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.text = text
	text:SetPoint("TOPLEFT", bar, 0, 0)
	text:SetPoint("BOTTOMRIGHT", bar, 0, 1)
	text:SetJustifyH("CENTER")
	text:SetTextColor(1, 1, 1)

	-- tag
	local tag = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	bar.tag = tag
	tag:SetPoint("LEFT", bar, "RIGHT", 0, 1)
	tag:SetJustifyH("LEFT")
	tag:SetTextColor(1, 1, 1)

	return bar
end

local function UpdateBarTextures(bar)
	bar:SetStatusBarTexture(profile.barTexture)
	bar.bg:SetTexture(profile.barTexture)
end

local function CreateBorderedChildFrame(parent, backdrop)
	local newf = CreateFrameSameLevel("Frame", nil, parent)
	newf:SetBackdrop(backdrop or backdrop_gray125)
	newf:SetBackdropColor(0, 0, 0, 1)
	newf:SetBackdropBorderColor(.5, .5, .5, 1)
	return newf
end

local function UpdateFrameGradient(frame)
	-- I hate how this works. I followed the traditional implementation because I want users to be happy
	-- with what they're used to, but ChatFrameBackground is slightly off-white: (248, 252, 248, 255).
	local c = profile.color
	if c.gradient then
		if not frame.gradient then
			frame.gradient = frame:CreateTexture(nil, "BORDER")
			frame.gradient:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
			frame.gradient:SetBlendMode("ADD")
		end
		local ins = frame:GetBackdrop().insets
		frame.gradient:SetPoint("TOPLEFT", ins.left, -ins.top)
		frame.gradient:SetPoint("BOTTOMRIGHT", -ins.right, ins.bottom)
		frame.gradient:SetGradientAlpha(c.gradient, grad1r, grad1g, grad1b, grad1a, grad2r, grad2g, grad2b, grad2a)
		frame.gradient:Show()
	elseif frame.gradient then
		frame.gradient:Hide()
	end
end

local pointFlipH = {
	-- left -> right
	["TOPLEFT"] = "TOPRIGHT",
	["LEFT"] = "RIGHT",
	["BOTTOMLEFT"] = "BOTTOMRIGHT",
	-- right -> left
	["TOPRIGHT"] = "TOPLEFT",
	["RIGHT"] = "LEFT",
	["BOTTOMRIGHT"] = "BOTTOMLEFT",
	-- center unaffected
	["CENTER"] = "CENTER",
	["TOP"] = "TOP",
	["BOTTOM"] = "BOTTOM",
}
local function attach(self, frame1name, point1, frame2name, point2, xOff, yOff, specialNegativeXOff)
	if not self.settings.leftToRight then
		point1 = pointFlipH[point1]
		point2 = pointFlipH[point2]
		xOff = specialNegativeXOff or -xOff
	end
	local frame1 = frame1name and self[frame1name] or self
	local frame2 = frame2name and self[frame2name] or self
	frame1:SetPoint(point1, frame2, point2, xOff, yOff)
end

local function DoNameFrame(unitFrame, unit, isSingle)
	-- NameFrame
	local NameFrame = CreateBorderedChildFrame(unitFrame)
	unitFrame.NameFrame = NameFrame

	local Name = NameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	unitFrame.Name = Name
	Name:SetPoint("BOTTOMRIGHT", NameFrame, 0, 1)
	Name:SetTextColor(1, 1, 1)
	unitFrame:Tag(Name, "[name]")
end

local function DoStatsFrame(unitFrame, unit, isSingle)
	-- StatsFrame
	local StatsFrame = CreateBorderedChildFrame(unitFrame)
	unitFrame.StatsFrame = StatsFrame

	-- Health
	local Health = CreateStatusBar(StatsFrame)
	unitFrame.Health = Health
	Health:SetPoint("TOP", StatsFrame, 0, -5)
	Health:SetPoint("LEFT", StatsFrame, 5, 0)

	-- I don't understand this oUF stuff yet
	Health.frequentUpdates = true
	Health.colorSmooth = true
	Health.Override = HealthOverride

	local Power = CreateStatusBar(StatsFrame)
	unitFrame.Power = Power
	Power:SetPoint("TOPRIGHT", Health, "BOTTOMRIGHT", 0, 0)
	Power:SetPoint("BOTTOMLEFT", StatsFrame, 5, 5)

	Power.frequentUpdates = true
	Power.Override = PowerOverride
end

local function LayoutPvPIcon(self, c, initial)
	if c.pvpIcon then
		if not self.PvP then
			self.PvP = self.NameFrame:CreateTexture(nil, "OVERLAY")
			self.PvP:SetTexCoord(0, 42/64, 0, 42/64) -- icon is 42x42 in a 64x64 file
		end
		if not initial then self:EnableElement("PvP") end
		self.PvP:SetSize(c.pvpIconSize, c.pvpIconSize)
		self.PvP:SetPoint("CENTER", self.NameFrame, c.pvpIcon, c.pvpIconX, c.pvpIconY)
	elseif self.PvP then
		self:DisableElement("PvP")
		self.PvP:Hide()
	end

	if c.pvpTimer and c.pvpIcon then
		if not self.PvPTimer then
			self.PvPTimer = self.NameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.PvPTimer:SetTextColor(1, 1, 1)
		end
		if not initial then self:EnableElement("PvPTimer") end
		self.PvPTimer:SetPoint("CENTER", self.PvP, "CENTER", 0, 1)
	elseif self.PvPTimer then
		self:DisableElement("PvPTimer")
		self.PvPTimer:Hide()
	end
end

local function LayoutRaidIcon(self, c, initial)
	if c.raidIcon then
		if not self.RaidIcon then
			self.RaidIcon = self.NameFrame:CreateTexture(nil, "OVERLAY")
		end
		if not initial then self:EnableElement("RaidIcon") end
		self.RaidIcon:SetSize(c.raidIconSize, c.raidIconSize)
		self.RaidIcon:SetPoint("CENTER", self.NameFrame, c.raidIcon, c.raidIconX, c.raidIconY)
	elseif self.RaidIcon then
		self:DisableElement("RaidIcon")
		self.RaidIcon:Hide()
	end
end

local function LayoutLeaderIcon(self, c, initial)
	if c.leaderIcon then
		if not self.Leader then
			self.Leader = self.NameFrame:CreateTexture(nil, "OVERLAY")
		end
		if not initial then self:EnableElement("Leader") end
		self.Leader:SetSize(c.leaderIconSize, c.leaderIconSize)
		self.Leader:SetPoint("CENTER", self.NameFrame, c.leaderIcon, c.leaderIconX, c.leaderIconY)
	elseif self.Leader then
		self:DisableElement("Leader")
		self.Leader:Hide()
	end
end

local function LayoutMasterLooterIcon(self, c, initial)
	if c.masterLooterIcon then
		if not self.MasterLooter then
			self.MasterLooter = self.NameFrame:CreateTexture(nil, "OVERLAY")
		end
		if not initial then self:EnableElement("MasterLooter") end
		self.MasterLooter:SetSize(c.masterLooterIconSize, c.masterLooterIconSize)
		self.MasterLooter:SetPoint("CENTER", self.NameFrame, c.masterLooterIcon, c.masterLooterIconX, c.masterLooterIconY)
	elseif self.MasterLooter then
		self:DisableElement("MasterLooter")
		self.MasterLooter:Hide()
	end
end

local function LayoutCombatIcon(self, c, initial)
	if c.combatIcon then
		if not self.Combat then
			self.Combat = self.NameFrame:CreateTexture(nil, "OVERLAY")
			self.Combat:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			self.Combat:SetTexCoord(32/64, 64/64, 0/64, 32/64)
			self.Combat.Override = CombatOverride
			self.Resting = self.NameFrame:CreateTexture(nil, "OVERLAY")
			self.Resting:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			self.Resting:SetTexCoord(0/64, 32/64, 0/64, 32/64)
			self.Resting.Override = RestingOverride
		end
		if not initial then self:EnableElement("Combat") end
		if not initial then self:EnableElement("Resting") end
		self.Combat:SetSize(c.combatIconSize, c.combatIconSize)
		self.Combat:SetPoint("CENTER", self.NameFrame, c.combatIcon, c.combatIconX, c.combatIconY)
		self.Resting:SetSize(c.combatIconSize, c.combatIconSize)
		self.Resting:SetPoint("CENTER", self.NameFrame, c.combatIcon, c.combatIconX, c.combatIconY)
	elseif self.Combat then
		self:DisableElement("Combat")
		self.Combat:Hide()
		self:DisableElement("Resting")
		self.Resting:Hide()
	end
end

local function LayoutRange(self, c, initial)
	if c.rangeAlphaCoef then
		self.Range = self.Range or {}
		self.Range.insideAlpha = c.alpha / 255
		self.Range.outsideAlpha = floor(c.alpha * c.rangeAlphaCoef + .5) / 255
		if not initial then self:EnableElement("Range") end
	elseif self.Range then
		self:DisableElement("Range")
	end
end

local function LayoutPortrait(self, c, initial)
	if c.portrait and not self.PortraitFrame then
		self.PortraitFrame = CreateBorderedChildFrame(self, backdrop_black0)
	end
	if self.PortraitFrame then
		UpdateFrameGradient(self.PortraitFrame)
		local oldPortraitType = self.Portrait and (self.Portrait:GetObjectType() == "PlayerModel" and "3d" or "2d") or false
		if c.portrait ~= oldPortraitType then
			if oldPortraitType then
				self.Portrait:Hide()
				self:DisableElement("Portrait")
				if oldPortraitType == "3d" then
					self.Portrait:ClearModel()
				else
					self.Portrait:SetTexture()
				end
				self.Portrait = nil
			end
			if c.portrait then
				if c.portrait == "3d" then
					local _3d = self.PortraitFrame._3d or CreateFrameSameLevel("PlayerModel", nil, self.PortraitFrame)
					_3d.PostUpdate = PortraitPostUpdate3D
					self.Portrait = _3d
				else
					local _2d = self.PortraitFrame._2d or self.PortraitFrame:CreateTexture(nil, "ARTWORK")
					self.Portrait = _2d
				end
				if not initial then self:EnableElement("Portrait") end
				self.Portrait:Show()
			end
		end
		self.PortraitFrame:SetSize(c.portraitW, c.portraitH)
		if self.Portrait then
			self.Portrait:SetSize(51, 52)
			self.Portrait:SetPoint("TOPLEFT", self.PortraitFrame, 5, -5)
			self.Portrait:SetPoint("BOTTOMRIGHT", self.PortraitFrame, -5, 5)
			self.PortraitFrame:Show()
		else
			self.PortraitFrame:Hide()
		end
		self.PortraitFrame:ClearAllPoints()
	end
end

local function LayoutLevel(self, c, initial)
	local specialLevelFrame = c.embedLevelAndClassIcon and (c.level or c.classIcon) and not c.portrait
	-- LevelFrame
	if c.level or specialLevelFrame then
		if not self.LevelFrame then
			self.LevelFrame = CreateBorderedChildFrame(self)
		end
		UpdateFrameGradient(self.LevelFrame)
		self.LevelFrame:ClearAllPoints()
		if specialLevelFrame then
			self.LevelFrame:SetSize(30, c.healthH + c.powerH + 10)
		else
			self.LevelFrame:SetSize(27, 22)
		end
		self.LevelFrame:Show()
	elseif self.LevelFrame then
		self.LevelFrame:Hide()
	end
	-- Level
	if c.level then
		if not self.Level then
			self.Level = self.LevelFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
		end
		if not initial then self:EnableElement("Level") end
		self.Level:ClearAllPoints()
		if specialLevelFrame then
			if c.classIcon then
				self.Level:SetPoint("BOTTOM", 0, 4)
			else
				self.Level:SetPoint("CENTER")
			end
		else
			self.Level:SetPoint("TOPLEFT")
			self.Level:SetPoint("BOTTOMRIGHT")
		end
	elseif self.Level then
		self:DisableElement("Level")
	end
end

local function LayoutClassIcon(self, c, initial)
	local specialLevelFrame = c.embedLevelAndClassIcon and (c.level or c.classIcon) and not c.portrait
	if c.classIcon then
		if not self.ClassIcon then
			self.ClassIcon = self:CreateTexture(nil, "OVERLAY")
			self.ClassIcon:SetSize(20, 20)
		end
		self.ClassIcon:ClearAllPoints()
		if specialLevelFrame then
			self.ClassIcon:SetTexture(classIconsAlpha)
			if c.level then
				self.ClassIcon:SetPoint("TOPLEFT", self.LevelFrame, "TOPLEFT", 5, -5)
			else
				self.ClassIcon:SetPoint("CENTER", self.LevelFrame)
			end
		else
			self.ClassIcon:SetTexture(classIconsBg)
			attach(self, "ClassIcon", "BOTTOMRIGHT", "corner", "BOTTOMLEFT", -1, 2, 2)
		end
		if not initial then self:EnableElement("ClassIcon") end
		self.ClassIcon:Show()
	elseif self.ClassIcon and self.ClassIcon:IsShown() then
		self.ClassIcon:Hide()
		self:DisableElement("ClassIcon")
		self.ClassIcon:SetTexture()
	end
end

local function LayoutEliteFrame(self, c, initial)
	if c.eliteType then
		if not self.EliteFrame then
			self.EliteFrame = CreateBorderedChildFrame(self)
			local text = self.EliteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.EliteFrame.text = text
			text:SetPoint("TOPLEFT")
			text:SetPoint("BOTTOMRIGHT", 0, 1)
		end
		UpdateFrameGradient(self.EliteFrame)
		self.EliteFrame:SetSize(38, 20)
		self.EliteFrame:ClearAllPoints()
		attach(self, "EliteFrame", "BOTTOMRIGHT", "corner", "BOTTOMLEFT", 2, 0)
	elseif self.EliteFrame then
		self.EliteFrame:Hide()
	end
end

local function LayoutRaceFrame(self, c, initial)
	if c.npcRace then
		if not self.RaceFrame then
			self.RaceFrame = CreateBorderedChildFrame(self)
			local text = self.RaceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.RaceFrame.text = text
			text:SetPoint("TOPLEFT")
			text:SetPoint("BOTTOMRIGHT")
			text:SetTextColor(1, 1, 1)
		end
		UpdateFrameGradient(self.RaceFrame)
		self.RaceFrame:SetSize(68, 22)
		self.RaceFrame:ClearAllPoints()
		-- positioning done in PostUpdate
	elseif self.RaceFrame then
		self.RaceFrame:Hide()
	end
end

local function LayoutNameAndStats(self, c, initial)
	UpdateFrameGradient(self.NameFrame)
	self.NameFrame:ClearAllPoints()
	self.NameFrame:SetSize(c.nameW, c.nameH)
	self.Name:SetFont(GameFontNormal:GetFont(), c.nameFontSize)
	if c.nameLeft then
		self.Name:SetPoint("TOPLEFT", 6, 0)
		self.Name:SetJustifyH("LEFT")
	else
		self.Name:SetPoint("TOPLEFT")
		self.Name:SetJustifyH("CENTER")
	end

	UpdateFrameGradient(self.StatsFrame)
	self.StatsFrame:ClearAllPoints()
	self.StatsFrame:SetSize(c.statsW, c.healthH + c.powerH + 10)

	UpdateBarTextures(self.Health)
	self.Health.text.formatValMax = Module.valMaxFormatters[c.healthFormat]
	self.Health.text:SetFont(GameFontNormal:GetFont(), c.healthFontSize)
	self.Health.tag:SetFont(GameFontNormal:GetFont(), c.tagFontSize)
	self.Health:SetHeight(c.healthH)
	self.Health.tag:SetSize(c.statTagW, c.statTagH)

	UpdateBarTextures(self.Power)
	self.Power.text.formatValMax = Module.valMaxFormatters[c.powerFormat]
	self.Power.text:SetFont(GameFontNormal:GetFont(), c.powerFontSize)
	self.Power.tag:SetFont(GameFontNormal:GetFont(), c.tagFontSize)
	self.Power.tag:SetSize(c.statTagW, c.statTagH)
	self.Health:SetPoint("RIGHT", self.StatsFrame, -(5 + c.statTagWSpace), 0)
end

local function LayoutHealPrediction(self, c, initial)
	if c.healPrediction then
		if not self.HealPrediction then
			self.HealPrediction = CreateFrameSameLevel("StatusBar", nil, self.StatsFrame)
			self.HealPrediction.Override = HealPredictionOverride
		end
		if not initial then self:EnableElement("HealPrediction") end
		self.HealPrediction:SetStatusBarTexture(profile.barTexture)
		self.HealPrediction:GetStatusBarTexture():SetDrawLayer("ARTWORK", -1)
		self.HealPrediction:SetStatusBarColor(0, 1, 1)
		self.HealPrediction:SetPoint("TOPLEFT", self.Health, 0, -2)
		self.HealPrediction:SetPoint("BOTTOMRIGHT", self.Health, 0, 2)
	elseif self.HealPrediction then
		self:DisableElement("HealPrediction")
		self.HealPrediction:Hide()
	end
end

local function LayoutCombatFeedback(self, c, initial)
	if c.combatFeedback then
		if not self.SimpleCombatFeedback then
			self.SimpleCombatFeedback = self:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
		end
		if not initial then self:EnableElement("SimpleCombatFeedback") end
		self.SimpleCombatFeedback:ClearAllPoints()
		self.SimpleCombatFeedback:SetPoint("CENTER", c.portrait and self.PortraitFrame or self.NameFrame)
	elseif self.SimpleCombatFeedback then
		self:DisableElement("SimpleCombatFeedback")
		self.SimpleCombatFeedback:Hide()
	end
end

local function LayoutSounds(self, c, initial)
	if c.sounds then
		self.SoundOnSelect = self.SoundOnSelect or {}
		self.SoundOnSelect.channel = c.sounds
		if not initial then self:EnableElement("SoundOnSelect") end
	elseif self.SoundOnSelect then
		self:DisableElement("SoundOnSelect")
	end
	if c.pvpSound then
		self.PvPSound = self.PvPSound or {}
		self.PvPSound.channel = c.pvpSound
		if not initial then self:EnableElement("PvPSound") end
	elseif self.PvPSound then
		self:DisableElement("PvPSound")
	end
end

local function LayoutCastbar(self, c, initial)
	if c.castbar then
		local Castbar = self.Castbar
		if not Castbar then
			self.Castbar = CreateFrame( "StatusBar", nil, self.NameFrame )
			Castbar = self.Castbar
			Castbar:SetBackdrop( {
				bgFile = Core.texturePath..[[black0_32px]], tile = true, tileSize = 32,
				insets = {left = 0, right = 0, top = 0, bottom = 0},
			})
			Castbar.Text = Castbar:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
			Castbar.Time = Castbar:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
			Castbar.Icon = Castbar:CreateTexture(nil, 'OVERLAY')
			Castbar.Icon.bg = Castbar:CreateTexture(nil, 'OVERLAY')
			Castbar.SafeZone = Castbar:CreateTexture(nil, "OVERLAY")
			Castbar.Shield = Castbar:CreateTexture(nil)
			Castbar.Shield:SetDrawLayer("OVERLAY", 1)
			Castbar.Shield:SetTexture([[Interface\CastingBar\UI-CastingBar-Arena-Shield]])
			Castbar.Shield:SetTexCoord(0/64, 40/64, 6/64, 56/64)
		end
		if not initial then self:EnableElement("Castbar") end
		Castbar:SetPoint( "TOPLEFT", 4, -4 )
		Castbar:SetPoint( "BOTTOMRIGHT", -4, 4 )
		Castbar:SetFrameLevel(6)

		Castbar:SetBackdropBorderColor(.5, .5, .5, 1)
		Castbar:SetBackdropColor( 0, 0, 0, 1 )
		Castbar:SetStatusBarTexture( profile.barTexture )
		Castbar:SetStatusBarColor( 1, 1, 0 )

		Castbar.Text:SetPoint('LEFT', Castbar, c.nameH, 0)
		Castbar.Text:SetTextColor(1, 1, 1)

		Castbar.Time:SetPoint('RIGHT', Castbar, -3, 0)
		Castbar.Time:SetTextColor(1, 1, 1)

		Castbar.Icon:SetSize( c.nameH - 6, c.nameH - 6 )
		Castbar.Icon:SetTexCoord(0, 1, 0, 1)
		Castbar.Icon:SetPoint( "TOPLEFT", 0, 0 )

		Castbar.Icon.bg:SetPoint("TOPLEFT", Castbar.Icon, "TOPLEFT")
		Castbar.Icon.bg:SetPoint("BOTTOMRIGHT", Castbar.Icon, "BOTTOMRIGHT")
		Castbar.Icon.bg:SetVertexColor(0.25, 0.25, 0.25)

		Castbar.SafeZone:SetTexture(1,0,0,.5)

		Castbar.Shield:SetPoint( "CENTER", Castbar.Icon  )
		local shieldIconSpace = 22 -- size of icon that would fit properly in the center of the shield
		Castbar.Shield:SetWidth(40 * Castbar.Icon:GetWidth() / shieldIconSpace)
		Castbar.Shield:SetHeight(50 * Castbar.Icon:GetHeight() / shieldIconSpace)
	elseif self.Castbar then
		self:DisableElement("Castbar")
		self.Castbar:Hide()
	end
end

local Layout = function(self, initial)
	local c = self.settings

	-- Alphas. XPerl is weird about this. Nested frames get an alpha that combines with the main one, with some exceptions.
	local alpha = c.alpha
	self:SetAlpha(alpha / 255)
	if c.nestedAlpha then
		self.NameFrame:SetAlpha(alpha / 255)
		self.StatsFrame:SetAlpha(alpha / 255)
	else
		self.NameFrame:SetAlpha(1)
		self.StatsFrame:SetAlpha(1)
	end

	self.corner = false -- to make sure nothing tries to use until it's set
	LayoutNameAndStats(self, c, initial)
	LayoutPortrait(self, c, initial)
	LayoutLevel(self, c, initial)

	-- 4 basic layouts.
	local width
	local height = max(c.portrait and c.portraitH or 0, c.nameH + (c.healthH + c.powerH + 10) + c.statsTopPadding)
	if c.embedLevelAndClassIcon and (c.level or c.classIcon) then
		if c.portrait then
			-- "group" frame w/ portrait
			if c.level then
				attach(self, "LevelFrame", "TOPLEFT", nil, "TOPLEFT", 0, 0)
				attach(self, "PortraitFrame", "TOPLEFT", "LevelFrame", "TOPRIGHT", -2, 0)
			else
				attach(self, "PortraitFrame", "TOPLEFT", nil, "TOPLEFT", 27 - 2, 0)
			end
			attach(self, "NameFrame", "TOPLEFT", "PortraitFrame", "TOPRIGHT", c.portraitPadding, 0)
			attach(self, "StatsFrame", "TOPLEFT", "NameFrame", "BOTTOMLEFT", 0, -c.statsTopPadding)
			width = 27 + c.portraitW - 2 + max(c.nameW, c.statsW) + c.portraitPadding
			self.corner = self.PortraitFrame
		else
			-- "group" frame w/o portrait. This has the distinctive embedded level frame.
			attach(self, "NameFrame", "TOPLEFT", nil, "TOPLEFT", 0, 0)
			attach(self, "LevelFrame", "TOPLEFT", "NameFrame", "BOTTOMLEFT", 0, -c.statsTopPadding)
			attach(self, "StatsFrame", "TOPLEFT", "LevelFrame", "TOPRIGHT", -2, 0)
			width = max(c.nameW, 30 + c.statsW - 2)
			self.corner = self.LevelFrame
		end
	else
		width = max(c.nameW, c.statsW)
		if c.portrait then
			-- "standard" frame w/ portrait, like player & target.
			attach(self, "PortraitFrame", "TOPLEFT", nil, "TOPLEFT", 0, 0)
			attach(self, "NameFrame", "TOPLEFT", "PortraitFrame", "TOPRIGHT", c.portraitPadding, 0)
			if c.level then
				attach(self, "LevelFrame", "TOPRIGHT", "PortraitFrame", "TOPLEFT", 2, 0)
			end
			width = width + c.portraitW + c.portraitPadding
			self.corner = self.PortraitFrame
		else
			-- "standard" frame w/o portrait, like the default targettarget
			attach(self, "NameFrame", "TOPLEFT", nil, "TOPLEFT", 0, 0)
			if c.level then
				attach(self, "LevelFrame", "TOPRIGHT", "NameFrame", "TOPLEFT", 2, 0)
			end
			self.corner = self.StatsFrame
		end
		attach(self, "StatsFrame", "TOPLEFT", "NameFrame", "BOTTOMLEFT", 0, -c.statsTopPadding)
	end
	self:SetSize(width, height)

	LayoutHealPrediction(self, c, initial)
	LayoutCombatFeedback(self, c, initial)
	LayoutRange(self, c, initial)
	LayoutPvPIcon(self, c, initial)
	LayoutRaidIcon(self, c, initial)
	LayoutLeaderIcon(self, c, initial)
	LayoutMasterLooterIcon(self, c, initial)
	LayoutCombatIcon(self, c, initial)
	LayoutClassIcon(self, c, initial)
	LayoutEliteFrame(self, c, initial)
	LayoutRaceFrame(self, c, initial)
	LayoutSounds(self, c, initial)
	LayoutCastbar(self, c, initial)
end

local eliteTypeDisplay = {
	worldboss = "Boss",
	rare = "Rare",
	rareelite = "Rare+",
	elite = "Elite",
	pet = "Pet",
}
local PostUpdate = function(self, event)
	local c = self.settings
	local unit = self.unit
	if c.eliteType then
		local eliteType = UnitClassification(unit)
		if eliteType == "normal" and UnitPlayerControlled(unit) and not UnitIsPlayer(unit) then
			eliteType = "pet"
		end
		if eliteType == "normal" then
			if c.classIcon then self.ClassIcon:Show() end
			self.EliteFrame:Hide()
		else
			if c.classIcon then self.ClassIcon:Hide() end
			local text = self.EliteFrame.text
			local color = self.colors.elite[eliteType]
			text:SetText(eliteTypeDisplay[eliteType])
			text:SetTextColor(color[1], color[2], color[3])
			self.EliteFrame:SetWidth(text:GetStringWidth() + 10)
			self.EliteFrame:Show()
		end
	end
	if c.npcRace then
		if UnitIsPlayer(unit) then
			self.RaceFrame:Hide()
		else
			local race = UnitCreatureFamily(unit) or UnitCreatureType(unit)
			self.RaceFrame.text:SetText(race)
			self.RaceFrame:SetWidth(self.RaceFrame.text:GetStringWidth() + 10)
			self.RaceFrame:ClearAllPoints()
			attach(self, "RaceFrame", "TOPLEFT", "corner", "BOTTOMLEFT", 0, 2)
			-- FIXME: special logic for too-long races
			-- if self.RaceFrame:GetWidth() > self.PortraitFrame:GetWidth() then
				-- attachLeft = not attachLeft
			-- end
			-- if attachLeft then
				-- self.RaceFrame:SetPoint("TOPLEFT", self.PortraitFrame, "BOTTOMLEFT", 0, 2)
			-- else
				-- self.RaceFrame:SetPoint("TOPRIGHT", self.PortraitFrame, "BOTTOMRIGHT", 0, 2)
			-- end
			self.RaceFrame:Show()
		end
	end
end

local Shared = function(self, unit, isSingle)
	self.menu = menu
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyUp")

	DoNameFrame(self, unit, isSingle)
	DoStatsFrame(self, unit, isSingle)

	self.colors = Module.colors
	self.PostUpdate = PostUpdate

	self.settings = profile[unit] or profile.party
	self.Layout = Layout
	self:Layout(true)
end

function Module:LayoutAll()
	if oUF then
		for i = 1,#oUF.objects do
			oUF.objects[i]:Layout()
		end
	end
end

function Module:PLAYER_FLAGS_CHANGED(event, unit)
	local unitFrame = oUF.units[unit]
	if unitFrame and unitFrame:IsShown() then
		unitFrame.Health:ForceUpdate()
	end
end

function Module:InitOUFSettings()
	self.InitOUFSettings = nil
	oUF = Core.oUF
	self.colors = setmetatable({
		health = {0, 1, 0},
		gray = {0.5, 0.5, 0.5},
		tapped = {0.5, 0.5, 0.5},
		-- power = setmetatable({
		-- }, {__index = oUF.colors.power}),
		elite = {
			worldboss = { 1, 0.5, 0.5 },
			rare = { 0.8, 0.8, 0.8 },
			rareelite = { 0.8, 0.8, 0.8 },
			elite = { 1, 1, 0.5 },
			pet = { 1, 1, 1 },
		},
		reaction = {
			{ 1, 0, 0 }, -- 1, enemy
			{ 1, 0, 0 }, -- 2, enemy
			{ 1, .5, 0 }, -- 3, unfriendly
			{ 1, 1, 0 }, -- 4, neutral
			{ 0, 1, 0 }, -- 5, friend
			{ 0, 1, 0 }, -- 6, friend
			{ 0, 1, 0 }, -- 7, friend
			{ 0, 1, 0 }, -- 8, friend
		},
		nameDefault = { 0.5, 0.5, 1 },
	}, {__index = oUF.colors})

	-- Tags. FIXME: this is just an example
	oUF.Tags['perllite:Foo'] = function(unit)
		if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end
		return "FOO"..UnitHealth(unit) .. '/' .. UnitHealthMax(unit)
	end
	oUF.TagEvents['perllite:Foo'] = oUF.TagEvents.missinghp
end

function Module:EnableOrDisableFrame(unit)
	local frame = (unit == "party") and self.partyHeader or oUF.units[unit]
	if profile[unit].enabled then
		if frame then
			frame:Enable()
			frame:Layout()
		else
			oUF:SetActiveStyle(_addonName)
			if unit == "party" then
				frame = oUF:SpawnHeader(_addonName.."_Party", nil, "raid,party",
					"showParty", true,
					"yOffset", -23
					--[=[
					"oUF-initialConfigFunction", [[
						self:SetWidth(225)
						self:SetHeight(60)
					]]
					--]=]
				)
				self.partyHeader = frame
				frame.Layout = function(self)
					for i = 1,#self do
						self[i]:Layout()
					end
				end
				frame.UpdateAllElements = function(self, ...)
					for i = 1,#self do
						self[i]:UpdateAllElements(...)
					end
				end
			else
				local cunit = unit:gsub("target","Target"):gsub("^%l", strupper)
				frame = oUF:Spawn(unit, _addonName.."_"..cunit)
			end
			Core.Movable:RegisterMovable(frame, unit)
		end
		if unit == "player" then
			Core.LayoutResource:Enable()
		end
	elseif frame then
		if unit == "player" then
			Core.LayoutResource:Disable()
		end
		frame:Disable()
	end
end

function Module:OnInitialize()
	self.OnInitialize = nil
	self:ProfileChanged()
	Core:RegisterForProfileChange(self, "ProfileChanged")

	self:InitOUFSettings()
	oUF:RegisterStyle(_addonName, Shared)
end

function Module:OnEnable()
	self:RegisterEvent("PLAYER_FLAGS_CHANGED")
	self:EnableOrDisableFrame("player")
	self:EnableOrDisableFrame("pet")
	self:EnableOrDisableFrame("target")
	self:EnableOrDisableFrame("targettarget")
	self:EnableOrDisableFrame("focus")
	self:EnableOrDisableFrame("focustarget")
	self:EnableOrDisableFrame("party")
end

function Module:OnDisable()
end
--@do-not-package@ --{{{

function _G:PerlTest()
	_G.b = _G.PerlLite_Target
end

--}}} --@end-do-not-package@
