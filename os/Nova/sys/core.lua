
local fs, term, shell, textutils = fs, term, shell, textutils

local PACKAGES_DIR = "/nova/packages"
local COMMANDS_FILE = "/nova/commands.lua"
local LOG_DIR = "/nova/logs"
local unpack = table.unpack or unpack

-- Ensure directories exist
if not fs.exists(PACKAGES_DIR) then fs.makeDir(PACKAGES_DIR) end
if not fs.exists(LOG_DIR) then fs.makeDir(LOG_DIR) end

-- Auto-create default commands.lua if missing
if not fs.exists(COMMANDS_FILE) then
  local ok, h = pcall(function() return fs.open(COMMANDS_FILE, "w") end)
  if ok and h then
    h.write([[
-- /nova/commands.lua (auto-created)
local commands = {}

commands.about = function(args)
  print("Nova Shell 1.0")
end

return commands
]])
    h.close()
  end
end

-- Load commands table safely
local function loadCommands()
  local ok, res = pcall(function() return dofile(COMMANDS_FILE) end)
  if ok and type(res) == "table" then return res end
  return {}
end

-- Return list of package names (no .lua)
local function listPackageNames()
  local out = {}
  if not fs.exists(PACKAGES_DIR) then return out end
  for _,f in ipairs(fs.list(PACKAGES_DIR)) do
    if f:sub(-4) == ".lua" then table.insert(out, f:sub(1, -5)) end
  end
  table.sort(out, function(a,b) return a:lower() < b:lower() end)
  return out
end

-- Build candidate list
local function buildCandidates()
  local candMap = {}
  local builtinList = { "help", "list", "exit", "quit", "clear" }
  for _,b in ipairs(builtinList) do candMap[b:lower()] = b end
  local commands = loadCommands()
  for name,fn in pairs(commands) do
    if type(name) == "string" and type(fn) == "function" then
      candMap[name:lower()] = name
    end
  end
  for _,pkg in ipairs(listPackageNames()) do
    candMap[pkg:lower()] = pkg
  end
  local candidates = {}
  for _,v in pairs(candMap) do table.insert(candidates, v) end
  table.sort(candidates, function(a,b) return a:lower() < b:lower() end)
  return candidates
end

-- Completion function
local function completion(text)
  local full = tostring(text or "")
  local prefix = full:match("^%s*(%S*)") or ""
  local lowPref = prefix:lower()
  local candidates = buildCandidates()
  if prefix == "" then return candidates end
  local matches = {}
  for _,c in ipairs(candidates) do
    if c:lower():sub(1, #lowPref) == lowPref then table.insert(matches, c) end
  end
  for _,c in ipairs(matches) do
    if c:lower() == lowPref then return {} end
  end
  if #matches == 0 then return {} end
  if #matches == 1 then
    local c = matches[1]
    local suffix = c:sub(#prefix + 1)
    if suffix == "" then return {} end
    return { suffix }
  end
  return matches
end

-- Helpers
local function splitWords(s)
  local t = {}
  for w in s:gmatch("%S+") do table.insert(t, w) end
  return t
end

local function sanitizeName(name)
  if not name or type(name) ~= "string" then return nil end
  if name:find("[/\\]") or name:find("%.%.") then return nil end
  if name:sub(-4) == ".lua" then name = name:sub(1, -5) end
  if name == "" then return nil end
  return name
end

-- Try to run package by name
local function tryRunPackageByName(name, args)
  local cands = {
    PACKAGES_DIR .. "/" .. name .. ".lua",
    PACKAGES_DIR .. "/" .. name:lower() .. ".lua",
    PACKAGES_DIR .. "/" .. name:upper() .. ".lua",
  }
  for _, path in ipairs(cands) do
    if fs.exists(path) then
      local ok, err = pcall(function()
        if args and #args > 0 then shell.run(path, unpack(args)) else shell.run(path) end
      end)
      if not ok then
        term.setTextColor(colors.lightBlue)
        print("Error running package:", err)
      end
      return true
    end
  end
  return false
end

local function listPackages()
  term.setTextColor(colors.lightBlue)
  local names = listPackageNames()
  if #names == 0 then print("(no packages found in " .. PACKAGES_DIR .. ")") return end
  for _,n in ipairs(names) do print(n) end
end

local function printHelp()
  term.setTextColor(colors.lightBlue)
  print("Nova Shell 1.0 - help")
  print("Commands: help, list, exit, quit, clear")
  local commands = loadCommands()
  local cmds = {}
  for name,fn in pairs(commands) do
    if type(name) == "string" and type(fn) == "function" then table.insert(cmds, name) end
  end
  if #cmds > 0 then
    table.sort(cmds, function(a,b) return a:lower() < b:lower() end)
    io.write("")
    for i,name in ipairs(cmds) do
      io.write(name)
      if i < #cmds then io.write(", ") end
    end
    print()
  end
  print(" To run a package, type its name.")
end

-- REPL
local function repl()
  term.setTextColor(colors.lightBlue)
  print("Welcome to Nova Shell 1.0 - type 'help' for more info.")
  while true do
    term.setTextColor(colors.purple)
    term.write("> ")
    term.setTextColor(colors.purple)
    local ok, line = pcall(function() return read(nil, nil, completion) end)
    term.setTextColor(colors.lightBlue)

    if not ok then print() break end
    if not line then print() break end

    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
      local parts = splitWords(line)
      local cmd = parts[1]
      local args = {}
      for i=2,#parts do args[#args+1] = parts[i] end

      if cmd == "help" then
        printHelp()
      elseif cmd == "list" then
        listPackages()
      elseif cmd == "exit" or cmd == "quit" then
        print("Bye.")
        break
      elseif cmd == "clear" then
        term.clear()
        term.setCursorPos(1,1)
      else
        local commands = loadCommands()
        local matched = false
        local lowerCmd = cmd:lower()
        for name,fn in pairs(commands) do
          if type(name) == "string" and type(fn) == "function" and name:lower() == lowerCmd then
            local ok2, err = pcall(function() fn(args) end)
            if not ok2 then print("Command error:", err) end
            matched = true
            break
          end
        end
        if not matched then
          local sane = sanitizeName(cmd)
          if not sane then
            print("Invalid package name.")
          else
            local ran = tryRunPackageByName(sane, args)
            if not ran then print("Package not found: " .. cmd) end
          end
        end
      end
    end
  end
end

-- Start shell
repl()
