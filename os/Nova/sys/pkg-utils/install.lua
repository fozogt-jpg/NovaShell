local http, fs, textutils, shell = http, fs, textutils, shell

local name = ...
if not name then
  print("Usage: install <appName>")
  return
end

-- read repository URL from config
local repoConfigPath = "/nova/sys/config/pkgrepo.txt"
if not fs.exists(repoConfigPath) then
  error("Package repo config missing: " .. repoConfigPath)
end

local repoFile = fs.open(repoConfigPath, "r")
local INDEX = repoFile.readAll():gsub("%s+$", "")
repoFile.close()

-- fetch package index
local res = http.get(INDEX)
if not res then error("Cannot fetch package index from " .. INDEX) end
local index = textutils.unserializeJSON(res.readAll())
res.close()

local info = index[name]
if not info or not info.url then
  error("No such package: " .. name)
end

-- ensure packages dir exists
if not fs.exists("/nova/packages") then
  fs.makeDir("/nova/packages")
end

-- download and save package
local pkgRes, err = http.get(info.url)
if not pkgRes then error("Failed to download " .. info.url .. " (" .. tostring(err) .. ")") end
local data = pkgRes.readAll()
pkgRes.close()

local path = "/nova/packages/" .. name .. ".lua"
local file = fs.open(path, "w")
file.write(data)
file.close()

print("Installed " .. name)

-- call dependency resolver
if fs.exists("/nova/sys/pkg-utils/depend.lua") then
  shell.run("/nova/sys/pkg-utils/depend.lua", name)
end
