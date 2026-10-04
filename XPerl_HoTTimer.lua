-- [patch] Remaining time of your own HoTs (Renew, Rejuvenation, Regrowth) as
-- a countdown on the buff icons of the party, raid, target and ToT frames.
-- 1.12 has no buff duration for other units, so SuperWoW (UNIT_CASTEVENT)
-- is used to record when we cast which HoT on whom. Without SuperWoW the
-- module stays silent.
--
-- The duration learns itself: as soon as a HoT lands on ourselves, the real
-- remaining time is measured with GetPlayerBuffTimeLeft and stored per
-- character in XPerl_HoTDurations. Talents or set bonuses that extend the
-- duration are thus included automatically after one self-cast.

-- base duration without talents, key = icon file name in lower case
local defaultDurations = {
	spell_holy_renew		= 15,	-- Renew
	spell_nature_rejuvenation	= 12,	-- Rejuvenation
	spell_nature_resistnature	= 21,	-- Regrowth (HoT part)
}

-- fallback in case SpellInfo returns no icon
local nameToKey = {
	["Renew"]		= "spell_holy_renew",
	["Rejuvenation"]	= "spell_nature_rejuvenation",
	["Regrowth"]		= "spell_nature_resistnature",
}

local timers = {}		-- timers[guid][key] = expiry time (GetTime)
local pendingLearn = {}		-- pendingLearn[key] = time of the self-cast
local textShown = {}		-- buttons currently showing a countdown
local playerGUID

local function TexKey(tex)
	if (not tex) then
		return
	end
	return strlower((gsub(tex, "^.*\\", "")))
end

local function NormGUID(guid)
	if (not guid or guid == "") then
		return
	end
	guid = gsub(guid, "^0x", "")
	if (tonumber(guid, 16) == 0) then
		return
	end
	return guid
end

local function UnitGUID(unit)
	local exists, guid = UnitExists(unit)
	if (exists) then
		return NormGUID(guid)
	end
end

local function GetDuration(key)
	if (XPerl_HoTDurations and XPerl_HoTDurations[key]) then
		return XPerl_HoTDurations[key]
	end
	return defaultDurations[key]
end

local function SpellKey(spellID)
	local name, _, tex = SpellInfo(spellID)
	local key = TexKey(tex)
	if (key and defaultDurations[key]) then
		return key
	end
	return name and nameToKey[name]
end

-- measure a self-cast: remaining time + time since the cast = full duration
local function LearnFromPlayerBuffs()
	if (not next(pendingLearn)) then
		return
	end
	local now = GetTime()
	for i = 0, 31 do
		local bid = GetPlayerBuff(i, "HELPFUL")
		if (not bid or bid < 0) then
			break
		end
		local key = TexKey(GetPlayerBuffTexture(bid))
		local castTime = key and pendingLearn[key]
		if (castTime) then
			local left = GetPlayerBuffTimeLeft(bid)
			local dur = left and floor(left + (now - castTime) + 0.5)
			-- talents only extend; a shorter value would be an old HoT that
			-- has not been refreshed yet
			if (dur and dur >= defaultDurations[key] and now - castTime < 2) then
				pendingLearn[key] = nil
				XPerl_HoTDurations = XPerl_HoTDurations or {}
				XPerl_HoTDurations[key] = dur
				if (playerGUID and timers[playerGUID]) then
					timers[playerGUID][key] = castTime + dur
				end
			end
		end
	end
	-- discard anything that does not show up within 2s (e.g. cast missed)
	for key, t in pairs(pendingLearn) do
		if (now - t >= 2) then
			pendingLearn[key] = nil
		end
	end
end

local function OnCastEvent(casterGUID, targetGUID, evType, spellID)
	if (evType ~= "CAST" or not spellID) then
		return
	end
	if (not playerGUID) then
		playerGUID = UnitGUID("player")
	end
	if (NormGUID(casterGUID) ~= playerGUID) then
		return
	end
	local key = SpellKey(spellID)
	if (not key) then
		return
	end

	local now = GetTime()
	local target = NormGUID(targetGUID) or playerGUID
	timers[target] = timers[target] or {}
	timers[target][key] = now + GetDuration(key)

	if (target == playerGUID) then
		pendingLearn[key] = now
	end
end

local function SetButtonText(button, left)
	local text = button.perlHoTText
	if (not text) then
		text = button:CreateFontString(nil, "OVERLAY")
		text:SetPoint("CENTER", button, "CENTER", 0, 0)
		button.perlHoTText = text
	end

	local size = floor(button:GetHeight() * 0.55)
	if (size < 8) then
		size = 8
	end
	if (text.perlSize ~= size) then
		text:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE")
		text.perlSize = size
	end

	if (left >= 60) then
		text:SetText(ceil(left / 60).."m")
	else
		text:SetText(ceil(left))
	end
	if (left <= 3) then
		text:SetTextColor(1, 0.2, 0.2)
	elseif (left <= 6) then
		text:SetTextColor(1, 0.9, 0.2)
	else
		text:SetTextColor(1, 1, 1)
	end
	text:Show()
	textShown[button] = true
end

-- frames with a buff row: name -> unit (nil = from frame.partyid/unitid)
local frameList = {
	{"XPerl_Target", "target"},
	{"XPerl_TargetTarget"},
	{"XPerl_TargetTargetTarget"},
	{"XPerl_party1"}, {"XPerl_party2"}, {"XPerl_party3"}, {"XPerl_party4"},
}
for i = 1, 40 do
	tinsert(frameList, {"XPerl_raid"..i})
end

local function UpdateFrame(frameName, unit, now, seen)
	local frame = getglobal(frameName)
	if (not frame or not frame:IsVisible()) then
		return
	end
	unit = unit or frame.partyid or frame.unitid
	if (not unit) then
		return
	end
	local guid = UnitGUID(unit)
	local myTimers = guid and timers[guid]
	if (not myTimers) then
		return
	end

	for n = 1, 20 do
		local button = getglobal(frameName.."_BuffFrame_Buff"..n)
		if (not button) then
			break
		end
		if (button:IsVisible()) then
			local icon = getglobal(button:GetName().."Icon")
			local expire = myTimers[TexKey(icon:GetTexture())]
			if (expire and expire > now) then
				SetButtonText(button, expire - now)
				seen[button] = true
			end
		end
	end
end

local elapsedSum = 0
local function OnUpdate()
	elapsedSum = elapsedSum + arg1
	if (elapsedSum < 0.2) then
		return
	end
	elapsedSum = 0

	LearnFromPlayerBuffs()
	local now = GetTime()

	-- clean up expired timers
	for guid, list in pairs(timers) do
		for key, expire in pairs(list) do
			if (expire <= now) then
				list[key] = nil
			end
		end
		if (not next(list)) then
			timers[guid] = nil
		end
	end

	local seen = {}
	if (next(timers)) then
		for _, entry in ipairs(frameList) do
			UpdateFrame(entry[1], entry[2], now, seen)
		end
	end

	-- buttons are reused for other buffs: remove old numbers
	for button in pairs(textShown) do
		if (not seen[button]) then
			button.perlHoTText:Hide()
			textShown[button] = nil
		end
	end
end

local frame = CreateFrame("Frame", "XPerl_HoTTimerFrame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
	if (event == "PLAYER_ENTERING_WORLD") then
		playerGUID = UnitGUID("player")
		-- SuperWoW detection: no tracking possible without SpellInfo/GUIDs
		if (SpellInfo and playerGUID and not this.perlActive) then
			this.perlActive = true
			this:RegisterEvent("UNIT_CASTEVENT")
			this:RegisterEvent("PLAYER_AURAS_CHANGED")
			this:SetScript("OnUpdate", OnUpdate)
		end
	elseif (event == "UNIT_CASTEVENT") then
		OnCastEvent(arg1, arg2, arg3, arg4)
	elseif (event == "PLAYER_AURAS_CHANGED") then
		LearnFromPlayerBuffs()
	end
end)
