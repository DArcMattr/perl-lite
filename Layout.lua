--[[-------------------------------------------------------------------------
	"PerlLite" - a Perl layout for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.
---------------------------------------------------------------------------]]
--{{{ top
local _addonName, _addonScope = ...

local Core = LibStub("AceAddon-3.0"):GetAddon(_addonName)
local Module = Core:NewModule("Layout", "AceEvent-3.0")
Core.Layout = Module
local L = Core.L
local profile

local oUF = _addonScope.oUF or oUF
_addonScope.oUF = oUF
assert(oUF, _addonName .. " was unable to locate oUF.")

local __OUF_1_5__ = not not oUF.units
--}}}
--{{{ upvalues
-- GLOBALS: CreateFrame
-- GLOBALS: FAILED
-- GLOBALS: GameFontNormal
-- GLOBALS: IsResting
-- GLOBALS: SPELL_FAILED_INTERRUPTED
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
-- GLOBALS: UnitIsPVP
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
local geterrorhandler = geterrorhandler
local max = max
local next = next
local rawget = rawget
local setmetatable = setmetatable
local strmatch = strmatch
local strupper = strupper
local tostring = tostring
local unpack = unpack
local wipe = wipe
--}}}

local stylePrototypes; do -- styles
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
	alpha = 216,
	nestedAlpha = true,
	rangeAlphaCoef = false,
	sounds = false,
	castbar = false,
	castTime = false,
	castSafeZone = false,
	castShield = true,
	castIcon = false,
	castIconSize = 20,
	castIconX = -8,
	castIconY = 0,
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
	statTags = true,
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
stylePrototypes = {
	player = {
		scale = 0.9,
		attachPoint = "TOPLEFT",
		attachX = 22,
		attachY = -22,
		nestedAlpha = false,
		castTime = true,
		castSafeZone = true,
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
		scale = 0.7,
		attachPoint = "TOPLEFT",
		attachX = 128,
		attachY = -75,
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
		statTags = false,
		healthH = 14,
		healthFontSize = 10,
		powerFormat = "val/max full",
	},
	target = {
		scale = 0.8,
		attachPoint = "TOP",
		attachX = -177,
		attachY = -22,
		sounds = "Master",
		castbar = true,
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
		scale = 0.7,
		attachPoint = "TOP",
		attachX = -15,
		attachY = -22,
		level = false,
		classIcon = false,
		raidIcon = "RIGHT",
	},
	focus = {
		_inherits = "target",
		scale = 0.8,
		attachPoint = "LEFT",
		attachX = 256,
		attachY = 148,
	},
	focustarget = {
		_inherits = "targettarget",
		scale = 0.7,
		attachPoint = "LEFT",
		attachX = 450,
		attachY = 151,
	},
	party = {
		scale = 0.8,
		attachPoint = "TOPLEFT",
		attachX = 0,
		attachY = -140,
		rangeAlphaCoef = 0.5,
		combatFeedback = true,
		embedLevelAndClassIcon = true,
		pvpIcon = "RIGHT",
		pvpIconSize = 23.5,
		pvpIconX = -8,
		pvpIconY = -0.5,
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
	partypet = {
		scale = 0.7,
		level = false,
		classIcon = false,
		pvpIcon = false,
		nameW = 80,
		nameFontSize = 10,
		nameLeft = true,
		nameH = 20,
		statsW = 80,
		statsTopPadding = -4,
		statTags = false,
		healthH = 13,
		healthFormat = "val%",
		powerH = 0,
	},
	partytarget = {
		_inherits = false,
		alpha = 216,
		scale = 1,
		pvpIcon = "TOPLEFT",
		pvpIconSize = 21,
		pvpIconX = 7.5,
		pvpIconY = -10.5,
		pvpTimer = false,
		raidIcon = "RIGHT",
		raidIconSize = 16,
		raidIconX = 1,
		raidIconY = 0,
		width = 120,
		nameH = 10,
		nameFontSize = 10,
		healthH = 7,
		healthFontSize = 10,
		healthFormat = "val%",
	},
}
--}}} style data
--{{{ style init
do
	local complainsInvalidStyleProperty = {
		__index = function(self, key)
			error("invalid style property: "..(rawget(self, "_style") or "???").."."..tostring(key))
		end
	}
	setmetatable(basicStyle, complainsInvalidStyleProperty)
	local indexesBasicStyle = { __index = basicStyle }
	for k,proto in next, stylePrototypes do
		proto._style = k -- so a style knows its own name
		proto._indexme = { __index = proto }
		local meta
		if proto._inherits then
			meta = { __index=stylePrototypes[proto._inherits] }
		elseif proto._inherits == false then
			meta = complainsInvalidStyleProperty
		else
			meta = indexesBasicStyle
		end
		setmetatable(proto, meta)
	end
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

function Module:UpdateSettingsPointer(newSettings)
	profile = newSettings
	for styleName,proto in next, stylePrototypes do
		profile[styleName] = profile[styleName] or {}
		setmetatable(profile[styleName], proto._indexme)
	end
	for _,frame in next, Core.frames do
		if frame.settings then
			frame.settings = profile[frame.stylekey]
		end
	end
end

function Module:PruneSettings()
	for styleName,proto in next, stylePrototypes do
		local settings = profile[styleName]
		setmetatable(settings, nil)
		for k,v in next, settings do
			if v == proto[k] then
				settings[k] = nil
			end
		end
		if not next(settings) then
			profile[styleName] = nil
		end
	end
end

function Module:LoadSettings()
	do -- color upvalues
		local color = profile.color
		local s,e = color.gradientStart, color.gradientEnd
		grad1r, grad1g, grad1b, grad1a = s[1]/255, s[2]/255, s[3]/255, s[4]/255
		grad2r, grad2g, grad2b, grad2a = e[1]/255, e[2]/255, e[3]/255, e[4]/255
	end
	-- the frames themselves
	self:EnableOrDisableFrame("player")
	self:EnableOrDisableFrame("pet")
	self:EnableOrDisableFrame("target")
	self:EnableOrDisableFrame("targettarget")
	self:EnableOrDisableFrame("focus")
	self:EnableOrDisableFrame("focustarget")
	self:EnableOrDisableFrame("party")
end

local menu = function(self)
	local unit = self.unit:sub(1, -2)
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

Module.valMaxFormatters["val%"] = function(fontString, val, maxVal)
	return fontString:SetFormattedText("%d%%", (100 * val / maxVal))
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
		if react >= 5 and UnitPlayerControlled(unit) and not UnitIsPVP(unit) then
			nameColor = self.colors.nameDefault
		else
			nameColor = self.colors.reaction[react]
		end
	end
	name:SetTextColor(nameColor[1], nameColor[2], nameColor[3])

	-- health bar fullness
	local val, maxVal = UnitHealth(unit), UnitHealthMax(unit)
	health:SetMinMaxValues(0, maxVal)
	health:SetValue(disconnected and maxVal or val) -- fill to maxVal when disconnected
	health.disconnected = disconnected

	-- health text & tag
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
	if health.tag then
		-- text & tag
		health.text:formatValMax(val, maxVal)
		if tag then
			health.tag:SetText(tag)
		elseif maxVal ~= 0 then
			health.tag:SetFormattedText("%d%%", (100 * val / maxVal))
		else
			health.tag:SetText("")
		end
	elseif tag then
		-- tag overrides text
		health.text:SetText(tag)
	else
		-- text only
		health.text:formatValMax(val, maxVal)
	end

	-- health color
	local r, g, b
	if tag then
		local t = self.colors.gray
		r, g, b = t[1], t[2], t[3]
	elseif health.colorSmooth then
		if __OUF_1_5__ then
			local perc = (maxVal ~= 0) and (val / maxVal) or 0
			r, g, b = self.ColorGradient(perc, unpack(health.smoothGradient or self.colors.smooth))
		else
			r, g, b = self.ColorGradient(val, maxVal, unpack(health.smoothGradient or self.colors.smooth))
		end
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
		if self.Power and self.Power:IsShown() then
			self.Power:ForceUpdate()
		end
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
		if power.tag then power.tag:Hide() end
	else
		power.text:formatValMax(val, maxVal)
		power.text:Show()
		if power.tag then
			power.tag:SetFormattedText("%d%%", (100 * val / maxVal))
			power.tag:Show()
		end
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

local HealPredictionOverride = function(self, event, unit)
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

local function MakeStatusBarTag(bar)
	local tag = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tag:SetPoint("LEFT", bar, "RIGHT", 0, 1)
	tag:SetJustifyH("LEFT")
	tag:SetTextColor(1, 1, 1)
	return tag
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

local function createFrameIcon(frame, layer)
	local parent = frame.NameFrame or frame
	return parent:CreateTexture(nil, layer)
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

local function LayoutPvPIcon(self, c)
	if c.pvpIcon then
		if not self.PvP then
			self.PvP = createFrameIcon(self, "OVERLAY")
			self.PvP:SetTexCoord(0, 42/64, 0, 42/64) -- icon is 42x42 in a 64x64 file
		end
		self:EnableElement("PvP")
		self.PvP:SetSize(c.pvpIconSize, c.pvpIconSize)
		self.PvP:SetPoint("CENTER", self.PvP:GetParent(), c.pvpIcon, c.pvpIconX, c.pvpIconY)
	elseif self.PvP then
		self:DisableElement("PvP")
		self.PvP:Hide()
	end

	if c.pvpTimer and c.pvpIcon then
		if not self.PvPTimer then
			self.PvPTimer = self.NameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			self.PvPTimer:SetTextColor(1, 1, 1)
		end
		self:EnableElement("PvPTimer")
		self.PvPTimer:SetPoint("CENTER", self.PvP, "CENTER", 0, 1)
	elseif self.PvPTimer then
		self:DisableElement("PvPTimer")
		self.PvPTimer:Hide()
	end
end

local function LayoutRaidIcon(self, c)
	if c.raidIcon then
		if not self.RaidIcon then
			self.RaidIcon = createFrameIcon(self, "OVERLAY")
		end
		self:EnableElement("RaidIcon")
		self.RaidIcon:SetSize(c.raidIconSize, c.raidIconSize)
		self.RaidIcon:SetPoint("CENTER", self.RaidIcon:GetParent(), c.raidIcon, c.raidIconX, c.raidIconY)
	elseif self.RaidIcon then
		self:DisableElement("RaidIcon")
		self.RaidIcon:Hide()
	end
end

local function LayoutLeaderIcon(self, c)
	if c.leaderIcon then
		if not self.Leader then
			self.Leader = createFrameIcon(self, "OVERLAY")
		end
		self:EnableElement("Leader")
		self.Leader:SetSize(c.leaderIconSize, c.leaderIconSize)
		self.Leader:SetPoint("CENTER", self.Leader:GetParent(), c.leaderIcon, c.leaderIconX, c.leaderIconY)
	elseif self.Leader then
		self:DisableElement("Leader")
		self.Leader:Hide()
	end
end

local function LayoutMasterLooterIcon(self, c)
	if c.masterLooterIcon then
		if not self.MasterLooter then
			self.MasterLooter = createFrameIcon(self, "OVERLAY")
		end
		self:EnableElement("MasterLooter")
		self.MasterLooter:SetSize(c.masterLooterIconSize, c.masterLooterIconSize)
		self.MasterLooter:SetPoint("CENTER", self.MasterLooter:GetParent(), c.masterLooterIcon, c.masterLooterIconX, c.masterLooterIconY)
	elseif self.MasterLooter then
		self:DisableElement("MasterLooter")
		self.MasterLooter:Hide()
	end
end

local function LayoutCombatIcon(self, c)
	if c.combatIcon then
		if not self.Combat then
			self.Combat = createFrameIcon(self, "OVERLAY")
			self.Combat:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			self.Combat:SetTexCoord(32/64, 64/64, 0/64, 32/64)
			self.Combat.Override = CombatOverride
			self.Resting = createFrameIcon(self, "OVERLAY")
			self.Resting:SetTexture([[Interface\CharacterFrame\UI-StateIcon]])
			self.Resting:SetTexCoord(0/64, 32/64, 0/64, 32/64)
			self.Resting.Override = RestingOverride
		end
		self:EnableElement("Combat")
		self:EnableElement("Resting")
		self.Combat:SetSize(c.combatIconSize, c.combatIconSize)
		self.Combat:SetPoint("CENTER", self.Combat:GetParent(), c.combatIcon, c.combatIconX, c.combatIconY)
		self.Resting:SetSize(c.combatIconSize, c.combatIconSize)
		self.Resting:SetPoint("CENTER", self.Resting:GetParent(), c.combatIcon, c.combatIconX, c.combatIconY)
	elseif self.Combat then
		self:DisableElement("Combat")
		self.Combat:Hide()
		self:DisableElement("Resting")
		self.Resting:Hide()
	end
end

local function LayoutRange(self, c)
	if c.rangeAlphaCoef then
		self.Range = self.Range or {}
		self.Range.insideAlpha = c.alpha / 255
		self.Range.outsideAlpha = floor(c.alpha * c.rangeAlphaCoef + .5) / 255
		self:EnableElement("Range")
	elseif self.Range then
		self:DisableElement("Range")
	end
end

local function LayoutPortrait(self, c)
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
					self.PortraitFrame._3d = _3d
					_3d.PostUpdate = PortraitPostUpdate3D
					self.Portrait = _3d
				else
					local _2d = self.PortraitFrame._2d or self.PortraitFrame:CreateTexture(nil, "ARTWORK")
					self.PortraitFrame._2d = _2d
					self.Portrait = _2d
				end
				self:EnableElement("Portrait")
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

local function LayoutLevel(self, c)
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
		self:EnableElement("Level")
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

local function LayoutClassIcon(self, c)
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
		self:EnableElement("ClassIcon")
		self.ClassIcon:Show()
	elseif self.ClassIcon and self.ClassIcon:IsShown() then
		self.ClassIcon:Hide()
		self:DisableElement("ClassIcon")
		self.ClassIcon:SetTexture()
	end
end

local function LayoutEliteFrame(self, c)
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

local function LayoutRaceFrame(self, c)
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

local function LayoutName(self, c)
	if not self.Name then
		self.Name = self.NameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.Name:SetPoint("BOTTOMRIGHT", self.NameFrame, 0, 1)
		self.Name:SetTextColor(1, 1, 1)
		self:Tag(self.Name, "[name]")
	end
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
end

local function LayoutStats(self, c)
	local StatsFrame, Health, Power = self.StatsFrame, self.Health, self.Power

	-- Stats & Health
	if not StatsFrame then
		StatsFrame = CreateBorderedChildFrame(self)
		self.StatsFrame = StatsFrame

		Health = CreateStatusBar(StatsFrame)
		self.Health = Health
		Health:SetPoint("TOP", StatsFrame, 0, -5)
		Health:SetPoint("LEFT", StatsFrame, 5, 0)

		Health.frequentUpdates = true
		Health.colorSmooth = true
		Health.Override = HealthOverride

		self:EnableElement("Health")
	end
	UpdateBarTextures(Health)
	Health.text.formatValMax = Module.valMaxFormatters[c.healthFormat]
	Health.text:SetFont(GameFontNormal:GetFont(), c.healthFontSize)
	Health:SetHeight(c.healthH)

	-- Power
	if c.powerH > 0 then
		if not Power then
			Power = CreateStatusBar(StatsFrame)
			self.Power = Power
			Power:SetPoint("TOPRIGHT", Health, "BOTTOMRIGHT", 0, 0)
			Power:SetPoint("BOTTOMLEFT", StatsFrame, 5, 5)
			Power.frequentUpdates = true
			Power.Override = PowerOverride
		end
		self:EnableElement("Power")
		UpdateBarTextures(Power)
		Power.text.formatValMax = Module.valMaxFormatters[c.powerFormat]
		Power.text:SetFont(GameFontNormal:GetFont(), c.powerFontSize)
	elseif Power then
		self:DisableElement("Power")
		Power:Hide()
	end

	-- Tags
	local attachX = -5
	if c.statTags then
		if not Health.tag then
			Health.tag = Health._tag or MakeStatusBarTag(Health)
			Health.tag:Show()
		end
		Health.tag:SetFont(GameFontNormal:GetFont(), c.tagFontSize)
		Health.tag:SetSize(c.statTagW, c.statTagH)
		if c.powerH > 0 then
			if not Power.tag then
				Power.tag = Power._tag or MakeStatusBarTag(Power)
				Power.tag:Show()
			end
			Power.tag:SetFont(GameFontNormal:GetFont(), c.tagFontSize)
			Power.tag:SetSize(c.statTagW, c.statTagH)
		end
		attachX = attachX - c.statTagWSpace
	else
		if Health.tag then
			Health._tag = Health.tag
			Health.tag:Hide()
			Health.tag = nil
		end
		if Power and Power.tag then
			Power._tag = Power.tag
			Power.tag:Hide()
			Power.tag = nil
		end
	end

	-- Size & Layout of the StatsFrame
	UpdateFrameGradient(StatsFrame)
	StatsFrame:ClearAllPoints()
	StatsFrame:SetSize(c.statsW, c.healthH + (Power and Power:IsShown() and c.powerH or 0) + 10)
	Health:SetPoint("RIGHT", StatsFrame, attachX, 0)
end

local function LayoutHealPrediction(self, c)
	if c.healPrediction then
		if not self.HealPrediction then
			self.HealPrediction = CreateFrameSameLevel("StatusBar", nil, self.StatsFrame)
			self.HealPrediction.Override = HealPredictionOverride
		end
		self:EnableElement("HealPrediction")
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

local function LayoutCombatFeedback(self, c)
	if c.combatFeedback then
		if not self.SimpleCombatFeedback then
			self.SimpleCombatFeedback = self:CreateFontString(nil, "OVERLAY", "NumberFontNormalHuge")
		end
		self:EnableElement("SimpleCombatFeedback")
		self.SimpleCombatFeedback:ClearAllPoints()
		self.SimpleCombatFeedback:SetPoint("CENTER", c.portrait and self.PortraitFrame or self.NameFrame)
	elseif self.SimpleCombatFeedback then
		self:DisableElement("SimpleCombatFeedback")
		self.SimpleCombatFeedback:Hide()
	end
end

local function LayoutSounds(self, c)
	if c.sounds then
		self.SoundOnSelect = self.SoundOnSelect or {}
		self.SoundOnSelect.channel = c.sounds
		self:EnableElement("SoundOnSelect")
	elseif self.SoundOnSelect then
		self:DisableElement("SoundOnSelect")
	end
	if c.pvpSound then
		self.PvPSound = self.PvPSound or {}
		self.PvPSound.channel = c.pvpSound
		self:EnableElement("PvPSound")
	elseif self.PvPSound then
		self:DisableElement("PvPSound")
	end
end

local LayoutCastbar; do
	local function Flash_OnUpdate(self, elapsed)
		if self.fadeIn then
			local alpha = self.fadeIn + (elapsed * 3)
			if alpha < 1 then
				self.border:SetAlpha(alpha)
				self.fadeIn = alpha
			else
				self.border:SetAlpha(1)
				self.fadeIn = nil
				self.nameref:Show()
				self.nameref:SetAlpha(1 - self.fadeOut)
			end
		elseif self.holdTime then
			local holdTime = self.holdTime - elapsed
			if holdTime > 0 then
				self.holdTime = holdTime
			else
				self.holdTime = nil
				self.nameref:Show()
				self.nameref:SetAlpha(1 - self.fadeOut)
			end
		elseif self.fadeOut then
			local alpha = self.fadeOut - (elapsed * 2)
			if alpha > 0 then
				self:SetAlpha(alpha)
				self.textref:SetAlpha(alpha)
				self.nameref:SetAlpha(1 - alpha)
				self.fadeOut = alpha
			else
				self:Hide()
				self.textref:Hide()
				self.nameref:SetAlpha(1)
				self.fadeOut = nil
			end
		else
			self:Hide()
			error("Castbar FlashAndFade error. Hiding frame.")
		end
	end
	local function Castbar_OnHide(self)
		self.Text:Hide()
		if self.Icon then self.Icon:Hide() end
		if self.Shield then self.Shield:Hide() end
		self.Flash:Hide()
		self.Flash.nameref:Show()
		self.Flash.nameref:SetAlpha(1)
	end
	local function FlashAndFade(self, failure, r, g, b)
		local flash = self.Flash
		if r then
			flash.bg:Show()
			flash.bg:SetVertexColor(r, g, b)
		else
			flash.bg:Hide()
		end
		if failure and flash.fadeIn then
			flash.fadeIn = nil
			flash.holdTime = 1
			flash.border:Hide()
		end
		-- Additional calls can change color or convert to failure (above), but can't restart the animation (below).
		if not flash.fadeOut then
			self.Text:Show()
			flash.nameref:Hide()
			if failure then
				flash.fadeIn = nil
				flash.holdTime = 1
				flash.border:Hide()
			else
				flash.fadeIn = 0
				flash.holdTime = nil
				flash.border:Show()
			end
			local alpha = self:GetAlpha()
			flash:SetAlpha(alpha)
			flash.fadeOut = alpha
			flash:Show()
		end
	end
	local function ClearFlashing(self, r, g, b, alpha)
		self.Flash:Hide()
		self.Flash.fadeOut = nil
		self.__owner.Name:Hide()
		self.Text:Show()
		if self.Icon then self.Icon:Show() end
		self:SetAlpha(alpha)
		self.Text:SetAlpha(alpha)
		self:SetStatusBarColor(r, g, b, self.__owner.settings.alpha / 255)
	end

	local function PostCastStart(self, unit, name, _, castid)
		return self:ClearFlashing(1, .7, 0, 0.8)
	end
	local function PostCastFailed(self, unit, spellname, _, castid)
		self.Text:SetText(FAILED)
		return self:FlashAndFade(true, 1, 0, 0)
	end
	local function PostCastInterrupted(self, unit, spellname, _, castid)
		self.Text:SetText(SPELL_FAILED_INTERRUPTED)
		return self:FlashAndFade(true, 1, 0, 0)
	end
	local function PostCastStop(self, unit, spellname, _, castid)
		if not self.Flash.fadeOut then -- don't let success overwrite failure
			return self:FlashAndFade(false, 0, 1, 0)
		end
	end
	local function PostChannelStart(self, unit, name)
		return self:ClearFlashing(0, 1, 0, 1)
	end
	local function PostChannelStop(self, unit, spellname)
		if not self.Flash.fadeOut then -- don't let success overwrite failure
			return self:FlashAndFade(false)
		end
	end

	function LayoutCastbar(self, c)
		if c.castbar then
			local Castbar = self.Castbar
			if not Castbar then
				self.Castbar = CreateFrameSameLevel("StatusBar", nil, self.NameFrame)
				Castbar = self.Castbar
				Castbar:Hide()

				Castbar.FlashAndFade = FlashAndFade
				Castbar.ClearFlashing = ClearFlashing
				Castbar:SetScript("OnHide", Castbar_OnHide)
				Castbar.PostCastStart = PostCastStart
				Castbar.PostCastFailed = PostCastFailed
				Castbar.PostCastInterrupted = PostCastInterrupted
				Castbar.PostCastStop = PostCastStop
				Castbar.PostChannelStart = PostChannelStart
				Castbar.PostChannelStop = PostChannelStop

				Castbar.Text = self.NameFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				Castbar.Text:Hide()

				Castbar.spark = Castbar:CreateTexture(nil) -- intentionally lower-case; "Spark" has unnecessary default behavior
				Castbar.spark:SetDrawLayer("OVERLAY", 4)
				Castbar.spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
				Castbar.spark:SetBlendMode("ADD")

				Castbar.Flash = CreateFrameSameLevel("Frame", nil, self.NameFrame)
				local Flash = Castbar.Flash
				Flash:Hide()
				Flash:SetScript("OnUpdate", Flash_OnUpdate)
				Flash:SetPoint("CENTER", Castbar)
				Flash.nameref = self.Name
				Flash.textref = Castbar.Text
				Flash.bg = Flash:CreateTexture(nil, "BACKGROUND")
				Flash.bg:SetPoint("TOPLEFT", Castbar)
				Flash.bg:SetPoint("BOTTOMRIGHT", Castbar)
				Flash.border = Flash:CreateTexture(nil, "OVERLAY")
				Flash.border:SetAllPoints()
				Flash.border:SetTexture(Core.texturePath..[[bigbarflash]])
				Flash.border:SetDrawLayer("OVERLAY", 2)
				Flash.border:SetBlendMode("ADD")
			end
			self:EnableElement("Castbar")

			local ins = self.NameFrame:GetBackdrop().insets
			Castbar:SetPoint("TOPLEFT", ins.left, -ins.top)
			Castbar:SetPoint("BOTTOMRIGHT", -ins.right, ins.bottom)
			local cbarHeight = c.nameH - ins.top - ins.bottom
			local cbarWidth = c.nameW - ins.left - ins.right
			Castbar:SetStatusBarTexture(profile.barTexture)
			Castbar:GetStatusBarTexture():SetDrawLayer("OVERLAY", 1)

			Castbar.Text:SetPoint("TOPLEFT")
			Castbar.Text:SetPoint("BOTTOMRIGHT", 0, 1)
			Castbar.Text:SetTextColor(1, 1, 1)

			Castbar.spark:SetHeight(cbarHeight * 3.5)
			Castbar.spark:SetWidth(cbarHeight * 1.75)
			Castbar.spark:ClearAllPoints()
			Castbar.spark:SetPoint("CENTER", Castbar:GetStatusBarTexture(), "RIGHT")

			Castbar.Flash:SetWidth(cbarWidth * (164 / 152))
			Castbar.Flash:SetHeight(cbarHeight * (40 / 16))
			Castbar.Flash.bg:SetTexture(profile.barTexture)
			Castbar.Flash.bg:SetDrawLayer("OVERLAY", 1)

			if c.castTime then
				if not Castbar._time then
					Castbar._time = Castbar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
					Castbar._time:SetPoint("RIGHT", Castbar, -3, 0)
					Castbar._time:SetTextColor(1, 1, 1)
				end
				Castbar.Time = Castbar._time
				Castbar.Time:Show()
			elseif Castbar._time then
				Castbar._time:Hide()
				Castbar.Time = nil
			end

			if c.castSafeZone then
				if not Castbar._safezone then
					Castbar._safezone = Castbar:CreateTexture(nil, "OVERLAY")
					Castbar._safezone:SetTexture(1, 0, 0)
				end
				Castbar.SafeZone = Castbar._safezone
			elseif Castbar._safezone then
				Castbar._safezone:Hide()
				Castbar.SafeZone = nil
			end

			if c.castIcon then
				if not Castbar._icon then
					Castbar._icon = self:CreateTexture(nil)
					Castbar._icon:SetDrawLayer("OVERLAY", 2)
				end
				Castbar.Icon = Castbar._icon
				Castbar.Icon:Hide()
				Castbar.Icon:SetSize(c.castIconSize, c.castIconSize)
				Castbar.Icon:SetPoint("CENTER", self.NameFrame, c.castIcon, c.castIconX, c.castIconY)
			elseif Castbar._icon then
				Castbar._icon:Hide()
				Castbar.Icon = nil
			end

			if c.castShield and c.castIcon then
				if not Castbar._shield then
					Castbar._shield = self:CreateTexture(nil)
					Castbar._shield:SetDrawLayer("OVERLAY", 3)
					Castbar._shield:SetTexture([[Interface\CastingBar\UI-CastingBar-Arena-Shield]])
					Castbar._shield:SetTexCoord(0/64, 40/64, 6/64, 56/64)
					Castbar._shield:SetPoint("CENTER", Castbar.Icon)
				end
				Castbar.Shield = Castbar._shield
				Castbar.Shield:Hide()
				local shieldIconSpace = 22 -- size of icon that would fit properly in the center of the shield
				Castbar.Shield:SetWidth(40 * c.castIconSize / shieldIconSpace)
				Castbar.Shield:SetHeight(50 * c.castIconSize / shieldIconSpace)
			elseif Castbar._shield then
				Castbar._shield:Hide()
				Castbar.Shield = nil
			end

		elseif self.Castbar then
			self:DisableElement("Castbar")
			self.Castbar:Hide()
		end
	end
end

local function sizeForLayout(c, partyPositions)
	local extraWidth = 0
	local statsWidth = c.statsW
	local hasPortrait = c.portrait
	if hasPortrait then
		extraWidth = extraWidth + (c.portraitW + c.portraitPadding)
	end
	if c.embedLevelAndClassIcon and (c.level or c.classIcon) then
		if hasPortrait then
			-- extra space for LevelFrame outside the portrait
			extraWidth = extraWidth + (27 - 2)
		else
			-- embedded level frame adds to statsWidth
			statsWidth = statsWidth + (30 - 2)
		end
	end
	local width = extraWidth + max(c.nameW, statsWidth)

	local portraitHeight = hasPortrait and c.portraitH or 0
	local nameStatsHeight = c.nameH + (c.healthH + c.powerH + 10) + c.statsTopPadding
	local height = max(portraitHeight, nameStatsHeight)

	if partyPositions then
		local targetx = extraWidth + c.nameW - 2
		local targety = -c.nameH
		local petx = extraWidth + statsWidth - 2
		local pety = -(c.nameH + c.statsTopPadding)
		return width, height, targetx, targety, petx, pety
	else
		return width, height
	end
end

local function sizeForMiniLayout(c)
	local height = 4 + c.nameH + 2 + c.healthH + 5
	return c.width, height
end

local Layout = function(self)
	local c = self.settings

	LayoutName(self, c)
	LayoutStats(self, c)

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

	LayoutPortrait(self, c)
	LayoutLevel(self, c)

	-- 4 basic layouts.
	-- sizeForLayout() needs to match the width/height requirements of what's done here.
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
			self.corner = self.PortraitFrame
		else
			-- "group" frame w/o portrait. This has the distinctive embedded level frame.
			attach(self, "NameFrame", "TOPLEFT", nil, "TOPLEFT", 0, 0)
			attach(self, "LevelFrame", "TOPLEFT", "NameFrame", "BOTTOMLEFT", 0, -c.statsTopPadding)
			attach(self, "StatsFrame", "TOPLEFT", "LevelFrame", "TOPRIGHT", -2, 0)
			self.corner = self.LevelFrame
		end
	else
		if c.portrait then
			-- "standard" frame w/ portrait, like player & target.
			attach(self, "PortraitFrame", "TOPLEFT", nil, "TOPLEFT", 0, 0)
			attach(self, "NameFrame", "TOPLEFT", "PortraitFrame", "TOPRIGHT", c.portraitPadding, 0)
			if c.level then
				attach(self, "LevelFrame", "TOPRIGHT", "PortraitFrame", "TOPLEFT", 2, 0)
			end
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
	self:SetSize(sizeForLayout(c))
	if self.anchor then self.anchor:Resize() end

	LayoutHealPrediction(self, c)
	LayoutCombatFeedback(self, c)
	LayoutRange(self, c)
	LayoutPvPIcon(self, c)
	LayoutRaidIcon(self, c)
	LayoutLeaderIcon(self, c)
	LayoutMasterLooterIcon(self, c)
	LayoutCombatIcon(self, c)
	LayoutClassIcon(self, c)
	LayoutEliteFrame(self, c)
	LayoutRaceFrame(self, c)
	LayoutSounds(self, c)
	LayoutCastbar(self, c)
end

local MiniLayout = function(self)
	local c = self.settings
	local alpha = c.alpha
	self:SetAlpha(alpha / 255)
	self:SetSize(sizeForMiniLayout(c))

	if not self:GetBackdrop() then
		self:SetBackdrop(backdrop_gray125)
		self:SetBackdropColor(0, 0, 0, 1)
		self:SetBackdropBorderColor(.5, .5, .5, 1)
	end
	UpdateFrameGradient(self)

	local Name = self.Name
	if not Name then
		Name = self:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		self.Name = Name
		Name:SetPoint("TOPLEFT", 3, -4)
		Name:SetPoint("TOPRIGHT", -3, -4)
		Name:SetJustifyH("CENTER")
		Name:SetTextColor(1, 1, 1)
		self:Tag(Name, "[name]")
	end
	Name:SetHeight(c.nameH)
	Name:SetFont(GameFontNormal:GetFont(), c.nameFontSize)

	local Health = self.Health
	if not Health then
		Health = self._health
		self.Health = Health
		self._health = nil
		Health:SetPoint("BOTTOMLEFT", 5, 5)
		Health:SetPoint("BOTTOMRIGHT", -5, 5)

		Health.frequentUpdates = true
		Health.colorSmooth = true
		Health.Override = HealthOverride
		self:EnableElement("Health")
	end
	UpdateBarTextures(Health)
	Health.bg:SetDrawLayer("OVERLAY", 1)
	Health:GetStatusBarTexture():SetDrawLayer("OVERLAY", 2)
	Health.text.formatValMax = Module.valMaxFormatters[c.healthFormat]
	Health.text:SetFont(GameFontNormal:GetFont(), c.healthFontSize)
	Health:SetHeight(c.healthH)

	LayoutPvPIcon(self, c)
	LayoutRaidIcon(self, c)
	-- LayoutCombatIcon(self, c)
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
			if c.classIcon then
				if c.embedLevelAndClassIcon and not c.portrait then
					self.ClassIcon:Show()
				else
					self.ClassIcon:Hide()
				end
			end
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
			local race = UnitCreatureType(unit)
			self.RaceFrame.text:SetText(race)
			self.RaceFrame:SetWidth(self.RaceFrame.text:GetStringWidth() + 10)
			self.RaceFrame:ClearAllPoints()
			if self.corner == self.StatsFrame then
				attach(self, "RaceFrame", "TOPRIGHT", "corner", "BOTTOMLEFT", 0, 2)
			elseif self.RaceFrame:GetWidth() > self.corner:GetWidth() then
				attach(self, "RaceFrame", "TOPRIGHT", "corner", "BOTTOMRIGHT", 0, 2)
			else
				attach(self, "RaceFrame", "TOPLEFT", "corner", "BOTTOMLEFT", 0, 2)
			end
			self.RaceFrame:Show()
		end
	end
end

local function noop() end
local function LayoutOnce_OnUpdate(nameFrame)
	nameFrame:SetScript("OnUpdate", nil)
	local self = nameFrame:GetParent()

	self.colors = Module.colors
	self.PostUpdate = PostUpdate
	self.Layout = Layout
	-- Noop Layout's resize because we're supposed to have the correct size anyway at
	-- this point. (Because this initial show can happen in combat.) If it's wrong, I
	-- want it to fail; I don't want Layout to overwrite a bad size and obscure a bug.
	self.SetSize = noop
	self:Layout()
	self.SetSize = nil
	self:UpdateAllElements()
end

local function MiniLayoutOnce_OnUpdate(_health)
	_health:SetScript("OnUpdate", nil)
	local self = _health:GetParent()

	self.colors = Module.colors
	self.Layout = MiniLayout
	self.SetSize = noop -- see comment in LayoutOnce_OnUpdate
	self:Layout()
	self.SetSize = nil
	self:UpdateAllElements()
end

local Shared = function(self, unit, isSingle)
	self.menu = menu
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	self:RegisterForClicks("AnyUp")

	self.settings = profile[unit]
	if not self.settings then
		geterrorhandler()("no settings for unit '"..unit.."'")
		return
	end
	self.stylekey = self.settings._style
	self.Layout = noop

	-- Postpone as much initialization as possible. But we need the size, and a single child for OnUpdate.
	if isSingle then
		self:SetSize(sizeForLayout(self.settings))
	end
	if unit == "partytarget" then
		self._health = CreateStatusBar(self)
		self._health:SetScript("OnUpdate", MiniLayoutOnce_OnUpdate)
	else
		self.NameFrame = CreateBorderedChildFrame(self)
		if unit == "player" then
			-- Layout player frame immediately, so we can attach resources.
			local ee = self.EnableElement
			self.EnableElement = noop
			LayoutOnce_OnUpdate(self.NameFrame)
			self.EnableElement = ee
		else
			self.NameFrame:SetScript("OnUpdate", LayoutOnce_OnUpdate)
		end
	end
end

function Module:PLAYER_FLAGS_CHANGED(event, unit)
	local unitFrame = Core.frames[unit]
	if unitFrame and unitFrame:IsShown() then
		unitFrame.Health:ForceUpdate()
	end
end

function Module:InitOUFSettings()
	self.InitOUFSettings = nil
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
end

local partyConfigSnippit = [[
	local suffix = self:GetAttribute("unitsuffix")
	local parent = self:GetParent()
	local header = suffix and parent:GetParent() or parent
	local attr = suffix or "initial"

	local w = header:GetAttribute(attr.."-width")
	if w == nil then
		print("PerlLite: missing initialization for 'party"..(suffix or "").."' frame")
		return
	end
	local h = header:GetAttribute(attr.."-height")
	self:SetWidth(w)
	self:SetHeight(h)

	if suffix then
		local s = header:GetAttribute(attr.."-scale")
		local attach = header:GetAttribute(attr.."-attach")
		local attachTo = header:GetAttribute(attr.."-attachTo")
		local xOff = header:GetAttribute(attr.."-attachX")
		local yOff = header:GetAttribute(attr.."-attachY")
		self:SetScale(s)
		self:ClearAllPoints()
		self:SetPoint(attach, parent, attachTo, xOff / s, yOff / s)
	else
		header:CallMethod("newChildSpawned", self:GetName())
	end
]]
function Module:CreatePartyHeader()
	oUF:SetActiveStyle(_addonName)
	local header = oUF:SpawnHeader(_addonName.."_Party", nil, nil,
		"showParty", true,
		"yOffset", -23,
		"template", _addonName.."_PartyTemplate",
		"oUF-initialConfigFunction", partyConfigSnippit
	)
	Core.frames.party = header
	header.newChildSpawned = function(self, newChildName)
		for i = #self,1,-1 do
			local child = self[i]
			if child:GetName() == newChildName then
				Core.frames["party"..i] = child
				Core.frames["party"..i.."target"] = child.Target
				Core.frames["partypet"..i] = child.Pet
				break
			end
		end
	end
	header.Disable = function(self)
		for i = 1,#self do
			self[i]:Disable()
		end
	end
	header.Enable = function(self)
		for i = 1,#self do
			self[i]:Enable()
		end
	end
	header.UpdateAllElements = function(self, ...)
		for i = 1,#self do
			self[i]:UpdateAllElements(...)
			self[i].Target:UpdateAllElements(...)
			self[i].Pet:UpdateAllElements(...)
		end
	end
	header.Layout = function(self)
		local c = profile.party
		local iw, ih, tx, ty, px, py = sizeForLayout(c, true)

		-- target: width, height, scale, attach points
		local tw, th = sizeForMiniLayout(profile.partytarget)
		local ts = profile.partytarget.scale
		local ta1, ta2 = "BOTTOMLEFT", "TOPLEFT"
		if not c.leftToRight then
			ta1 = pointFlipH[ta1]
			ta2 = pointFlipH[ta2]
			tx = -tx
		end

		-- pet: width, height, scale, attach points
		local pw, ph = sizeForLayout(profile.partypet)
		local ps = profile.partypet.scale
		local pa1, pa2 = "TOPLEFT", "TOPLEFT"
		if not c.leftToRight then
			pa1 = pointFlipH[pa1]
			pa2 = pointFlipH[pa2]
			px = -px
		end

		for i = 1,#self do
			self[i]:Layout()
			self[i].Target:SetScale(ts)
			self[i].Target:ClearAllPoints()
			self[i].Target:SetPoint(ta1, self, ta2, tx / ts, ty / ts)
			self[i].Target:Layout()
			self[i].Pet:SetScale(ps)
			self[i].Pet:ClearAllPoints()
			self[i].Pet:SetPoint(pa1, self, pa2, px / ps, py / ps)
			self[i].Pet:Layout()
		end

		-- The _ignore attribute is an optimization; it keeps the secure header from recomputing
		-- everything when an attribute is set.
		self:SetAttribute("_ignore", true)
		self:SetAttribute("target-width", tw)
		self:SetAttribute("target-height", th)
		self:SetAttribute("target-scale", ts)
		self:SetAttribute("target-attach", ta1)
		self:SetAttribute("target-attachTo", ta2)
		self:SetAttribute("target-attachX", tx)
		self:SetAttribute("target-attachY", ty)
		self:SetAttribute("pet-width", pw)
		self:SetAttribute("pet-height", ph)
		self:SetAttribute("pet-scale", ps)
		self:SetAttribute("pet-attach", pa1)
		self:SetAttribute("pet-attachTo", pa2)
		self:SetAttribute("pet-attachX", px)
		self:SetAttribute("pet-attachY", py)
		self:SetAttribute("initial-width", iw)
		self:SetAttribute("_ignore", false)
		self:SetAttribute("initial-height", ih)

		self.container:Layout()
	end

	local container = CreateFrame("Frame", nil, header:GetParent())
	header.container = container
	header:SetParent(container)
	container.header = header
	container.Layout = function(container)
		local header = container.header
		local w = header:GetAttribute("initial-width")
		local h = header:GetAttribute("initial-height")
		local yOffset = header:GetAttribute("yOffset")
		container:SetSize(w, 4*h + 3*-yOffset)
		if container.anchor then container.anchor:Resize() end
	end
	header:SetPoint("TOPLEFT")
	Core.Movable:RegisterMovable(container, "party")

	header:Layout()
	header:Show()
end

function Module:EnableOrDisableFrame(unit)
	local frame = Core.frames[unit]
	if profile[unit].enabled then
		if frame then
			frame:Enable()
			frame:Layout()
			frame:UpdateAllElements()
		else
			if unit == "party" then
				self:CreatePartyHeader()
			else
				local cunit = unit:gsub("target","Target"):gsub("^%l", strupper)
				oUF:SetActiveStyle(_addonName)
				frame = oUF:Spawn(unit, _addonName.."_"..cunit)
				Core.frames[unit] = frame
				Core.Movable:RegisterMovable(frame, unit)
			end
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
	Core.db.RegisterCallback(self, "OnProfileShutdown", "PruneSettings")
	self:InitOUFSettings()
	oUF:RegisterStyle(_addonName, Shared)
end

function Module:OnEnable()
	self:RegisterEvent("PLAYER_FLAGS_CHANGED")
	self:LoadSettings()
end

function Module:OnDisable()
end
--@do-not-package@ --{{{

Core.oUF = oUF

--}}} --@end-do-not-package@
