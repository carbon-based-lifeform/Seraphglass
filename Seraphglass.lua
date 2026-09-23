-- Seraphglass: a small, independent orb HUD built on RothUI's fill textures.
-- Keep health and power as opaque values. Forever's combat values may be secret:
-- status bars can receive them, but Lua must not compare or calculate with them.
local ADDON, S = ...
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\media\\"

local hud = CreateFrame("Frame", "SeraphglassHUD", UIParent)
hud:SetSize(1050, 256)
hud:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 15)
hud:SetFrameStrata("BACKGROUND")

-- The offsets and 256px orb size follow oUF_Diablo/style/player.lua.
local left = CreateFrame("Frame", nil, hud)
left:SetSize(256, 256)
left:SetPoint("CENTER", hud, "CENTER", -400, 0)
local right = CreateFrame("Frame", nil, hud)
right:SetSize(256, 256)
right:SetPoint("CENTER", hud, "CENTER", 400, 0)

local artwork = {}
S.animations, S.orbLayers = {}, {}
local function ornament(frame, file, xOffset)
  -- Draw the metal behind the globe. The fill covers the inside edge of the
  -- sculpture, leaving a close-fitting rim without shrinking the liquid.
  local texture = frame:CreateTexture(nil, "BACKGROUND", nil, 7)
  texture:SetSize(230, 230)
  texture:SetPoint("CENTER", frame, "CENTER", xOffset, 0)
  texture:SetTexture(MEDIA .. file)
  artwork[#artwork + 1] = texture
end

local function liquidMotion(texture, degrees, duration)
  local group = texture:CreateAnimationGroup()
  local rotation = group:CreateAnimation("Rotation")
  rotation:SetDegrees(degrees)
  rotation:SetDuration(duration)
  group:SetLooping("REPEAT")
  group:Play()
  S.animations[#S.animations+1] = group
end

local function orb(frame, color, artFile, artOffset)
  local background = frame:CreateTexture(nil, "BACKGROUND")
  background:SetSize(190, 190)
  background:SetPoint("CENTER")
  background:SetTexture(MEDIA .. "orb_background")

  ornament(frame, artFile, artOffset)

  local bar = CreateFrame("StatusBar", nil, frame)
  bar:SetSize(190, 190)
  bar:SetPoint("CENTER")
  bar:SetFrameLevel(frame:GetFrameLevel() + 3)
  bar:SetOrientation("VERTICAL")
  bar:SetStatusBarTexture(MEDIA .. "orb_filling15")
  bar:SetStatusBarColor(color[1], color[2], color[3])

  -- The moving highlights are clipped to the status bar texture, so they
  -- follow the client's fill level without inspecting secret combat values.
  local clip = CreateFrame("Frame", nil, frame)
  clip:SetClipsChildren(true)
  clip:SetFrameLevel(bar:GetFrameLevel() + 1)
  clip:SetPoint("TOPLEFT", bar:GetStatusBarTexture(), "TOPLEFT")
  clip:SetPoint("BOTTOMRIGHT", bar:GetStatusBarTexture(), "BOTTOMRIGHT")
  local swirls = {}
  local mask = clip:CreateMaskTexture(nil, "ARTWORK")
  mask:SetSize(190, 190)
  mask:SetPoint("CENTER", frame, "CENTER")
  mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
  for index = 1, 3 do
    local current = index
    local swirl = clip:CreateTexture(nil, "ARTWORK")
    swirl:SetSize(190, 190)
    swirl:SetPoint("CENTER", frame, "CENTER")
    swirl:SetTexture(MEDIA .. "liquid_swirl.png")
    swirl:SetBlendMode("ADD")
    swirl:AddMaskTexture(mask)
    swirl:SetVertexColor(color[1], color[2], color[3])
    swirl:SetAlpha(current == 1 and 0.24 or current == 2 and 0.14 or 0.06)
    swirls[#swirls+1] = swirl
    liquidMotion(swirl, current == 2 and -360 or 360, ({17, 29, 43})[current])
  end

  local front = CreateFrame("Frame", nil, frame)
  front:SetAllPoints(frame)
  front:SetFrameLevel(clip:GetFrameLevel() + 1)
  front:EnableMouse(false)

  local gloss = front:CreateTexture(nil, "ARTWORK")
  gloss:SetSize(190, 190)
  gloss:SetPoint("CENTER")
  gloss:SetTexture(MEDIA .. "orb_gloss")

  local sheen = front:CreateTexture(nil, "OVERLAY", nil, 2)
  sheen:SetSize(190, 190)
  sheen:SetPoint("CENTER")
  sheen:SetTexture(MEDIA .. "orb_gloss")
  sheen:SetBlendMode("ADD")
  sheen:SetAlpha(0.16)
  local pulse = sheen:CreateAnimationGroup()
  local fade = pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(0.08)
  fade:SetToAlpha(0.23)
  fade:SetDuration(3.2)
  pulse:SetLooping("BOUNCE")
  pulse:Play()
  S.animations[#S.animations+1] = pulse
  S.orbLayers[#S.orbLayers+1] = {frame=frame, bar=bar, clip=clip, front=front, mask=mask, swirls=swirls}

  return bar
end

local health = orb(left, { 0.75, 0.05, 0.03 }, "eternal_frame_left.png", -13)
S.healthOrb = left
local power = orb(right, { 0.05, 0.2, 0.85 }, "eternal_frame_right.png", 13)

-- The loss bars share the liquid geometry. They sit behind the opaque
-- instantaneous health fill, so only the recently damaged portion is seen.
local function lossBar(level, red, green, blue)
  local bar = CreateFrame("StatusBar", nil, left)
  bar:SetSize(190, 190)
  bar:SetPoint("CENTER")
  bar:SetFrameLevel(health:GetFrameLevel() - level)
  bar:SetOrientation("VERTICAL")
  bar:SetStatusBarTexture(MEDIA .. "orb_filling15")
  bar:SetStatusBarColor(red, green, blue)
  return bar
end

local trailingHealth = lossBar(2, 0.36, 0.015, 0.025)
local flashHealth = lossBar(1, 1, 1, 1)
flashHealth:Hide()

-- Status bars can consume opaque combat values. Their fill textures provide
-- moving anchors for two more fills; clipping performs the cap at 100%.
local predictionClip = CreateFrame("Frame", nil, left)
predictionClip:SetSize(190, 190)
predictionClip:SetPoint("CENTER")
predictionClip:SetFrameLevel(health:GetFrameLevel() + 1)
predictionClip:SetClipsChildren(true)
predictionClip:EnableMouse(false)

-- A square clipping frame caps the fill vertically. A circular texture mask
-- also trims its sides to the glass, including when a shield overcaps health.
local function maskToOrb(texture)
  local mask = texture:GetParent():CreateMaskTexture(nil, "ARTWORK")
  mask:SetAllPoints(predictionClip)
  mask:SetTexture(MEDIA .. "orb_filling15")
  texture:AddMaskTexture(mask)
end

local incomingHeal = CreateFrame("StatusBar", nil, predictionClip)
incomingHeal:SetSize(190, 190)
incomingHeal:SetOrientation("VERTICAL")
incomingHeal:SetStatusBarTexture(MEDIA .. "orb_filling15")
incomingHeal:SetStatusBarColor(0.32, 0.86, 0.56)
incomingHeal:SetPoint("BOTTOM", health:GetStatusBarTexture(), "TOP")
maskToOrb(incomingHeal:GetStatusBarTexture())

local function isReadableNumber(value)
  if issecretvalue and issecretvalue(value) then return false end
  return type(value) == "number"
end

local function valueOrZero(value)
  if issecretvalue and issecretvalue(value) then return value end
  return value or 0
end

local previousHealth
local hasPreviousHealth = false
local flashElapsed, trailElapsed, trailStart, trailTarget
local flashDuration, trailDelay, trailDuration = 0.16, 0.16, 0.90
local pendingSecretHealth, hasPendingSecretTrail, secretTrailElapsed = nil, false, 0
local secretTrailDelay = 0.38
local lossAnimation = CreateFrame("Frame", nil, left)

local function animateLoss(self, elapsed)
  local active = false
  if flashElapsed then
    flashElapsed = flashElapsed + elapsed
    if flashElapsed >= flashDuration then
      flashElapsed = nil
      flashHealth:Hide()
    else
      flashHealth:SetAlpha(1 - flashElapsed / flashDuration)
      active = true
    end
  end
  if trailTarget then
    trailElapsed = trailElapsed + elapsed
    local progress = (trailElapsed - trailDelay) / trailDuration
    if progress >= 1 then
      trailingHealth:SetValue(trailTarget)
      trailTarget = nil
    else
      if progress > 0 then
        trailingHealth:SetValue(trailStart + (trailTarget - trailStart) * progress)
      end
      active = true
    end
  end
  if hasPendingSecretTrail then
    secretTrailElapsed = secretTrailElapsed + elapsed
    if secretTrailElapsed >= secretTrailDelay then
      if Enum and Enum.StatusBarInterpolation then
        trailingHealth:SetValue(pendingSecretHealth, Enum.StatusBarInterpolation.ExponentialEaseOut)
      else
        trailingHealth:SetValue(pendingSecretHealth)
      end
      pendingSecretHealth = nil
      hasPendingSecretTrail = false
    else
      active = true
    end
  end
  if not active then self:SetScript("OnUpdate", nil) end
end

local function startFlash(value)
  flashHealth:SetValue(value)
  flashHealth:SetAlpha(0.88)
  flashHealth:Show()
  flashElapsed = 0
  lossAnimation:SetScript("OnUpdate", animateLoss)
end

local function updatePrediction()
  if UnitGetIncomingHeals then
    incomingHeal:SetMinMaxValues(0, UnitHealthMax("player"))
    incomingHeal:SetValue(valueOrZero(UnitGetIncomingHeals("player")))
  end
  if S.UpdateShield then S.UpdateShield() end
end

-- Keep the usual player unit interactions if the Blizzard frame is hidden.
-- Secure attributes are set during addon load, before combat can begin.
local function playerButton(parent, name)
  local button = CreateFrame("Button", name, parent, "SecureUnitButtonTemplate")
  button:SetAllPoints(parent)
  button:RegisterForClicks("AnyUp")
  button:SetAttribute("unit", "player")
  button:SetAttribute("*type1", "target")
  button:SetAttribute("*type2", "togglemenu")
  button:SetScript("OnEnter", function(self)
    if GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
      GameTooltip:SetUnit("player")
      GameTooltip:Show()
    end
  end)
  button:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  return button
end
playerButton(left, "SeraphglassHealthButton")
playerButton(right, "SeraphglassPowerButton")

-- Moving is deliberately session only while the Forever beta has unreliable
-- SavedVariables loading. The handle is present only when explicitly unlocked.
hud:SetMovable(true)
hud:SetClampedToScreen(true)
local mover = CreateFrame("Button", nil, hud)
mover:SetFrameStrata("DIALOG")
mover:SetSize(160, 28)
mover:SetPoint("CENTER", hud, "CENTER", 0, 40)
mover:EnableMouse(true)
mover:RegisterForDrag("LeftButton")
local moverBackground = mover:CreateTexture(nil, "BACKGROUND")
moverBackground:SetAllPoints(mover)
moverBackground:SetColorTexture(0.15, 0.08, 0.02, 0.85)
local moverLabel = mover:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
moverLabel:SetPoint("CENTER")
moverLabel:SetText("Drag Seraphglass here")
mover:SetScript("OnDragStart", function()
  if InCombatLockdown and InCombatLockdown() then return end
  hud:StartMoving()
end)
mover:SetScript("OnDragStop", function() hud:StopMovingOrSizing() end)
mover:Hide()

local hideBlizzardPlayer = false
local pendingBlizzardPlayer = false
local playerFrameHooked = false
local playerFrameDriver = false
local function updateBlizzardPlayer()
  if not PlayerFrame then return end
  if InCombatLockdown and InCombatLockdown() then
    pendingBlizzardPlayer = true
    return
  end
  pendingBlizzardPlayer = false
  if hideBlizzardPlayer then
    -- The secure visibility driver survives combat and Blizzard's own Show
    -- calls. A Show hook alone cannot hide a protected unit frame in combat.
    if RegisterStateDriver and not playerFrameDriver then
      RegisterStateDriver(PlayerFrame, "visibility", "hide")
      playerFrameDriver = true
    elseif not playerFrameHooked and hooksecurefunc then
      playerFrameHooked = true
      hooksecurefunc(PlayerFrame, "Show", function(frame)
        if hideBlizzardPlayer then
          if InCombatLockdown and InCombatLockdown() then
            pendingBlizzardPlayer = true
          else
            frame:Hide()
          end
        end
      end)
    end
    PlayerFrame:Hide()
  else
    if playerFrameDriver and UnregisterStateDriver then
      UnregisterStateDriver(PlayerFrame, "visibility")
      playerFrameDriver = false
    end
    PlayerFrame:Show()
  end
end

local powerColors = {
  MANA = { 0.05, 0.2, 0.85 }, RAGE = { 0.75, 0.04, 0.02 },
  ENERGY = { 1, 0.8, 0.06 }, FOCUS = { 0.8, 0.45, 0.12 },
  RUNIC_POWER = { 0.12, 0.8, 0.95 }, LUNAR_POWER = { 0.24, 0.6, 0.95 },
  INSANITY = { 0.45, 0.1, 0.7 }, MAELSTROM = { 0.12, 0.4, 0.65 },
}

local function updateHealth(resetAnimation)
  if not UnitHealth or not UnitHealthMax then return end
  local maximum = UnitHealthMax("player")
  local current = UnitHealth("player")
  health:SetMinMaxValues(0, maximum)
  trailingHealth:SetMinMaxValues(0, maximum)
  flashHealth:SetMinMaxValues(0, maximum)

  -- Main fill drops immediately. When combat health is secret, the native
  -- status-bar interpolator can chase that opaque value without Lua math.
  if resetAnimation or not hasPreviousHealth then
    trailingHealth:SetValue(current)
    flashHealth:Hide()
    flashElapsed, trailElapsed, trailStart, trailTarget = nil, nil, nil, nil
    pendingSecretHealth, hasPendingSecretTrail = nil, false
    lossAnimation:SetScript("OnUpdate", nil)
  elseif isReadableNumber(current) and isReadableNumber(previousHealth) then
    pendingSecretHealth, hasPendingSecretTrail = nil, false
    if current < previousHealth then
      trailStart = trailTarget and trailingHealth:GetValue() or previousHealth
      trailTarget = current
      trailElapsed = 0
      trailingHealth:SetValue(trailStart)
      startFlash(previousHealth)
    else
      trailingHealth:SetValue(current)
      trailTarget = nil
      flashElapsed = nil
      flashHealth:Hide()
      lossAnimation:SetScript("OnUpdate", nil)
    end
  else
    trailTarget = nil
    pendingSecretHealth = current
    hasPendingSecretTrail = true
    secretTrailElapsed = 0
    startFlash(previousHealth)
  end
  health:SetValue(current)
  if S.UpdateLowHealth then S.UpdateLowHealth() end
  previousHealth = current
  hasPreviousHealth = true
  updatePrediction()
end

local function updatePower()
  if not UnitPowerType or not UnitPower or not UnitPowerMax then return end
  local powerID, token = UnitPowerType("player")
  local color = powerColors.MANA
  if not S.Secret(token) then color = powerColors[token] or color end
  if S.colorMode == "custom" then color = S.customColor
  elseif S.colorMode == "class" then
    local _, class = UnitClass("player")
    local c = not S.Secret(class) and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then color = {c.r, c.g, c.b} end
  end
  for _, swirl in ipairs(S.orbLayers[2].swirls) do swirl:SetVertexColor(color[1],color[2],color[3]) end
  power:SetStatusBarColor(color[1], color[2], color[3])
  power:SetMinMaxValues(0, UnitPowerMax("player", powerID))
  power:SetValue(UnitPower("player", powerID), Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.ExponentialEaseOut)
end

local events = CreateFrame("Frame")
for _, event in ipairs({
  "PLAYER_ENTERING_WORLD", "UNIT_HEALTH", "UNIT_MAXHEALTH",
  "UNIT_HEAL_PREDICTION", "UNIT_ABSORB_AMOUNT_CHANGED",
  "UNIT_HEAL_ABSORB_AMOUNT_CHANGED",
  "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER",
  "PLAYER_REGEN_ENABLED", "PLAYER_LOGIN", "ADDON_LOADED",
}) do
  events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, unit)
  if event:sub(1, 5) == "UNIT_" and unit ~= "player" then return end
  if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
    updateHealth(true)
    updatePower()
    if hideBlizzardPlayer then updateBlizzardPlayer() end
  elseif event == "ADDON_LOADED" then
    if hideBlizzardPlayer and PlayerFrame then updateBlizzardPlayer() end
  elseif event == "PLAYER_REGEN_ENABLED" then
    if pendingBlizzardPlayer then updateBlizzardPlayer() end
    updatePrediction()
  elseif event == "UNIT_HEALTH" then
    updateHealth(false)
  elseif event == "UNIT_MAXHEALTH" then
    updateHealth(true)
  elseif event == "UNIT_HEAL_PREDICTION"
      or event == "UNIT_ABSORB_AMOUNT_CHANGED"
      or event == "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
    updatePrediction()
  else
    updatePower()
  end
end)

SLASH_SERAPHGLASS1 = "/sgui"
SLASH_SERAPHGLASS2 = "/seraphglass"
SlashCmdList.SERAPHGLASS = function(message)
  local command, argument = (message or ""):match("^(%S*)%s*(.-)%s*$")
  if (command == "show" or command == "hide" or command == "scale" or command == "unlock") and InCombatLockdown() then
    print("Seraphglass: change the orb layout outside combat"); return
  end
  if S.commands[command] then
    S.commands[command](argument)
  elseif command == "show" then
    hud:Show()
  elseif command == "hide" then
    hud:Hide()
  elseif command == "art" then
    S.options.figures = not S.options.figures
    S.Apply()
  elseif command == "scale" then
    local scale = tonumber(argument)
    if scale and scale >= 0.5 and scale <= 1.5 then
      if InCombatLockdown and InCombatLockdown() then
        print("Seraphglass: move or scale the HUD outside combat")
      else
        hud:SetScale(scale)
      end
    else
      print("Seraphglass: scale must be from 0.5 to 1.5")
    end
  elseif command == "unlock" then
    mover:Show()
  elseif command == "lock" then
    mover:Hide()
  elseif command == "playerframe" then
    if argument == "hide" or argument == "show" then
      hideBlizzardPlayer = argument == "hide"
      updateBlizzardPlayer()
      if pendingBlizzardPlayer then
        print("Seraphglass: player frame change queued until combat ends")
      end
    else
      print("Seraphglass: /sgui playerframe hide | show")
    end
  else
    print("Seraphglass Orbs: /sgui status | option | color | show | hide | art | scale 0.5-1.5 | unlock | lock | playerframe hide/show")
  end
end

S.Report("Orbs", "ready")

S.hud, S.left, S.right = hud, left, right
S.ApplyHUD = function()
  for _, texture in ipairs(artwork) do texture:SetShown(S.options.figures) end
  updatePower()
end
