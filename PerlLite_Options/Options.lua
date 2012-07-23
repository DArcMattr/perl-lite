--[[-------------------------------------------------------------------------
	Perl Lite Options
	Copyright (C) 2012  Morsk
	All Rights Reserved.
---------------------------------------------------------------------------]]
--{{{ top
local _optionsAddonName = ...
local _coreAddonName = strmatch(_optionsAddonName, "^(.*)_Options$")

local Core = LibStub("AceAddon-3.0"):GetAddon(_coreAddonName)
local Module = Core:NewModule("Options")
Core.Options = Module
Module.L = LibStub("AceLocale-3.0"):GetLocale(_optionsAddonName)
local LC = Core.L
local LO = Module.L
local profile
--}}}
--{{{ upvalues
-- GLOBALS: GetAddOnInfo
-- GLOBALS: INTERFACEOPTIONS_ADDONCATEGORIES
-- GLOBALS: InterfaceAddOnsList_Update
-- GLOBALS: LibStub
-- GLOBALS: tremove
--}}}

function Module:ProfileChanged()
	profile = Core.db.profile
end

function Module:OpenOptions()
	LibStub("AceConfigDialog-3.0"):Open(_coreAddonName)
end

function Module:CloseOptions()
	LibStub("AceConfigDialog-3.0"):Close(_coreAddonName)
end

--{{{ generic functions
local function generic_get_style(info)
	local setting, style = info[#info], info[#info-1]
	return Core.Layout.style[style][setting]
end

local function generic_get_style_or_false(info)
	local val = generic_get_style(info)
	return (val ~= false) and val or "false"
end

local function generic_set_style(info, val)
	local setting, style = info[#info], info[#info-1]
	local prototypeVal = Core.Layout.stylePrototype[style][setting]
	profile[style][setting] = (val ~= prototypeVal) and val or nil
	Core.Layout.style[style][setting] = val
	Core.oUF.units[style]:Layout()
	Core.oUF.units[style]:UpdateAllElements()
end

local function generic_set_style_or_false(info, val)
	return generic_set_style(info, (val ~= "false") and val or false)
end
--}}}

do --{{{ Module:MakeSectionArgs()
	-- scale = 1,
	-- alpha = 216,
	local alpha = { order = 2,
		type = "range",
		name = "Alpha",
		min = 0, max = 255, step = 1,
	}
	-- nestedAlpha = true,
	local nestedAlpha = { order = 3,
		type = "toggle",
		name = "Nested Alpha",
	}
	-- rangeAlphaCoef = false,
	-- portrait = false,
	local portrait = { order = 4,
		type = "select",
		name = "Portrait",
		values = { ["false"]="None", ["2d"]="2D", ["3d"]="3D" },
		get = generic_get_style_or_false,
		set = generic_set_style_or_false,
	}
	-- portraitW = 60,
	local portraitW = { order = 5,
		type = "range",
		name = "Portrait Width",
		min = 40, max = 80, step = 1,
	}
	-- portraitH = 62,
	local portraitH = { order = 6,
		type = "range",
		name = "Portrait Height",
		min = 40, max = 80, step = 1,
	}
	-- leftToRight = true,
	local leftToRight = { order = 7,
		type = "toggle",
		name = "Left-to-Right",
	}
	-- level = true,
	local level = { order = 8,
		type = "toggle",
		name = "Level",
	}
	-- embedLevelAndClassIcon = false,
	local embedLevelAndClassIcon = { order = 9,
		type = "toggle",
		name = "Embed Level & Class",
	}
	-- classIcon = true,
	local classIcon = { order = 10,
		type = "toggle",
		name = "Class",
	}
	-- eliteType = false,
	local eliteType = { order = 11,
		type = "toggle",
		name = "Elite",
	}
	-- npcRace = false,
	local npcRace = { order = 12,
		type = "toggle",
		name = "NPC Race",
	}
	-- pvpIcon = "left",
	local pvpIcon = { order = 13,
		type = "select",
		name = "PvP Icon",
		values = { ["false"]="None", left="Left", right="Right" },
		get = generic_get_style_or_false,
		set = generic_set_style_or_false,
	}
	-- pvpIconSize = 26,
	local pvpIconSize = { order = 14,
		type = "range",
		name = "PvP Icon Size",
		min = 15, max = 35, step = 1,
	}
	-- pvpIconInset = 7,
	local pvpIconInset = { order = 15,
		type = "range",
		name = "PvP Icon Inset",
		min = 0, max = 15, step = 1,
	}
	-- pvpTimer = false,
	local pvpTimer = { order = 16,
		type = "toggle",
		name = "PvP Timer",
	}
	-- nameW = 160,
	local nameW = { order = 17,
		type = "range",
		name = "Name Width",
		min = 120, max = 200, step = 1,
	}
	-- nameH = 24,
	local nameH = { order = 18,
		type = "range",
		name = "Name Height",
		min = 10, max = 40, step = 1,
	}
	-- statsW = 160,
	local statsW = { order = 19,
		type = "range",
		name = "Stats Width",
		min = 120, max = 200, step = 1,
	}
	-- 20 removed
	-- statsTopPadding = -2,
	local statsTopPadding = { order = 21,
		type = "range",
		name = "Stats Top Padding",
		min = -10, max = 10, step = 1,
	}
	-- statTagWSpace = 35,
	local statTagWSpace = { order = 22,
		type = "range",
		name = "Stat Tag Space",
		min = 0, max = 80, step = 1,
	}
	--[[
	-- statTagW = 50,
	local statTagW = { order = 23,
		type = "range",
		name = "Stat Tag Width",
		min = 0, max = 80, step = 1,
	}
	-- statTagH = 12,
	local statTagH = { order = 24,
		type = "range",
		name = "Stat Tag Height",
		min = 0, max = 80, step = 1,
	}
	--]]
	-- healthH = 20,
	local healthH = { order = 25,
		type = "range",
		name = "Health Bar Height",
		min = 0, max = 50, step = 1,
	}
	-- powerH = 10,
	local powerH = { order = 26,
		type = "range",
		name = "Power Bar Height",
		min = 0, max = 50, step = 1,
	}
	-- 27 was removed
	-- portraitPadding = -3,
	local portraitPadding = { order = 28,
		type = "range",
		name = "Portrait Padding",
		min = -20, max = 20, step = 1,
	}
	-- nameFontSize = 12,
	local nameFontSize = { order = 29,
		type = "range",
		name = "Name Font Size",
		min = 8, max = 18, step = 1,
	}
	-- tagFontSize = 10,
	local tagFontSize = { order = 30,
		type = "range",
		name = "Tag Font Size",
		min = 8, max = 18, step = 1,
	}
	-- healthFontSize = 12,
	local healthFontSize = { order = 31,
		type = "range",
		name = "Health Font Size",
		min = 8, max = 18, step = 1,
	}
	-- powerFontSize = 10,
	local powerFontSize = { order = 32,
		type = "range",
		name = "Power Font Size",
		min = 8, max = 18, step = 1,
	}
	-- nameLeft = false,
	local nameLeft = { order = 33,
		type = "toggle",
		name = "Name-on-Left",
	}
	-- raidIcon = false,
	local raidIcon = { order = 34,
		type = "select",
		name = "Raid Icon",
		values = { ["false"]="None", left="Left", right="Right" },
		get = generic_get_style_or_false,
		set = generic_set_style_or_false,
	}
	-- raidIconSize = 16,
	local raidIconSize = { order = 35,
		type = "range",
		name = "Raid Icon Size",
		min = 10, max = 35, step = 1,
	}
	-- raidIconInset = 5,
	local raidIconInset = { order = 36,
		type = "range",
		name = "Raid Icon Inset",
		min = 0, max = 15, step = 1,
	}
	-- raidIconY = 12,
	local raidIconY = { order = 37,
		type = "range",
		name = "Raid Icon Y",
		min = -20, max = 20, step = 1,
	}

	local section = {
		-- scale = scale,
		alpha = alpha,
		nestedAlpha = nestedAlpha,
		-- rangeAlphaCoef = rangeAlphaCoef,
		portrait = portrait,
		portraitW = portraitW,
		portraitH = portraitH,
		leftToRight = leftToRight,
		level = level,
		embedLevelAndClassIcon = embedLevelAndClassIcon,
		classIcon = classIcon,
		eliteType = eliteType,
		npcRace = npcRace,
		pvpIcon = pvpIcon,
		pvpIconSize = pvpIconSize,
		pvpIconInset = pvpIconInset,
		pvpTimer = pvpTimer,
		nameW = nameW,
		nameH = nameH,
		statsW = statsW,
		statsTopPadding = statsTopPadding,
		statTagWSpace = statTagWSpace,
		-- statTagW = statTagW,
		-- statTagH = statTagH,
		healthH = healthH,
		powerH = powerH,
		portraitPadding = portraitPadding,
		nameFontSize = nameFontSize,
		tagFontSize = tagFontSize,
		healthFontSize = healthFontSize,
		powerFontSize = powerFontSize,
		nameLeft = nameLeft,
		raidIcon = raidIcon,
		raidIconSize = raidIconSize,
		raidIconInset = raidIconInset,
		raidIconY = raidIconY,
	}

	function Module:MakeSectionArgs()
		return section
	end

	function Module:MakeSection(order, name)
		local t = {
			type = "group",
			name = name,
			order = order,
			get = generic_get_style,
			set = generic_set_style,
			args = self:MakeSectionArgs()
		}
		return t
	end
end --}}}

function Module:OnInitialize()
	self.OnInitialize = nil
	self:ProfileChanged()
	Core:RegisterForProfileChange(self, "ProfileChanged")

	local options = {
		type = "group",
		name = "Options",
		args = {},
	}
	options.args.main = {
		type = "group",
		name = "Main",
		order = 1,
		args = {
			locked = {
				type = "toggle",
				name = "Locked",
				order = 1,
				get = function(info) return Core.Movable:IsLocked() end,
				set = function(info, val)
					if val then
						Core.Movable:Lock()
					else
						Core.Movable:Unlock()
					end
				end,
				width = "half",
			},
		}
	}
	options.args.player = self:MakeSection(2, "Player")
	options.args.pet = self:MakeSection(3, "Pet")
	options.args.target = self:MakeSection(4, "Target")
	options.args.targettarget = self:MakeSection(5, "TargetTarget")
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Core.db) -- Ace3 Profiles

	-- Remove any stub in the Interface options, before adding the real one.
	local categories = INTERFACEOPTIONS_ADDONCATEGORIES
	local _, _coreAddonTitle = GetAddOnInfo(_coreAddonName)
	for i = 1,#categories do
		if categories[i].name == _coreAddonTitle then
			tremove(categories, i)
			break
		end
	end
	InterfaceAddOnsList_Update()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(_coreAddonName, options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(_coreAddonName, _coreAddonTitle)
	Module.options = options
end

function Module:OnEnable()
end

function Module:OnDisable()
end
