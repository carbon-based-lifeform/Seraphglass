-- Tint the native Damage Meter and retain its buttons, rows and resize logic.
local hooked = false

local function isSafe(frame)
  if not frame then return false end
  if issecretvalue and issecretvalue(frame) then return false end
  return not (frame.IsForbidden and frame:IsForbidden())
end

local function styleEntry(frame)
  if not isSafe(frame) or frame.SeraphglassMeterLine then return end
  local line = frame:CreateTexture(nil, "OVERLAY", nil, 3)
  line:SetColorTexture(0.61, 0.40, 0.22, 0.48)
  line:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
  line:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
  line:SetHeight(1)
  frame.SeraphglassMeterLine = line
end

local function styleVisibleEntries(window)
  local scroll = window.GetScrollBox and window:GetScrollBox()
  if scroll and scroll.ForEachFrame then scroll:ForEachFrame(styleEntry) end
  if window.GetLocalPlayerEntry then styleEntry(window:GetLocalPlayerEntry()) end
end

local function meterLine(window, first, second, rgba)
  local line = window:CreateTexture(nil, "OVERLAY", nil, 1)
  line:SetColorTexture(unpack(rgba))
  line:SetPoint(first, window, first)
  line:SetPoint(second, window, second)
  line:SetHeight(1)
end

local function styleWindow(window)
  if not isSafe(window) or (InCombatLockdown and InCombatLockdown()) then return end
  if window.SeraphglassMeterArt then
    styleVisibleEntries(window)
    return
  end

  -- Tint native textures; do not replace the meter's art or cover its controls.
  if window.Header and window.Header.SetVertexColor then
    window.Header:SetVertexColor(0.31, 0.105, 0.13)
  end
  if window.GetBackground then
    local background = window:GetBackground()
    if background and background.SetVertexColor then
      background:SetVertexColor(0.18, 0.14, 0.15)
    end
  end
  meterLine(window, "TOPLEFT", "TOPRIGHT", { 0.65, 0.46, 0.26, 0.9 })
  meterLine(window, "BOTTOMLEFT", "BOTTOMRIGHT", { 0.38, 0.10, 0.11, 0.8 })
  local cream = { 0.96, 0.82, 0.65 }
  if window.DamageMeterTypeDropdown and window.DamageMeterTypeDropdown.TypeName then
    window.DamageMeterTypeDropdown.TypeName:SetTextColor(unpack(cream))
  end
  if window.SessionDropdown and window.SessionDropdown.SessionName then
    window.SessionDropdown.SessionName:SetTextColor(unpack(cream))
  end
  window.SeraphglassMeterArt = true
  styleVisibleEntries(window)
end

local function apply()
  if InCombatLockdown and InCombatLockdown() then return end
  for index = 1, 3 do styleWindow(_G["DamageMeterSessionWindow" .. index]) end
  if not hooked and hooksecurefunc and DamageMeterSessionWindowMixin then
    hooked = true
    hooksecurefunc(DamageMeterSessionWindowMixin, "OnShow", styleWindow)
    hooksecurefunc(DamageMeterSessionWindowMixin, "SetupEntry", function(_, frame)
      styleEntry(frame)
    end)
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", apply)
apply()
