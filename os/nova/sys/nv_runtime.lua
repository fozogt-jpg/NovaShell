-- Nova Script Runtime (nv_runtime.lua)
-- Low-level Lua interpreter for .nv (Nova Script) files.
-- This is the only Lua component bridging CraftOS and Nova Script.

local nv = {}

-- Translate Nova Script source to valid Lua source.
-- .nv keywords:
--   fn      -> function
--   let     -> local
--   ret     -> return
--   //...   -> --...  (line comment)
local function translateNV(source)
    local out = {}
    for line in (source .. "\n"):gmatch("([^\n]*)\n") do
        -- Convert // line comments to -- (only when not inside a string)
        local result = line:gsub("^(%s*)//(.*)$", "%1--%2")
        -- Replace keywords at word boundaries
        result = result:gsub("%f[%a]fn%f[%A]",  "function")
        result = result:gsub("%f[%a]let%f[%A]", "local")
        result = result:gsub("%f[%a]ret%f[%A]", "return")
        out[#out + 1] = result
    end
    return table.concat(out, "\n")
end

-- Run a .nv file with optional arguments.
function nv.run(path, ...)
    if not fs.exists(path) then
        error("NV: file not found: " .. tostring(path), 2)
    end
    local f = fs.open(path, "r")
    if not f then
        error("NV: cannot open: " .. tostring(path), 2)
    end
    local source = f.readAll()
    f.close()

    local luaSrc = translateNV(source)
    local fn, err = load(luaSrc, "@" .. path, "t", _ENV)
    if not fn then
        error("NV compile error [" .. path .. "]: " .. tostring(err), 2)
    end
    return fn(...)
end

-- Translate a Nova Script source string to a Lua source string.
function nv.translate(source)
    return translateNV(source)
end

-- Evaluate a Nova Script string directly.
function nv.eval(source, chunkName, ...)
    local luaSrc = translateNV(source)
    local fn, err = load(luaSrc, chunkName or "=(nv eval)", "t", _ENV)
    if not fn then
        error("NV compile error: " .. tostring(err), 2)
    end
    return fn(...)
end

return nv
