-- Compact bronze medallions stay attached to the health orb. Only relevant
-- states are shown. Cosmetic pulses never depend on secret combat numbers.
local _, S = ...
local root=CreateFrame("Frame",nil,S.left)
root:SetAllPoints(S.left); root:SetFrameLevel(S.left:GetFrameLevel()+12)
root:EnableMouse(false)
local icons={}
S.indicators=icons
local function badge(key,x,y,animated)
  local f=CreateFrame("Frame",nil,root)
  f:SetSize(22,22); f:SetPoint("CENTER",S.left,"CENTER",x,y); f:EnableMouse(false)
  local bg=f:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(f); bg:SetTexture(S.media.."orb_background")
  local icon=f:CreateTexture(nil,"ARTWORK")
  icon:SetSize(17,17); icon:SetPoint("CENTER")
  local rim=f:CreateTexture(nil,"OVERLAY")
  rim:SetSize(25,25); rim:SetPoint("CENTER"); rim:SetTexture(S.media.."ring_bg2")
  local mask=f:CreateMaskTexture(nil,"ARTWORK")
  mask:SetAllPoints(rim); mask:SetTexture(S.media.."ring_mask"); rim:AddMaskTexture(mask)
  rim:SetVertexColor(0.68,0.43,0.17)
  f.icon=icon
  if animated then
    local pulse=f:CreateAnimationGroup(); local alpha=pulse:CreateAnimation("Alpha")
    alpha:SetFromAlpha(0.5); alpha:SetToAlpha(1); alpha:SetDuration(key=="combat" and 0.55 or 1.2)
    pulse:SetLooping("BOUNCE"); f.pulse=pulse
  end
  f:Hide(); icons[key]=f
  return icon
end
badge("combat",0,106,true):SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
icons.combat.icon:SetTexCoord(0.5,1,0,0.49)
badge("rest",0,106,true):SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
icons.rest.icon:SetTexCoord(0,0.5,0,0.421875)
badge("death",0,106,false):SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
if SetRaidTargetIconTexture then SetRaidTargetIconTexture(icons.death.icon,8) end
badge("resurrection",0,106,true):SetAtlas("RaidFrame-Icon-Rez")
badge("leader",45,98,false):SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
badge("role",78,75,false):SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES")
badge("pvp",99,40,false)
badge("marker",107,0,false):SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
local function truth(fn,...)
  if not fn then return false end
  local value=fn(...)
  return not S.Secret(value) and value==true
end
local function show(key,value)
  local f=icons[key]; local visible=S.options.indicators and value
  f:SetShown(visible)
  if f.pulse then
    if visible and S.options.motion then
      if not f.pulse:IsPlaying() then f.pulse:Play() end
    else f.pulse:Stop(); f:SetAlpha(1) end
  end
end
local inCombat=false
function S.ApplyIndicators()
  local dead=truth(UnitIsDeadOrGhost,"player")
  local rez=truth(UnitHasIncomingResurrection,"player")
  show("resurrection",rez)
  show("death",dead and not rez)
  show("combat",inCombat and not dead and not rez)
  show("rest",not inCombat and not dead and not rez and truth(IsResting))
  local grouped=truth(IsInGroup)
  local leader=grouped and truth(UnitIsGroupLeader,"player")
  local assistant=grouped and truth(UnitIsGroupAssistant,"player")
  icons.leader.icon:SetTexture(leader and "Interface\\GroupFrame\\UI-Group-LeaderIcon" or "Interface\\GroupFrame\\UI-Group-AssistantIcon")
  show("leader",leader or assistant)
  local role=UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
  local validRole=not S.Secret(role) and (role=="TANK" or role=="HEALER" or role=="DAMAGER")
  if validRole and GetTexCoordsForRoleSmallCircle then icons.role.icon:SetTexCoord(GetTexCoordsForRoleSmallCircle(role)) end
  show("role",grouped and validRole and GetTexCoordsForRoleSmallCircle~=nil)
  local faction=UnitFactionGroup and UnitFactionGroup("player")
  local validFaction=not S.Secret(faction) and (faction=="Horde" or faction=="Alliance")
  local ffa=truth(UnitIsPVPFreeForAll,"player")
  if ffa then icons.pvp.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA")
  elseif validFaction then icons.pvp.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-"..faction) end
  show("pvp",ffa or (validFaction and truth(UnitIsPVP,"player")))
  local marker=GetRaidTargetIndex and GetRaidTargetIndex("player")
  local validMarker=S.Readable(marker) and marker>=1 and marker<=8 and SetRaidTargetIconTexture~=nil
  if validMarker then SetRaidTargetIconTexture(icons.marker.icon,marker) end
  show("marker",validMarker)
  S.Report("Indicators",S.options.indicators and "ready: combat/rest, death/rez, role, leader, PvP, raid marker" or "off")
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_UPDATE_RESTING","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED","PLAYER_DEAD","PLAYER_ALIVE","PLAYER_UNGHOST","GROUP_ROSTER_UPDATE","PARTY_LEADER_CHANGED","PLAYER_ROLES_ASSIGNED","ROLE_CHANGED_INFORM","UNIT_FACTION","RAID_TARGET_UPDATE","INCOMING_RESURRECT_CHANGED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,unit)
  if event=="UNIT_FACTION" and unit~="player" then return end
  if event=="PLAYER_REGEN_DISABLED" then inCombat=true
  elseif event=="PLAYER_REGEN_ENABLED" then inCombat=false
  elseif event=="PLAYER_ENTERING_WORLD" then inCombat=InCombatLockdown() or truth(UnitAffectingCombat,"player") end
  S.Run("Indicators",S.ApplyIndicators)
end)
