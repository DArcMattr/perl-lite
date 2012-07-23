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

--{{{ generics
local falseStr = "  false  " -- spaces make it early in asciibetical order

local point_values = {
	[falseStr]="None",
	TOPLEFT="TOPLEFT", LEFT="LEFT", BOTTOMLEFT="BOTTOMLEFT",
	TOP="TOP", CENTER="CENTER", BOTTOM="BOTTOM",
	TOPRIGHT="TOPRIGHT", RIGHT="RIGHT", BOTTOMRIGHT="BOTTOMRIGHT"
}

local function generic_get_style(info)
	local setting, style = info[#info], info[#info-1]
	return Core.Layout.style[style][setting]
end

local function generic_get_style_or_false(info)
	local val = generic_get_style(info)
	return (val ~= false) and val or falseStr
end

local function generic_set_style(info, val)
	local setting, style = info[#info], info[#info-1]
	local prototypeVal = Core.Layout.stylePrototype[style][setting]
	profile[style][setting] = (val ~= prototypeVal) and val or nil
	Core.Layout.style[style][setting] = val
	if style == "party" then
		for i = 1,4 do
			local frame = Core.oUF.units[style..i]
			if frame then
				frame:Layout()
				frame:UpdateAllElements()
			end
		end
	else
		Core.oUF.units[style]:Layout()
		Core.oUF.units[style]:UpdateAllElements()
	end
end

local function generic_set_style_or_false(info, val)
	return generic_set_style(info, (val ~= falseStr) and val or false)
end
--}}}

do --{{{ Module:MakeSectionArgs()
	local _nextOrder = 1
	local function nextOrder()
		local val = _nextOrder
		_nextOrder = _nextOrder + 1
		return val
	end

	-- scale = 1,
	-- alpha = 216,
	local alpha = { order = nextOrder(),
		type = "range",
		name = "Alpha",
		min = 0, max = 255, step = 1,
	}
	-- nestedAlpha = true,
	local nestedAlpha = { order = nextOrder(),
		type = "toggle",
		name = "Nested Alpha",
	}
	-- rangeAlphaCoef = false,
	-- portrait = false,
	local portrait = { order = nextOrder(),
		type = "select",
		name = "Portrait",
		values = { [falseStr]="None", ["2d"]="2D", ["3d"]="3D" },
		get = generic_get_style_or_false,
		set = generic_set_style_or_false,
	}
	-- portraitW = 60,
	local portraitW = { order = nextOrder(),
		type = "range",
		name = "Portrait Width",
		min = 40, max = 80, step = 1,
	}
	-- portraitH = 62,
	local portraitH = { order = nextOrder(),
		type = "range",
		name = "Portrait Height",
		min = 40, max = 80, step = 1,
	}
	-- leftToRight = true,
	local leftToRight = { order = nextOrder(),
		type = "toggle",
		name = "Left-to-Right",
	}
	-- level = true,
	local level = { order = nextOrder(),
		type = "toggle",
		name = "Level",
	}
	-- embedLevelAndClassIcon = false,
	local embedLevelAndClassIcon = { order = nextOrder(),
		type = "toggle",
		name = "Embed Level & Class",
	}
	-- classIcon = true,
	local classIcon = { order = nextOrder(),
		type = "toggle",
		name = "Class",
	}
	-- eliteType = false,
	local eliteType = { order = nextOrder(),
		type = "toggle",
		name = "Elite",
	}
	-- npcRace = false,
	local npcRace = { order = nextOrder(),
		type = "toggle",
		name = "NPC Race",
	}
	-- pvpTimer = false,
	local pvpTimer = { order = nextOrder(),
		type = "toggle",
		name = "PvP Timer",
	}
	-- nameW = 160,
	local nameW = { order = nextOrder(),
		type = "range",
		name = "Name Width",
		min = 120, max = 200, step = 1,
	}
	-- nameH = 24,
	local nameH = { order = nextOrder(),
		type = "range",
		name = "Name Height",
		min = 10, max = 40, step = 1,
	}
	-- statsW = 160,
	local statsW = { order = nextOrder(),
		type = "range",
		name = "Stats Width",
		min = 120, max = 200, step = 1,
	}
	-- statsTopPadding = -2,
	local statsTopPadding = { order = nextOrder(),
		type = "range",
		name = "Stats Top Padding",
		min = -10, max = 10, step = 1,
	}
	-- statTagWSpace = 35,
	local statTagWSpace = { order = nextOrder(),
		type = "range",
		name = "Stat Tag Space",
		min = 0, max = 80, step = 1,
	}
	--[[
	-- statTagW = 50,
	local statTagW = { order = nextOrder(),
		type = "range",
		name = "Stat Tag Width",
		min = 0, max = 80, step = 1,
	}
	-- statTagH = 12,
	local statTagH = { order = nextOrder(),
		type = "range",
		name = "Stat Tag Height",
		min = 0, max = 80, step = 1,
	}
	--]]
	-- healthH = 20,
	local healthH = { order = nextOrder(),
		type = "range",
		name = "Health Bar Height",
		min = 0, max = 50, step = 1,
	}
	-- powerH = 10,
	local powerH = { order = nextOrder(),
		type = "range",
		name = "Power Bar Height",
		min = 0, max = 50, step = 1,
	}
	-- portraitPadding = -3,
	local portraitPadding = { order = nextOrder(),
		type = "range",
		name = "Portrait Padding",
		min = -20, max = 20, step = 1,
	}
	-- nameFontSize = 12,
	local nameFontSize = { order = nextOrder(),
		type = "range",
		name = "Name Font Size",
		min = 8, max = 18, step = 1,
	}
	-- tagFontSize = 10,
	local tagFontSize = { order = nextOrder(),
		type = "range",
		name = "Tag Font Size",
		min = 8, max = 18, step = 1,
	}
	-- healthFontSize = 12,
	local healthFontSize = { order = nextOrder(),
		type = "range",
		name = "Health Font Size",
		min = 8, max = 18, step = 1,
	}
	-- powerFontSize = 10,
	local powerFontSize = { order = nextOrder(),
		type = "range",
		name = "Power Font Size",
		min = 8, max = 18, step = 1,
	}
	-- nameLeft = false,
	local nameLeft = { order = nextOrder(),
		type = "toggle",
		name = "Name-on-Left",
	}

	local function MakeIconSettings(t, name, cname)
		t[name] = { order = nextOrder(),
			type = "select",
			name = cname,
			values = point_values,
			get = generic_get_style_or_false,
			set = generic_set_style_or_false,
		}
		t[name.."Size"] = { order = nextOrder(),
			type = "range",
			name = cname.." Size",
			min = 10, max = 35, step = 1,
		}
		t[name.."X"] = { order = nextOrder(),
			type = "range",
			name = cname.." X",
			min = -40, max = 40, step = 1,
		}
		t[name.."Y"] = { order = nextOrder(),
			type = "range",
			name = cname.." Y",
			min = -40, max = 40, step = 1,
		}
	end

	local section = {}
	-- section.scale = scale
	section.alpha = alpha
	section.nestedAlpha = nestedAlpha
	-- section.rangeAlphaCoef = rangeAlphaCoef
	section.portrait = portrait
	section.portraitW = portraitW
	section.portraitH = portraitH
	section.leftToRight = leftToRight
	section.level = level
	section.embedLevelAndClassIcon = embedLevelAndClassIcon
	section.classIcon = classIcon
	section.eliteType = eliteType
	section.npcRace = npcRace
	MakeIconSettings(section, "pvpIcon", "PvP Icon")
	section.pvpTimer = pvpTimer
	section.nameW = nameW
	section.nameH = nameH
	section.statsW = statsW
	section.statsTopPadding = statsTopPadding
	section.statTagWSpace = statTagWSpace
	-- section.statTagW = statTagW
	-- section.statTagH = statTagH
	section.healthH = healthH
	section.powerH = powerH
	section.portraitPadding = portraitPadding
	section.nameFontSize = nameFontSize
	section.tagFontSize = tagFontSize
	section.healthFontSize = healthFontSize
	section.powerFontSize = powerFontSize
	section.nameLeft = nameLeft
	MakeIconSettings(section, "raidIcon", "Raid Icon")
	MakeIconSettings(section, "leaderIcon", "Leader Icon")
	MakeIconSettings(section, "masterLooterIcon", "Master Looter Icon")

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
	options.args.party = self:MakeSection(6, "Party")
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
