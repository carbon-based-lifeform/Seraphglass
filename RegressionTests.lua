-- Run from this folder: luahbtex --luaonly RegressionTests.lua
-- Deliberately validates Forever's ItemButton intrinsic/template distinction.
local expected = {
  HeadSlot = 1, NeckSlot = 2, ShoulderSlot = 3, ShirtSlot = 4,
  ChestSlot = 5, WaistSlot = 6, LegsSlot = 7, FeetSlot = 8,
  WristSlot = 9, HandsSlot = 10, Finger0Slot = 11, Finger1Slot = 12,
  Trinket0Slot = 13, Trinket1Slot = 14, BackSlot = 15,
  MainHandSlot = 16, SecondaryHandSlot = 17, RangedSlot = 18,
  TabardSlot = 19,
}
local ids, textures, buttons, frames = {}, {}, {}, {}
local combat, combined = false, false
local methods = {}
function methods:SetID(value) self.id = value end
function methods:GetID() return self.id end
function methods:GetName() return self.name end
function methods:SetTexture(value) self.texture = value end
function methods:SetScript(name, callback) self.scripts[name] = callback end
function methods:RegisterEvent() end
function methods:RegisterForClicks() end
function methods:RegisterForDrag() end
function methods:SetParent(parent) self.parent = parent end
function methods:GetParent() return self.parent end
function methods:IsShown() return self.shown == true end
function methods:Show() self.shown = true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() self.shown = false; if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:SetAlpha(v) self.alpha = v end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:GetWidth() return self.width or 500 end
function methods:GetHeight() return self.height or 300 end
function methods:HookScript(event, f) self.scripts[event] = f end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:CreateTexture() return setmetatable({ scripts = {} }, { __index = methods }) end
function methods:CreateFontString() return setmetatable({ scripts = {} }, { __index = methods }) end
setmetatable(methods, { __index = function(_, key)
  if key == "Icon" or key == "NineSlice" or key == "Bg" or key == "PortraitContainer"
      or key == "TitleContainer" or key == "CloseButton" or key == "BorderArt"
      or key == "ActionBarPageNumber" or key == "NormalTexture" then return nil end
  if key:match("^[A-Z]") then return function() end end
end })
function CreateFrame(kind, name, parent, template)
  -- Forever XML defines ItemButton as an intrinsic, not a virtual template.
  assert(template == nil or template == "UIPanelCloseButton", "invalid template: " .. tostring(template))
  local frame = setmetatable({ scripts = {}, events = {}, parent = parent, name = name }, { __index = methods })
  if name then _G[name] = frame end
  if kind == "ItemButton" then buttons[#buttons + 1] = frame end
  frames[#frames + 1] = frame
  return frame
end
UIParent = CreateFrame()
UIParent:SetSize(1920, 1080)
local function event(event, value)
  for _, f in ipairs(frames) do if f.events[event] and f.scripts.OnEvent then f.scripts.OnEvent(f, event, value) end end
end
C_PaperDollInfo = {
  GetInventorySlotInfo = function(name)
    assert(expected[name], name)
    return expected[name], "empty:" .. name
  end,
  IsRangedSlotShown = function() return true end,
}
GetCVarBool = function() return combined end
SetCVar = function(_, v) combined = v == "1"; event("CVAR_UPDATE", "combinedBags") end
InCombatLockdown = function() return combat end
GetInventoryItemTexture = function(_, id) return "item:" .. id end
GetInventoryItemLink = function(_, id) return "link:" .. id end
SetItemButtonCount = function() end
GameTooltip = setmetatable({}, { __index = methods })
PickupInventoryItem = function(id) ids[#ids + 1] = id end
UseInventoryItem = function(id) ids[#ids + 1] = id end
local S = {commands = {}, Report = function() end, Run = function(_, fn, ...) fn(...); return true end}
assert(loadfile("SeraphglassInventory.lua"))("Seraphglass", S)
assert(#buttons == 0, "must wait for native bags")
ContainerFrameCombinedBags = CreateFrame()
combat = true
event("ADDON_LOADED", "Blizzard_UIPanels_Game")
assert(#buttons == 0, "must defer creation during combat")
combat = false
event("PLAYER_REGEN_ENABLED")
assert(combined, "must enable combined mode")
assert(#buttons == 19, "all 19 equipment slots should be present")
for name, id in pairs(expected) do
  local button = assert(_G["SeraphglassGear" .. name], name)
  assert(button:GetID() == id, "wrong equipment ID: " .. name)
  assert(button.icon.texture == "item:" .. id, "wrong equipped icon: " .. name)
end
local head = _G.SeraphglassGearHeadSlot
head.scripts.OnClick(head, "LeftButton")
assert(ids[1] == expected.HeadSlot, "click picked the wrong equipment slot")
GetInventoryItemTexture = function() return nil end
head.scripts.OnEvent(head, "PLAYER_EQUIPMENT_CHANGED", expected.HeadSlot)
assert(head.icon.texture == "empty:HeadSlot", "empty slot texture not restored")
print("equipment slot mapping, item icons, click, and empty state OK")

ContainerFrameCombinedBags:Show()
assert(SeraphglassInventory.alpha == 1, "native B open must show custom frame")
assert(ContainerFrameCombinedBags:GetParent() == SeraphglassInventory, "bags and equipment must share parent")
ContainerFrameCombinedBags:Hide()
assert(SeraphglassInventory.alpha == 0, "B close must hide custom frame")
event("ADDON_LOADED", "AnotherAddon")
assert(#buttons == 19, "repeated events must not duplicate equipment")
print("delayed loading, combat deferral, CVar reentry, unified open/close OK")

-- Bar regression uses Blizzard's real UpdateShownButtons behavior below:
-- an empty action slot is shown only when its showgrid flag is nonzero.
unpack = table.unpack or unpack
local function region() return setmetatable({scripts={}}, {__index=methods}) end
function methods:SetColorTexture() end
function methods:SetAttribute(k,v) self.attributes[k]=v end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:GetNormalTexture() return nil end
function methods:SetShown(v) self.shown=v end
bit = { bor = function(a,b) return a % 2 == 0 and a+b or a end }
ACTION_BUTTON_SHOW_GRID_REASON_CVAR = 1
SeraphglassHUD = CreateFrame("Frame")
local barNames={"MainActionBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarRight"}
Settings = {GetValue=function() return false end, SetValue=function() end}
for _, name in ipairs(barNames) do
  local b = CreateFrame("Frame", name)
  b.actionButtons = {}; b.shownButtonContainers = {}
  for i=1,12 do
    local prefix = name == "MainActionBar" and "ActionButton" or name .. "Button"
    local button=CreateFrame("Button",prefix..i,b)
    button.attributes = {showgrid=0}; button.index=i
    b.actionButtons[i]=button
  end
  function b:UpdateShownButtons()
    for _, button in ipairs(self.actionButtons) do
      button:SetShown(button.index <= self.numButtonsShowable and button:GetAttribute("showgrid") > 0)
    end
  end
  function b:UpdateGridLayout() end
end
assert(loadfile("SeraphglassActionBars.lua"))("Seraphglass", S)
local visible=0
for _, name in ipairs(barNames) do
  for i,b in ipairs(_G[name].actionButtons) do
    assert(b:IsShown() == (i<=5), name .. " slot " .. i)
    if b:IsShown() then visible=visible+1 end
  end
end
assert(visible==20, "all 20 empty slots must remain visible")
print("four native action bars: 20 empty slots visible, slots 6-12 hidden OK")
