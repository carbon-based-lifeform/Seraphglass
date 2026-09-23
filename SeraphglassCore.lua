-- Shared diagnostics and options. Module failures are reported, never silent.
local ADDON, S = ...
S.version = "0.15.0-beta"
S.status = {}
S.commands = {}
S.defaults = { focus = true, vignette = true, lowhealth = true, dispel = true, visibility = false }
S.options = {}
for key, value in pairs(S.defaults) do S.options[key] = value end
function S.Report(module, state) S.status[module] = state end
function S.Run(module, callback, ...)
  local ok, err = pcall(callback, ...)
  if not ok then
    local message = tostring(err)
    if S.status[module] ~= message then print("|cffff6666Seraphglass " .. module .. ": " .. message .. "|r") end
    S.Report(module, message)
  end
  return ok
end
function S.Status()
  local version, build, _, interface = GetBuildInfo()
  print("Seraphglass " .. S.version .. " / " .. version .. " build " .. build .. " / interface " .. interface)
  for _, name in ipairs({ "Orbs", "Inventory", "Action bars", "Damage meter", "Roth details", "Low health", "Dispel", "Vignettes" }) do
    print(name .. ": " .. (S.status[name] or "not initialized"))
  end
end
S.commands.status = S.Status
S.commands.option = function(argument)
  local key, value = argument:match("^(%S+)%s+(%S+)$")
  if key and S.defaults[key] ~= nil and (value == "on" or value == "off") then
    S.options[key] = value == "on"
    SeraphglassDB = SeraphglassDB or { options = {} }
    SeraphglassDB.options[key] = S.options[key]
    if S.ApplyOptions then S.ApplyOptions() end
    print("Seraphglass: " .. key .. " " .. value)
  else
    print("/sgui option focus|vignette|lowhealth|dispel|visibility on|off")
  end
end
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, name)
  if name ~= ADDON then return end
  SeraphglassDB = type(SeraphglassDB) == "table" and SeraphglassDB or {}
  SeraphglassDB.options = type(SeraphglassDB.options) == "table" and SeraphglassDB.options or {}
  for key in pairs(S.defaults) do
    if type(SeraphglassDB.options[key]) == "boolean" then S.options[key] = SeraphglassDB.options[key] end
  end
  print("|cffe7bd79Seraphglass " .. S.version .. " loaded. /sgui status|r")
end)
