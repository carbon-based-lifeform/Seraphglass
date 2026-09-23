-- Effects never use health values in Lua arithmetic while they are secret.
local _, S = ...
local media = S.media
local lowFrame = CreateFrame("Frame", nil, S.left)
lowFrame:SetAllPoints(S.left)
lowFrame:SetFrameLevel(S.left:GetFrameLevel()+9)
lowFrame:EnableMouse(false)
local low = lowFrame:CreateTexture(nil, "OVERLAY")
low:SetSize(228,228)
low:SetPoint("CENTER")
low:SetTexture(media .. "orb_glow2")
low:SetBlendMode("ADD")
low:SetVertexColor(1,0.025,0.005,0)
local pulse = lowFrame:CreateAnimationGroup()
local beat = pulse:CreateAnimation("Alpha")
beat:SetFromAlpha(0.3); beat:SetToAlpha(1); beat:SetDuration(0.48)
pulse:SetLooping("BOUNCE")
S.animations[#S.animations+1] = pulse
local curve
if C_CurveUtil and C_CurveUtil.CreateColorCurve and UnitHealthPercent then
  curve = C_CurveUtil.CreateColorCurve()
  curve:SetType(Enum.LuaCurveType.Step)
  curve:AddPoint(0, CreateColor(1,0.025,0.005,0.95))
  curve:AddPoint(0.20, CreateColor(1,0.025,0.005,0))
end
function S.UpdateLowHealth()
  lowFrame:SetShown(S.options.lowhealth)
  if curve then
    local c = UnitHealthPercent("player", true, curve)
    low:SetVertexColor(c:GetRGBA())
  else
    local h,m = UnitHealth("player"),UnitHealthMax("player")
    low:SetVertexColor(1,0.025,0.005, S.Readable(h) and S.Readable(m) and m>0 and h/m<0.2 and 0.95 or 0)
  end
end

-- A vertical native status bar controls the clipping height, while a fixed
-- ring mask shapes Blizzard's shield atlas into the inner-facing semicircle.
-- The crescent saturates at max HP; it never overlaps the health liquid.
local shield = CreateFrame("StatusBar", nil, S.left)
shield:SetSize(230,230); shield:SetPoint("CENTER")
shield:SetFrameLevel(S.left:GetFrameLevel()+7)
shield:SetOrientation("VERTICAL")
shield:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
shield:SetStatusBarColor(1,1,1,0)
local shieldClip = CreateFrame("Frame", nil, shield)
shieldClip:SetClipsChildren(true)
shieldClip:SetPoint("BOTTOMLEFT", shield, "BOTTOM", 0,0)
shieldClip:SetPoint("TOPRIGHT", shield:GetStatusBarTexture(), "TOPRIGHT")
local mask = shieldClip:CreateMaskTexture(nil,"ARTWORK")
mask:SetAllPoints(shield); mask:SetTexture(media .. "ring_mask")
local shieldTexture = shieldClip:CreateTexture(nil,"ARTWORK")
shieldTexture:SetAllPoints(shield); shieldTexture:SetAtlas("raidframe-shield-fill")
shieldTexture:SetVertexColor(0.48,0.8,1,0.95); shieldTexture:SetBlendMode("ADD")
shieldTexture:AddMaskTexture(mask)
local pattern = shieldClip:CreateTexture(nil,"OVERLAY")
pattern:SetAllPoints(shield); pattern:SetAtlas("RaidFrame-Shield-Overlay")
pattern:SetVertexColor(0.8,0.93,1,0.65); pattern:AddMaskTexture(mask)
local overflow = shield:CreateTexture(nil,"OVERLAY")
overflow:SetAtlas("RaidFrame-Shield-Overshield")
overflow:SetPoint("TOP", shield,"TOP",0,4); overflow:SetSize(18,28)
overflow:Hide()
function S.UpdateShield()
  if not UnitGetTotalAbsorbs then shield:Hide(); S.Report("Shield","API unavailable"); return end
  local maximum, amount = UnitHealthMax("player"), UnitGetTotalAbsorbs("player")
  if not S.Secret(amount) then amount = amount or 0 end
  shield:SetMinMaxValues(0,maximum); shield:SetValue(amount)
  -- Overcap cue is optional when numeric comparisons are restricted.
  overflow:SetShown(S.Readable(amount) and S.Readable(maximum) and amount>maximum)
  S.Report("Shield", "ready: Blizzard shield crescent; saturated at max health")
end

-- Twelve small motes per orb. Motion is purely cosmetic, capped at 30 Hz;
-- both the native fill clip and circular mask trim every particle.
local particles, models = {}, {}
for index, layer in ipairs(S.orbLayers) do
  for i=1,12 do
    local p = layer.clip:CreateTexture(nil,"OVERLAY",nil,1)
    p:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    p:SetBlendMode("ADD"); p:SetSize(1.5+i%3,1.5+i%3)
    p:AddMaskTexture(layer.mask)
    p:SetVertexColor(index==1 and 1 or 0.6,index==1 and 0.45 or 0.8,index==1 and 0.3 or 1)
    particles[#particles+1] = {texture=p, frame=layer.frame, phase=i/12, x=(i*43%130)-65, speed=0.08+(i%4)*0.015}
  end
end
local ticker = CreateFrame("Frame", nil, S.hud)
local clock, accumulator = 0,0
local function animate(_, elapsed)
  clock=clock+elapsed; accumulator=accumulator+elapsed
  if accumulator<1/30 then return end
  accumulator=0
  for _, p in ipairs(particles) do
    local phase=(p.phase+clock*p.speed)%1
    local x=p.x+math.sin(phase*6.283+p.phase*4)*7
    p.texture:ClearAllPoints()
    p.texture:SetPoint("CENTER",p.frame,"CENTER",x,-85+phase*170)
    p.texture:SetAlpha(math.sin(phase*math.pi)*0.45)
  end
end

-- Optional native spell models from Roth's model catalogue. Inscribed square
-- viewports keep the model inside the sphere; liquid/gloss remain in front.
local function configureModels()
  if not S.options.models or not S.options.motion then
    for _, model in ipairs(models) do model:Hide() end
    S.Report("Models","off (optional native spell effects)"); return
  end
  if #models==0 then
    for i,layer in ipairs(S.orbLayers) do
      local model = CreateFrame("PlayerModel",nil,layer.clip)
      model:SetSize(130,130); model:SetPoint("CENTER",layer.frame,"CENTER")
      model:SetAlpha(0.20); model:EnableMouse(false)
      model:SetFrameLevel(layer.front:GetFrameLevel()-1)
      local function load(self)
        self:SetModel(i==1 and 4544400 or 2030216)
        self:SetCameraPosition(i==1 and 14.4006 or 2.5282,0,0)
        self:SetCameraTarget(0,0,0)
      end
      model:SetScript("OnShow", load)
      models[#models+1]=model
      load(model)
    end
  end
  for _,model in ipairs(models) do model:Show() end
  S.Report("Models","enabled: client spell assets; appearance needs in-game check")
end
function S.ApplyVisuals()
  for _,group in ipairs(S.animations) do
    if S.options.motion then group:Play() else group:Stop() end
  end
  if not S.options.motion then lowFrame:SetAlpha(0.65) end
  ticker:SetScript("OnUpdate",S.options.motion and animate or nil)
  for _,p in ipairs(particles) do p.texture:SetShown(S.options.motion) end
  S.UpdateLowHealth(); S.UpdateShield()
  S.Run("Models",configureModels)
  S.Report("Effects",S.options.motion and "layered liquid + motes + 20% pulse" or "reduced motion; static low-health warning")
end
