local ADDON, S = ...
S.version = "0.21.0-beta"
S.media = "Interface\\AddOns\\" .. ADDON .. "\\media\\"
S.status, S.commands, S.options = {}, {}, {}
S.defaults = { motion = true, lowhealth = true, resources = true, indicators = true, cast = true, figures = true }
for key, value in pairs(S.defaults) do S.options[key] = value end
S.hidePlayer = true
S.colorMode, S.customColor = "power", {0.15, 0.4, 1}
function S.Secret(value) return issecretvalue and issecretvalue(value) end
function S.Readable(value) return not S.Secret(value) and type(value) == "number" end
function S.Report(module, state) S.status[module] = state end
function S.Run(module, fn, ...)
  local ok, err = pcall(fn, ...)
  if not ok then
    local message = tostring(err)
    if S.status[module] ~= message then print("|cffff6666Seraphglass " .. module .. ": " .. message .. "|r") end
    S.Report(module, message)
  end
  return ok
end
function S.Status()
  local version, build = GetBuildInfo()
  print("Seraphglass Orbs " .. S.version .. " / " .. version .. " build " .. build)
  for _, name in ipairs({"Orbs", "Effects", "Shield", "Cast ring", "Resources", "Indicators"}) do
    print(name .. ": " .. (S.status[name] or "waiting"))
  end
end
S.commands.status = S.Status
function S.Save()
  SeraphglassDB = SeraphglassDB or {}
  SeraphglassDB.orbs = SeraphglassDB.orbs or {}
  local db = SeraphglassDB.orbs
  db.options, db.colorMode, db.customColor = S.options, S.colorMode, S.customColor
  db.hidePlayer = S.hidePlayer
  if S.layout then db.layout = S.layout end
end
function S.Apply()
  if S.ApplyVisuals then S.ApplyVisuals() end
  if S.ApplyResources then S.ApplyResources() end
  if S.ApplyHUD then S.ApplyHUD() end
  if S.ApplyIndicators then S.ApplyIndicators() end
  S.Save()
end
S.commands.option = function(argument)
  local key, value = argument:match("^(%S+)%s+(%S+)$")
  if S.defaults[key] ~= nil and (value == "on" or value == "off") then
    S.options[key] = value == "on"; S.Apply()
    print("Seraphglass: " .. key .. " " .. value)
  else print("/sgui option motion|lowhealth|resources|indicators|cast|figures on|off") end
end
S.commands.color = function(argument)
  if argument == "power" or argument == "class" then S.colorMode = argument
  else
    local r,g,b = argument:match("^(%S+)%s+(%S+)%s+(%S+)$")
    r,g,b = tonumber(r),tonumber(g),tonumber(b)
    if not r or not g or not b or r<0 or r>1 or g<0 or g>1 or b<0 or b>1 then
      print("/sgui color power | class | R G B (0 to 1)"); return
    end
    S.colorMode, S.customColor = "custom", {r,g,b}
  end
  S.Apply()
end
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == ADDON then
    SeraphglassDB = type(SeraphglassDB) == "table" and SeraphglassDB or {}
    local db = type(SeraphglassDB.orbs) == "table" and SeraphglassDB.orbs or {}
    if type(db.options) == "table" then
      for k in pairs(S.defaults) do if type(db.options[k]) == "boolean" then S.options[k] = db.options[k] end end
    end
    if db.colorMode == "class" or db.colorMode == "power" or db.colorMode == "custom" then S.colorMode = db.colorMode end
    local c = db.customColor
    if type(c) == "table" then
      local valid = true
      for i=1,3 do if type(c[i]) ~= "number" or c[i]<0 or c[i]>1 then valid=false end end
      if valid then S.customColor = {c[1],c[2],c[3]} end
    end
    if type(db.hidePlayer) == "boolean" then S.hidePlayer = db.hidePlayer end
    if S.LoadLayout then S.LoadLayout(db.layout) end
    -- Old whole-UI options are retired; never restore their side effects.
    SeraphglassDB.options = nil
    S.Save()
  elseif event == "PLAYER_LOGIN" then
    S.Run("Orbs", S.Apply)
    print("|cffe7bd79Seraphglass Orbs " .. S.version .. " loaded. /sgui status|r")
  end
end)
