--[[-------------------------------------------------------------------------
	"PerlLite" - a Perl layout for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.

	I haven't open sourced this because I think it would lead to me lazily
	pasting in code from XPerl. (Under a GPL license, XPerl code could be pasted
	in freely.) When the project is more mature, I'll decide on a license.
---------------------------------------------------------------------------]]
--{{{ top
local _addonName, _addonScope = ...
_addonScope.oUF = _addonScope.oUF or oUF

local Addon = LibStub("AceAddon-3.0"):NewAddon(_addonName, "AceEvent-3.0", "AceConsole-3.0")
_G[_addonName] = Addon
local L = LibStub("AceLocale-3.0"):GetLocale(_addonName)
Addon.L = L
Addon.oUF = _addonScope.oUF; assert(Addon.oUF, _addonName .. " was unable to locate oUF.")
Addon.path = [[Interface\Addons\]].._addonName..[[\]]
Addon.texturePath = Addon.path..[[textures\]]

local profile
--}}}
--{{{ upvalues
-- GLOBALS: CreateFrame
-- GLOBALS: EnableAddOn
-- GLOBALS: GetAddOnInfo
-- GLOBALS: GetAddOnMetadata
-- GLOBALS: InterfaceOptionsFrame_OpenToCategory
-- GLOBALS: InterfaceOptions_AddCategory
-- GLOBALS: LibStub
-- GLOBALS: LoadAddOn
-- GLOBALS: _G
-- GLOBALS: assert
-- GLOBALS: gmatch
--}}}

Addon.defaults = {
	profile = {
		barTexture = Addon.texturePath..[[Smooth]], -- "Interface\\TargetingFrame\\UI-TargetingFrame-BarFill"
		color = {
			gradient = "VERTICAL",
			gradientStart = { 26, 26, 26, 0 },
			gradientEnd = { 64, 64, 64, 255},
		},
		resource = {
			eclipse = true,
			soulshards = true,
			holypower = true,
			runes = true,
			totems = true,
		},
		player = {
			scale = 0.9,
			attachPoint = "TOPLEFT",
			attachX = 22,
			attachY = -22,
		},
		pet = {
			scale = 0.7,
			attachPoint = "TOPLEFT",
			attachX = 128,
			attachY = -75,
		},
		target = {
			scale = 0.8,
			attachPoint = "TOP",
			attachX = -177,
			attachY = -22,
		},
		targettarget = {
			scale = 0.7,
			enableFrame = false,
			attachPoint = "TOP",
			attachX = -15,
			attachY = -22,
		},
		focus = {
			scale = 0.8,
			attachPoint = "LEFT",
			attachX = 256,
			attachY = 148,
		},
		focustarget = {
			scale = 0.7,
			enableFrame = false,
			attachPoint = "LEFT",
			attachX = 450,
			attachY = 151,
		},
		party = {
			scale = 0.8,
			attachPoint = "TOPLEFT",
			attachX = 0,
			attachY = -140,
		},
	}
}

function Addon:ProfileChanged()
	profile = self.db.profile
end

function Addon:RegisterForProfileChange(module, method)
	self.db.RegisterCallback(module, "OnProfileChanged", method)
	self.db.RegisterCallback(module, "OnProfileCopied", method)
	self.db.RegisterCallback(module, "OnProfileReset", method)
	self.db.RegisterCallback(module, "OnProfileDeleted", method)
end

function Addon:OnInitialize()
	self.OnInitialize = nil
	local DBVERSION = 1
	local savedVarName = GetAddOnMetadata(_addonName, "X-SavedVariables")
	_G[savedVarName] = _G[savedVarName] or { dbversion = DBVERSION }
	self.db = LibStub("AceDB-3.0"):New(_G[savedVarName], self.defaults, "Default")
	self:ProfileChanged()
	self:RegisterForProfileChange(self, "ProfileChanged")

	do
		local _, _addonTitle = GetAddOnInfo(_addonName)
		local function LoadOptions()
			if Addon.Options then return end
			EnableAddOn(_addonName.."_Options")
			LoadAddOn(_addonName.."_Options")
		end

		-- Command-line stubs for opening options.
		local function OpenOptions()
			LoadOptions()
			self.Options:OpenOptions()
		end
		for slashCmd in gmatch(GetAddOnMetadata(_addonName, "X-SlashCmdList"), "/(%a+)") do
			Addon:RegisterChatCommand(slashCmd, OpenOptions)
		end

		-- UI stub for opening options, but only if we need it.
		if not Addon.Options then
			local dummyOptionsFrame = CreateFrame("Frame")
			dummyOptionsFrame.name = _addonTitle
			dummyOptionsFrame:Hide()
			dummyOptionsFrame:SetScript("OnShow", function(frame)
				frame:SetScript("OnShow", nil)
				frame:Hide()
				LoadOptions()
				InterfaceOptionsFrame_OpenToCategory(_addonName)
			end)
			InterfaceOptions_AddCategory(dummyOptionsFrame, _addonName)
		end
	end
end

function Addon:OnEnable()
end

function Addon:OnDisable()
end
