-- Run outside WoW from the addon directory: luahbtex --luaonly OrbTests.lua
local frames, groups={},{}
local methods={}
local noop=function() end
for _,name in ipairs({'SetColorTexture','SetFrameStrata','EnableMouse','SetOrientation','SetAllPoints','SetTexCoord','SetBlendMode','SetRotation','SetDegrees','SetDuration','SetLooping','SetFromAlpha','SetToAlpha','SetClipsChildren','RegisterForClicks','SetMovable','SetClampedToScreen','RegisterForDrag','SetWidth','SetHeight','SetDrawEdge','SetHideCountdownNumbers','SetCameraPosition','SetCameraTarget','SetRadialProgressBarStartOffset','SetRadialProgressBarFeather','SetTextColor','StartMoving','StopMovingOrSizing','SetModel','SetCooldown','Clear'}) do methods[name]=noop end
local function object(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,scripts={},events={},shown=true,alpha=1,masks={}}, {__index=methods})
 if name then _G[name]=o end
 return o
end
function CreateFrame(kind,name,parent,template)
 assert(template==nil or template=='SecureUnitButtonTemplate' or template=='CooldownFrameTemplate', 'unknown template '..tostring(template))
 local f=object(kind,name,parent); frames[#frames+1]=f; return f
end
function methods:IsPlaying() return self.playing end
function methods:GetCenter() return self.centerX or 600,self.centerY or 300 end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:GetName() return self.name end
function methods:GetParent() return self.parent end
function methods:SetScript(e,f) self.scripts[e]=f end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:CreateTexture() return object('Texture',nil,self) end
function methods:CreateMaskTexture() return object('Mask',nil,self) end
function methods:CreateFontString() return object('FontString',nil,self) end
function methods:SetTexture(v) self.texture=v end
function methods:SetAtlas(v) self.atlas=v end
function methods:AddMaskTexture(m) self.masks[#self.masks+1]=m end
function methods:SetStatusBarTexture(v) self.bar=self:CreateTexture();self.bar:SetTexture(v) end
function methods:GetStatusBarTexture() return self.bar end
function methods:SetStatusBarColor(...) self.color={...} end
function methods:SetVertexColor(...) self.color={...} end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
function methods:SetValue(v) self.value=v end
function methods:GetValue() return self.value end
function methods:SetPoint(...) self.point={...} end
function methods:ClearAllPoints() self.point=nil end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetScale(v) self.scale=v end
function methods:SetAttribute(k,v) self[k]=v end
function methods:SetText(v) self.text=v end
function methods:IsShown() return self.shown end
function methods:SetShown(v) self.shown=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:CreateAnimationGroup() local a=object('AnimationGroup',nil,self); groups[#groups+1]=a;return a end
function methods:CreateAnimation() return object('Animation',nil,self) end
function methods:Play() self.playing=true end
function methods:Stop() self.playing=false end
function methods:SetRadialProgressBarPercent(p) self.radial=p end
local function event(e,...)
 for _,f in ipairs(frames) do if f.events[e] and f.scripts.OnEvent then f.scripts.OnEvent(f,e,...) end end
end
local secret={secret=true}
issecretvalue=function(v) return type(v)=='table' and v.secret==true end
unpack=table.unpack or unpack
UIParent=CreateFrame('Frame')
SlashCmdList={}
Enum={LuaCurveType={Step=1},StatusBarInterpolation={ExponentialEaseOut=1}}
function CreateColor(...) local c={...}; function c:GetRGBA() return table.unpack(self) end; return c end
C_CurveUtil={CreateColorCurve=function()
 local c={points={}};c.SetType=noop
 function c:AddPoint(x,color) self.points[#self.points+1]={x,color} end
 return c
end}
local current,maximum,power=75,100,2
local fraction=0.75
UnitHealth=function() return current end; UnitHealthMax=function() return maximum end
UnitHealthPercent=function(_,_,curve) return fraction<curve.points[2][1] and curve.points[1][2] or curve.points[2][2] end
UnitPowerType=function() return 0,'MANA' end
UnitPower=function() return power end
UnitPowerMax=function(_,id) return id==9 and 5 or 100 end
UnitClass=function() return 'Paladin','PALADIN' end
RAID_CLASS_COLORS={PALADIN={r=1,g=0.5,b=0.7}}
UnitGetTotalAbsorbs=function() return 130 end
UnitGetIncomingHeals=function() return 20 end
local combat,rest,dead,rez,grouped,leader,assistant,pvp,marker=false,true,false,false,false,false,false,false,nil
InCombatLockdown=function() return combat end
UnitAffectingCombat=function() return combat end
IsResting=function() return rest end
UnitIsDeadOrGhost=function() return dead end
UnitHasIncomingResurrection=function() return rez end
IsInGroup=function() return grouped end
UnitIsGroupLeader=function() return leader end
UnitIsGroupAssistant=function() return assistant end
UnitGroupRolesAssigned=function() return 'HEALER' end
GetTexCoordsForRoleSmallCircle=function() return 0,1,0,1 end
UnitFactionGroup=function() return 'Alliance' end
UnitIsPVP=function() return pvp end
GetRaidTargetIndex=function() return marker end
SetRaidTargetIconTexture=function(texture,index) texture.raidIndex=index end
RegisterStateDriver=function(frame,state,condition) frame.driver=condition end
UnregisterStateDriver=function(frame) frame.driver=nil end
GetBuildInfo=function() return '1.60.1','69977' end
GetTime=function() return 15 end
local casting=false
UnitCastingInfo=function() if casting then return secret,nil,nil,secret,secret end end
UnitChannelInfo=function() end
local duration={secret=true,GetElapsedPercent=function() return secret end}
UnitCastingDuration=function() return duration end
-- Any retired whole-UI side effect is a regression.
SetCVar=function() error('orb addon must not change CVars') end
Settings={SetValue=function() error('orb addon must not change native bars') end}
PlayerFrame=CreateFrame('Frame','PlayerFrame')
-- Simulate upgrading from the old model option plus saved orb placement.
SeraphglassDB={orbs={options={models=true},layout={health={x=330,y=220,scale=0.8},power={x=1000,y=220,scale=1}}}}
local S={}
for line in io.lines('Seraphglass.toc') do
 if line:match('%.lua$') then assert(loadfile(line))('Seraphglass',S) end
end
event('ADDON_LOADED','Seraphglass'); event('PLAYER_LOGIN');event('PLAYER_ENTERING_WORLD')
assert(S.version=='0.21.0-beta')
assert(not SeraphglassInventory and not SeraphglassAngelActionArt)
assert(S.options.models==nil,'retired model option must not migrate')
for _,f in ipairs(frames) do assert(f.kind~='PlayerModel','square model viewport removed') end
assert(not PlayerFrame.shown and PlayerFrame.driver=='hide','native player frame hidden with secure driver')
assert(S.left.point[4]==330/0.8 and S.right.point[4]==1000,'restore independent positions')
assert(S.indicators.rest.shown and not S.indicators.combat.shown)
combat=true;event('PLAYER_REGEN_DISABLED')
assert(S.indicators.combat.shown and S.indicators.combat.pulse.playing and not S.indicators.rest.shown)
SlashCmdList.SERAPHGLASS('playerframe show')
assert(not PlayerFrame.shown,'protected frame update deferred in combat')
SlashCmdList.SERAPHGLASS('unlock');assert(not S.movers.health.shown)
combat=false;event('PLAYER_REGEN_ENABLED');assert(PlayerFrame.shown)
SlashCmdList.SERAPHGLASS('playerframe hide');assert(not PlayerFrame.shown and SeraphglassDB.orbs.hidePlayer)
SlashCmdList.SERAPHGLASS('unlock');assert(S.movers.health.shown and S.movers.power.shown)
S.left.centerX,S.left.centerY=800,500
local oldPowerX=S.layout.power.x
S.movers.health.scripts.OnDragStop()
assert(S.layout.health.x==640 and S.layout.health.y==400 and S.layout.power.x==oldPowerX,'health drag must not move power orb')
assert(SeraphglassDB.orbs.layout.health.x==640,'position saved')
SlashCmdList.SERAPHGLASS('lock');assert(not S.movers.health.shown)
S.commands.reset();assert(S.layout.health.x==nil and S.layout.power.x==nil)
grouped,leader,pvp,marker=true,true,true,8;event('GROUP_ROSTER_UPDATE')
assert(S.indicators.leader.shown and S.indicators.role.shown and S.indicators.pvp.shown and S.indicators.marker.shown)
dead=true;event('PLAYER_DEAD');assert(S.indicators.death.shown and not S.indicators.rest.shown)
rez=true;event('INCOMING_RESURRECT_CHANGED','player');assert(S.indicators.resurrection.shown and not S.indicators.death.shown)
S.commands.option('motion off');assert(not S.indicators.resurrection.pulse.playing and S.indicators.resurrection.shown)
S.commands.option('indicators off');for _,f in pairs(S.indicators) do assert(not f.shown) end
S.commands.option('indicators on')
assert(S.orbLayers[1].bar.value==75)
for _,layer in ipairs(S.orbLayers) do
 assert(#layer.swirls==3)
 for _,t in ipairs(layer.swirls) do assert(#t.masks==1,'swirl must stay inside glass') end
end
local shield
for _,f in ipairs(frames) do if f.kind=='StatusBar' and f.width==230 then shield=f end end
assert(shield and shield.value==130 and shield.maximum==100,'overcap passed to native clamp')
S.commands.color('0.2 0.3 0.8');assert(S.orbLayers[2].bar.color[3]==0.8)
S.commands.color('class');assert(S.orbLayers[2].bar.color[2]==0.5)
S.commands.option('motion off');for _,g in ipairs(groups) do assert(not g.playing) end
fraction=0.1; event('UNIT_HEALTH','player')
current,maximum,power=secret,secret,secret
event('UNIT_HEALTH','player');event('UNIT_POWER_UPDATE','player')
assert(S.orbLayers[1].bar.value==secret,'health must be passed through opaquely')
casting=true; event('UNIT_SPELLCAST_START','player')
for _,f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.016) end end
assert(S.status['Cast ring']=='ready: player casts/channels',tostring(S.status['Cast ring']))
casting=false;event('UNIT_SPELLCAST_STOP','player')
assert(S.status.Resources:match('ready'))
print('PASS: independent saved orb layout, model removal, secure player-frame hiding, status indicator transitions; orb-only startup, circular masks, overcap inputs, colors, reduced motion, opaque health/resources/cast duration')
