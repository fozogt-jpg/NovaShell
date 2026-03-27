-- Nova OS v5.1 — bios.lua
-- Minimal Lua launcher: loads nv_runtime and runs bios.nv (Nova Script).
local fs = fs
local ok, nv = pcall(dofile, "/nova/.sys/nv_runtime.lua")
if not ok or type(nv) ~= "table" then
    term.setTextColor(colors.red)
    print("[bios] nv_runtime unavailable: " .. tostring(nv))
    term.setTextColor(colors.white)
    return
end
local nvFile = "/nova/.sys/bios.nv"
if fs.exists(nvFile) then
    nv.run(nvFile)
else
    term.setTextColor(colors.red); print("[bios] bios.nv not found"); term.setTextColor(colors.white)
end
