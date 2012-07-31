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
local UnitClass = UnitClass
local math_round = math.round
local select = select
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

local function normalize255(n)
	local val = math_round(n * 255)
	return val
end

--{{{ generics
local falseStr = "  false  " -- spaces make it early in asciibetical order

local point_values = {
	[falseStr]="None",
	TOPLEFT="TOPLEFT", LEFT="LEFT", BOTTOMLEFT="BOTTOMLEFT",
	TOP="TOP", CENTER="CENTER", BOTTOM="BOTTOM",
	TOPRIGHT="TOPRIGHT", RIGHT="RIGHT", BOTTOMRIGHT="BOTTOMRIGHT"
}

local sound_values = { [falseStr]="Off", Master="Master", SFX="SFX" }

local valMaxFormatters_values = {}
do
	for i,_ in next, Core.Layout.valMaxFormatters do
		valMaxFormatters_values[i] = i
	end
end

local function generic_disabled_style(info)
	if #info == 2 then
		local setting, style = info[#info], info[#info-1]
		if setting ~= "enabled" and not Core.Layout.style[style].enabled then
			return true
		end
	end
	return false
end

local function generic_get_style(info)
	local setting, style = info[#info], info[#info-1]
	return Core.Layout.style[style][setting]
end

local function generic_get_style_or_false(info)
	local val = generic_get_style(info)
	if val == false then val = falseStr end
	return val
end

local function generic_set_style(info, val)
	local setting, style = info[#info], info[#info-1]
	local prototypeVal = Core.Layout.stylePrototype[style][setting]
	if val ~= prototypeVal then
		profile[style][setting] = val
	else
		profile[style][setting] = nil
	end
	Core.Layout.style[style][setting] = val
	if setting == "enabled" then
		Core.Layout:EnableOrDisableFrame(style)
		if val == false then
			return
		end
	end
	local frame = (style == "party") and Core.Layout.partyHeader or Core.oUF.units[style]
	if frame then
		frame:Layout()
		frame:UpdateAllElements()
	end
end

local function generic_set_style_or_false(info, val)
	if val == falseStr then val = false end
	return generic_set_style(info, val)
end

local function generic_disabled_resource(info)
	return not Core.Layout.style.player.enabled
end

local function generic_get_resource(info)
	local setting = info[#info]
	return profile.resource[setting]
end

local function generic_set_resource(info, val)
	local setting = info[#info]
	profile.resource[setting] = val
	Core.LayoutResource:LoadSettings()
end
--}}}

do --{{{ Module:MakeSectionArgs()
	local _nextOrder = 1
	local function nextOrder()
		local val = _nextOrder
		_nextOrder = _nextOrder + 1
		return val
	end

	-- enabled = true,
	local enabled = { order = nextOrder(),
		type = "toggle",
		name = "Enabled",
	}
	-- scale = 1,
	local scale = { order = nextOrder(),
		type = "range",
		name = "Scale",
		isPercent = true,
		min = 0.5, max = 1.5, bigStep = 0.01,
		set = function(info, val)
			local style = info[#info-1]
			generic_set_style(info, val)
			Core.Movable:RestorePosition(style)
		end,
	}
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
	-- sounds = false,
	local sounds = { order = nextOrder(),
		type = "select",
		name = "Sounds",
		values = sound_values,
		get = generic_get_style_or_false,
		set = generic_set_style_or_false,
		disabled = function(info)
			if generic_disabled_style(info) then return true end
			local style = info[#info-1]
			return (style ~= "target" and style ~= "focus")
		end,
		hidden = function(info)
			local style = info[#info-1]
			return (style == "player")
		end,
	}
	-- pvpSound = false,
	local pvpSound = { order = nextOrder(),
		type = "select",
		name = "PvP Sound",
		values = sound_values,
		get = generic_get_style_or_false,
		set = generic_set_style_or_false,
		disabled = function(info)
			if generic_disabled_style(info) then return true end
			local style = info[#info-1]
			return (style ~= "player")
		end,
		hidden = function(info)
			local style = info[#info-1]
			return (style ~= "player")
		end,
	}
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
	-- enableCastbar = true
	local enableCastbar = { order = nextOrder(),
		type = "toggle",
		name = "Enable Castbar",
	}
	-- leftToRight = true,
	local leftToRight = { order = nextOrder(),
		type = "toggle",
		name = "Left-to-Right",
	}
	-- healPrediction = true,
	local healPrediction = { order = nextOrder(),
		type = "toggle",
		name = "Heal Prediction",
	}
	-- combatFeedback = false,
	local combatFeedback = { order = nextOrder(),
		type = "toggle",
		name = "Combat Feedback",
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
	-- healthFormat = "val/max",
	local healthFormat = { order = nextOrder(),
		type = "select",
		name = "Health Format",
		values = valMaxFormatters_values,
	}
	-- powerFormat = "val/max",
	local powerFormat = { order = nextOrder(),
		type = "select",
		name = "Power Format",
		values = valMaxFormatters_values,
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
	section.enabled = enabled
	section.scale = scale
	section.alpha = alpha
	section.nestedAlpha = nestedAlpha
	-- section.rangeAlphaCoef = rangeAlphaCoef
	section.sounds = sounds
	section.pvpSound = pvpSound
	section.portrait = portrait
	section.portraitW = portraitW
	section.portraitH = portraitH
	section.enableCastbar = enableCastbar
	section.leftToRight = leftToRight
	section.healPrediction = healPrediction
	section.combatFeedback = combatFeedback
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
	section.healthFormat = healthFormat
	section.powerFormat = powerFormat
	section.portraitPadding = portraitPadding
	section.nameFontSize = nameFontSize
	section.tagFontSize = tagFontSize
	section.healthFontSize = healthFontSize
	section.powerFontSize = powerFontSize
	section.nameLeft = nameLeft
	MakeIconSettings(section, "raidIcon", "Raid Icon")
	MakeIconSettings(section, "leaderIcon", "Leader Icon")
	MakeIconSettings(section, "masterLooterIcon", "Master Looter Icon")
	MakeIconSettings(section, "combatIcon", "Combat Icon")

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
			disabled = generic_disabled_style,
			args = self:MakeSectionArgs()
		}
		return t
	end
end --}}}

function Module:OnInitialize()
	self.OnInitialize = nil
	self:ProfileChanged()
	Core:RegisterForProfileChange(self, "ProfileChanged")

	local _, _coreAddonTitle = GetAddOnInfo(_coreAddonName)
	local options = {
		type = "group",
		name = _coreAddonTitle,
		childGroups = "tab",
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
			gradient = {
				type = "select",
				name = "Gradient",
				order = 2,
				values = { [falseStr]="None", VERTICAL="Vertical", HORIZONTAL="Horizontal" },
				get = function(info)
					local val = profile.color.gradient
					if val == false then val = falseStr end
					return val
				end,
				set = function(info, val)
					if val == falseStr then val = false end
					profile.color.gradient = val
					Core.Layout:ProfileChanged()
				end,
			},
			gradientStart = {
				type = "color",
				hasAlpha = true,
				name = function(info)
					local grad = profile.color.gradient
					if grad == "VERTICAL" then return "Gradient Bottom"
					elseif grad == "HORIZONTAL" then return "Gradient Left"
					else return "Gradient Color 1"
					end
				end,
				width = "half",
				order = 3,
				get = function(info)
					local gc = profile.color[info[#info]]
					return gc[1]/255, gc[2]/255, gc[3]/255, gc[4]/255
				end,
				set = function(info, r, g, b, a)
					local gc = profile.color[info[#info]]
					gc[1],gc[2],gc[3],gc[4] = normalize255(r), normalize255(g), normalize255(b), normalize255(a)
					Core.Layout:ProfileChanged()
				end,
				disabled = function(info)
					return not profile.color.gradient
				end,
			},
			gradientEnd = {
				type = "color",
				hasAlpha = true,
				name = function(info)
					local grad = profile.color.gradient
					if grad == "VERTICAL" then return "Gradient Top"
					elseif grad == "HORIZONTAL" then return "Gradient Right"
					else return "Gradient Color 2"
					end
				end,
				width = "half",
				order = 4,
				get = function(info)
					local gc = profile.color[info[#info]]
					return gc[1]/255, gc[2]/255, gc[3]/255, gc[4]/255
				end,
				set = function(info, r, g, b, a)
					local gc = profile.color[info[#info]]
					gc[1],gc[2],gc[3],gc[4] = normalize255(r), normalize255(g), normalize255(b), normalize255(a)
					Core.Layout:ProfileChanged()
				end,
				disabled = function(info)
					return not profile.color.gradient
				end,
			},
			gradientSwap = {
				type = "execute",
				name = "Reverse Gradient",
				order = 5,
				func = function(info)
					local x,y = profile.color.gradientStart, profile.color.gradientEnd
					local r,g,b,a = x[1],x[2],x[3],x[4]
					x[1],x[2],x[3],x[4] = y[1],y[2],y[3],y[4]
					y[1],y[2],y[3],y[4] = r,g,b,a
					Core.Layout:ProfileChanged()
				end,
				disabled = function(info)
					return not profile.color.gradient
				end,
			},
			_resource_header = {
				order = 10,
				type = "header",
				name = "Resources",
			},
			_resource_description = {
				order = 11,
				type = "description",
				name = function(info)
					if generic_disabled_resource(info) then
						return "All resources are disabled, since the Player frame is disabled. Their default behavior might or might not work, depending on your other mods and the default UI."
					else
						return "Checking a box will make ".._coreAddonTitle.." attach that resource to the player frame. This isn't guaranteed to work; other addons might be hiding the resource. Unchecking means ".._coreAddonTitle.." will not touch or interfere with the resource. An unchecked resource might or might not hide; that's up to your other mods and the default UI. Unchecking means ".._coreAddonTitle.." will do NOTHING, insuring there are no conflicts with other addons."
					end
				end,
			},
			eclipse = {
				order = 12,
				type = "toggle",
				name = "Eclipse",
				desc = "For Balance Druids",
				get = generic_get_resource,
				set = generic_set_resource,
				disabled = generic_disabled_resource,
			},
			soulshards = {
				order = 13,
				type = "toggle",
				name = "Soul Shards",
				desc = "For Warlocks",
				get = generic_get_resource,
				set = generic_set_resource,
				disabled = generic_disabled_resource,
			},
			holypower = {
				order = 14,
				type = "toggle",
				name = "Holy Power",
				desc = "For Paladins",
				get = generic_get_resource,
				set = generic_set_resource,
				disabled = generic_disabled_resource,
			},
			runes = {
				order = 15,
				type = "toggle",
				name = "Runes",
				desc = "For Death Knights",
				get = generic_get_resource,
				set = generic_set_resource,
				disabled = generic_disabled_resource,
			},
			totems = {
				order = 16,
				type = "toggle",
				name = "Totems",
				desc = "For Shamans. Paladins and Druids also use the Totem display for some spells.",
				get = generic_get_resource,
				set = generic_set_resource,
				disabled = generic_disabled_resource,
			},
		}
	}
	options.args.player = self:MakeSection(2, "Player")
	options.args.pet = self:MakeSection(3, "Pet")
	options.args.target = self:MakeSection(4, "Target")
	options.args.focus = self:MakeSection(5, "Focus")
	options.args.targettarget = self:MakeSection(6, "TargetTarget")
	options.args.focustarget = self:MakeSection(7, "FocusTarget")
	options.args.party = self:MakeSection(8, "Party")
	options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Core.db) -- Ace3 Profiles

	-- Remove any stub in the Interface options, before adding the real one.
	local categories = INTERFACEOPTIONS_ADDONCATEGORIES
	for i = 1,#categories do
		if categories[i].name == _coreAddonTitle then
			tremove(categories, i)
			break
		end
	end
	InterfaceAddOnsList_Update()
	LibStub("AceConfig-3.0"):RegisterOptionsTable(_coreAddonName, options)
	LibStub("AceConfigDialog-3.0"):SetDefaultSize(_coreAddonName, 760, 500)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(_coreAddonName, _coreAddonTitle)
	Module.options = options
end

function Module:OnEnable()
end

function Module:OnDisable()
end
