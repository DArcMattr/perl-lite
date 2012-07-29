--[[-------------------------------------------------------------------------
	SimpleCombatFeedback module for oUF
	Copyright (C) 2012  Morsk
	This file is available under the MIT license. Look for LICENSE.txt in its folder.

	This 100% uses Blizzard's combat feedback code. It has an optimization
	that completely avoids Blizzard's OnUpdate handlers by using Animations
	to perform the fade in/out. Blizzard's CombatFeedback_OnCombatEvent does
	nothing but fading and can be completely avoided with our own fading
	implementation.
---------------------------------------------------------------------------]]
local parent, ns = ...
local oUF = ns.oUF

-- GLOBALS: COMBATFEEDBACK_FADEINTIME
-- GLOBALS: COMBATFEEDBACK_FADEOUTTIME
-- GLOBALS: COMBATFEEDBACK_HOLDTIME
local CombatFeedback_OnCombatEvent = CombatFeedback_OnCombatEvent
local rawget = rawget

local function hideMyParent(self)
	return self:GetParent():Hide()
end

local animationPool = setmetatable({}, { -- lazy creation
	__index = function(pool, scf)
		local group = scf:CreateAnimationGroup()
		do
			local fadeIn = group:CreateAnimation("Alpha")
			fadeIn:SetOrder(1)
			fadeIn:SetDuration(COMBATFEEDBACK_FADEINTIME) -- fade in to 100% alpha
			fadeIn:SetChange(1)
			fadeIn:SetEndDelay(COMBATFEEDBACK_HOLDTIME) -- hold at 100% alpha
		end
		do
			local fadeOut = group:CreateAnimation("Alpha")
			fadeOut:SetOrder(2)
			fadeOut:SetDuration(COMBATFEEDBACK_FADEOUTTIME) -- fade out to 0% alpha
			fadeOut:SetChange(-1)
		end
		group:SetScript("OnFinished", hideMyParent) -- hide

		pool[scf] = group
		return group
	end,
})

local Update = function(self, event, unit, ...)
	if self.unit ~= unit then return end
	if event == "UNIT_COMBAT" then
		-- oUF "events" like ForceUpdate aren't meaningful for us; UNIT_COMBAT is the only event we know.
		local scf = self.SimpleCombatFeedback
		CombatFeedback_OnCombatEvent(scf, ...)
		local fader = animationPool[scf]
		fader:Stop()
		fader:Play()
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
		local anim = rawget(animationPool, scf)
		if anim then anim:Stop() end
		self:UnregisterEvent("UNIT_COMBAT", Path)
	end
end

oUF:AddElement("SimpleCombatFeedback", Path, Enable, Disable)