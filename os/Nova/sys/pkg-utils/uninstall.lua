
local fs = fs

local mode, name = ...
if mode ~= "uninstall" or not name then
  print("Usage: uninstall <appName>")
  return
end

local path = "/nova/packages/"..name..".lua"
if fs.exists(path) then
  fs.delete(path)
  print("Uninstalled "..name)
else
  print("Package not found: "..name)
end
