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

-- Five compact rows keep every slot inside the dark part of the painting.
-- Armor forms the center, weapons flank the legs, and jewelry fills the foot.
local positions = {
  { "NeckSlot", -124, -98, "Neck" }, { "RangedSlot", -62, -98, "Ranged" },
  { "HeadSlot", 0, -98, "Head" }, { "TabardSlot", 62, -98, "Tabard" },
  { "BackSlot", 124, -98, "Back" },
  { "ShoulderSlot", -124, -148, "Shoulder" },
  { "ChestSlot", 0, -148, "Chest" }, { "ShirtSlot", 124, -148, "Shirt" },
  { "WristSlot", -124, -198, "Wrist" },
  { "WaistSlot", 0, -198, "Waist" }, { "HandsSlot", 124, -198, "Hands" },
  { "MainHandSlot", -124, -248, "Main Hand" },
  { "LegsSlot", 0, -248, "Legs" }, { "SecondaryHandSlot", 124, -248, "Off Hand" },
  { "Finger0Slot", -124, -298, "Ring 1" },
  { "Trinket0Slot", -62, -298, "Trinket 1" },
  { "FeetSlot", 0, -298, "Feet" },
  { "Trinket1Slot", 62, -298, "Trinket 2" },
  { "Finger1Slot", 124, -298, "Ring 2" },
}

local function addEquipmentSlots()
  for _, entry in ipairs(positions) do
    local slotName, x, y, label = entry[1], entry[2], entry[3], entry[4]
    local getSlot = C_PaperDollInfo and C_PaperDollInfo.GetInventorySlotInfo or GetInventorySlotInfo
    local slotID, emptyTexture
    if getSlot then slotID, emptyTexture = getSlot(slotName) end
    local rangedVisible = slotName ~= "RangedSlot" or not C_PaperDollInfo
      or not C_PaperDollInfo.IsRangedSlotShown or C_PaperDollInfo.IsRangedSlotShown()
    if slotID and rangedVisible then
      -- PaperDollItemSlotButtonTemplate also registers itself in Blizzard's
      -- private slot table; using it here can overwrite the real character
      -- buttons. Plain ItemButtonTemplate keeps the inventory interactions.
      local button = CreateFrame("ItemButton", "SeraphglassGear" .. slotName, equipment, "ItemButtonTemplate")
      button:SetID(slotID)
      button:SetSize(38, 38)
      button:SetPoint("CENTER", root, "TOP", x, y)
      button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
      button:RegisterForDrag("LeftButton")
      local icon = button.icon or button.Icon or _G[button:GetName() .. "IconTexture"]
      if not icon then
        icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints(button)
        button.icon = icon
      end
      local caption = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      caption:SetPoint("TOP", button, "BOTTOM", 0, -1)
      caption:SetWidth(60)
      caption:SetText(label)
      caption:SetTextColor(0.93, 0.76, 0.48)
      local function refresh()
        local texture = GetInventoryItemTexture("player", slotID)
        if issecretvalue and issecretvalue(texture) then
          icon:SetTexture(texture)
          icon:SetDesaturated(false)
        else
          icon:SetTexture(texture or emptyTexture)
          icon:SetDesaturated(texture == nil)
        end
        if SetItemButtonCount then SetItemButtonCount(button, 0) end
      end
      button:SetScript("OnShow", refresh)
      button:SetScript("OnEvent", function(_, event, changedID)
        if event ~= "PLAYER_EQUIPMENT_CHANGED" or (issecretvalue and issecretvalue(changedID))
            or changedID == slotID then refresh() end
      end)
      button:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
      button:RegisterEvent("PLAYER_ENTERING_WORLD")
      button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetInventoryItem("player", slotID)
        GameTooltip:Show()
      end)
      button:SetScript("OnLeave", function() GameTooltip:Hide() end)
      button:SetScript("OnClick", function(_, mouseButton)
        local link = GetInventoryItemLink("player", slotID)
        if not (issecretvalue and issecretvalue(link)) and link
            and IsModifiedClick and IsModifiedClick() and HandleModifiedItemClick then
          HandleModifiedItemClick(link)
        elseif mouseButton == "RightButton" then
          if UseInventoryItem then UseInventoryItem(slotID) end
        elseif PickupInventoryItem then
          PickupInventoryItem(slotID)
        end
      end)
      button:SetScript("OnDragStart", function()
        if PickupInventoryItem then PickupInventoryItem(slotID) end
      end)
      button:SetScript("OnReceiveDrag", function()
        if PickupInventoryItem then PickupInventoryItem(slotID) end
      end)
      refresh()
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
  if initialized or not (ContainerFrameCombinedBags and (C_PaperDollInfo or GetInventorySlotInfo)) then return end
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
