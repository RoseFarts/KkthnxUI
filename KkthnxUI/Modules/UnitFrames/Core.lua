local K, C = unpack(select(2, ...))
local Module = K:NewModule("Unitframes", "AceEvent-3.0", "AceTimer-3.0")

local oUF = oUF or K.oUF
assert(oUF, "KkthnxUI was unable to locate oUF.")

local _G = _G
local math_ceil = math.ceil
local pairs = pairs
local select = select
local string_find = string.find
local string_gsub = string.gsub
local table_insert = table.insert
local table_wipe = table.wipe
local tonumber = tonumber
local unpack = unpack
local math_abs = math.abs
local math_min = math.min
local string_match = string.match

local C_NamePlate_GetNamePlateForUnit = _G.C_NamePlate.GetNamePlateForUnit
local CLASS_ICON_TCOORDS = _G.CLASS_ICON_TCOORDS
local CreateFrame = _G.CreateFrame
local CUSTOM_CLASS_COLORS = _G.CUSTOM_CLASS_COLORS
local DebuffTypeColor = _G.DebuffTypeColor
local FACTION_BAR_COLORS = _G.FACTION_BAR_COLORS
local GetArenaOpponentSpec = _G.GetArenaOpponentSpec
local GetSpecializationInfoByID = _G.GetSpecializationInfoByID
local GetSpellInfo = _G.GetSpellInfo
local GetTime = _G.GetTime
local InCombatLockdown = _G.InCombatLockdown
local IsInGroup = _G.IsInGroup
local IsInInstance = _G.IsInInstance
local IsInRaid = _G.IsInRaid
local MAX_ARENA_ENEMIES = _G.MAX_ARENA_ENEMIES or 5
local MAX_BOSS_FRAMES = _G.MAX_BOSS_FRAMES or 5
local PlaySound = _G.PlaySound
local RAID_CLASS_COLORS = _G.RAID_CLASS_COLORS
local SetCVar = _G.SetCVar
local SOUNDKIT = _G.SOUNDKIT
local UIParent = _G.UIParent
local UnitAffectingCombat = _G.UnitAffectingCombat
local UnitAura = _G.UnitAura
local UnitCanAttack = _G.UnitCanAttack
local UnitClass = _G.UnitClass
local UnitClassification = _G.UnitClassification
local UnitDetailedThreatSituation = _G.UnitDetailedThreatSituation
local UnitExists = _G.UnitExists
local UnitFactionGroup = _G.UnitFactionGroup
local UnitGroupRolesAssigned = _G.UnitGroupRolesAssigned
local UnitIsConnected = _G.UnitIsConnected
local UnitIsEnemy = _G.UnitIsEnemy
local UnitIsFriend = _G.UnitIsFriend
local UnitIsPlayer = _G.UnitIsPlayer
local UnitIsPVP = _G.UnitIsPVP
local UnitIsPVPFreeForAll = _G.UnitIsPVPFreeForAll
local UnitIsTapDenied = _G.UnitIsTapDenied
local UnitIsUnit = _G.UnitIsUnit
local UnitName = _G.UnitName
local UnitPlayerControlled = _G.UnitPlayerControlled
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitReaction = _G.UnitReaction
local UnitSpellHaste = _G.UnitSpellHaste

local Movers = K["Movers"]
Module.ticks = {}

Module.RaidBuffsTrackingPosition = {
	TOPLEFT = {6, 1},
	TOPRIGHT = {-6, 1},
	BOTTOMLEFT = {6, 1},
	BOTTOMRIGHT = {-6, 1},
	LEFT = {6, 1},
	RIGHT = {-6, 1},
	TOP = {0, 0},
	BOTTOM = {0, 0}
}

Module.DebuffHighlightColors = {
	[25771] = {enable = false, style = "FILL", color = {r = 0.85, g = 0, b = 0, a = 0.85}},
}

Module.PlateTotemData = {
	[GetSpellInfo(192058)] = "Interface\\Icons\\spell_nature_brilliance", -- Lightning Surge Totem
	[GetSpellInfo(98008)] = "Interface\\Icons\\spell_shaman_spiritlink", -- Spirit Link Totem
	[GetSpellInfo(192077)] = "Interface\\Icons\\ability_shaman_windwalktotem", -- Wind Rush Totem
	[GetSpellInfo(204331)] = "Interface\\Icons\\spell_nature_wrathofair_totem", -- Counterstrike Totem
	[GetSpellInfo(204332)] = "Interface\\Icons\\spell_nature_windfury", -- Windfury Totem
	[GetSpellInfo(204336)] = "Interface\\Icons\\spell_nature_groundingtotem", -- Grounding Totem
	-- Water
	[GetSpellInfo(157153)] = "Interface\\Icons\\ability_shaman_condensationtotem", -- Cloudburst Totem
	[GetSpellInfo(5394)] = "Interface\\Icons\\INV_Spear_04", -- Healing Stream Totem
	[GetSpellInfo(108280)] = "Interface\\Icons\\ability_shaman_healingtide", -- Healing Tide Totem
	-- Earth
	[GetSpellInfo(207399)] = "Interface\\Icons\\spell_nature_reincarnation", -- Ancestral Protection Totem
	[GetSpellInfo(198838)] = "Interface\\Icons\\spell_nature_stoneskintotem", -- Earthen Shield Totem
	[GetSpellInfo(51485)] = "Interface\\Icons\\spell_nature_stranglevines", -- Earthgrab Totem
	[GetSpellInfo(61882)] = "Interface\\Icons\\spell_shaman_earthquake", -- Earthquake Totem
	[GetSpellInfo(196932)] = "Interface\\Icons\\spell_totem_wardofdraining", -- Voodoo Totem
	-- Fire
	[GetSpellInfo(192222)] = "Interface\\Icons\\spell_shaman_spewlava", -- Liquid Magma Totem
	[GetSpellInfo(204330)] = "Interface\\Icons\\spell_fire_totemofwrath", -- Skyfury Totem
	-- Totem Mastery
	[GetSpellInfo(202188)] = "Interface\\Icons\\spell_nature_stoneskintotem", -- Resonance Totem
	[GetSpellInfo(210651)] = "Interface\\Icons\\spell_shaman_stormtotem", -- Storm Totem
	[GetSpellInfo(210657)] = "Interface\\Icons\\spell_fire_searingtotem", -- Ember Totem
	[GetSpellInfo(210660)] = "Interface\\Icons\\spell_nature_invisibilitytotem", -- Tailwind Totem
}

function Module:UpdateClassPortraits(unit)
	if not unit then
		return
	end

	local _, unitClass = UnitClass(unit)

	if unitClass then
		local PartyValue = C["Party"].PortraitStyle.Value
		local BossValue = C["Boss"].PortraitStyle.Value
		local UnitframeValue = C["Unitframe"].PortraitStyle.Value
		local ClassTCoords = CLASS_ICON_TCOORDS[unitClass]

		if PartyValue == "ClassPortraits" or BossValue == "ClassPortraits" or UnitframeValue == "ClassPortraits" then
			self:SetTexture("Interface\\WorldStateFrame\\ICONS-CLASSES")
			if ClassTCoords then
				self:SetTexCoord(ClassTCoords[1], ClassTCoords[2], ClassTCoords[3], ClassTCoords[4])
			end
		elseif PartyValue == "NewClassPortraits" or BossValue == "NewClassPortraits" or UnitframeValue == "NewClassPortraits" then
			self:SetTexture(C["Media"].NewClassPortraits)
			if ClassTCoords then
				self:SetTexCoord(ClassTCoords[1], ClassTCoords[2], ClassTCoords[3], ClassTCoords[4])
			end
		else
			self:SetTexCoord(0.15, 0.85, 0.15, 0.85)
		end
	end
end

function Module:ThreatPlate()
	if C["Nameplates"].Threat ~= true then
		return
	end

	local unit = self.unit
	local health = self.Health

	if UnitIsPlayer(unit) then
		return
	end

	if (not health:IsShown()) then
		return
	end

	do
		local isTanking, status, percent = UnitDetailedThreatSituation("player", unit)
		local isInGroup, isInRaid = IsInGroup(), IsInRaid()
		self.ThreatData = {}
		self.ThreatData.player = {isTanking, status, percent}
		self.isBeingTanked = false

		if (isTanking and K.GetPlayerRole() == "TANK") then
			self.isBeingTanked = true
		end

		if (status and (isInRaid or isInGroup)) then
			if isInRaid then
				for i = 1, 40 do
					if UnitExists("raid" .. i) and not UnitIsUnit("raid" .. i, "player") then
						self.ThreatData["raid" .. i] = self.ThreatData["raid" .. i] or {}
						isTanking, status, percent = UnitDetailedThreatSituation("raid" .. i, unit)
						self.ThreatData["raid" .. i] = {isTanking, status, percent}

						if (self.isBeingTanked ~= true and isTanking and UnitGroupRolesAssigned("raid" .. i) == "TANK") then
							self.isBeingTanked = true
						end
					end
				end
			else
				self.ThreatData = {}
				self.ThreatData.player = {UnitDetailedThreatSituation("player", unit)}
				for i = 1, 4 do
					if UnitExists("party" .. i) then
						self.ThreatData["party" .. i] = self.ThreatData["party" .. i] or {}
						isTanking, status, percent = UnitDetailedThreatSituation("party" .. i, unit)
						self.ThreatData["party" .. i] = {isTanking, status, percent}

						if (self.isBeingTanked ~= true and isTanking and UnitGroupRolesAssigned("party" .. i) == "TANK") then
							self.isBeingTanked = true
						end
					end
				end
			end
		end
	end

	if (not UnitIsConnected(unit)) then
		health:SetStatusBarColor(0.3, 0.3, 0.3)
	else
		if (not UnitPlayerControlled(unit) and UnitIsTapDenied(unit)) then
			-- Use grey if not a player and can"t get tap on unit
			health:SetStatusBarColor(0.6, 0.6, 0.6)
		else
			-- Use color based on the type of unit (neutral, etc.)
			local _, status = UnitDetailedThreatSituation("player", unit)
			if status then
				if (status == 3) then -- Securely Tanking
					if (K.GetPlayerRole() == "TANK") then
						health:SetStatusBarColor(C["Nameplates"].GoodColor[1], C["Nameplates"].GoodColor[2], C["Nameplates"].GoodColor[3])
					else
						health:SetStatusBarColor(C["Nameplates"].BadColor[1], C["Nameplates"].BadColor[2], C["Nameplates"].BadColor[3])
					end
				elseif (status == 2) then -- insecurely tanking
					if (K.GetPlayerRole() == "TANK") then
						health:SetStatusBarColor(C["Nameplates"].BadTransition[1], C["Nameplates"].BadTransition[2], C["Nameplates"].BadTransition[3])
					else
						health:SetStatusBarColor(C["Nameplates"].GoodTransition[1], C["Nameplates"].GoodTransition[2], C["Nameplates"].GoodTransition[3])
					end
				elseif (status == 1) then -- not tanking but threat higher than tank
					if (K.GetPlayerRole() == "TANK") then
						health:SetStatusBarColor(C["Nameplates"].GoodTransition[1], C["Nameplates"].GoodTransition[2], C["Nameplates"].GoodTransition[3])
					else
						health:SetStatusBarColor(C["Nameplates"].BadTransition[1], C["Nameplates"].BadTransition[2], C["Nameplates"].BadTransition[3])
					end
				else
					if (K.GetPlayerRole() == "TANK") then
						-- Check if it is being tanked by an offtank.
						if (IsInRaid() or IsInGroup()) and self.isBeingTanked and C["Nameplates"].TankedByTank then
							health:SetStatusBarColor(C["Nameplates"].TankedByTankColor[1], C["Nameplates"].TankedByTankColor[2], C["Nameplates"].TankedByTankColor[3])
						else
							health:SetStatusBarColor(C["Nameplates"].BadColor[1], C["Nameplates"].BadColor[2], C["Nameplates"].BadColor[3])
						end
					else
						if (IsInRaid() or IsInGroup()) and self.isBeingTanked and C["Nameplates"].TankedByTank then
							health:SetStatusBarColor(C["Nameplates"].TankedByTankColor[1], C["Nameplates"].TankedByTankColor[2], C["Nameplates"].TankedByTankColor[3])
						else
							health:SetStatusBarColor(C["Nameplates"].GoodColor[1], C["Nameplates"].GoodColor[2], C["Nameplates"].GoodColor[3])
						end
					end
				end
			end
		end
	end
end

function Module:HighlightPlate()
	local unit = self.unit

	local health = self.Health
	local shadowH = health.Shadow
	local arrowT = C["Nameplates"].TargetArrow and self.TopArrow

	local isPlayer = unit and UnitIsPlayer(unit)
	local reaction = unit and UnitReaction(unit, "player")

	if (not health:IsShown()) then
		return
	end

	if UnitIsUnit(unit, "target") and not UnitIsUnit(unit, "player") then
		if isPlayer then
			local _, class = UnitClass(unit)
			if class then
				local color = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
				if color then
					if arrowT then
						arrowT:Show()
						arrowT:SetVertexColor(color.r, color.g, color.b)
					end

					if shadowH then
						shadowH:SetBackdropBorderColor(color.r, color.g, color.b)
					end
				end
			end
		elseif reaction then
			local color = FACTION_BAR_COLORS[reaction]
			if color then
				if arrowT then
					arrowT:Show()
					arrowT:SetVertexColor(color.r, color.g, color.b)
				end

				if shadowH then
					shadowH:SetBackdropBorderColor(color.r, color.g, color.b)
				end
			end
		end
	else
		if arrowT then
			arrowT:Hide()
		end

		if shadowH then
			shadowH:SetBackdropBorderColor(0, 0, 0, 0.8)
		end
	end
end

function Module:UpdatePlateTotems()
	local name = UnitName(self.unit)

	if name then
		if Module.PlateTotemData[name] then
			self.Totem.Icon:SetTexture(Module.PlateTotemData[name])
			self.Totem.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
			self.Totem:Show()
		else
			self.Totem:Hide()
		end
	end
end

function Module:MouseoverHealth(unit)
	if (not unit) then
		return
	end

	local Health = self.Health
	local Texture = C["Media"].Mouseover

	self.Highlight = Health:CreateTexture(nil, "OVERLAY")
	self.Highlight:SetAllPoints()
	self.Highlight:SetTexture(Texture)
	self.Highlight:SetVertexColor(1, 1, 1, .36)
	self.Highlight:SetBlendMode("ADD")
	self.Highlight:Hide()
end

function Module:CustomCastTimeText(duration)
	if self.channeling then
		self.Time:SetText(("%.1f"):format(math_abs(duration - self.max)))
	else
		self.Time:SetText(("%.1f"):format(duration))
	end
end

function Module:CustomCastDelayText(duration)
	if self.channeling then
		self.Time:SetText(("%.1f |cffaf5050%.1f|r"):format(math_abs(duration - self.max), self.delay))
	else
		self.Time:SetText(("%.1f |cffaf5050%s %.1f|r"):format(duration, "+", self.delay))
	end
end

function Module:HideTicks()
	for i = 1, #Module.ticks do
		Module.ticks[i]:Hide()
	end
end

function Module:SetCastTicks(castbar, numTicks, extraTickRatio)
	local CastTicksTexture = K.GetTexture(C["Unitframe"].Texture)

	extraTickRatio = extraTickRatio or 0
	Module:HideTicks()

	if numTicks and numTicks <= 0 then
		return
	end

	local w = castbar:GetWidth()
	local d = w / (numTicks + extraTickRatio)

	for i = 1, numTicks do
		if not Module.ticks[i] then
			Module.ticks[i] = castbar:CreateTexture(nil, "OVERLAY")
			Module.ticks[i]:SetTexture(CastTicksTexture)
			Module.ticks[i]:SetVertexColor(castbar.tickColor[1], castbar.tickColor[2], castbar.tickColor[3], castbar.tickColor[4])
			Module.ticks[i]:SetWidth(castbar.tickWidth)
		end

		Module.ticks[i]:SetHeight(castbar.tickHeight or castbar:GetHeight())
		Module.ticks[i]:ClearAllPoints()
		Module.ticks[i]:SetPoint("RIGHT", castbar, "LEFT", d * i, 0)
		Module.ticks[i]:Show()
	end
end

function Module:PostCastStart(unit, name)
	if unit == "vehicle" then
		unit = "player"
	end

	if self.Text and name then
		self.Text:SetText(name)
	end

	-- Get length of Time, then calculate available length for Text
	local timeWidth = self.Time:GetStringWidth()
	local textWidth = self:GetWidth() - timeWidth - 10
	local textStringWidth = self.Text:GetStringWidth()

	if timeWidth == 0 or textStringWidth == 0 then
		K.Delay(0.05, function() -- Delay may need tweaking
			textWidth = self:GetWidth() - self.Time:GetStringWidth() - 10
			textStringWidth = self.Text:GetStringWidth()
			if textWidth > 0 then self.Text:SetWidth(math_min(textWidth, textStringWidth)) end
		end)
	else
		self.Text:SetWidth(math_min(textWidth, textStringWidth))
	end

	if self.Spark then
		self.Spark:SetHeight(self:GetHeight())
	end

	self.unit = unit

	if C["Unitframe"].CastbarTicks and unit == "player" then
		local baseTicks = Module.ChannelTicks[name]

		-- Detect channeling spell and if it"s the same as the previously channeled one
		if baseTicks and name == self.prevSpellCast then
			self.chainChannel = true
		elseif baseTicks then
			self.chainChannel = nil
			self.prevSpellCast = name
		end

		if baseTicks and Module.ChannelTicksSize[name] and Module.HastedChannelTicks[name] then
			local tickIncRate = 1 / baseTicks
			local curHaste = UnitSpellHaste("player") * 0.01
			local firstTickInc = tickIncRate / 2
			local bonusTicks = 0
			if curHaste >= firstTickInc then
				bonusTicks = bonusTicks + 1
			end

			local x = tonumber(K.Round(firstTickInc + tickIncRate, 2))
			while curHaste >= x do
				x = tonumber(K.Round(firstTickInc + (tickIncRate * bonusTicks), 2))
				if curHaste >= x then
					bonusTicks = bonusTicks + 1
				end
			end

			local baseTickSize = Module.ChannelTicksSize[name]
			local hastedTickSize = baseTickSize / (1 + curHaste)
			local extraTick = self.max - hastedTickSize * (baseTicks + bonusTicks)
			local extraTickRatio = extraTick / hastedTickSize

			Module:SetCastTicks(self, baseTicks + bonusTicks, extraTickRatio)
		elseif baseTicks and Module.ChannelTicksSize[name] then
			local curHaste = UnitSpellHaste("player") * 0.01
			local baseTickSize = Module.ChannelTicksSize[name]
			local hastedTickSize = baseTickSize / (1 + curHaste)
			local extraTick = self.max - hastedTickSize * (baseTicks)
			local extraTickRatio = extraTick / hastedTickSize

			Module:SetCastTicks(self, baseTicks, extraTickRatio)
		elseif baseTicks then
			Module:SetCastTicks(self, baseTicks)
		else
			Module:HideTicks()
		end
	elseif unit == "player" then
		Module:HideTicks()
	end

	local colors = K.Colors
	local r, g, b = colors.status.castColor[1], colors.status.castColor[2], colors.status.castColor[3]

	local t
	if C["Unitframe"].CastClassColor and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		t = K.Colors.class[class]
	elseif C["Unitframe"].CastReactionColor and UnitReaction(unit, 'player') then
		t = K.Colors.reaction[UnitReaction(unit, "player")]
	end

	if (t) then
		r, g, b = t[1], t[2], t[3]
	end

	if self.notInterruptible and unit ~= "player" and UnitCanAttack("player", unit) then
		r, g, b = colors.status.castNoInterrupt[1], colors.status.castNoInterrupt[2], colors.status.castNoInterrupt[3]
	end

	self:SetStatusBarColor(r, g, b)
end

function Module:PostCastStop()
	self.chainChannel = nil
	self.prevSpellCast = nil
end

function Module:PostChannelUpdate(unit, name)
	if not (unit == "player" or unit == "vehicle") then
		return
	end

	if C["Unitframe"].CastbarTicks then
		local baseTicks = Module.ChannelTicks[name]

		if baseTicks and Module.ChannelTicksSize[name] and Module.HastedChannelTicks[name] then
			local tickIncRate = 1 / baseTicks
			local curHaste = UnitSpellHaste("player") * 0.01
			local firstTickInc = tickIncRate / 2
			local bonusTicks = 0
			if curHaste >= firstTickInc then
				bonusTicks = bonusTicks + 1
			end

			local x = tonumber(K.Round(firstTickInc + tickIncRate, 2))
			while curHaste >= x do
				x = tonumber(K.Round(firstTickInc + (tickIncRate * bonusTicks), 2))
				if curHaste >= x then
					bonusTicks = bonusTicks + 1
				end
			end

			local baseTickSize = Module.ChannelTicksSize[name]
			local hastedTickSize = baseTickSize / (1 + curHaste)
			local extraTick = self.max - hastedTickSize * (baseTicks + bonusTicks)

			if self.chainChannel then
				self.extraTickRatio = extraTick / hastedTickSize
				self.chainChannel = nil
			end

			Module:SetCastTicks(self, baseTicks + bonusTicks, self.extraTickRatio)
		elseif baseTicks and Module.ChannelTicksSize[name] then
			local curHaste = UnitSpellHaste("player") * 0.01
			local baseTickSize = Module.ChannelTicksSize[name]
			local hastedTickSize = baseTickSize / (1 + curHaste)
			local extraTick = self.max - hastedTickSize * (baseTicks)
			if self.chainChannel then
				self.extraTickRatio = extraTick / hastedTickSize
				self.chainChannel = nil
			end

			Module:SetCastTicks(self, baseTicks, self.extraTickRatio)
		elseif baseTicks then
			if self.chainChannel then
				baseTicks = baseTicks + 1
			end
			Module:SetCastTicks(self, baseTicks)
		else
			Module:HideTicks()
		end
	else
		Module:HideTicks()
	end
end

function Module:PostCastInterruptible(unit)
	if unit == "vehicle" or unit == "player" then
		return
	end

	local colors = K.Colors
	local r, g, b = colors.status.castColor[1], colors.status.castColor[2], colors.status.castColor[3]

	local t
	if C["Unitframe"].CastClassColor and UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		t = K.Colors.class[class]
	elseif C["Unitframe"].CastReactionColor and UnitReaction(unit, 'player') then
		t = K.Colors.reaction[UnitReaction(unit, "player")]
	end

	if (t) then
		r, g, b = t[1], t[2], t[3]
	end

	if self.notInterruptible and UnitCanAttack("player", unit) then
		r, g, b = colors.status.castNoInterrupt[1], colors.status.castNoInterrupt[2], colors.status.castNoInterrupt[3]
	end

	self:SetStatusBarColor(r, g, b)
end

function Module:PostCastNotInterruptible()
	local colors = K.Colors
	self:SetStatusBarColor(colors.status.castNoInterrupt[1], colors.status.castNoInterrupt[2], colors.status.castNoInterrupt[3])
end

function Module:PostCastFailedOrInterrupted()
	self:SetStatusBarColor(1.0, 0.0, 0.0)
	self:SetValue(self.max)

	local time = self.Time
	if (time) then
		time:SetText("")
	end

	local spark = self.Spark
	if (spark) then
		spark:SetPoint("CENTER", self, "RIGHT")
	end
end

function Module:CreateAuraTimer(elapsed)
	if (self.TimeLeft) then
		self.Elapsed = (self.Elapsed or 0) + elapsed

		if self.Elapsed >= 0.1 then
			if not self.First then
				self.TimeLeft = self.TimeLeft - self.Elapsed
			else
				self.TimeLeft = self.TimeLeft - GetTime()
				self.First = false
			end

			if self.TimeLeft > 0 then
				local Time = K.FormatTime(self.TimeLeft)
				self.Remaining:SetText(Time)

				if self.TimeLeft <= 5 then
					self.Remaining:SetTextColor(1, 0, 0)
				else
					self.Remaining:SetTextColor(1, 1, 1)
				end
			else
				self.Remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end

			self.Elapsed = 0
		end
	end
end

function Module:PostCreateAura(button)
	local buttonFont = C["Media"].Font
	local buttonFontSize = self.size * 0.46

	if string_match(button:GetName(), "NamePlate") then
		if C["Nameplates"].Enable then
			button:CreateShadow(true)

			button.Remaining = button.cd:CreateFontString(nil, "OVERLAY")
			button.Remaining:SetFont(buttonFont, buttonFontSize, "THINOUTLINE")
			button.Remaining:SetPoint("CENTER", 1, 0)

			button.cd.noOCC = true
			button.cd.noCooldownCount = true
			button.cd:SetReverse(true)
			button.cd:SetFrameLevel(button:GetFrameLevel() + 1)
			button.cd:ClearAllPoints()
			button.cd:SetAllPoints()
			button.cd:SetHideCountdownNumbers(true)

			button.icon:SetAllPoints()
			button.icon:SetTexCoord(K.TexCoords[1], K.TexCoords[2], K.TexCoords[3], K.TexCoords[4])
			button.icon:SetDrawLayer("ARTWORK")

			button.count:SetPoint("BOTTOMRIGHT", 1, 1)
			button.count:SetJustifyH("RIGHT")
			button.count:SetFont(buttonFont, buttonFontSize, "THINOUTLINE")
			button.count:SetTextColor(0.84, 0.75, 0.65)
		end
	else
		button:CreateBorder()

		button.Remaining = button.cd:CreateFontString(nil, "OVERLAY")
		button.Remaining:SetFont(buttonFont, buttonFontSize, "THINOUTLINE")
		button.Remaining:SetPoint("CENTER", 1, 0)

		button.cd.noOCC = true
		button.cd.noCooldownCount = true
		button.cd:SetReverse(true)
		button.cd:SetFrameLevel(button:GetFrameLevel() + 1)
		button.cd:ClearAllPoints()
		button.cd:SetPoint("TOPLEFT", 1, -1)
		button.cd:SetPoint("BOTTOMRIGHT", -1, 1)
		button.cd:SetHideCountdownNumbers(true)

		button.icon:SetAllPoints()
		button.icon:SetTexCoord(K.TexCoords[1], K.TexCoords[2], K.TexCoords[3], K.TexCoords[4])
		button.icon:SetDrawLayer("ARTWORK")

		button.count:SetPoint("BOTTOMRIGHT", 1, 1)
		button.count:SetJustifyH("RIGHT")
		button.count:SetFont(buttonFont, buttonFontSize, "THINOUTLINE")
		button.count:SetTextColor(0.84, 0.75, 0.65)

		button.OverlayFrame = CreateFrame("Frame", nil, button, nil)
		button.OverlayFrame:SetFrameLevel(button.cd:GetFrameLevel() + 1)
		button.overlay:SetParent(button.OverlayFrame)
		button.count:SetParent(button.OverlayFrame)
		button.Remaining:SetParent(button.OverlayFrame)

		button.Animation = button:CreateAnimationGroup()
		button.Animation:SetLooping("BOUNCE")

		button.Animation.FadeOut = button.Animation:CreateAnimation("Alpha")
		button.Animation.FadeOut:SetFromAlpha(1)
		button.Animation.FadeOut:SetToAlpha(0)
		button.Animation.FadeOut:SetDuration(.6)
		button.Animation.FadeOut:SetSmoothing("IN_OUT")
	end
end

function Module:PostUpdateAura(unit, button, index)
	if not button then
		return
	end

	local Name, _, _, DType, Duration, ExpirationTime, Caster, IsStealable = UnitAura(unit, index, button.filter)

	local isPlayer = (Caster == "player" or Caster == "vehicle")
	local isFriend = unit and UnitIsFriend("player", unit) and not UnitCanAttack("player", unit)

	if button then
		if button.isDebuff then
			if (not isFriend and not isPlayer) then
				if C["Unitframe"].OnlyShowPlayerDebuff then
					button:Hide()
				else
					button.icon:SetDesaturated((unit and not string_find(unit, "arena%d")) and true or false)
					button:SetBackdropBorderColor()
					if button.Shadow then
						button.Shadow:SetBackdropBorderColor(0, 0, 0, 0.8)
					end
				end
			else
				local color = (DType and DebuffTypeColor[DType]) or DebuffTypeColor.none
				if Name and (Name == "Unstable Affliction" or Name == "Vampiric Touch") and K.Class ~= "WARLOCK" then
					button:SetBackdropBorderColor(0.05, 0.85, 0.94)
					if button.Shadow then
						button.Shadow:SetBackdropBorderColor(0.05, 0.85, 0.94, 0.8)
					end
				else
					button:SetBackdropBorderColor(color.r, color.g, color.b)
					if button.Shadow then
						button.Shadow:SetBackdropBorderColor(color.r * 0.6, color.g * 0.6, color.b * 0.6, 0.8)
					end
				end
				button.icon:SetDesaturated(false)
			end
		else
			if button.Animation then
				if IsStealable and not isFriend and not button.Animation.Playing then
					button:SetBackdropBorderColor(237/255, 234/255, 142/255)
					button.Animation:Play()
					button.Animation.Playing = true
				else
					button:SetBackdropBorderColor()
					button.Animation:Stop()
					button.Animation.Playing = false
				end
			end
		end

		if button.Remaining then
			if Duration and Duration > 0 then
				button.Remaining:Show()
			else
				button.Remaining:Hide()
			end

			button:SetScript("OnUpdate", Module.CreateAuraTimer)
		end

		button.Duration = Duration
		button.TimeLeft = ExpirationTime
		button.First = true
	end
end

function Module:CreateAuraWatchIcon(icon)
	icon:CreateShadow(true)
	icon.icon:SetPoint("TOPLEFT")
	icon.icon:SetPoint("BOTTOMRIGHT")
	icon.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	icon.icon:SetDrawLayer("ARTWORK")

	if (icon.cd) then
		icon.cd:SetHideCountdownNumbers(true)
		icon.cd:SetReverse(true)
	end

	icon.overlay:SetTexture()
end

function Module:CreateAuraWatch(frame)
	local buffs = {}
	local Class = select(2, UnitClass("player"))

	local Auras = CreateFrame("Frame", nil, frame)
	Auras:SetPoint("TOPLEFT", frame.Health, 2, -2)
	Auras:SetPoint("BOTTOMRIGHT", frame.Health, -2, 2)
	Auras.presentAlpha = 1
	Auras.missingAlpha = 0
	Auras.icons = {}
	Auras.PostCreateIcon = Module.CreateAuraWatchIcon
	Auras.strictMatching = true

	if (Module.RaidBuffsTracking["ALL"]) then
		for _, value in pairs(Module.RaidBuffsTracking["ALL"]) do
			table_insert(buffs, value)
		end
	end

	if (Module.RaidBuffsTracking[Class]) then
		for _, value in pairs(Module.RaidBuffsTracking[Class]) do
			table_insert(buffs, value)
		end
	end

	if (buffs) then
		for _, spell in pairs(buffs) do
			local Icon = CreateFrame("Frame", nil, Auras)
			Icon.spellID = spell[1]
			Icon.anyUnit = spell[4]
			Icon:SetWidth(C["Raid"].AuraWatchIconSize)
			Icon:SetHeight(C["Raid"].AuraWatchIconSize)
			Icon:SetPoint(spell[2], 0, 0)

			if C["Raid"].AuraWatchTexture then
				local Texture = Icon:CreateTexture(nil, "OVERLAY")
				Texture:SetInside(Icon)
				Texture:SetTexture(C["Media"].Blank)

				if (spell[3]) then
					Texture:SetVertexColor(unpack(spell[3]))
				else
					Texture:SetVertexColor(0.8, 0.8, 0.8)
				end
			end

			local Count = Icon:CreateFontString(nil, "OVERLAY")
			Count:SetFont(C["Media"].Font, 8, "THINOUTLINE")
			Count:SetPoint("CENTER", unpack(Module.RaidBuffsTrackingPosition[spell[2]]))
			Icon.count = Count

			Auras.icons[spell[1]] = Icon
		end
	end

	frame.AuraWatch = Auras
end

function Module:UpdateNameplateTarget()
	local Nameplate = self

	if not Nameplate then
		return
	end

	local targetExists = UnitExists("target")
	local unitIsPlayer = UnitIsUnit(Nameplate.unit, "player")
	local unitIsTarget = UnitIsUnit(Nameplate.unit, "target")
	local plateDatabase = C["Nameplates"]

	if unitIsTarget and not unitIsPlayer then
		Nameplate:SetSize(plateDatabase.Width, plateDatabase.Height)
		Nameplate.Castbar:SetPoint("TOPLEFT", Nameplate.Health, "BOTTOMLEFT", 0, -4)
		Nameplate.Castbar:SetPoint("TOPRIGHT", Nameplate.Health, "BOTTOMRIGHT", 0, -4)

		Nameplate:SetAlpha(1)
	else
		Nameplate:SetSize(plateDatabase.Width, plateDatabase.Height)
		Nameplate.Castbar:SetPoint("TOPLEFT", Nameplate.Health, "BOTTOMLEFT", 0, -4)
		Nameplate.Castbar:SetPoint("TOPRIGHT", Nameplate.Health, "BOTTOMRIGHT", 0, -4)

		if targetExists and not unitIsPlayer then
			Nameplate:SetAlpha(plateDatabase.NonTargetAlpha)
		else
			Nameplate:SetAlpha(1)
		end
	end
end

function Module:NameplatesCallback(event, unit)
	local Nameplate = self

	if not unit or not Nameplate then
		return
	end

	-- Position of the resources
	local Point, Relpoint, xOffset, yOffset = "TOP", "BOTTOM", 0, -8

	if Nameplate.QuestIcon then
		Module.UpdateQuestUnit(Nameplate, unit)
	end

	if C["Nameplates"].EliteIcon and Nameplate.EliteIcon then
		Module.NameplateEliteIcon(Nameplate)
	end

	Module.HighlightPlate(Nameplate)
	Module.UpdateNameplateTarget(Nameplate)

	if C["Nameplates"].ClassIcons and Nameplate.Class then
		Module.NameplateClassIcons(Nameplate)
	end

	if C["Nameplates"].Totems and Nameplate.Totem then
		Module.UpdatePlateTotems(Nameplate)
	end

	if C["Nameplates"].MarkHealers and Nameplate.HealerTexture then
		Module.DisplayHealerTexture(Nameplate)
	end

	if event == "NAME_PLATE_UNIT_ADDED" then
		if UnitIsUnit(unit, "player") then
			Nameplate:DisableElement("Castbar")
			Nameplate:DisableElement("RaidTargetIndicator")
			Nameplate:DisableElement("PvPIndicator")
			Nameplate.Name:Hide()

			if Nameplate.ClassPowerText then
				Nameplate.ClassPowerText:Show()
			end

			if Nameplate.ClassPower then
				Nameplate.ClassPower:Show()
				Nameplate:EnableElement("ClassPower")
				Nameplate.ClassPower:ForceUpdate()

				if (K.Class == "DEATHKNIGHT") then
					Nameplate.Runes:Show()
					Nameplate:EnableElement("Runes")
					Nameplate.Runes:ForceUpdate()
				end
			end
		else
			Nameplate:EnableElement("Castbar")
			Nameplate:EnableElement("RaidTargetIndicator")
			Nameplate:EnableElement("PvPIndicator")
			Nameplate.Name:Show()

			if Nameplate.ClassPowerText then
				Nameplate.ClassPowerText:Hide()
			end

			if Nameplate.ClassPower then
				Nameplate.ClassPower:Hide()
				Nameplate:DisableElement("ClassPower")

				if (K.Class == "DEATHKNIGHT") then
					Nameplate.Runes:Hide()
					Nameplate:DisableElement("Runes")
				end
			end
		end
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		Nameplate:DisableElement("ClassPower")
		Nameplate:DisableElement("Runes")
		Nameplate:DisableElement("Stagger")

		Nameplate:EnableElement("Castbar")
		Nameplate:EnableElement("RaidTargetIndicator")
		Nameplate:EnableElement("PvPIndicator")
		Nameplate.Name:Show()

		if Nameplate.ClassPowerText then
			Nameplate.ClassPowerText:Hide()
			Nameplate.ClassPowerText:ClearAllPoints()
			Nameplate.ClassPowerText:SetPoint(Point, Nameplate.Health, Relpoint, xOffset, yOffset)
			Nameplate.ClassPowerText:SetParent(Nameplate)
		end

		if Nameplate.ClassPower then
			Nameplate.ClassPower:Hide()
			Nameplate.ClassPower:ClearAllPoints()
			Nameplate.ClassPower:SetParent(Nameplate)
			Nameplate.ClassPower:SetPoint(Point, Nameplate.Health, Relpoint, xOffset, yOffset)
		end

		if Nameplate.Runes then
			Nameplate.Runes:Hide()
			Nameplate.Runes:ClearAllPoints()
			Nameplate.Runes:SetParent(Nameplate)
			Nameplate.Runes:SetPoint(Point, Nameplate.Health, Relpoint, xOffset, yOffset)
		end

		if Nameplate.Stagger then
			Nameplate.Stagger:Hide()
			Nameplate.Stagger:ClearAllPoints()
			Nameplate.Stagger:SetParent(Nameplate)
			Nameplate.Stagger:SetPoint(Point, Nameplate.Health, Relpoint, xOffset, yOffset)
		end
	end

	if _G.GetCVarBool("nameplateResourceOnTarget") then
		local Player, Target = C_NamePlate_GetNamePlateForUnit("player"), UnitExists("target") and C_NamePlate_GetNamePlateForUnit("target")
		if Target and Target:IsForbidden() then
			Target = nil
		end
		if Player then
			local Anchor = Target and Target.unitFrame or Player.unitFrame
			if Player.unitFrame.ClassPowerText then
				Player.unitFrame.ClassPowerText:ClearAllPoints()
				Player.unitFrame.ClassPowerText:SetParent(Anchor)
				Player.unitFrame.ClassPowerText:SetPoint(Point, Anchor.Health, Relpoint, xOffset, yOffset)
			end
			if Player.unitFrame.ClassPower then
				Player.unitFrame.ClassPower:ClearAllPoints()
				Player.unitFrame.ClassPower:SetParent(Anchor)
				Player.unitFrame.ClassPower:SetPoint(Point, Anchor.Health, Relpoint, xOffset, yOffset)
			end
			if Player.unitFrame.Runes then
				Player.unitFrame.Runes:ClearAllPoints()
				Player.unitFrame.Runes:SetParent(Anchor)
				Player.unitFrame.Runes:SetPoint(Point, Anchor.Health, Relpoint, xOffset, yOffset)
			end
			if Player.unitFrame.Stagger then
				Player.unitFrame.Stagger:ClearAllPoints()
				Player.unitFrame.Stagger:SetParent(Anchor)
				Player.unitFrame.Stagger:SetPoint(Point, Anchor.Health, Relpoint, xOffset, yOffset)
			end
		end
	end
end

function Module:NameplatePowerAndCastBar(unit, cur, _, max)
	if not unit then
		unit = self:GetParent().unit
	end

	if not unit then
		return
	end

	if not cur then
		cur, max = UnitPower(unit), UnitPowerMax(unit)
	end

	local CurrentPower = cur
	local MaxPower = max
	local Nameplate = self:GetParent()
	local PowerBar = Nameplate.Power
	local CastBar = Nameplate.Castbar
	local Health = Nameplate.Health
	local IsPowerHidden = PowerBar.IsHidden

	if (not CastBar:IsShown()) and (CurrentPower and CurrentPower == 0) and (MaxPower and MaxPower == 0) then
		if (not IsPowerHidden) then
			Health:ClearAllPoints()
			Health:SetAllPoints()

			PowerBar:Hide()
			PowerBar.IsHidden = true
		end
	else
		if IsPowerHidden then
			Health:ClearAllPoints()
			Health:SetPoint("TOPLEFT")
			Health:SetHeight(C["Nameplates"].Height - C["Nameplates"].CastHeight - 1)
			Health:SetWidth(Nameplate:GetWidth())

			PowerBar:Show()
			PowerBar.IsHidden = false
		end
	end
end

function Module:NameplateClassIcons()
	local Nameplate = self
	local reaction = UnitReaction(Nameplate.unit, "player")

	if UnitIsPlayer(Nameplate.unit) and (reaction and reaction <= 4) then
		local _, class = UnitClass(Nameplate.unit)
		local texcoord = CLASS_ICON_TCOORDS[class]

		Nameplate.Class.Icon:SetTexCoord(texcoord[1] + 0.015, texcoord[2] - 0.02, texcoord[3] + 0.018, texcoord[4] - 0.02)
		Nameplate.Class:Show()
	else
		Nameplate.Class.Icon:SetTexCoord(0, 0, 0, 0)
		Nameplate.Class:Hide()
	end
end

function Module:NameplateEliteIcon()
	if C["Nameplates"].EliteIcon ~= true then
		return
	end

	local icon = self.EliteIcon
	local c = UnitClassification(self.unit)
	if c == "elite" or c == "worldboss" then
		icon:SetTexCoord(0, 0.15, 0.25, 0.53)
		icon:Show()
	elseif c == "rareelite" or c == "rare" then
		icon:SetTexCoord(0, 0.15, 0.52, 0.84)
		icon:Show()
	else
		icon:Hide()
	end
end

function Module:GetPartyFramesAttributes()
	local PartyProperties = C["Party"].PartyAsRaid and "custom [group:party] hide" or "custom [@raid6,exists] hide;show"

	return "oUF_Party", nil, PartyProperties,
	"oUF-initialConfigFunction", [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute("initial-width"))
	self:SetHeight(header:GetAttribute("initial-height"))
	]],

	"initial-width", 158,
	"initial-height", 38,
	"showSolo", false,
	"showParty", true,
	"showPlayer", C["Party"].ShowPlayer,
	"showRaid", true,
	"groupFilter", "1, 2, 3, 4, 5, 6, 7, 8",
	"groupingOrder", "1, 2, 3, 4, 5, 6, 7, 8",
	"groupBy", "GROUP",
	"yOffset", C["Party"].ShowBuffs and -44 or -18
end

function Module:GetDamageRaidFramesAttributes()
	local DamageRaidProperties = C["Party"].PartyAsRaid and "custom [group:party] show" or "custom [@raid6,exists] show;hide"

	return "DamageRaid", nil, DamageRaidProperties,
	"oUF-initialConfigFunction", [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute("initial-width"))
	self:SetHeight(header:GetAttribute("initial-height"))
	]],

	"initial-width", C["Raid"].Width,
	"initial-height", C["Raid"].Height,
	"showParty", true,
	"showRaid", true,
	"showPlayer", true,
	"showSolo", false,
	"xoffset", 6,
	"yOffset", -6,
	"point", "TOP",
	"groupFilter", "1, 2, 3, 4, 5, 6, 7, 8",
	"groupingOrder", "1, 2, 3, 4, 5, 6, 7, 8",
	"groupBy", C["Raid"].GroupBy.Value,
	"maxColumns", math_ceil(40 / 5),
	"unitsPerColumn", C["Raid"].MaxUnitPerColumn,
	"columnSpacing", 6,
	"columnAnchorPoint", "LEFT"
end

function Module:GetHealerRaidFramesAttributes()
	local HealerRaidProperties = C["Party"].PartyAsRaid and "custom [group:party] show" or "custom [@raid6,exists] show;hide"

	return "HealerRaid", nil, HealerRaidProperties,
	"oUF-initialConfigFunction", [[
	local header = self:GetParent()
	self:SetWidth(header:GetAttribute("initial-width"))
	self:SetHeight(header:GetAttribute("initial-height"))
	]],

	"initial-width", C["Raid"].Width - 12,
	"initial-height", C["Raid"].Height - 6,
	"showParty", true,
	"showRaid", true,
	"showPlayer", true,
	"showSolo", false,
	"xoffset", 6,
	"yOffset", -6,
	"point", "TOP",
	"groupFilter", "1, 2, 3, 4, 5, 6, 7, 8",
	"groupingOrder", "1, 2, 3, 4, 5, 6, 7, 8",
	"groupBy", C["Raid"].GroupBy.Value,
	"maxColumns", 8,
	"unitsPerColumn", 5,
	"columnSpacing", 6,
	"columnAnchorPoint", "LEFT"
end

function Module:GetMainTankAttributes()
	local MainTankProperties = "raid"

	return "oUF_MainTank", nil, MainTankProperties,
	"oUF-initialConfigFunction", [[
	self:SetWidth(76)
	self:SetHeight(40)
	]],

	"showRaid", true,
	"yOffset", -8,
	"groupFilter", "MAINTANK",
	"template", "oUF_MainTank"
end

function Module:CreateStyle(unit)
	if (not unit) then
		return
	end

	local Parent = self:GetParent():GetName()

	if (unit == "player") then
		Module.CreatePlayer(self)
	elseif (unit == "target") then
		Module.CreateTarget(self)
	elseif (unit == "targettarget") then
		Module.CreateTargetOfTarget(self)
	elseif (unit == "pet") then
		Module.CreatePet(self)
	elseif (unit == "focus") then
		Module.CreateFocus(self)
	elseif (unit == "focustarget") then
		Module.CreateFocusTarget(self)
	elseif string_find(unit, "arena%d") then
		Module.CreateArena(self)
	elseif string_find(unit, "boss%d") then
		Module.CreateBoss(self)
	elseif (string_find(unit, "party") or string_find(unit, "raid") or string_find(unit, "maintank")) then
		if string_match(Parent, "Party") then
			Module.CreateParty(self)
		else
			Module.CreateRaid(self)
		end
	elseif string_match(unit, "nameplate") and C["Nameplates"].Enable then
		Module.CreateNameplates(self)
	end

	return self
end

function Module:CreateUnits()
	if (C["Unitframe"].Enable) then
		local Player = oUF:Spawn("player")
		Player:SetPoint("BOTTOMRIGHT", "ActionBarAnchor", "TOPLEFT", 44, 200)
		Player:SetSize(200, 52)

		local Target = oUF:Spawn("target")
		Target:SetPoint("BOTTOMLEFT", "ActionBarAnchor", "TOPRIGHT", -44, 200)
		Target:SetSize(200, 52)

		local TargetOfTarget = oUF:Spawn("targettarget")
		TargetOfTarget:SetPoint("TOPLEFT", Target, "BOTTOMRIGHT", -56, 2)
		TargetOfTarget:SetSize(116, 36)

		local Pet = oUF:Spawn("pet")
		if C["Unitframe"].CombatFade and Player and not InCombatLockdown() then
			Pet:SetParent(Player)
		end
		Pet:SetPoint("TOPRIGHT", Player, "BOTTOMLEFT", 56, 2)
		Pet:SetSize(116, 36)

		local Focus = oUF:Spawn("focus")
		Focus:SetPoint("BOTTOMRIGHT", Player, "TOPLEFT", -60, 30)
		Focus:SetSize(190, 52)

		local FocusTarget = oUF:Spawn("focustarget")
		FocusTarget:SetPoint("TOPRIGHT", Focus, "BOTTOMLEFT", 56, 2)
		FocusTarget:SetSize(116, 36)

		Module.Player = Player
		Module.Target = Target
		Module.TargetOfTarget = TargetOfTarget
		Module.Pet = Pet
		Module.Focus = Focus
		Module.FocusTarget = FocusTarget

		if (C["Arena"].Enable) then
			local Arena = {}
			for i = 1, MAX_ARENA_ENEMIES or 5 do
				Arena[i] = oUF:Spawn("arena" .. i, nil)
				Arena[i]:SetSize(190, 52)
				if (i == 1) then
					Arena[i]:SetPoint("BOTTOMRIGHT", UIParent, "RIGHT", -140, 140)
				else
					Arena[i]:SetPoint("TOPLEFT", Arena[i - 1], "BOTTOMLEFT", 0, -48)
				end
				Movers:RegisterFrame(Arena[i])
			end

			Module.Arena = Arena
		end

		if (C["Boss"].Enable) then
			local Boss = {}
			for i = 1, MAX_BOSS_FRAMES do
				Boss[i] = oUF:Spawn("boss" .. i)
				if (i == 1) then
					Boss[i]:SetPoint("BOTTOMRIGHT", UIParent, "RIGHT", -140, 140)
				else
					Boss[i]:SetPoint("TOPLEFT", Boss[i - 1], "BOTTOMLEFT", 0, -28)
				end

				Boss[i]:SetSize(190, 52)
				Movers:RegisterFrame(Boss[i])
			end

			Module.Boss = Boss
		end

		if C["Party"].Enable then
			local Party = oUF:SpawnHeader(Module:GetPartyFramesAttributes())
			Party:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 4, -180)
			Movers:RegisterFrame(Party)
		end

		if C["Raid"].Enable then
			local DamageRaid = oUF:SpawnHeader(Module:GetDamageRaidFramesAttributes())
			local HealerRaid = oUF:SpawnHeader(Module:GetHealerRaidFramesAttributes())
			local MainTankRaid = oUF:SpawnHeader(Module:GetMainTankAttributes())

			if C["Raid"].RaidLayout.Value == "Healer" then
				HealerRaid:SetPoint("TOPLEFT", "oUF_Player", "BOTTOMRIGHT", 10, 14)
				Movers:RegisterFrame(HealerRaid)
			elseif C["Raid"].RaidLayout.Value == "Damage" then
				DamageRaid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 4, -30)
				Movers:RegisterFrame(DamageRaid)
			end

			if C["Raid"].MainTankFrames then
				if C["Raid"].RaidLayout.Value == "Healer" then
					MainTankRaid:SetPoint("BOTTOMLEFT", "ActionBarAnchor", "BOTTOMRIGHT", 6, 2)
				elseif C["Raid"].RaidLayout.Value == "Damage" then
					MainTankRaid:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 6, -6)
				end

				Movers:RegisterFrame(MainTankRaid)
			end
		end

		Movers:RegisterFrame(Player)
		Movers:RegisterFrame(Target)
		Movers:RegisterFrame(TargetOfTarget)
		Movers:RegisterFrame(Pet)
		Movers:RegisterFrame(Focus)
		Movers:RegisterFrame(FocusTarget)
	end

	if C["Nameplates"].Enable then
		Module.NameplatesVars = {
			nameplateGlobalScale = 1,
			NamePlateHorizontalScale = 1,
			nameplateLargerScale = 1.2,
			nameplateMaxAlpha = 1,
			nameplateMaxAlphaDistance = 0,
			nameplateMaxDistance = C["Nameplates"].Distance + 6 or 46,
			nameplateMaxScale = 1,
			nameplateMaxScaleDistance = 0,
			nameplateMinAlpha = 1,
			nameplateMinAlphaDistance = 0,
			nameplateMinScale = 1,
			nameplateMinScaleDistance = 0,
			nameplateOtherBottomInset = C["Nameplates"].Clamp and 0.1 or -1,
			nameplateOtherTopInset = C["Nameplates"].Clamp and 0.08 or -1,
			nameplateOverlapV = C["Nameplates"].OverlapV or 1.2,
			nameplateOverlapW = C["Nameplates"].OverlapH or 1.2,
			nameplateSelectedAlpha = 1,
			nameplateSelectedScale = C["Nameplates"].SelectedScale or 1,
			nameplateSelfAlpha = 1,
			nameplateSelfScale = 1,
			nameplateShowAll = 1,
			nameplateShowFriendlyNPCs = 0,
			NamePlateVerticalScale = 1,
		}

		oUF:SpawnNamePlates(nil, Module.NameplatesCallback, Module.NameplatesVars)
	end
end

function Module:PostUpdateArenaPreparationSpec()
	local specIcon = self.PVPSpecIcon
	local instanceType = select(2, IsInInstance())

	if (instanceType == "arena") then
		local specID = self.id and GetArenaOpponentSpec(tonumber(self.id))

		if specID and specID > 0 then
			local icon = select(4, GetSpecializationInfoByID(specID))

			specIcon.Icon:SetTexture(icon)
		else
			specIcon.Icon:SetTexture([[INTERFACE\ICONS\INV_MISC_QUESTIONMARK]])
		end
	else
		local faction = UnitFactionGroup(self.unit)

		if faction == "Horde" then
			specIcon.Icon:SetTexture([[Interface\Icons\INV_BannerPVP_01]])
		elseif faction == "Alliance" then
			specIcon.Icon:SetTexture([[Interface\Icons\INV_BannerPVP_02]])
		else
			specIcon.Icon:SetTexture([[INTERFACE\ICONS\INV_MISC_QUESTIONMARK]])
		end
	end

	self.forceInRange = true
end

function Module:UpdatePowerColorArenaPreparation(specID)
	-- oUF is unable to get power color on arena preparation, so we add this feature here.
	local power = self
	local playerClass = select(6, GetSpecializationInfoByID(specID))

	if playerClass then
		local powerColor = K.Colors.specpowertypes[playerClass][specID]

		if powerColor then
			local r, g, b = unpack(powerColor)

			power:SetStatusBarColor(r, g, b)
		else
			power:SetStatusBarColor(0, 0, 0)
		end
	end
end

function Module:CreateFilgerAnchors()
	if C["Filger"].Enable and C["Unitframe"].Enable then
		P_BUFF_ICON_Anchor:SetPoint("BOTTOMRIGHT", "oUF_Player", "TOPRIGHT", 2, 169)
		P_BUFF_ICON_Anchor:SetSize(C["Filger"].BuffSize, C["Filger"].BuffSize)

		P_PROC_ICON_Anchor:SetPoint("BOTTOMLEFT", "oUF_Target", "TOPLEFT", -2, 169)
		P_PROC_ICON_Anchor:SetSize(C["Filger"].BuffSize, C["Filger"].BuffSize)

		SPECIAL_P_BUFF_ICON_Anchor:SetPoint("BOTTOMRIGHT", "oUF_Player", "TOPRIGHT", 2, 211)
		SPECIAL_P_BUFF_ICON_Anchor:SetSize(C["Filger"].BuffSize, C["Filger"].BuffSize)

		T_DEBUFF_ICON_Anchor:SetPoint("BOTTOMLEFT", "oUF_Target", "TOPLEFT", -2, 211)
		T_DEBUFF_ICON_Anchor:SetSize(C["Filger"].BuffSize, C["Filger"].BuffSize)

		T_BUFF_Anchor:SetPoint("BOTTOMLEFT", "oUF_Target", "TOPLEFT", -2, 253)
		T_BUFF_Anchor:SetSize(C["Filger"].PvPSize, C["Filger"].PvPSize)

		PVE_PVP_DEBUFF_Anchor:SetPoint("BOTTOMRIGHT", "oUF_Player", "TOPRIGHT", 2, 253)
		PVE_PVP_DEBUFF_Anchor:SetSize(C["Filger"].PvPSize, C["Filger"].PvPSize)

		PVE_PVP_CC_Anchor:SetPoint("TOPLEFT", "oUF_Player", "BOTTOMLEFT", -2, -44)
		PVE_PVP_CC_Anchor:SetSize(221, 25)

		COOLDOWN_Anchor:SetPoint("BOTTOMRIGHT", "oUF_Player", "TOPRIGHT", 63, 17)
		COOLDOWN_Anchor:SetSize(C["Filger"].CooldownSize, C["Filger"].CooldownSize)

		T_DE_BUFF_BAR_Anchor:SetPoint("BOTTOMLEFT", "oUF_Target", "BOTTOMRIGHT", 2, 3)
		T_DE_BUFF_BAR_Anchor:SetSize(218, 25)

		Movers:RegisterFrame(P_BUFF_ICON_Anchor)
		Movers:RegisterFrame(P_PROC_ICON_Anchor)
		Movers:RegisterFrame(SPECIAL_P_BUFF_ICON_Anchor)
		Movers:RegisterFrame(T_DEBUFF_ICON_Anchor)
		Movers:RegisterFrame(T_BUFF_Anchor)
		Movers:RegisterFrame(PVE_PVP_DEBUFF_Anchor)
		Movers:RegisterFrame(PVE_PVP_CC_Anchor)
		Movers:RegisterFrame(COOLDOWN_Anchor)
		Movers:RegisterFrame(T_DE_BUFF_BAR_Anchor)
	end
end

function Module:ToggleCombatNameplates(event)
	if event == "PLAYER_REGEN_ENABLED" then
		SetCVar("nameplateShowEnemies", 0)
	elseif event == "PLAYER_REGEN_DISABLED" then
		SetCVar("nameplateShowEnemies", 1)
	end
end

function Module:PLAYER_ENTERING_WORLD()
	local inInstance, instanceType = IsInInstance()
	local lockedInstance = instanceType and not (instanceType == "none" or instanceType == "pvp" or instanceType == "arena")

	if C["Nameplates"].Enable then
		if C["Nameplates"].Combat then
			SetCVar("nameplateShowEnemies", UnitAffectingCombat("player") and 1 or 0)

			if C["Nameplates"].Threat then
				SetCVar("threatWarning", 3)
			end
		end
	end

	if C["Nameplates"].Enable then
		if C["Nameplates"].MarkHealers then
			table_wipe(self.Healers)

			if inInstance and (instanceType == "pvp") and C["Nameplates"].MarkHealers then
				self.CheckHealerTimer = self:ScheduleRepeatingTimer("CheckBGHealers", 3)
				self:CheckBGHealers()
			elseif inInstance and (instanceType == "arena") and C["Nameplates"].MarkHealers then
				self:RegisterEvent("UNIT_NAME_UPDATE", "CheckArenaHealers")
				self:RegisterEvent("ARENA_OPPONENT_UPDATE", "CheckArenaHealers")
				self:CheckArenaHealers()
			else
				self:UnregisterEvent("UNIT_NAME_UPDATE")
				self:UnregisterEvent("ARENA_OPPONENT_UPDATE")
				if self.CheckHealerTimer then
					self:CancelTimer(self.CheckHealerTimer)
					self.CheckHealerTimer = nil
				end
			end
		end
	end

	if lockedInstance then
		K.LockCVar("nameplateShowDebuffsOnFriendly", false)
	else
		K.LockedCVars["nameplateShowDebuffsOnFriendly"] = nil
		SetCVar("nameplateShowDebuffsOnFriendly", true)
	end
end

function Module:DisplayHealerTexture()
	local name, realm = UnitName(self.unit)
	realm = (realm and realm ~= "") and string_gsub(realm, "[%s%-]", "")

	if realm then
		name = name .. "-" .. realm
	end

	local icon = self.HealerTexture

	if C["Nameplates"].MarkHealers then
		if Module.Healers[name] then
			if Module.exClass[Module.Healers[name]] then
				icon:Hide()
			else
				icon:Show()
			end
		else
			icon:Hide()
		end
	end
end

function Module:UpdateRaidDebuffIndicator()
	local ORD = oUF_RaidDebuffs or K.oUF_RaidDebuffs

	if (ORD) then
		ORD:ResetDebuffData()
		local _, InstanceType = IsInInstance()
		if (InstanceType == "party" or InstanceType == "raid") then
			ORD:RegisterDebuffs(Module.DebuffsTracking.RaidDebuffs.spells)
		else
			ORD:RegisterDebuffs(Module.DebuffsTracking.CCDebuffs.spells)
		end
	end
end

local function CreateTargetSound(unit)
	if UnitExists(unit) then
		if UnitIsEnemy(unit, "player") then
			PlaySound(SOUNDKIT.IG_CREATURE_AGGRO_SELECT)
		elseif UnitIsFriend("player", unit) then
			PlaySound(SOUNDKIT.IG_CHARACTER_NPC_SELECT)
		else
			PlaySound(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT)
		end
	else
		PlaySound(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT)
	end
end

function Module:PLAYER_FOCUS_CHANGED()
	CreateTargetSound("focus")
end

function Module:PLAYER_TARGET_CHANGED()
	CreateTargetSound("target")
end

local announcedPVP
function Module:UNIT_FACTION(_, unit)
	if (unit ~= "player") then
		return
	end

	if UnitIsPVPFreeForAll("player") or UnitIsPVP("player") then
		if not announcedPVP then
			announcedPVP = true
			PlaySound(SOUNDKIT.IG_PVP_UPDATE)
		end
	else
		announcedPVP = nil
	end
end

function Module:OnEnable()
	if C["Unitframe"].Enable ~= true and C["Party"].Enable ~= true and C["Raid"].Enable ~= true and C["Nameplates"].Enable ~= true then
		return
	end

	self.Backdrop = {
		bgFile = C["Media"].Blank,
		insets = {top = -K.Mult, left = -K.Mult, bottom = -K.Mult, right = -K.Mult}
	}

	oUF:RegisterStyle(" ", Module.CreateStyle)
	oUF:SetActiveStyle(" ")

	self:CreateUnits()
	self:CreateFilgerAnchors()

	if C["Raid"].AuraWatch then
		local RaidDebuffs = CreateFrame("Frame")
		RaidDebuffs:RegisterEvent("PLAYER_ENTERING_WORLD")
		RaidDebuffs:SetScript("OnEvent", Module.UpdateRaidDebuffIndicator)

		local ORD = oUF_RaidDebuffs or K.oUF_RaidDebuffs
		if (ORD) then
			ORD.ShowDispellableDebuff = true
			ORD.FilterDispellableDebuff = true
			ORD.MatchBySpellName = false
		end
	end

	if C["Nameplates"].Enable then
		local UIHider = K.UIFrameHider
		local CNMBFrames = {
			ClassNameplateManaBarFrame,
			ClassNameplateManaBarFrame.Border,
			ClassNameplateManaBarFrame.FeedbackFrame,
			ClassNameplateManaBarFrame.FullPowerFrame,
			ClassNameplateManaBarFrame.ManaCostPredictionBar,
			ClassNameplateManaBarFrame.background,
			ClassNameplateManaBarFrame.Texture
		}

		if C["Nameplates"].Combat then
			self:RegisterEvent("PLAYER_REGEN_ENABLED", "ToggleCombatNameplates")
			self:RegisterEvent("PLAYER_REGEN_DISABLED", "ToggleCombatNameplates")
		end

		if C["Nameplates"].Combat or C["Nameplates"].MarkHealers then
			self:RegisterEvent("PLAYER_ENTERING_WORLD")
		end

		-- disable the default class resource bars
    	DeathKnightResourceOverlayFrame:UnregisterAllEvents()
    	ClassNameplateBarMageFrame:UnregisterAllEvents()
    	ClassNameplateBarWindwalkerMonkFrame:UnregisterAllEvents()
    	ClassNameplateBarPaladinFrame:UnregisterAllEvents()
    	ClassNameplateBarRogueDruidFrame:UnregisterAllEvents()
    	ClassNameplateBarWarlockFrame:UnregisterAllEvents()
    	ClassNameplateManaBarFrame:UnregisterAllEvents()

 	    NamePlateDriverFrame:SetClassNameplateManaBar(nil)
 	    NamePlateDriverFrame:SetClassNameplateBar(nil)

		for _, CNMBFrames in pairs(CNMBFrames) do
			CNMBFrames:ClearAllPoints()
			CNMBFrames:SetParent(UIHider)
		end
	end

	if C["Unitframe"].Enable then
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("UNIT_FACTION")
	end
end