-- Compatible presentation details adapted from RothUI wow12.0/rLayout.
-- Never change Blizzard's action-bar state drivers: Seraphglass owns its
-- four five-button bars, and the player's own bindings must remain usable.
local _, S = ...
local gold = { 0.70, 0.52, 0.32 }
local muted = { 0.86, 0.75, 0.63 }
local initialized = false

local function tint(texture, color)
  if not texture or not texture.SetVertexColor then return end
  if issecretvalue and issecretvalue(texture) then return end
  if texture.IsForbidden and texture:IsForbidden() then return end
  if texture.SetDesaturated then texture:SetDesaturated(true) end
  texture:SetVertexColor(color[1], color[2], color[3])
end

local function skinUnit(frame)
  if not frame then return end
  local container = frame.TargetFrameContainer
  if container then tint(container.FrameTexture, gold) end
  local content = frame.TargetFrameContent
  local main = content and content.TargetFrameContentMain
  if main and main.Name then main.Name:SetTextColor(muted[1], muted[2], muted[3]) end
end

local function skinTooltip()
  local tooltip = GameTooltip
  if not tooltip then return end
  local nine = tooltip.NineSlice
  if nine and nine.GetRegions then
    for _, region in ipairs({ nine:GetRegions() }) do
      if region and region.IsObjectType and region:IsObjectType("Texture") then
        tint(region, gold)
      end
    end
  end
  if tooltip.StatusBar then
    tooltip.StatusBar:SetStatusBarColor(0.63, 0.12, 0.15)
  end
end

local function skinChat()
  for index = 1, (NUM_CHAT_WINDOWS or 1) do
    local chat = _G["ChatFrame" .. index]
    if chat and not chat.seraphglassSkinned then
      chat.seraphglassSkinned = true
      if chat.SetClampRectInsets then chat:SetClampRectInsets(0, 0, 0, 0) end
      local buttons = _G["ChatFrame" .. index .. "ButtonFrame"]
      if buttons then buttons:Hide() end
      local background = chat:CreateTexture(nil, "BACKGROUND")
      background:SetAllPoints(chat)
      background:SetColorTexture(0.055, 0.038, 0.035, 0.38)
      local edit = _G["ChatFrame" .. index .. "EditBox"]
      if edit then
        if edit.SetAltArrowKeyMode then edit:SetAltArrowKeyMode(false) end
        edit:ClearAllPoints()
        edit:SetPoint("BOTTOMLEFT", chat, "TOPLEFT", -5, 4)
        edit:SetPoint("BOTTOMRIGHT", chat, "TOPRIGHT", 5, 4)
        edit:SetAlpha(0.72)
        edit:HookScript("OnEditFocusGained", function(self) self:SetAlpha(1) end)
        edit:HookScript("OnEditFocusLost", function(self) self:SetAlpha(0.72) end)
      end
    end
  end
end

local function skinWorld()
  if InCombatLockdown and InCombatLockdown() then return end
  skinUnit(TargetFrame)
  skinUnit(FocusFrame)
  for index = 1, 5 do skinUnit(_G["Boss" .. index .. "TargetFrame"]) end
  tint(MinimapBorder, gold)
  tint(MinimapCompassTexture, gold)
  local tracker = ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header
  if tracker then
    tint(tracker.Background, gold)
    if tracker.Text then tracker.Text:SetTextColor(muted[1], muted[2], muted[3]) end
  end
  skinChat()
  skinTooltip()
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
-- Empower casts are absent in some Forever builds; a missing event must not
-- prevent the rest of the addon from loading.
pcall(frame.RegisterEvent, frame, "UNIT_SPELLCAST_EMPOWER_START")
frame:SetScript("OnEvent", function(_, event, unit)
  if event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"
      or event == "UNIT_SPELLCAST_EMPOWER_START" then
    -- RothUI's focus-cast bell, without reading protected cast information.
    if S.options.focus and unit == "focus" and PlaySoundFile then PlaySoundFile(1129273) end
    return
  end
  if not initialized and GameTooltip then
    initialized = true
    GameTooltip:HookScript("OnShow", skinTooltip)
  end
  S.Run("Roth details", function() skinWorld(); S.SkinExtras(); S.Report("Roth details", "ready") end)
end)


local compactHooked, procHooked, chatHooked = false, false, false
local function compact(frame)
  if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
  if frame.healthBar then frame.healthBar:GetStatusBarTexture():SetBlendMode("ADD") end
  if frame.background then frame.background:SetAlpha(0.2) end
end
local function aura(a)
  if not a or a.SeraphglassAuraBorder or not a.Icon then return end
  local border = a:CreateTexture(nil, "OVERLAY")
  border:SetPoint("TOPLEFT", a.Icon, "TOPLEFT", -2, 2)
  border:SetPoint("BOTTOMRIGHT", a.Icon, "BOTTOMRIGHT", 2, -2)
  border:SetTexture("Interface\\Buttons\\UI-TempEnchant-Border")
  tint(border, gold)
  a.SeraphglassAuraBorder = border
end
function S.SkinExtras()
  if InCombatLockdown() then return end
  if not compactHooked and DefaultCompactUnitFrameSetup then
    compactHooked = true
    hooksecurefunc("DefaultCompactUnitFrameSetup", compact)
  end
  if CompactRaidFrameContainer and CompactRaidFrameContainer.ApplyToFrames then
    CompactRaidFrameContainer:ApplyToFrames("normal", compact)
  end
  if CompactPartyFrame and CompactPartyFrame.ApplyFunctionToAllFrames then
    CompactPartyFrame:ApplyFunctionToAllFrames("normal", compact)
  end
  if BuffFrame and BuffFrame.auraFrames then for _, a in ipairs(BuffFrame.auraFrames) do aura(a) end end
  for _, name in ipairs({ "ObjectiveTrackerFrame", "QuestObjectiveTracker", "CampaignQuestObjectiveTracker", "WorldQuestObjectiveTracker", "ScenarioObjectiveTracker" }) do
    local header = _G[name] and _G[name].Header
    if header then
      tint(header.Background, gold)
      if header.Text then header.Text:SetTextColor(unpack(muted)) end
    end
  end
  if StatusTrackingBarManager then
    for _, key in ipairs({ "MainStatusTrackingBarContainer", "SecondaryStatusTrackingBarContainer" }) do
      local bar = StatusTrackingBarManager[key]
      if bar then tint(bar.BarFrameTexture, gold) end
    end
  end
  if SpellActivationOverlayFrame and not procHooked and SpellActivationOverlayFrame.ShowOverlay then
    procHooked = true
    SpellActivationOverlayFrame:SetScale(0.6)
    hooksecurefunc(SpellActivationOverlayFrame, "ShowOverlay", function(self, spellID, _, position)
      local overlay = self:GetOverlay(spellID, position)
      if overlay and overlay.texture then overlay.texture:SetBlendMode("ADD") end
    end)
  end
  if not chatHooked and FCF_OpenTemporaryWindow then
    chatHooked = true
    hooksecurefunc("FCF_OpenTemporaryWindow", skinChat)
  end
end

-- Optional Roth modifier-key visibility for auxiliary controls. The four
-- main skill rows retain Blizzard's vehicle/override visibility handling.
local visibilityApplied = {}
function S.ApplyOptions()
  if S.UpdateWarnings then S.Run("Low health", S.UpdateWarnings) end
  if S.UpdateDispel then S.Run("Dispel", S.UpdateDispel) end
  if InCombatLockdown() then return end
  for name, condition in pairs({ BagsBar = "[mod:ctrl] show; hide", MicroMenu = "[mod:ctrl] show; hide", StatusTrackingBarManager = "[mod:alt] show; hide" }) do
    local f = _G[name]
    if f and RegisterStateDriver then
      if S.options.visibility then
        RegisterStateDriver(f, "visibility", condition)
        visibilityApplied[name] = true
      elseif visibilityApplied[name] then
        UnregisterStateDriver(f, "visibility")
        f:Show()
        visibilityApplied[name] = nil
      end
    end
  end
end
local optionsFrame = CreateFrame("Frame")
optionsFrame:RegisterEvent("PLAYER_LOGIN")
optionsFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
optionsFrame:SetScript("OnEvent", function() S.Run("Roth details", S.ApplyOptions) end)

-- Keep Blizzard's tooltip text (including guild, level and AFK) and color
-- the native name line by class or reaction without comparing secret values.
local function unitTooltip(tooltip)
  if not tooltip or not tooltip.GetUnit or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
  local _, unit = tooltip:GetUnit()
  if (issecretvalue and issecretvalue(unit)) or not unit then return end
  local line = tooltip:GetName() and _G[tooltip:GetName() .. "TextLeft1"]
  if not line then return end
  local _, class = UnitClass(unit)
  if issecretvalue and issecretvalue(class) then return end
  local color = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if not color then
    local reaction = UnitReaction(unit, "player")
    if issecretvalue and issecretvalue(reaction) then return end
    color = reaction and FACTION_BAR_COLORS and FACTION_BAR_COLORS[reaction]
  end
  if color then line:SetTextColor(color.r, color.g, color.b) end
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, unitTooltip)
end
