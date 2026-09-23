-- Roth player warnings and vignette notifications, using native color curves.
local ADDON, S = ...
local frame = CreateFrame("Frame")
local low, curve
local seen = {}
local blacklist = {}
for _, name in ipairs({ "Garrison Cache", "Full Garrison Cache", "Expedition Scout's Pack", "Valeera Sanguinar", "Decor Specialist", "Altar of Blessings", "Rostrum of Transformation", "Witherbark Prisoner", "Glowing Moth", "Leaf-wrapped Package" }) do blacklist[name] = true end
local function secret(value) return issecretvalue and issecretvalue(value) end
local function setupLowHealth()
  if low or not S.healthOrb then return end
  low = S.healthOrb:CreateTexture(nil, "OVERLAY", nil, 7)
  low:SetSize(210, 210)
  low:SetPoint("CENTER")
  low:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\media\\orb_gloss")
  low:SetBlendMode("ADD")
  low:SetVertexColor(1, 0.08, 0.02, 0)
  if C_CurveUtil and C_CurveUtil.CreateColorCurve and UnitHealthPercent then
    curve = C_CurveUtil.CreateColorCurve()
    curve:SetType(Enum.LuaCurveType.Step)
    curve:AddPoint(0, CreateColor(1, 0.06, 0.01, 0.85))
    curve:AddPoint(0.31, CreateColor(1, 0.06, 0.01, 0))
  end
  S.Report("Low health", curve and "ready: native color curve below 31%" or "readable health fallback")
end
local function updateLow()
  setupLowHealth()
  if not low then return end
  low:SetShown(S.options.lowhealth)
  if not S.options.lowhealth then return end
  if curve then
    local color = UnitHealthPercent("player", true, curve)
    low:SetVertexColor(color:GetRGBA()) -- Never branch on a combat health value.
  else
    local current, maximum = UnitHealth("player"), UnitHealthMax("player")
    if not secret(current) and not secret(maximum) and maximum > 0 then
      low:SetVertexColor(1, 0.06, 0.01, current / maximum < 0.31 and 0.85 or 0)
    else low:SetVertexColor(1, 0.06, 0.01, 0) end
  end
end
local function vignette(id)
  if not S.options.vignette or secret(id) or not id or seen[id] then return end
  if not C_VignetteInfo or not C_VignetteInfo.GetVignetteInfo then return end
  local info = C_VignetteInfo.GetVignetteInfo(id)
  if secret(info) or not info or secret(info.onMinimap) or secret(info.name) then return end
  if not info.onMinimap or not info.name or blacklist[info.name] then return end
  seen[id] = true
  local message = info.name .. " spotted!"
  print("|cffe7bd79Seraphglass: " .. message .. "|r")
  if RaidNotice_AddMessage and RaidWarningFrame then
    RaidNotice_AddMessage(RaidWarningFrame, message, { r = 0.91, g = 0.74, b = 0.47 })
  end
  if PlaySoundFile then PlaySoundFile(2530811) end
end
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "UNIT_HEALTH", "UNIT_MAXHEALTH" }) do frame:RegisterEvent(event) end
local hasVignette = C_VignetteInfo and C_VignetteInfo.GetVignetteInfo and pcall(frame.RegisterEvent, frame, "VIGNETTE_MINIMAP_UPDATED")
S.Report("Vignettes", hasVignette and "ready" or "unavailable in this client")
frame:SetScript("OnEvent", function(_, event, unit)
  if event == "VIGNETTE_MINIMAP_UPDATED" then S.Run("Vignettes", vignette, unit)
  elseif event == "PLAYER_ENTERING_WORLD" then seen = {}; S.Run("Low health", updateLow)
  elseif event == "PLAYER_LOGIN" or unit == "player" then S.Run("Low health", updateLow) end
end)
S.UpdateWarnings = updateLow

-- Native aura containers evaluate dispellability inside Blizzard's secure
-- aura system. Addon Lua never enumerates or branches on secret debuffs.
local dispel, dispelFailed
local function setupDispel()
  if dispel or dispelFailed or not S.healthOrb or InCombatLockdown() then return end
  if not C_AuraContainerUtil or not Enum.CustomAuraButtonDispelTypeTextureStyle then
    S.Report("Dispel", "native aura container unavailable")
    return
  end
  local ok = S.Run("Dispel", function()
    local container = CreateFrame("AuraContainer", "SeraphglassDispelWarning", S.healthOrb, "CustomAuraContainerTemplate")
    container:SetSize(210, 210)
    container:SetPoint("CENTER", S.healthOrb, "CENTER")
    container:SetFrameLevel(S.healthOrb:GetFrameLevel() + 8)
    container:EnableMouse(false)
    container:SetEditModePreviewEnabled(false)
    container:AddAuraGroup("dispel", "HARMFUL|DISPELLABLE", {
      maxFrameCount = 1,
      layout = { elementWidth = 210, elementHeight = 210 },
      initializeFrame = function(button)
        button:SetSize(210, 210)
        button:EnableMouse(false)
        local glow = button:CreateTexture(nil, "OVERLAY")
        glow:SetAllPoints(button)
        glow:SetTexture("Interface\\AddOns\\" .. ADDON .. "\\media\\orb_gloss")
        glow:SetBlendMode("ADD")
        button:AddDispelTypeTexture(glow, {
          style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
          showWhenHarmful = true, showWhenHelpful = false,
        })
      end,
    })
    container:SetUnit("player")
    dispel = container
    S.Report("Dispel", "ready: native dispellable-debuff glow")
  end)
  dispelFailed = not ok
end
S.UpdateDispel = function()
  setupDispel()
  if dispel then dispel:SetAuraGroupEnabled("dispel", S.options.dispel) end
end
local dispelLoader = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_LOGIN", "ADDON_LOADED", "PLAYER_REGEN_ENABLED" }) do dispelLoader:RegisterEvent(event) end
dispelLoader:SetScript("OnEvent", function() S.Run("Dispel", S.UpdateDispel) end)
