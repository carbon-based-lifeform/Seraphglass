-- Four native Blizzard action bars, five buttons each. Layout changes are
-- made out of combat; Blizzard still owns clicks, paging, spells and keybinds.
local ADDON = ...
local artworkPath = "Interface\\AddOns\\" .. ADDON .. "\\media\\seraph_action_center.png"
local hud = _G.SeraphglassHUD
local columns = {
  { frame = "MainActionBar",       prefix = "ActionButton",                    x = -166, y =  29 },
  { frame = "MultiBarBottomLeft",  prefix = "MultiBarBottomLeftButton",       x = -166, y = -27, setting = "PROXY_SHOW_ACTIONBAR_2" },
  { frame = "MultiBarBottomRight", prefix = "MultiBarBottomRightButton",      x =  166, y =  29, setting = "PROXY_SHOW_ACTIONBAR_3" },
  { frame = "MultiBarRight",       prefix = "MultiBarRightButton",            x =  166, y = -27, setting = "PROXY_SHOW_ACTIONBAR_4" },
}
local others = {
  "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
  "MultiBar7Button", "PetActionButton", "StanceButton",
}
local gold = { 0.62, 0.44, 0.25, 0.89 }

local artFrame = CreateFrame("Frame", "SeraphglassAngelActionArt", hud or UIParent)
artFrame:SetSize(548, 183)
artFrame:SetPoint("CENTER", hud or UIParent, "CENTER", 0, -17)
artFrame:SetFrameStrata("BACKGROUND")
artFrame:EnableMouse(false)
local painting = artFrame:CreateTexture(nil, "ARTWORK")
painting:SetAllPoints(artFrame)
painting:SetTexture(artworkPath)

local function edge(button, first, second, horizontal)
  local texture = button:CreateTexture(nil, "OVERLAY", nil, 3)
  texture:SetColorTexture(unpack(gold))
  texture:SetPoint(first, button, first)
  texture:SetPoint(second, button, second)
  if horizontal then texture:SetHeight(1) else texture:SetWidth(1) end
end

local function styleButton(button)
  if not button or button.SeraphglassWrapped then return end
  if issecretvalue and issecretvalue(button) then return end
  if button.IsForbidden and button:IsForbidden() then return end
  local normal = button.NormalTexture or (button.GetNormalTexture and button:GetNormalTexture())
  if normal and normal.SetVertexColor then
    normal:SetDesaturated(true)
    normal:SetVertexColor(0.27, 0.21, 0.18)
  end
  local shade = button:CreateTexture(nil, "BACKGROUND", nil, -1)
  shade:SetAllPoints(button)
  shade:SetColorTexture(0.05, 0.025, 0.03, 0.83)
  edge(button, "TOPLEFT", "TOPRIGHT", true)
  edge(button, "BOTTOMLEFT", "BOTTOMRIGHT", true)
  edge(button, "TOPLEFT", "BOTTOMLEFT", false)
  edge(button, "TOPRIGHT", "BOTTOMRIGHT", false)
  button.SeraphglassWrapped = true
end

local function safe(frame)
  return frame and not (issecretvalue and issecretvalue(frame))
      and not (frame.IsForbidden and frame:IsForbidden())
end

local function enableBar(entry)
  if not entry.setting or not Settings or not Settings.GetValue or not Settings.SetValue then return end
  local value = Settings.GetValue(entry.setting)
  if value == false or value == 0 then Settings.SetValue(entry.setting, true) end
end

local function layoutBar(entry)
  local bar = _G[entry.frame]
  if not safe(bar) or not hud then return end
  -- Forever uses Blizzard's native bar mixin. Keep the bar's original buttons
  -- rather than cloning protected spell buttons or modifying their attributes.
  if not bar.UpdateShownButtons or not bar.UpdateGridLayout
      or not bar.actionButtons or not bar.shownButtonContainers then return end
  enableBar(entry)
  bar.numButtonsShowable = 5
  bar.numRows = 1
  bar.isHorizontal = true
  bar.addButtonsToRight = true
  bar.addButtonsToLeft = false
  bar.addButtonsToTop = false
  bar.buttonPadding = math.max(bar.minButtonPadding or 2, 3)
  if entry.frame == "MainActionBar" then
    bar.hideBarArt = true
    if bar.UpdateEndCaps then bar:UpdateEndCaps(true) end
    if bar.BorderArt then bar.BorderArt:Hide() end
    if bar.ActionBarPageNumber then bar.ActionBarPageNumber:Hide() end
  end
  bar:UpdateShownButtons()
  bar:UpdateGridLayout()
  -- Use the orb HUD as the reference so moving the HUD moves the whole set.
  bar:ClearAllPoints()
  bar:SetPoint("CENTER", hud, "CENTER", entry.x, entry.y)
  bar:SetScale(0.85)
  for index = 1, 5 do styleButton(_G[entry.prefix .. index]) end
end

local function updateArtVisibility()
  local main = _G.MainActionBar
  artFrame:SetShown(not main or main:IsShown())
end

local applying = false
local function apply()
  if applying or (InCombatLockdown and InCombatLockdown()) then return end
  applying = true
  for _, entry in ipairs(columns) do layoutBar(entry) end
  for _, prefix in ipairs(others) do
    local count = prefix == "StanceButton" and 10 or 12
    for index = 1, count do styleButton(_G[prefix .. index]) end
  end
  updateArtVisibility()
  applying = false
end

local hooked = false
local function hookEditMode()
  if hooked then return end
  if EditModeManagerFrame and EditModeManagerFrame.HookScript then
    hooked = true
    EditModeManagerFrame:HookScript("OnHide", apply)
  end
end
local mainHooked = false
local function hookMainBar()
  if mainHooked then return end
  local main = _G.MainActionBar
  if safe(main) and main.HookScript then
    mainHooked = true
    main:HookScript("OnShow", updateArtVisibility)
    main:HookScript("OnHide", updateArtVisibility)
  end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:SetScript("OnEvent", function()
  hookEditMode()
  hookMainBar()
  -- Blizzard may still apply a saved Edit Mode layout during world entry.
  if C_Timer and C_Timer.After then C_Timer.After(0, apply) else apply() end
end)
hookEditMode()
hookMainBar()
apply()
