-- Taverners Ammo Guard - compact Taverners-themed UI
local Core = _G.TavernersCore
local Ammo = _G.TavernersAmmoGuard
if not Core or not Ammo then return end

local UI = {}
Ammo.UI = UI
local frame, warningFrame, countText, detailText, statusText

local function MakeButton(parent, label, width, onClick)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width, 24)
  button:SetText(label)
  button:SetScript("OnClick", onClick)
  return button
end

local function StylePanel(panel)
  if panel.SetBackdrop then
    panel:SetBackdrop({
      bgFile="Interface/Tooltips/UI-Tooltip-Background",
      edgeFile="Interface/Tooltips/UI-Tooltip-Border",
      tile=true, tileSize=16, edgeSize=16,
      insets={left=4, right=4, top=4, bottom=4}
    })
    local c = Core.Theme.panel
    panel:SetBackdropColor(c[1], c[2], c[3], c[4] or 0.96)
  end
end

local function CreateMain()
  if frame then return end
  frame = CreateFrame("Frame", "TavernersAmmoGuardFrame", UIParent)
  frame:SetSize(340, 205)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  StylePanel(frame)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -15)
  title:SetText("|cffffd27aTaverners|r |cffffffffAmmo Guard|r")
  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -3, -3)

  countText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
  countText:SetPoint("TOP", 0, -55)
  countText:SetText("--")
  detailText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  detailText:SetPoint("TOP", countText, "BOTTOM", 0, -5)
  statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  statusText:SetPoint("TOP", detailText, "BOTTOM", 0, -8)

  local restock = MakeButton(frame, "Restock at Merchant", 150, function()
    local ok, reason = Ammo:Restock()
    if not ok then Core.Notifications:Print(reason) end
    UI:Refresh()
  end)
  restock:SetPoint("BOTTOMLEFT", 16, 16)
  local closeButton = MakeButton(frame, "Close", 90, function() frame:Hide() end)
  closeButton:SetPoint("BOTTOMRIGHT", -16, 16)
end

local function CreateWarning()
  if warningFrame then return end
  warningFrame = CreateFrame("Frame", "TavernersAmmoGuardWarning", UIParent)
  warningFrame:SetSize(360, 150)
  warningFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
  warningFrame:SetFrameStrata("FULLSCREEN_DIALOG")
  warningFrame:SetMovable(true)
  warningFrame:EnableMouse(true)
  warningFrame:RegisterForDrag("LeftButton")
  warningFrame:SetScript("OnDragStart", warningFrame.StartMoving)
  warningFrame:SetScript("OnDragStop", warningFrame.StopMovingOrSizing)
  StylePanel(warningFrame)

  local title = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -15)
  title:SetText("|cffff5555Low Ammunition!|r")
  local message = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  message:SetPoint("TOP", title, "BOTTOM", 0, -12)
  message:SetWidth(320)
  message:SetJustifyH("CENTER")
  warningFrame.message = message

  local buy = MakeButton(warningFrame, "Restock at Merchant", 170, function()
    if MerchantFrame and MerchantFrame:IsShown() then
      local ok, reason = Ammo:Restock()
      if not ok then Core.Notifications:Print(reason) end
    else
      Core.Notifications:Print("Visit an ammunition vendor to restock.")
    end
  end)
  buy:SetPoint("BOTTOM", 0, 14)
  local dismiss = CreateFrame("Button", nil, warningFrame, "UIPanelCloseButton")
  dismiss:SetPoint("TOPRIGHT", -2, -2)
end

function UI:ShowWarning(status)
  CreateWarning()
  warningFrame.message:SetText("Only |cffff5555" .. tostring(status.count) .. "|r " .. tostring(status.name) .. " remaining.\nWarning threshold: " .. tostring(status.threshold) .. ".")
  warningFrame:Show()
end

function UI:Refresh()
  if not frame then return end
  local status = Ammo:GetStatus()
  if not status.equipped then
    countText:SetText("--")
    detailText:SetText("No supported ammunition equipped")
    statusText:SetText("Equip arrows or bullets to begin monitoring.")
    return
  end
  countText:SetText(tostring(status.count))
  detailText:SetText((status.low and "|cffff5555" or "|cff65cc75") .. tostring(status.name) .. "|r")
  statusText:SetText(status.low and "|cffff5555Below warning threshold (" .. status.threshold .. ")|r" or "|cff65cc75Ammunition supply looks good|r")
end

function UI:Toggle()
  CreateMain()
  self:Refresh()
  if frame:IsShown() then frame:Hide() else frame:Show() end
end
