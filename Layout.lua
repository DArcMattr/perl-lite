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
-- GLOBALS: ToggleDropDownMenu
-- GLOBALS: UnitClass
-- GLOBALS: UnitClassification
-- GLOBALS: UnitCreatureFamily
-- GLOBALS: UnitCreatureType
-- GLOBALS: UnitFrame_OnEnter
-- GLOBALS: UnitFrame_OnLeave
-- GLOBALS: UnitHealth
-- GLOBALS: UnitHealthMax
-- GLOBALS: UnitInRange
-- GLOBALS: UnitIsAFK
-- GLOBALS: UnitIsConnected
-- GLOBALS: UnitIsDead
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
local getmetatable = getmetatable
local max = max
local next = next
local setmetatable = setmetatable
local strmatch = strmatch
local strupper = strupper
local unpack = unpack
local wipe = wipe
--}}}

--{{{ styles
local basicStyle = {
	scale = 1,
	alpha = 216,
	rangeAlphaCoef = false,
	portrait = false,
	portraitW = 60,
	portraitH = 62,
	leftToRight = true,
	level = true,
	embedLevelAndClassIcon = false,
	classIcon = true,
	eliteType = false,
	npcRace = false,
	pvpIcon = "left",
	pvpIconSize = 26,
	pvpIconInset = 7,
	pvpTimer = false,
	nameW = 160,
	nameH = 24,
	statsW = 160,
	statsTopPadding = -2,
	statTagWSpace = 35,
	statTagW = 50,
	statTagH = 12,
	healthH = 20,
	powerH = 10,
	portraitPadding = -3,
}
local stylePrototype = {
	player = {
		portrait = "3d",
		pvpIconSize = 30,
		pvpTimer = true,
	},
	target = {
		portrait = "3d",
		leftToRight = false,
		eliteType = true,
		npcRace = true,
	},
	targettarget = {
		classIcon = false,
	},
	party = {
		rangeAlphaCoef = 0.5,
		embedLevelAndClassIcon = true,
		pvpIcon = "far",
		pvpIconSize = 24,
		nameW = 106,
		statsW = 142,
		statsTopPadding = -3,
		healthH = 21,
		portraitPadding = -2,
	},
}
--}}}
--{{{ style init
local style = {}
do
	local inheritsBasicStyle = { __index = function(self, key)
		local val = basicStyle[key]
		if val == nil then error("invalid style property: '"..key.."'") end
		return val
	end }
	local function cachingIndexFunction(self, key)
		local val = getmetatable(self).__prototype[key] -- '__prototype' isn't some big Lua convention; it's just our little design for these settings tables
		self[key] = val
		return val
	end
	for s,_ in next, stylePrototype do
		-- Set up indexing.
		setmetatable(stylePrototype[s], inheritsBasicStyle) -- All prototypes index basic style.
		style[s] = setmetatable({}, { __prototype = stylePrototype[s], __index = cachingIndexFunction }) -- New table, indexing prototype.
	end
end
Module.basicStyle = basicStyle
Module.stylePrototype = stylePrototype
Module.style = style
--}}}

function Module:ProfileChanged()
	profile = Core.db.profile
	for styleName, settings in next, style do
		wipe(settings) -- 1. wipe old settings for this style
		if profile[styleName] then -- 2. copy in settings from profile
			for i,j in next, profile[styleName] do
				settings[i] = j
			end
		end
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

local backdrop_black255 = {
	bgFile = Core.texturePath..[[black255_32px]], tile = true, tileSize = 32,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
}
--}}} textures & backdrops

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

local function formatNumberAndUnits(fontString, val, maxVal)
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
		nameColor = self.colors.class[class]
	else
		local react = UnitReaction(unit, "player")
		-- note: UnitSelectionColor is a possible alternative to UnitReaction
		nameColor = self.colors.reaction[react]
	end
	name:SetTextColor(nameColor[1], nameColor[2], nameColor[3])

	-- health bar fullness
	local val, maxVal = UnitHealth(unit), UnitHealthMax(unit)
	health:SetMinMaxValues(0, maxVal)
	health:SetValue(disconnected and maxVal or val) -- fill to maxVal when disconnected
	health.disconnected = disconnected

	-- health text
	if unit == "player" then
		health.text:SetFormattedText("%d", (val - maxVal)) -- 0 or negative
	else
		formatNumberAndUnits(health.text, val, maxVal)
	end

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
			local c = self.styleConf
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
		if unit == "player" then
			power.text:SetFormattedText("%d/%d", val, maxVal)
		else
			formatNumberAndUnits(power.text, val, maxVal)
		end
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

local function CreateStatusBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)

	-- bg texture
	local bg = bar:CreateTexture(nil, "BORDER")
	bar.bg = bg
	bg:SetAllPoints()
	bg:SetAlpha(.25)

	-- text
	local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	bar.text = text
	-- text:SetFont(GameFontNormal:GetFont(), 12)
	text:SetPoint("TOPLEFT", bar, 0, 0)
	text:SetPoint("BOTTOMRIGHT", bar, 0, 1)
	text:SetJustifyH("CENTER")
	text:SetTextColor(1, 1, 1)

	-- tag
	local tag = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	bar.tag = tag
	-- tag:SetFont(GameFontNormal:GetFont(), 10)
	tag:SetPoint("LEFT", bar, "RIGHT", 0, 1)
	tag:SetJustifyH("LEFT")
	tag:SetTextColor(1, 1, 1)

	return bar
end

local function UpdateBarTextures(bar)
	bar:SetStatusBarTexture(profile.barTexture)
	bar.bg:SetTexture(profile.barTexture)
end

local function SetStandardBackdrop(frame, backdrop)
	frame:SetBackdrop(backdrop or backdrop_gray125)
	frame:SetBackdropColor(0, 0, 0, 1)
	frame:SetBackdropBorderColor(.5, .5, .5, 1)
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
	if not self.styleConf.leftToRight then
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
	local NameFrame = CreateFrame("Frame", nil, unitFrame)
	unitFrame.NameFrame = NameFrame
	SetStandardBackdrop(NameFrame)

	local Name = NameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	unitFrame.Name = Name
	Name:SetPoint("TOPLEFT", NameFrame, 0, 0)
	Name:SetPoint("BOTTOMRIGHT", NameFrame, 0, 1)
	Name:SetJustifyH("CENTER")
	Name:SetTextColor(1, 1, 1)
	unitFrame:Tag(Name, "[name]")
end

local function DoStatsFrame(unitFrame, unit, isSingle)
	-- StatsFrame
	local StatsFrame = CreateFrame("Frame", nil, unitFrame)
	unitFrame.StatsFrame = StatsFrame
	SetStandardBackdrop(StatsFrame)

	-- Health
	local Health = CreateStatusBar(StatsFrame)
	unitFrame.Health = Health
	Health:SetPoint("TOP", StatsFrame, 0, -5)
	Health:SetPoint("LEFT", StatsFrame, 5, 0)

	-- I don't understand this oUF stuff yet
	Health.frequentUpdates = true
	Health.colorSmooth = true
	Health.Override = HealthOverride

	-- text & tag
	Health.text:SetFontObject(GameFontNormal)

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
			self.PvP = self.NameFrame:CreateTexture(nil, "ARTWORK")
			self.PvP:SetTexCoord(0, 42/64, 0, 42/64) -- icon is 42x42 in a 64x64 file
		end
		if not initial then self:EnableElement("PvP") end
		self.PvP:SetSize(c.pvpIconSize, c.pvpIconSize)
		local pos = c.pvpIcon
		if pos == "near" then pos = c.leftToRight and "left" or "right" end
		if pos == "far" then pos = c.leftToRight and "right" or "left" end
		if pos == "left" then
			self.PvP:SetPoint("CENTER", self.NameFrame, "LEFT", c.pvpIconInset, 0)
		else
			self.PvP:SetPoint("CENTER", self.NameFrame, "RIGHT", -(c.pvpIconInset), 0)
		end
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
		self.PortraitFrame = CreateFrame("Frame", nil, self)
		SetStandardBackdrop(self.PortraitFrame, backdrop_black255)
	end
	if self.PortraitFrame then
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
					local _3d = self.PortraitFrame._3d or CreateFrame("PlayerModel", nil, self.PortraitFrame)
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
	if c.level or specialLevelFrame then
		if not self.LevelFrame then
			self.LevelFrame = CreateFrame("Frame", nil, self)
			self.LevelFrame:SetFrameLevel(0) -- So we don't cover the ClassIcon when it's embedded.
			SetStandardBackdrop(self.LevelFrame, backdrop_gray125)
		end
		self.LevelFrame:ClearAllPoints()
		if specialLevelFrame then
			self.LevelFrame:SetSize(30, c.healthH + c.powerH + 10)
		else
			self.LevelFrame:SetSize(27, 22)
		end
		self.LevelFrame:Show()
	else
		self.LevelFrame:Hide()
	end
	if c.level then
		if not self.Level then
			self.Level = self.LevelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
		self.Level:Show()
	elseif self.LevelFrame then
		self:DisableElement("Level")
		self.Level:Hide()
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
			self.EliteFrame = CreateFrame("Frame", nil, self)
			SetStandardBackdrop(self.EliteFrame, backdrop_gray125)
			local text = self.EliteFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.EliteFrame.text = text
			text:SetPoint("TOPLEFT")
			text:SetPoint("BOTTOMRIGHT", 0, 1)
		end
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
			self.RaceFrame = CreateFrame("Frame", nil, self)
			SetStandardBackdrop(self.RaceFrame, backdrop_gray125)
			local text = self.RaceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.RaceFrame.text = text
			text:SetPoint("TOPLEFT")
			text:SetPoint("BOTTOMRIGHT")
			text:SetTextColor(1, 1, 1)
		end
		self.RaceFrame:SetSize(68, 22)
		self.RaceFrame:ClearAllPoints()
		-- positioning done in PostUpdate
	elseif self.RaceFrame then
		self.RaceFrame:Hide()
	end
end

local function LayoutNameAndStats(self, c, initial)
	self.NameFrame:ClearAllPoints()
	self.NameFrame:SetSize(c.nameW, c.nameH)

	self.StatsFrame:ClearAllPoints()
	self.StatsFrame:SetSize(c.statsW, c.healthH + c.powerH + 10)

	UpdateBarTextures(self.Health)
	self.Health:SetHeight(c.healthH)
	self.Health.tag:SetSize(c.statTagW, c.statTagH)

	UpdateBarTextures(self.Power)
	self.Power.tag:SetSize(c.statTagW, c.statTagH)
	self.Health:SetPoint("RIGHT", self.StatsFrame, -(5 + c.statTagWSpace), 0)
end

local Layout = function(self, initial)
	local c = self.styleConf
	
	-- Alphas. XPerl is weird about this. Nested frames get an alpha that combines with the main one, except for the Player frame.
	local alpha = c.alpha
	self:SetAlpha(alpha / 255)
	if self.unit ~= "player" then
		self.NameFrame:SetAlpha(alpha / 255)
		self.StatsFrame:SetAlpha(alpha / 255)
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
	
	LayoutRange(self, c, initial)
	LayoutPvPIcon(self, c, initial)
	LayoutClassIcon(self, c, initial)
	LayoutEliteFrame(self, c, initial)
	LayoutRaceFrame(self, c, initial)
end

local eliteTypeDisplay = {
	worldboss = "Boss",
	rare = "Rare",
	rareelite = "Rare+",
	elite = "Elite",
	pet = "Pet",
}
local PostUpdate = function(self, event)
	local c = self.styleConf
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

	self.styleConf = style[unit] or style.party
	self.Layout = Layout
	self:Layout(true)
end

local DoAuras = function(self)
	-- Buffs
	local Buffs = CreateFrame("Frame", nil, self)
	Buffs:SetPoint("BOTTOM", self, "TOP")
	Buffs:SetPoint"LEFT"
	Buffs:SetPoint"RIGHT"
	Buffs:SetHeight(17)

	Buffs.size = 17
	Buffs.num = floor(self:GetWidth() / Buffs.size + .5)

	self.Buffs = Buffs

	-- Debuffs
	local Debuffs = CreateFrame("Frame", nil, self)
	Debuffs:SetPoint("TOP", self, "BOTTOM")
	Debuffs:SetPoint"LEFT"
	Debuffs:SetPoint"RIGHT"
	Debuffs:SetHeight(20)

	Debuffs.initialAnchor = "TOPLEFT"
	Debuffs.size = 20
	Debuffs.showDebuffType = true
	Debuffs.num = floor(self:GetWidth() / Debuffs.size + .5)

	self.Debuffs = Debuffs
end

function Module:LayoutAll()
	for i = 1,#oUF.objects do
		oUF.objects[i]:Layout()
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
	}, {__index = oUF.colors})

	-- Tags. FIXME: this is just an example
	oUF.Tags['perllite:Foo'] = function(unit)
		if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end
		return "FOO"..UnitHealth(unit) .. '/' .. UnitHealthMax(unit)
	end
	oUF.TagEvents['perllite:Foo'] = oUF.TagEvents.missinghp
end

function Module:OnInitialize()
	self.OnInitialize = nil
	self:ProfileChanged()
	Core:RegisterForProfileChange(self, "ProfileChanged")

	self:InitOUFSettings()
	oUF:RegisterStyle(_addonName, Shared)

	-- A small helper to change the style into a unit specific, if it exists.
	local spawnHelper = function(self, unit)
		self:SetActiveStyle(_addonName)
		local cunit = unit:gsub("target","Target"):gsub("^%l", strupper)
		local object = self:Spawn(unit, _addonName.."_"..cunit)
		Core.Movable:RegisterMovable(object, unit)
		return object
	end

	oUF:Factory(function(self)
		local player = spawnHelper(self, "player")
		-- spawnHelper(self, "pet", "TOP", player, "BOTTOM", 0, -16)
		spawnHelper(self, "target")
		spawnHelper(self, "targettarget")

		self:SetActiveStyle(_addonName)
		local party = self:SpawnHeader(_addonName.."_Party", nil, "raid,party",
			"showParty", true,
			"yOffset", -23
			--[=[
			"oUF-initialConfigFunction", [[
				self:SetWidth(225)
				self:SetHeight(60)
			]]
			--]=]
		)
		Core.Movable:RegisterMovable(party, "party") -- TODO: needs an anchor frame
	end)
end

function Module:OnEnable()
	self:RegisterEvent("PLAYER_FLAGS_CHANGED")
end

function Module:OnDisable()
end
--@do-not-package@ --{{{

function _G:PerlTest()
	_G.b = _G.PerlLite_Target
end

--}}} --@end-do-not-package@