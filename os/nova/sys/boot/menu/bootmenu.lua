-- Nova OS v5.1 — bootmenu.lua
-- Minimal Lua launcher: loads nv_runtime and runs bootmenu.nv (Nova Script).
local fs = fs
local ok, nv = pcall(dofile, "/nova/.sys/nv_runtime.lua")
if not ok or type(nv) ~= "table" then
    term.setTextColor(colors.red)
    print("[bootmenu] nv_runtime unavailable: " .. tostring(nv))
    term.setTextColor(colors.white)
    return
end
local nvFile = "/nova/.sys/boot/menu/bootmenu.nv"
if fs.exists(nvFile) then
    nv.run(nvFile)
else
    term.setTextColor(colors.red); print("[bootmenu] bootmenu.nv not found"); term.setTextColor(colors.white)
end
