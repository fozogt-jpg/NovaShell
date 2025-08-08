

local fs = fs
local term = term

local PACKAGES_DIR = "/nova/packages"

-- ensure packages dir exists
if not fs.exists(PACKAGES_DIR) then
  fs.makeDir(PACKAGES_DIR)
end

local function splitWords(s)
  local t = {}
  for word in s:gmatch("%S+") do table.insert(t, word) end
  return t
end

local function listPackages()
  if not fs.exists(PACKAGES_DIR) then
    print("(no packages directory)")
    return
  end
  local items = fs.list(PACKAGES_DIR)
  local printed = false
  for _,name in ipairs(items) do
    if name:sub(-4) == ".lua" then
      print(name:sub(1, -5))
      printed = true
    end
  end
  if not printed then print("(no .lua packages found in " .. PACKAGES_DIR .. ")") end
end

local function packagePath(name)
  -- allow either "foo" or "foo.lua"
  if name:sub(-4) == ".lua" then
    return PACKAGES_DIR .. "/" .. name
  else
    return PACKAGES_DIR .. "/" .. name .. ".lua"
  end
end

local function runPackage(name, args)
  local path = packagePath(name)
  if not fs.exists(path) then
    print("Package not found: " .. name)
    return false
  end

  -- read file
  local handle, err = fs.open(path, "r")
  if not handle then
    print("Error opening package: " .. tostring(err))
    return false
  end
  local src = handle.readAll()
  handle.close()

  -- prepare env where package gets arg and inherits global _G
  local env = { arg = args or {} }
  setmetatable(env, { __index = _G })

  -- try to load the chunk in a way compatible with both Lua 5.1 and 5.2+ used by CC variants
  local chunk, loadErr

  -- try load with environment (Lua 5.2+)
  local ok, try = pcall(function() return load(src, "@"..path, "t", env) end)
  if ok and try then
    chunk = try
  else
    -- fallback: load then setfenv (Lua 5.1 / setfenv available)
    local loaded, le = load(src, "@"..path)
    if loaded and setfenv then
      setfenv(loaded, env)
      chunk = loaded
    else
      loadErr = le or try -- whichever error we got
    end
  end

  if not chunk then
    print("Error loading package '"..name.."': " .. tostring(loadErr))
    return false
  end

  -- run in protected mode, show traceback on error
  local ok, err = xpcall(chunk, debug.traceback)
  if not ok then
    print("Error running package '"..name.."':")
    print(err)
    return false
  end

  return true
end

-- builtin commands
local builtins = {
  ["help"] = function()
    print("nova shell - commands:")
    print("  help             show this help")
    print("  list             list packages in " .. PACKAGES_DIR)
    print("  run <pkg> [...]  run a package explicitly")
    print("  exit / quit      leave nova shell")
    print("  clear            clear the screen")
    print("")
    print("To run a package just type its name (e.g. mypkg arg1 arg2).")
  end,
  ["list"] = function() listPackages() end,
  ["run"] = function(args)
    if #args < 1 then
      print("Usage: run <package> [args...]")
      return
    end
    local pkg = table.remove(args, 1)
    runPackage(pkg, args)
  end,
  ["clear"] = function() term.clear(); term.setCursorPos(1,1) end,
}

-- main REPL
local function repl()
  print("Welcome to Nova Shell")
  print("Packages dir: " .. PACKAGES_DIR)
  print("Type 'help' for commands.")
  while true do
    io.write("> ")
    local line = read()
    if not line then -- EOF / ctrl-D
      print()
      break
    end
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line == "" then goto continue end

    local parts = splitWords(line)
    local cmd = parts[1]
    local args = {}
    for i=2,#parts do args[#args+1] = parts[i] end

    -- builtins
    if builtins[cmd] then
      builtins[cmd](args)
      goto continue
    end

    -- exit aliases
    if cmd == "exit" or cmd == "quit" then
      print("Leaving Nova Shell.")
      break
    end

    -- try to run as package
    local ok = runPackage(cmd, args)
    if not ok then
      print("Unknown command or package: " .. cmd)
    end

    ::continue::
  end
end

-- if executed as a program, start REPL
repl()
