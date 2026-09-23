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
InCombatLockdown=function() return false end
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
PlayerFrame.Hide=function() error('native player frame hidden by default') end
local S={}
for line in io.lines('Seraphglass.toc') do
 if line:match('%.lua$') then assert(loadfile(line))('Seraphglass',S) end
end
event('ADDON_LOADED','Seraphglass'); event('PLAYER_LOGIN');event('PLAYER_ENTERING_WORLD')
assert(S.version=='0.20.0-beta')
assert(not SeraphglassInventory and not SeraphglassAngelActionArt)
assert(S.options.models==false)
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
print('PASS: orb-only startup, circular masks, overcap inputs, colors, reduced motion, opaque health/resources/cast duration')
