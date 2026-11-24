-- Taverners Ammo Guard
-- Requires TavernersCore. Designed for WoW Forever's vanilla-style API.
local ADDON = ...
local Core = _G.TavernersCore
if not Core then
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff5555Taverners Ammo Guard requires TavernersCore.|r") end
  return
end

local Defaults = {
  enabled = true,
  ammoSupport = "both",       -- both, arrows, bullets
  restockTarget = "maximum",  -- maximum compatible bag capacity
  warningThreshold = 200,
  autoRestock = true,
  popup = true,
}
local DB = Core.Database:Register("TavernersAmmoGuardDB", Defaults, 1)
local Ammo = {name = ADDON or "TavernersAmmoGuard", db = DB, Core = Core}
_G.TavernersAmmoGuard = Ammo
Core:RegisterModule("AmmoGuard", Ammo)

local lastWarningItem

-- Only classes that can use the classic ranged-ammunition system are eligible.
local function IsEligibleClass()
  if not UnitClass then return false end
  local _, classToken = UnitClass("player")
  return classToken == "HUNTER" or classToken == "ROGUE" or classToken == "WARRIOR"
end
local function SafeCall(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b, c, d, e = pcall(fn, ...)
  if ok then return a, b, c, d, e end
end

local function ItemInfo(item)
  if not item then return nil end
  local name, link, quality, itemLevel, reqLevel, itemType, itemSubType, maxStack = GetItemInfo(item)
  return {name=name, link=link, type=itemType, subtype=itemSubType, maxStack=tonumber(maxStack) or 200}
end

local function GetEquippedAmmo()
  local itemID = GetInventoryItemID and GetInventoryItemID("player", 0)
  if not itemID and GetInventoryItemLink then
    local link = GetInventoryItemLink("player", 0)
    if link then itemID = tonumber(link:match("item:(%d+)")) end
  end
  if not itemID then return nil end
  local info = ItemInfo(itemID)
  if not info or not info.name then return nil end
  info.id = itemID
  info.count = (GetItemCount and GetItemCount(itemID, false)) or (GetInventoryItemCount and GetInventoryItemCount("player", 0)) or 0
  info.count = tonumber(info.count) or 0
  return info
end

local function IsSupported(info)
  if not info then return false end
  local subtype = tostring(info.subtype or ""):lower()
  local isArrow = subtype:find("arrow", 1, true) ~= nil
  local isBullet = subtype:find("bullet", 1, true) ~= nil
  if not isArrow and not isBullet then
    local itemType, name = tostring(info.type or ""):lower(), tostring(info.name or ""):lower()
    if itemType:find("projectile", 1, true) then
      isArrow = name:find("arrow", 1, true) ~= nil
      isBullet = name:find("bullet", 1, true) ~= nil
    end
  end
  if DB.ammoSupport == "arrows" then return isArrow end
  if DB.ammoSupport == "bullets" then return isBullet end
  return isArrow or isBullet
end

function Ammo:GetStatus()
  if not IsEligibleClass() then
    return {eligible=false, equipped=false, count=0, threshold=tonumber(DB.warningThreshold) or 200}
  end
  local info = GetEquippedAmmo()
  if not info or not IsSupported(info) then
    return {eligible=true, equipped=false, count=0, threshold=tonumber(DB.warningThreshold) or 200}
  end
  info.equipped = true
  info.threshold = tonumber(DB.warningThreshold) or 200
  info.low = info.count <= info.threshold
  return info
end

local function CountFreeSlotsForAmmo(info)
  local freeSlots = 0
  if not GetContainerNumFreeSlots or not GetItemFamily or not bit or not bit.band then return 0 end
  local itemFamily = tonumber(GetItemFamily(info.id)) or 0
  if itemFamily == 0 then return 0 end

  -- Bag 0 is the general backpack. Deliberately inspect only equipped bags
  -- with a non-zero family mask matching this projectile (quiver / ammo pouch).
  for bag = 1, 4 do
    local free, family = GetContainerNumFreeSlots(bag)
    free, family = tonumber(free) or 0, tonumber(family) or 0
    if family ~= 0 and bit.band(family, itemFamily) ~= 0 then
      freeSlots = freeSlots + free
    end
  end
  return freeSlots
end

local function FindMerchantAmmo(itemID)
  if not GetMerchantNumItems or not GetMerchantItemLink then return nil end
  for index = 1, GetMerchantNumItems() do
    local link = GetMerchantItemLink(index)
    local id = link and tonumber(link:match("item:(%d+)"))
    if id == itemID then return index end
  end
end

function Ammo:Restock()
  if not IsEligibleClass() then return false, "Ammo Guard restocking is only available to Hunters, Rogues and Warriors." end
  if not DB.enabled or not DB.autoRestock then return false, "Automatic restocking is disabled." end
  if not MerchantFrame or not MerchantFrame:IsShown() then return false, "Visit an ammunition merchant first." end
  local info = GetEquippedAmmo()
  if not info or not IsSupported(info) then return false, "Equip arrows or bullets first." end
  if info.count > (tonumber(DB.warningThreshold) or 200) then return false, "Ammunition is above the warning threshold." end
  local merchantIndex = FindMerchantAmmo(info.id)
  if not merchantIndex then return false, "This merchant does not sell your equipped ammunition." end
  local freeSlots = CountFreeSlotsForAmmo(info)
  if freeSlots <= 0 then return false, "No free space in an equipped compatible quiver or ammo pouch. General bags are not used." end

  local maxStack = math.max(1, info.maxStack or 200)
  local merchantMax = (GetMerchantItemMaxStack and tonumber(GetMerchantItemMaxStack(merchantIndex))) or maxStack
  local purchaseSize = math.max(1, math.min(maxStack, merchantMax))
  local stacks = math.min(freeSlots, math.ceil((freeSlots * maxStack) / purchaseSize))
  if not BuyMerchantItem then return false, "The merchant purchase API is unavailable." end

  -- Buy only up to the client-reported free-slot capacity. The game handles
  -- affordability and any last-stack fit checks through its normal merchant UI.
  for i = 1, stacks do SafeCall(BuyMerchantItem, merchantIndex, purchaseSize) end
  Core.Diagnostics:Log("INFO", "Restock requested for " .. info.name .. "; free slots: " .. freeSlots)
  Core.Notifications:Print("Restock requested for " .. info.name .. ".")
  return true
end

function Ammo:CheckAmmo(showPopup)
  if not DB.enabled or not IsEligibleClass() then
    if self.UI and self.UI.Refresh then self.UI:Refresh() end
    return
  end
  local status = self:GetStatus()
  if not status.equipped then return end
  if status.low then
    if lastWarningItem ~= status.id then
      lastWarningItem = status.id
      Core.Diagnostics:Log("WARN", "Low ammunition: " .. status.name .. " (" .. status.count .. " remaining)")
      if DB.popup and showPopup and self.UI then self.UI:ShowWarning(status) end
      Core.Notifications:Toast("Low ammunition: " .. status.count .. " " .. status.name .. " remaining!")
    end
  elseif lastWarningItem == status.id then
    lastWarningItem = nil
  end
  if self.UI and self.UI.Refresh then self.UI:Refresh() end
end

function Ammo:OnMerchantShow()
  if not IsEligibleClass() then return end
  local status = self:GetStatus()
  if status.equipped and status.low and DB.autoRestock then
    local ok, reason = self:Restock()
    if not ok then Core.Diagnostics:Log("INFO", "Restock skipped: " .. tostring(reason)) end
  end
end

local events = CreateFrame("Frame")
Ammo.EventFrame = events
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_CLOSED")
events:SetScript("OnEvent", function(_, event, unit)
  if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    Ammo:CheckAmmo(true)
  elseif event == "UNIT_INVENTORY_CHANGED" then
    if unit == "player" then Ammo:CheckAmmo(true) end
  elseif event == "BAG_UPDATE" then
    Ammo:CheckAmmo(true)
  elseif event == "MERCHANT_SHOW" then
    Ammo:OnMerchantShow()
  elseif event == "MERCHANT_CLOSED" and Ammo.UI and Ammo.UI.Refresh then
    Ammo.UI:Refresh()
  end
end)

-- Ammo totals can change as shots are fired without a bag event on every
-- client build, so perform a lightweight periodic check as a safety net.
local scanElapsed = 0
events:SetScript("OnUpdate", function(_, elapsed)
  scanElapsed = scanElapsed + elapsed
  if scanElapsed >= 4 then
    scanElapsed = 0
    Ammo:CheckAmmo(true)
  end
end)

SLASH_TAVERNERSAMMOGUARD1 = "/ammo"
SLASH_TAVERNERSAMMOGUARD2 = "/tammoguard"
SlashCmdList = SlashCmdList or {}
SlashCmdList.TAVERNERSAMMOGUARD = function(msg)
  msg = tostring(msg or ""):lower()
  if msg == "restock" then
    local ok, reason = Ammo:Restock()
    if not ok then Core.Notifications:Print(reason) end
  elseif msg == "check" then
    Ammo:CheckAmmo(true)
  elseif Ammo.UI then
    Ammo.UI:Toggle()
  end
end

Core.Diagnostics:Log("INFO", "Taverners Ammo Guard loaded.")
