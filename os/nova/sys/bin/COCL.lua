-- COCL — CraftOS Compat Layer (bin/COCL.lua)
-- Lets you run standard CraftOS .lua programs on Nova OS by live-translating
-- them to Nova Script (.nv) and executing through the nv_runtime.
--
-- Usage:
--   COCL <file.lua>       Run a Lua program via the .nv runtime
--   COCL --show <file.lua>  Print the translated .nv source before running
--   COCL                  Interactive REPL: type Lua, run as .nv

local term   = term
local colors = colors
local fs     = fs
local shell  = shell

-- ── Load the Nova Script runtime ─────────────────────────────────────────────
local runtimePath = "/nova/.sys/nv_runtime.lua"
local ok, nv = pcall(dofile, runtimePath)
if not ok or type(nv) ~= "table" then
    term.setTextColor(colors.red)
    print("[COCL] ERROR: Cannot load nv_runtime at " .. runtimePath)
    print(tostring(nv))
    term.setTextColor(colors.white)
    return
end

-- ── Lua → .nv translation (reverse of nv_runtime's translateNV) ──────────────
local function luaToNV(source)
    local out = {}
    for line in (source .. "\n"):gmatch("([^\n]*)\n") do
        local result = line
        -- Replace Lua keywords with .nv equivalents (word boundaries)
        result = result:gsub("%f[%a]function%f[%A]", "fn")
        result = result:gsub("%f[%a]local%f[%A]",    "let")
        result = result:gsub("%f[%a]return%f[%A]",   "ret")
        out[#out + 1] = result
    end
    return table.concat(out, "\n")
end

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function printHeader()
    term.setTextColor(colors.purple)
    print("=== COCL — CraftOS Compat Layer ===")
    term.setTextColor(colors.lightGray)
    print("Live-translates Lua -> Nova Script (.nv) -> executes via nv_runtime")
    term.setTextColor(colors.white)
end

local function runFile(path, showSource)
    if not fs.exists(path) then
        term.setTextColor(colors.red)
        print("[COCL] File not found: " .. path)
        term.setTextColor(colors.white)
        return
    end

    local f = fs.open(path, "r")
    if not f then
        term.setTextColor(colors.red)
        print("[COCL] Cannot open: " .. path)
        term.setTextColor(colors.white)
        return
    end
    local luaSrc = f.readAll()
    f.close()

    -- Convert Lua → .nv → Lua (round-trip through translation layers)
    local nvSrc  = luaToNV(luaSrc)

    if showSource then
        term.setTextColor(colors.yellow)
        print("-- [COCL] Translated .nv source for: " .. path)
        term.setTextColor(colors.white)
        print(nvSrc)
        print("-- [COCL] Running translated source...")
    else
        term.setTextColor(colors.lightGray)
        print("[COCL] Translating " .. path .. " -> .nv -> executing...")
        term.setTextColor(colors.white)
    end

    -- Write translated source to a temp .nv file, run it, then delete
    local tmpPath = "/nova/.sys/.cocl_tmp.nv"
    local tf = fs.open(tmpPath, "w")
    if not tf then
        term.setTextColor(colors.red)
        print("[COCL] Cannot write temp file: " .. tmpPath)
        term.setTextColor(colors.white)
        return
    end
    tf.write(nvSrc)
    tf.close()

    local runOk, runErr = pcall(nv.run, tmpPath)
    pcall(fs.delete, tmpPath)

    if not runOk then
        term.setTextColor(colors.red)
        print("[COCL] Runtime error: " .. tostring(runErr))
        term.setTextColor(colors.white)
    end
end

-- ── Interactive REPL ──────────────────────────────────────────────────────────
local function runREPL()
    printHeader()
    term.setTextColor(colors.lightGray)
    print("Interactive mode. Type Lua code, press Enter to run.")
    print("Type 'exit' or press Ctrl+T to quit.")
    term.setTextColor(colors.white)

    local buf = {}
    while true do
        if #buf == 0 then
            term.setTextColor(colors.purple); io.write("cocl> ")
        else
            term.setTextColor(colors.lightGray); io.write("  ... ")
        end
        term.setTextColor(colors.white)
        local line = read()
        if line == nil or line == "exit" then
            print("[COCL] Exiting.")
            break
        end
        table.insert(buf, line)
        local combined = table.concat(buf, "\n")
        -- Try to compile; if incomplete wait for more lines
        local nvSrc = luaToNV(combined)
        local testFn, testErr = load(nv.translate(nvSrc), "=(cocl)", "t", _ENV)
        if testFn then
            buf = {}
            local runOk, runErr = pcall(nv.eval, nvSrc, "=(cocl)")
            if not runOk then
                term.setTextColor(colors.red)
                print("[COCL] " .. tostring(runErr))
                term.setTextColor(colors.white)
            end
        else
            -- Check if it looks like an incomplete chunk; if not, flush error
            if not testErr:find("<eof>") then
                term.setTextColor(colors.red)
                print("[COCL] " .. tostring(testErr))
                term.setTextColor(colors.white)
                buf = {}
            end
            -- else: continue collecting lines
        end
    end
end

-- ── Entry point ───────────────────────────────────────────────────────────────
local args = { ... }
if #args == 0 then
    runREPL()
elseif args[1] == "--show" and args[2] then
    printHeader()
    runFile(args[2], true)
else
    printHeader()
    runFile(args[1], false)
end
