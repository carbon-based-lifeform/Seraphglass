-- Each orb owns all its artwork, effects, interaction, and status indicators.
local _, S = ...
local frames = {health=S.left, power=S.right}
local unlocked, pendingLayout = false, false
S.layout = {health={scale=1}, power={scale=1}}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<100000 end
function S.LoadLayout(saved)
  if type(saved)~="table" then return end
  for key in pairs(frames) do
    local item=saved[key]
    if type(item)=="table" then
      local out=S.layout[key]
      if finite(item.x) and finite(item.y) then out.x,out.y=item.x,item.y end
      if finite(item.scale) and item.scale>=0.5 and item.scale<=1.5 then out.scale=item.scale end
    end
  end
end
local function place(key)
  local frame, item=frames[key], S.layout[key]
  frame:ClearAllPoints(); frame:SetScale(item.scale)
  if item.x then
    -- Saved centers use UIParent coordinates, independent of each orb's scale.
    frame:SetPoint("CENTER", UIParent,"BOTTOMLEFT",item.x/item.scale,item.y/item.scale)
  else
    frame:SetPoint("BOTTOM", UIParent,"BOTTOM",(key=="health" and -400 or 400)/item.scale,15/item.scale)
  end
end
function S.ApplyLayout()
  if InCombatLockdown() then pendingLayout=true; return end
  for key in pairs(frames) do place(key) end
  pendingLayout=false
end
local movers={}
S.movers=movers
local function saveCenter(key)
  local frame=frames[key]
  local x,y=frame:GetCenter()
  if not x or not y then return end
  local factor=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
  S.layout[key].x,S.layout[key].y=x*factor,y*factor
end
local function finish(key)
  local frame=frames[key]
  if InCombatLockdown() then frame.pendingStop=true; return end
  frame:StopMovingOrSizing(); frame.pendingStop=nil; frame.dragging=nil
  saveCenter(key); place(key); S.Save()
end
for key,frame in pairs(frames) do
  local orbKey,orbFrame=key,frame
  frame:SetMovable(true); frame:SetClampedToScreen(true)
  local mover=CreateFrame("Button",nil,frame)
  mover:SetFrameStrata("DIALOG"); mover:SetSize(180,28)
  mover:SetPoint("CENTER",frame,"CENTER",0,0)
  mover:EnableMouse(true); mover:RegisterForDrag("LeftButton")
  local bg=mover:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(mover); bg:SetColorTexture(0.12,0.065,0.025,0.95)
  local label=mover:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  label:SetPoint("CENTER"); label:SetText(key=="health" and "Drag health orb" or "Drag power orb")
  mover:SetScript("OnDragStart",function()
    if not InCombatLockdown() then orbFrame.dragging=true; orbFrame:StartMoving() end
  end)
  mover:SetScript("OnDragStop",function() finish(orbKey) end)
  mover:SetScript("OnHide",function() if orbFrame.dragging then finish(orbKey) end end)
  mover:Hide(); movers[key]=mover
end
function S.SetUnlocked(value)
  if InCombatLockdown() then print("Seraphglass: unlock or lock outside combat"); return end
  unlocked=value
  for key,mover in pairs(movers) do
    if not value then finish(key) end
    if RegisterStateDriver then
      UnregisterStateDriver(mover,"visibility")
      if value then RegisterStateDriver(mover,"visibility","[combat] hide; show") end
    end
    mover:SetShown(value)
  end
end
function S.SetOrbScale(scale)
  for key in pairs(frames) do saveCenter(key); S.layout[key].scale=scale end
  S.ApplyLayout(); S.Save()
end
S.commands.reset=function()
  if InCombatLockdown() then return end
  S.layout={health={scale=1},power={scale=1}}
  S.ApplyLayout(); S.Save()
  print("Seraphglass: both orb positions and scale reset")
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN"); events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function(_,event)
  for key,frame in pairs(frames) do if frame.pendingStop then finish(key) end end
  if event=="PLAYER_LOGIN" or pendingLayout then S.ApplyLayout() end
end)
