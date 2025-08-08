-- Auto-generated Nova installer
local root = "https://fozogt-jpg.github.io/NovaShell/os"
local files = {
  { url = root.."/bootscreen.lua", path = "/bootscreen.lua" },
  { url = root.."/editstartupoptions.lua", path = "/editstartupoptions.lua" },
  { url = root.."/nova.lua", path = "/nova.lua" },
  { url = root.."/reboot1.lua", path = "/reboot1.lua" },
  { url = root.."/shutdown1.lua", path = "/shutdown1.lua" },
  { url = root.."/startup.lua", path = "/startup.lua" },
  { url = root.."/startupoptions.txt", path = "/startupoptions.txt" },
  { url = root.."/Nova/core.lua", path = "/nova/core.lua" },
  { url = root.."/Nova/install.lua", path = "/nova/install.lua" },
  { url = root.."/Nova/uninstall.lua", path = "/nova/uninstall.lua" },
  { url = root.."/Nova/default_packages/appstore.lua", path = "/nova/packages/NovaStore.lua" },
}

-- ensure HTTP API is available
if not http then
  print("Error: HTTP API disabled")
  return
end

-- create directories
local function ensureDir(p)
  local dir = p:match("(.+)/[^/]+$")
  if dir and not fs.exists(dir) then
    fs.makeDir(dir)
  end
end

-- download a single file
local function download(f)
  print("Downloading "..f.url.." -> "..f.path)
  
  if f.path == "/startup.lua" and fs.exists("/startup.lua") then
    print("  Existing startup.lua found. Renaming to startup_old.lua")
    if fs.exists("/startup_old.lua") then fs.delete("/startup_old.lua") end
    fs.move("/startup.lua", "/startup_old.lua")
  elseif fs.exists(f.path) then
    print("  Deleting old version of "..f.path)
    fs.delete(f.path)
  end

  local res = http.get(f.url)
  if not res then
    print("  FAILED to fetch "..f.url)
    return false
  end

  ensureDir(f.path)

  local h = fs.open(f.path, "w")
  h.write(res.readAll())
  h.close()
  res.close()
  return true
end

-- install all files
for _, f in ipairs(files) do
  if not download(f) then
    print("Installation aborted.")
    return
  end
end

-- create packages folder
if not fs.exists("/nova/packages") then
  fs.makeDir("/nova/packages")
end

print()
print("Installation complete")
print("Reboot to start Nova OS:  reboot")
