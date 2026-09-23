-- Compatible presentation details adapted from RothUI wow12.0/rLayout.
-- Never change Blizzard's action-bar state drivers: Seraphglass owns its
-- four five-button bars, and the player's own bindings must remain usable.
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
      local background = chat:CreateTexture(nil, "BACKGROUND")
      background:SetAllPoints(chat)
      background:SetColorTexture(0.055, 0.038, 0.035, 0.38)
      local edit = _G["ChatFrame" .. index .. "EditBox"]
      if edit then
        if edit.SetAltArrowKeyMode then edit:SetAltArrowKeyMode(false) end
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
    if unit == "focus" and PlaySoundFile then PlaySoundFile(1129273) end
    return
  end
  if not initialized and GameTooltip then
    initialized = true
    GameTooltip:HookScript("OnShow", skinTooltip)
  end
  skinWorld()
end)
