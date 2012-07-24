--[[-------------------------------------------------------------------------
	SimpleCombatFeedback module for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.

	This 100% uses Blizzard's combat feedback code. It has an optimization
	only to call Blizzard's OnUpdate handlers when feedback text is visible.
	An AnimationGroup for the fade in/out would be a better optimization.
	Blizzard's CombatFeedback_OnCombatEvent does nothing but fading and can
	be completely avoided if we have our own fading implementation.
---------------------------------------------------------------------------]]
local parent, ns = ...
local oUF = ns.oUF

local CombatFeedback_OnCombatEvent = CombatFeedback_OnCombatEvent
local CombatFeedback_OnUpdate = CombatFeedback_OnUpdate
local CreateFrame = CreateFrame
local next = next

local displayedFeedback = {}
local updateFrame

local Update = function(self, event, unit, ...)
	if self.unit ~= unit then return end
	if event == "UNIT_COMBAT" then
		-- oUF "events" like ForceUpdate aren't meaningful for us; UNIT_COMBAT is the only event we know.
		local scf = self.SimpleCombatFeedback
		CombatFeedback_OnCombatEvent(scf, ...)
		displayedFeedback[scf] = true
		updateFrame:Show()
	end
end

local function updateFrame_OnUpdate(self, elapsed)
	local doneUpdating = true
	for scf,_ in next, displayedFeedback do
		CombatFeedback_OnUpdate(scf, elapsed)
		if scf:IsShown() then
			doneUpdating = false
		else
			displayedFeedback[scf] = nil
		end
	end
	if doneUpdating then
		self:Hide()
	end
end

local Path = function(self, ...)
	return (self.SimpleCombatFeedback.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local scf = self.SimpleCombatFeedback
	if scf then
		scf.__owner = self
		scf.ForceUpdate = ForceUpdate

		if not updateFrame then
			updateFrame = CreateFrame("Frame")
			updateFrame:Hide()
			updateFrame:SetScript("OnUpdate", updateFrame_OnUpdate)
		end
		scf:Hide()
		scf.feedbackText = scf
		scf.feedbackFontHeight = scf.feedbackFontHeight or 30
		self:RegisterEvent("UNIT_COMBAT", Path)
		return true
	end
end

local Disable = function(self)
	local scf = self.SimpleCombatFeedback
	if scf then
		displayedFeedback[scf] = nil
		self:UnregisterEvent("UNIT_COMBAT", Path)
	end
end

oUF:AddElement("SimpleCombatFeedback", Path, Enable, Disable)