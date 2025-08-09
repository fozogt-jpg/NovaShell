
local http, fs, textutils = http, fs, textutils

local name = ...
if not name then
  print("Usage: install <appName>")
  return
end

-- fetch index
local INDEX = "https://jxoj.github.io/CC/Nova/apps/packages.json"
local res = http.get(INDEX)
if not res then error("Cannot fetch package index") end
local index = textutils.unserializeJSON(res.readAll())
res.close()

local info = index[name]
if not info or not info.url then
  error("No such package: "..name)
end

-- ensure packages dir
if not fs.exists("/nova/packages") then
  fs.makeDir("/nova/packages")
end

-- download and save
local pkgRes, err = http.get(info.url)
if not pkgRes then error("Failed to download "..info.url.." ("..tostring(err)..")") end
local data = pkgRes.readAll()
pkgRes.close()

local path = "/nova/packages/"..name..".lua"
local file = fs.open(path, "w")
file.write(data)
file.close()

print("Installed "..name)
