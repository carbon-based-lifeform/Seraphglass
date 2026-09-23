-- Orb-local cast ring and secondary resource gems. No native bars are moved,
-- hidden, reparented or restyled by this module.
local _, S = ...
local ringFrame = CreateFrame("Frame",nil,S.right)
ringFrame:SetAllPoints(S.right)
ringFrame:SetFrameLevel(S.right:GetFrameLevel()+8)
ringFrame:EnableMouse(false)
local function ringTexture(layer, alpha)
  local texture=ringFrame:CreateTexture(nil,layer)
  texture:SetSize(244,244); texture:SetPoint("CENTER")
  texture:SetTexture(S.media.."ring_bg2")
  local mask=ringFrame:CreateMaskTexture(nil,"ARTWORK")
  mask:SetAllPoints(texture); mask:SetTexture(S.media.."ring_mask")
  texture:AddMaskTexture(mask)
  texture:SetVertexColor(0.85,0.64,0.32,alpha)
  return texture
end
local track=ringTexture("BACKGROUND",0.08)
local cast=ringTexture("OVERLAY",0.72)
cast:SetBlendMode("ADD")
local castName=ringFrame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
castName:SetPoint("BOTTOM",S.right,"TOP",0,-27)
castName:SetWidth(190); castName:SetTextColor(0.95,0.81,0.58)
ringFrame:Hide()
local duration, channel, legacyStart, legacyEnd
local hasDuration = false
local radial=cast.SetRadialProgressBarPercent ~= nil
if radial then
  cast:SetRadialProgressBarStartOffset(0)
  cast:SetRadialProgressBarFeather(0.015)
end
local function stopCast()
  duration, legacyStart,legacyEnd=nil,nil,nil
  hasDuration=false
  ringFrame:SetScript("OnUpdate",nil); ringFrame:Hide()
end
local function progress()
  if hasDuration then
    -- The duration object computes the ratio; the texture consumes the opaque
    -- result. No subtraction, comparison or division of cast times in Lua.
    if channel then cast:SetRadialProgressBarPercent(duration:GetRemainingPercent())
    else cast:SetRadialProgressBarPercent(duration:GetElapsedPercent()) end
  elseif legacyStart then
    local p=math.min(1,math.max(0,(GetTime()-legacyStart)/(legacyEnd-legacyStart)))
    cast:SetRadialProgressBarPercent(channel and 1-p or p)
    if p>=1 then stopCast() end
  end
end
local function updateCast()
  stopCast()
  if not radial or not S.options.cast then return end
  local name,_,_,startMS,endMS=UnitCastingInfo("player")
  channel=false
  if not S.Secret(name) and not name then
    name,_,_,startMS,endMS=UnitChannelInfo("player"); channel=true
  end
  if not S.Secret(name) and not name then return end
  local query=channel and UnitChannelDuration or UnitCastingDuration
  if query then
    local d=query("player")
    -- Do not branch on an opaque duration object itself.
    if S.Secret(d) or d~=nil then duration=d; hasDuration=true end
  elseif S.Readable(startMS) and S.Readable(endMS) and endMS>startMS then
    legacyStart,legacyEnd=startMS/1000,endMS/1000
  end
  if not hasDuration and not legacyStart then
    S.Report("Cast ring","no usable duration API for this cast"); return
  end
  castName:SetText(name)
  cast:SetVertexColor(channel and 0.5 or 1,channel and 0.78 or 0.72,channel and 1 or 0.35,0.72)
  ringFrame:Show()
  ringFrame:SetScript("OnUpdate",function()
    if not S.Run("Cast ring",progress) then stopCast() end
  end)
  S.Report("Cast ring","ready: player casts/channels")
end

local resourceFrame=CreateFrame("Frame",nil,S.right)
resourceFrame:SetAllPoints(S.right); resourceFrame:EnableMouse(false)
resourceFrame:SetFrameLevel(S.right:GetFrameLevel()+9)
local pips={}
for i=1,10 do
  local bar=CreateFrame("StatusBar",nil,resourceFrame)
  bar:SetSize(15,15); bar:SetOrientation("VERTICAL")
  bar:SetStatusBarTexture(S.media.."orb_filling15")
  local bg=bar:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(bar); bg:SetTexture(S.media.."orb_background")
  local glass=bar:CreateTexture(nil,"OVERLAY")
  glass:SetAllPoints(bar); glass:SetTexture(S.media.."orb_gloss")
  local trim=bar:CreateTexture(nil,"OVERLAY")
  trim:SetSize(18,18); trim:SetPoint("CENTER"); trim:SetTexture(S.media.."ring_bg2")
  trim:SetVertexColor(0.8,0.6,0.31)
  local mask=bar:CreateMaskTexture(nil,"ARTWORK")
  mask:SetAllPoints(trim); mask:SetTexture(S.media.."ring_mask"); trim:AddMaskTexture(mask)
  local cd=CreateFrame("Cooldown",nil,bar,"CooldownFrameTemplate")
  cd:SetAllPoints(bar); cd:SetDrawEdge(false); cd:SetHideCountdownNumbers(true)
  bar.cooldown=cd; pips[i]=bar; bar:Hide()
end
local resourceTypes={ROGUE={4,5,1,0.7,0.15},DRUID={4,5,1,0.65,0.12},PALADIN={9,5,1,0.85,0.38},
  WARLOCK={7,5,0.75,0.28,1},MONK={12,6,0.2,1,0.75},MAGE={16,4,0.5,0.65,1},EVOKER={19,6,0.3,0.85,1}}
local function positionPips(count)
  for i,p in ipairs(pips) do
    p:SetShown(i<=count)
    if i<=count then
      local angle=math.rad(count==1 and 270 or 205+(i-1)*130/(count-1))
      p:ClearAllPoints(); p:SetPoint("CENTER",S.right,"CENTER",112*math.cos(angle),112*math.sin(angle))
    end
  end
end
local function updateResources()
  if not S.options.resources then resourceFrame:Hide(); S.Report("Resources","off"); return end
  resourceFrame:Show()
  local _,class=UnitClass("player")
  if S.Secret(class) then return end
  if class=="DEATHKNIGHT" and GetRuneCooldown then
    positionPips(6)
    for i=1,6 do
      local start,length,ready=GetRuneCooldown(i)
      local p=pips[i]; p:SetMinMaxValues(0,1); p:SetStatusBarColor(0.3,0.8,1)
      if not S.Secret(ready) then p:SetValue(ready and 1 or 0.2) end
      if S.Readable(start) and S.Readable(length) then p.cooldown:SetCooldown(start,length) end
    end
    S.Report("Resources","ready: six native rune cooldowns"); return
  end
  local spec=resourceTypes[class]
  if not spec then positionPips(0); S.Report("Resources","no supported secondary resource for this class"); return end
  local maximum=UnitPowerMax("player",spec[1])
  if S.Readable(maximum) and maximum<=0 then positionPips(0); S.Report("Resources","inactive in this form/spec"); return end
  local count=S.Readable(maximum) and math.min(10,math.floor(maximum)) or spec[2]
  positionPips(count)
  local value=UnitPower("player",spec[1])
  for i=1,count do
    local p=pips[i]
    p.cooldown:Clear()
    -- Each bar clamps the same native power value to its own one-point range.
    p:SetMinMaxValues(i-1,i); p:SetValue(value)
    p:SetStatusBarColor(spec[3],spec[4],spec[5])
  end
  S.Report("Resources","ready: "..count.." secondary-resource gems")
end
function S.ApplyResources()
  S.Run("Resources",updateResources)
  S.Run("Cast ring",updateCast)
  if not S.options.cast then S.Report("Cast ring","off")
  elseif not radial then S.Report("Cast ring","radial texture API unavailable")
  elseif not ringFrame:IsShown() then S.Report("Cast ring","ready; idle") end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER",
 "PLAYER_TARGET_CHANGED","RUNE_POWER_UPDATE","UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED",
 "UNIT_SPELLCAST_INTERRUPTED","UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP"}) do
  pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,unit)
  if event:sub(1,5)=="UNIT_" and unit~="player" then return end
  if event:find("SPELLCAST",1,true) then S.Run("Cast ring",updateCast)
  else S.Run("Resources",updateResources)
    if event=="PLAYER_ENTERING_WORLD" then S.Run("Cast ring",updateCast) end
  end
end)
