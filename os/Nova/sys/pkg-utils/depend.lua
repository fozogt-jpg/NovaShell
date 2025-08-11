local http, fs, textutils, shell = http, fs, textutils, shell

local name = ...
if not name then
  print("Usage: dependency <appName>")
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
if not info or not info.durl then
  return -- no dependency list for this app
end

-- fetch dependency list
local depRes = http.get(info.durl)
if not depRes then
  error("Failed to fetch dependency list for " .. name)
end
local deps = textutils.unserializeJSON(depRes.readAll())
depRes.close()

if type(deps) ~= "table" or #deps == 0 then
  return -- no dependencies to install
end

print("Installing dependencies for " .. name .. ": " .. table.concat(deps, ", "))

-- install each dependency
for _, depName in ipairs(deps) do
  shell.run("/nova/sys/pkg-utils/install.lua", depName)
end

