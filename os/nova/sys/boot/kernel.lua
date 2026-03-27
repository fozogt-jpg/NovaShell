-- Nova OS v5.1 — kernel.lua
-- Low-level Lua bootstrapper.  The only job of this file is to load the
-- Nova Script runtime (nv_runtime.lua) and hand control to kernel.nv.
-- All real kernel logic lives in kernel.nv (Nova Script).

local term = term
local fs   = fs

-- Load the Nova Script runtime from its canonical location.
local runtimePath = "/nova/.sys/nv_runtime.lua"
if not fs.exists(runtimePath) then
    term.setTextColor(colors.red)
    print("[Error] nv_runtime.lua not found at " .. runtimePath)
    print("Cannot boot — Nova Script runtime is missing.")
    term.setTextColor(colors.white)
    sleep(3)
    return
end

local ok, nv = pcall(dofile, runtimePath)
if not ok or type(nv) ~= "table" then
    term.setTextColor(colors.red)
    print("[Error] Failed to load nv_runtime: " .. tostring(nv))
    term.setTextColor(colors.white)
    sleep(3)
    return
end

-- Delegate everything to kernel.nv (Nova Script).
local kernelNV = "/nova/.sys/boot/kernel.nv"
if not fs.exists(kernelNV) then
    term.setTextColor(colors.red)
    print("[Error] kernel.nv not found — cannot boot.")
    term.setTextColor(colors.white)
    sleep(3)
    return
end

nv.run(kernelNV)
