-- Nova OS v5.1 — nova.lua
-- Minimal Lua launcher: loads nv_runtime and runs nova.nv (Nova Script).
local fs = fs
local ok, nv = pcall(dofile, "/nova/.sys/nv_runtime.lua")
if not ok or type(nv) ~= "table" then
    -- Fallback: workspace launch without runtime (should not happen in v5.1)
    term.setTextColor(colors.red)
    print("[nova] nv_runtime unavailable: " .. tostring(nv))
    term.setTextColor(colors.white)
    return
end
local nvFile = "/nova/.sys/boot/nova.nv"
if fs.exists(nvFile) then
    nv.run(nvFile)
else
    term.setTextColor(colors.red); print("[nova] nova.nv not found"); term.setTextColor(colors.white)
end
