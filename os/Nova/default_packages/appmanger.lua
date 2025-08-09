-- nam - minimal Nova package manager wrapper (ComputerCraft)
-- Install/uninstall calls are executed exactly as requested and produce no extra output.

local fs = fs
local shell = shell

local REPO_PATH = "/nova/sys/config/pkgrepo.txt"
local REPO_DIR = "/nova/sys/config"

local INSTALL_SCRIPT = "/nova/sys/pkg-utils/install.lua"
local UNINSTALL_SCRIPT = "/nova/sys/pkg-utils/uninstall.lua"

local args = {...}
local cmd = args[1] and args[1]:lower()

local function usage()
  print("nam - Nova package manager wrapper")
  print("")
  print("Commands:")
  print("  nam install <pkg> [pkg2 ...]    - install package(s)")
  print("  nam uninstall <pkg> [pkg2 ...]  - uninstall package(s)")
  print("  nam repo                        - show configured repo URL(s)")
  print("  nam set repo <url>              - set repo to <url> (overwrites file)")
  print("  nam help                        - this message")
end

local function ensureRepoDir()
  if not fs.exists(REPO_DIR) then
    local parts = {}
    for part in string.gmatch(REPO_DIR, "[^/]+") do table.insert(parts, part) end
    local path = ""
    for i, p in ipairs(parts) do
      path = path .. "/" .. p
      if not fs.exists(path) then fs.makeDir(path) end
    end
  end
end

local function file_read(path)
  if not fs.exists(path) then return nil end
  local f = fs.open(path, "r")
  if not f then return nil end
  local txt = f.readAll()
  f.close()
  return txt
end

local function file_write(path, contents)
  ensureRepoDir()
  local f = fs.open(path, "w")
  if not f then return false, "failed to open file for writing: "..tostring(path) end
  f.write(contents)
  f.close()
  return true
end

-- If no command or help -> show usage
if not cmd or cmd == "help" or cmd == "-h" or cmd == "--help" then
  usage()
  return
end

-- INSTALL: call shell.run("/nova/sys/pkg-utils/install.lua", chosen)
if cmd == "install" then
  if not args[2] then
    print("Usage: nam install <package> [package2 ...]")
    return
  end
  for i = 2, #args do
    local chosen = args[i]
    -- exact call requested — DO NOT print anything else here
    shell.run(INSTALL_SCRIPT, chosen)
  end
  return
end

-- UNINSTALL: accept both 'uninstall' and common misspelling 'unistall'
-- call shell.run("/nova/sys/pkg-utils/uninstall.lua", "uninstall", chosen)
if cmd == "uninstall" or cmd == "unistall" then
  if not args[2] then
    print("Usage: nam uninstall <package> [package2 ...]")
    return
  end
  for i = 2, #args do
    local chosen = args[i]
    -- exact call requested — DO NOT print anything else here
    shell.run(UNINSTALL_SCRIPT, "uninstall", chosen)
  end
  return
end

-- repo: print file contents (allowed)
if cmd == "repo" then
  local txt = file_read(REPO_PATH)
  if not txt or txt == "" then
    print("No repo configured (file missing or empty): " .. REPO_PATH)
    return
  end
  print(txt)
  return
end

-- set repo: overwrite pkgrepo.txt with single URL
if cmd == "set" then
  local sub = args[2] and args[2]:lower()
  local url = args[3]
  if sub ~= "repo" or not url then
    print("Usage: nam set repo <url>")
    return
  end
  local ok, err = file_write(REPO_PATH, tostring(url) .. "\n")
  if not ok then
    print("Failed to write repo file: " .. tostring(err))
  end
  return
end

-- unknown command
print(("Unknown command: %s"):format(tostring(cmd)))
print("Type 'nam help' for usage.")
