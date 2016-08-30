local K, C, L, _ = select(2, ...):unpack()
if C.ExpRep.ExpEnable ~= true then return end

local Experience = CreateFrame("Frame", nil, UIParent)
local HideTooltip = GameTooltip_Hide
local Bars = 20

Experience.NumBars = 2
Experience.RestedColor = {75/255, 175/255, 76/255}
Experience.XPColor = {0/255, 144/255, 255/255}
Experience.AFColor = {229/255, 204/255, 127/255}
Experience.HNColor = {222/255, 22/255, 22/255}

local ExperienceAnchor = CreateFrame("Frame", "ExperienceAnchor", UIParent)
ExperienceAnchor:SetSize(C.ExpRep.ExpWidth, 18)
ExperienceAnchor:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", -1, -22)
ExperienceAnchor:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 1, -22)

function Experience:SetTooltip()
	local BarType = self.BarType
	local Current, Max

	if (self == Experience.XPBar1) then
		GameTooltip:SetOwner(self, "ANCHOR_LEFT", 0, -5)
	else
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT", 0, 5)
	end

	if BarType == "XP" then
		local Rested = GetXPExhaustion()
		local IsRested = GetRestState()

		Current, Max = Experience:GetExperience()

		if Max == 0 then
			return
		end

		GameTooltip:AddLine(string.format("|cff0090FF"..XP..": %d / %d (%d%% - %d/%d)|r", Current, Max, Current / Max * 100, Bars - (Bars * (Max - Current) / Max), Bars))

		if (IsRested == 1 and Rested) then
			GameTooltip:AddLine(string.format("|cff4BAF4C"..TUTORIAL_TITLE26..": +%d (%d%%)|r", Rested, Rested / Max * 100))
		end
	elseif BarType == "ARTIFACT" then
		Current, Max = Experience:GetArtifact()

		if Max == 0 then
			return
		end

		GameTooltip:AddLine(string.format("|cffe6cc80"..ARTIFACT_POWER..": %d / %d (%d%% - %d/%d)|r", Current, Max, Current / Max * 100, Bars - (Bars * (Max - Current) / Max), Bars))
	else
		local Level = UnitHonorLevel("player")
		local LevelMax = GetMaxPlayerHonorLevel()
		local Prestige = UnitPrestige("player")

		Current, Max = Experience:GetHonor()

		if Max == 0 then
			GameTooltip:AddLine(PVP_HONOR_PRESTIGE_AVAILABLE)
			GameTooltip:AddLine(PVP_HONOR_XP_BAR_CANNOT_PRESTIGE_HERE)
		else
			GameTooltip:AddLine(string.format("|cffee2222"..HONOR..": %d / %d (%d%% - %d/%d)|r", Current, Max, Current / Max * 100, Bars - (Bars * (Max - Current) / Max), Bars))
			GameTooltip:AddLine(string.format("|cffcccccc"..RANK..": %d / %d|r", Level, LevelMax))
			GameTooltip:AddLine(string.format("|cffcccccc"..PVP_PRESTIGE_RANK_UP_TITLE..": %d|r", Prestige))
		end
	end

	GameTooltip:Show()
end

function Experience:GetExperience()
	return UnitXP("player"), UnitXPMax("player")
end

function Experience:GetArtifact()
	local itemID, altItemID, name, icon, totalXP, pointsSpent, quality, artifactAppearanceID, appearanceModID, itemAppearanceID, altItemAppearanceID, altOnTop = C_ArtifactUI.GetEquippedArtifactInfo()
	local numPointsAvailableToSpend, xp, xpForNextPoint = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(pointsSpent, totalXP)

	return xp, xpForNextPoint
end

function Experience:GetHonor()
	return UnitHonor("player"), UnitHonorMax("player")
end

function Experience:Update(event, owner)
	if (event == "UNIT_INVENTORY_CHANGED" and owner ~= "player") then
		return
	end

	local ShowArtifact = HasArtifactEquipped()
	local PlayerLevel = UnitLevel("player")

	local Current, Max = self:GetExperience()
	local Rested = GetXPExhaustion()
	local IsRested = GetRestState()

	for i = 1, self.NumBars do
		local Bar = self["XPBar"..i]
		local RestedBar = self["RestedBar"..i]
		local r, g, b

		Bar.BarType = "XP"

		if (i == 1 and PlayerLevel == MAX_PLAYER_LEVEL) then
			Current, Max = self:GetHonor()

			Bar.BarType = "HONOR"
		elseif (i == 2) then
			if ShowArtifact then
				Current, Max = self:GetArtifact()

				Bar.BarType = "ARTIFACT"
			else
				Current, Max = self:GetHonor()

				Bar.BarType = "HONOR"
			end
		end

		local BarType = Bar.BarType

		Bar:SetMinMaxValues(0, Max)
		Bar:SetValue(Current)

		if (BarType == "XP" and IsRested == 1 and Rested) then
			RestedBar:Show()
			RestedBar:SetMinMaxValues(0, Max)
			RestedBar:SetValue(Rested + Current)
		else
			RestedBar:Hide()
		end

		if BarType == "XP" then
			r, g, b = unpack(self.XPColor)
		elseif BarType == "ARTIFACT" then
			r, g, b = unpack(self.AFColor)
		else
			r, g, b = unpack(self.HNColor)
		end

		Bar:SetStatusBarColor(r, g, b)
	end
end

function Experience:Create()
	for i = 1, self.NumBars do
		local XPBar = CreateFrame("StatusBar", nil, UIParent)
		local XPBarBG = CreateFrame("Frame", "StatusBarBG", XPBar)
		local RestedBar = CreateFrame("StatusBar", nil, UIParent)

		XPBar:SetStatusBarTexture(C.Media.Texture)
		XPBar:EnableMouse()
		XPBar:SetFrameStrata("BACKGROUND")
		XPBar:CreatePixelShadow()
		XPBar:SetFrameLevel(2)
		XPBar:SetScript("OnEnter", Experience.SetTooltip)
		XPBar:SetScript("OnLeave", HideTooltip)

		RestedBar:SetStatusBarTexture(C.Media.Texture)
		RestedBar:SetFrameStrata("BACKGROUND")
		RestedBar:SetStatusBarColor(unpack(self.RestedColor))
		RestedBar:SetAllPoints(XPBar)
		RestedBar:SetFrameLevel(XPBar:GetFrameLevel())

		XPBarBG:SetFrameLevel(XPBar:GetFrameLevel() - 1)
		XPBarBG:SetPoint("TOPLEFT", -1, 1)
		XPBarBG:SetPoint("BOTTOMRIGHT", 1, -1)
		XPBarBG:SetBackdrop(K.BorderBackdrop)
		XPBarBG:SetBackdropColor(unpack(C.Media.Backdrop_Color))

		XPBar:SetSize(C.ExpRep.ExpWidth, C.ExpRep.ExpHeight)
		XPBar:SetPoint("CENTER", ExperienceAnchor, "CENTER", 0, 0)

		self["XPBar"..i] = XPBar
		self["RestedBar"..i] = RestedBar
	end

	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("PLAYER_LEVEL_UP")
	self:RegisterEvent("UPDATE_EXHAUSTION")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_UPDATE_RESTING")
	self:RegisterEvent("ARTIFACT_XP_UPDATE")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("HONOR_XP_UPDATE")
	self:RegisterEvent("HONOR_LEVEL_UPDATE")
	self:RegisterEvent("HONOR_PRESTIGE_UPDATE")

	self:SetScript("OnEvent", self.Update)
end

function Experience:Enable()
	if not self.IsCreated then
		self:Create()

		self.IsCreated = true
	end

	for i = 1, self.NumBars do
		if not self["XPBar"..i]:IsShown() then
			self["XPBar"..i]:Show()
		end

		if not self["RestedBar"..i]:IsShown() then
			self["RestedBar"..i]:Show()
		end
	end
end

function Experience:Disable()
	for i = 1, self.NumBars do
		if self["XPBar"..i]:IsShown() then
			self["XPBar"..i]:Hide()
		end

		if self["RestedBar"..i]:IsShown() then
			self["RestedBar"..i]:Hide()
		end
	end
end

Experience:Enable()