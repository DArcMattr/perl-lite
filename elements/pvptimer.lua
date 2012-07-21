--[[-------------------------------------------------------------------------
	PvPTimer module for oUF
	Copyright (C) 2012  Morsk
	All Rights Reserved.
---------------------------------------------------------------------------]]
local parent, ns = ...
local oUF = ns.oUF

local floor = floor
local next = next
local AnimTimerFrame = AnimTimerFrame
local CreateFrame = CreateFrame
local GetPVPTimer = GetPVPTimer
local IsPVPTimerRunning = IsPVPTimerRunning
local UnitIsPvP = UnitIsPvP

local animGroup
local registry = {}
local f

local Update = function(self)
	-- We need to test both conditions, because UnitIsPvP goes nil a few seconds before IsPvPTimerRunning does.
	-- We don't want to display without the icons based on UnitIsPvP.
	if IsPVPTimerRunning() and UnitIsPVP(self.unit) then
		local tmMillisec = GetPVPTimer()
		local tmSec = floor(tmMillisec / 1000)
		self.PvPTimer:SetFormattedText("%d:%02d", (tmSec / 60), (tmSec % 60))
		self.PvPTimer:Show()
	else
		self.PvPTimer:Hide()
	end
end

local Path = function(self, ...)
	return (self.PvPTimer.Override or Update) (self, ...)
end

local function updateRegisteredFrames()
	for self, pvpTimer in next, registry do
		Path(self, "Tick")
	end
	if not IsPVPTimerRunning() then
		animGroup:Stop()
	end
end

local function initTimer()
	animGroup = AnimTimerFrame:CreateAnimationGroup()
	animGroup:SetScript("OnPlay", updateRegisteredFrames)

	local anim = animGroup:CreateAnimation("Animation")
	anim:SetDuration(.1)
	anim:SetOrder(1)
	anim:SetScript("OnFinished", updateRegisteredFrames)
	animGroup:SetLooping("REPEAT")
	return animGroup
end

local function onEvent(self, event)
	local gameTimer = not not IsPVPTimerRunning()
	local ourTimer = not not animGroup:IsPlaying()
	if gameTimer ~= ourTimer then
		if gameTimer then
			animGroup:Play()
		else
			updateRegisteredFrames() -- will do the stop
		end
	end
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	if self.unit ~= "player" then return end

	local pvpTimer = self.PvPTimer
	if pvpTimer then
		pvpTimer.__owner = self
		pvpTimer.ForceUpdate = ForceUpdate

		if not next(registry) then
			registry[self] = pvpTimer
			f = f or CreateFrame("Frame")
			f:SetScript("OnEvent", onEvent)
			f:RegisterEvent("PLAYER_FLAGS_CHANGED")
			if not animGroup then initTimer() end
			if IsPVPTimerRunning() then
				animGroup:Play()
			end
		else
			registry[self] = pvpTimer
		end
		return true
	end
end

local Disable = function(self)
	local pvpTimer = self.PvPTimer
	if pvpTimer and registry[self] then
		registry[self] = nil
		if not next(registry) then
			animGroup:Stop()
			f:UnregisterEvent("PLAYER_FLAGS_CHANGED")
		end
	end
end
oUF:AddElement("PvPTimer", Path, Enable, Disable)
--@do-not-package@
-- Set a global to let us debug this easier.
if _G._PvPTimer then return end

_G._PvPTimer = {
	animGroup = function() return animGroup end,
	registry = registry
}
--@end-do-not-package@