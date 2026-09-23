-- One inventory window with Forever's native bag and equipment item buttons.
-- The CharacterFrame and its 3D model are never opened by the B key.
local ADDON = ...
local ART = "Interface\\AddOns\\" .. ADDON .. "\\media\\eternal_inventory_unified.png"
local WIDTH, EQUIPMENT_HEIGHT, FOOTER = 520, 352, 20
local initialized, layingOut = false, false
local root, chrome, equipment, bag

local function ensureCombined()
  if GetCVarBool and SetCVar and not GetCVarBool("combinedBags")
      and not (InCombatLockdown and InCombatLockdown()) then
    SetCVar("combinedBags", "1")
  end
end

-- A cross-shaped paper doll: armor through the center, weapons across its
-- middle, and accessories along the arms and lower edge.
local positions = {
  { "HeadSlot",              0,  -80 },
  { "NeckSlot",            -88,  -80 },
  { "ShoulderSlot",      -130, -122 },
  { "ChestSlot",            0, -122 },
  { "BackSlot",           130, -122 },
  { "WristSlot",         -130, -164 },
  { "WaistSlot",            0, -164 },
  { "HandsSlot",          130, -164 },
  { "MainHandSlot",      -170, -206 },
  { "LegsSlot",             0, -206 },
  { "SecondaryHandSlot",  170, -206 },
  { "Finger0Slot",        -90, -248 },
  { "FeetSlot",             0, -248 },
  { "Finger1Slot",         90, -248 },
  { "RangedSlot",        -165, -290 },
  { "Trinket0Slot",       -60, -290 },
  { "TabardSlot",           0, -290 },
  { "Trinket1Slot",        60, -290 },
  { "ShirtSlot",          165, -290 },
}

local function addEquipmentSlots()
  for _, entry in ipairs(positions) do
    local slotName, x, y = entry[1], entry[2], entry[3]
    if slotName ~= "RangedSlot" or (C_PaperDollInfo and C_PaperDollInfo.IsRangedSlotShown()) then
      -- The prefix is exactly nine characters: Forever's slot template
      -- resolves the equipment name with strsub(button:GetName(), 10).
      local template = x < 0 and "PaperDollItemSlotButtonLeftTemplate"
        or (x > 0 and "PaperDollItemSlotButtonRightTemplate" or "PaperDollItemSlotButtonBottomTemplate")
      local button = CreateFrame("ItemButton", "SeraphglassGear_" .. slotName, equipment, template)
      button:ClearAllPoints()
      button:SetSize(38, 38)
      button:SetPoint("CENTER", root, "TOP", x, y)
    end
  end
end

local function addArtwork()
  chrome = CreateFrame("Frame", nil, root)
  chrome:SetAllPoints(root)
  chrome:EnableMouse(false)

  -- Two texture regions keep the engraved divider aligned with the gear
  -- area while the bag section grows with the character's inventory.
  local upper = chrome:CreateTexture(nil, "BACKGROUND")
  upper:SetTexture(ART)
  upper:SetTexCoord(0, 1, 0, 0.5)
  upper:SetSize(WIDTH, EQUIPMENT_HEIGHT)
  upper:SetPoint("TOP", root, "TOP")

  local lower = chrome:CreateTexture(nil, "BACKGROUND")
  lower:SetTexture(ART)
  lower:SetTexCoord(0, 1, 0.5, 1)
  lower:SetPoint("TOPLEFT", root, "TOPLEFT", 0, -EQUIPMENT_HEIGHT)
  lower:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT")

  local heading = chrome:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  heading:SetPoint("TOP", root, "TOP", 0, -48)
  heading:SetText("EQUIPMENT")
  heading:SetTextColor(0.97, 0.78, 0.46)

  local inventoryHeading = chrome:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  inventoryHeading:SetPoint("TOP", root, "TOP", 0, -EQUIPMENT_HEIGHT - 17)
  inventoryHeading:SetText("INVENTORY")
  inventoryHeading:SetTextColor(0.97, 0.78, 0.46)

  local close = CreateFrame("Button", nil, chrome, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", root, "TOPRIGHT", -19, -17)
  close:SetScript("OnClick", function() CloseAllBags() end)

  equipment = CreateFrame("Frame", nil, chrome)
  equipment:SetAllPoints(root)
  equipment:EnableMouse(false)
  addEquipmentSlots()
  chrome:Hide()
end

local function layOut()
  if not bag or not bag:IsShown() or layingOut then return end
  layingOut = true
  root:SetSize(WIDTH, EQUIPMENT_HEIGHT + bag:GetHeight() + FOOTER)
  -- Scale both sections together if the complete panel is taller than
  -- the player's display.
  local availableHeight = UIParent:GetHeight() - 36
  local availableWidth = UIParent:GetWidth() - 30
  root:SetScale(math.min(1, availableHeight / root:GetHeight(), availableWidth / WIDTH))
  -- Blizzard's container anchoring sets a separate bag scale. The root
  -- supplies the scale for both sections of the unified window instead.
  bag:SetScale(1)
  bag:ClearAllPoints()
  bag:SetPoint("TOP", root, "TOP", 0, -EQUIPMENT_HEIGHT - 6)
  layingOut = false
end

local function openWindow()
  if bag:GetParent() ~= root and not (InCombatLockdown and InCombatLockdown()) then
    bag:SetParent(root)
  end
  root:SetAlpha(1)
  chrome:Show()
  layOut()
end

local function closeWindow()
  chrome:Hide()
  root:SetAlpha(0)
end

local function initialize()
  if initialized or not (ContainerFrameCombinedBags and PaperDollFrame and PaperDollItemSlotButton_OnLoad) then return end
  if InCombatLockdown and InCombatLockdown() then return end
  initialized = true
  bag = ContainerFrameCombinedBags

  -- Root remains shown without art while bags are closed, so the client's
  -- normal ToggleBackpack binding can still fire the native bag OnShow.
  root = CreateFrame("Frame", "SeraphglassInventory", UIParent)
  root:SetPoint("CENTER", UIParent, "CENTER")
  root:SetSize(WIDTH, 700)
  root:SetFrameStrata("MEDIUM")
  root:EnableMouse(false)
  root:SetAlpha(0)
  addArtwork()

  -- Bag item buttons, search, money, sorting and drag actions remain native.
  bag:SetParent(root)
  if bag.NineSlice then bag.NineSlice:Hide() end
  if bag.Bg then bag.Bg:Hide() end
  if bag.PortraitContainer then bag.PortraitContainer:Hide() end
  if bag.TitleContainer then bag.TitleContainer:Hide() end
  if bag.CloseButton then bag.CloseButton:Hide() end
  bag:HookScript("OnShow", openWindow)
  bag:HookScript("OnHide", closeWindow)
  bag:HookScript("OnSizeChanged", layOut)
  if hooksecurefunc and UpdateContainerFrameAnchors then
    hooksecurefunc("UpdateContainerFrameAnchors", layOut)
  end

  -- B retains the native ToggleBackpack/ToggleAllBags behavior, using
  -- Forever's built-in combined mode for the lower item grid.
  ensureCombined()
  if bag:IsShown() then openWindow() end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:RegisterEvent("PLAYER_REGEN_ENABLED")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("CVAR_UPDATE")
loader:SetScript("OnEvent", function(_, event, name)
  if event == "CVAR_UPDATE" then
    if name and name:lower() == "combinedbags" then ensureCombined() end
  else
    initialize()
    if event == "PLAYER_REGEN_ENABLED" then
      ensureCombined()
      if bag and bag:IsShown() then openWindow() end
    end
  end
end)
initialize()
