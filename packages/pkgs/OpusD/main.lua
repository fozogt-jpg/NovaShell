-- pre_install.lua
local fs = fs
local tempDir = "temp"
local tempFile = fs.combine(tempDir, "sn.lua")
local flagFile = fs.combine(tempDir, "onb")
local startupFile = "startup.lua"

-- Ensure temp folder exists
if not fs.exists(tempDir) then
    fs.makeDir(tempDir)
end

-- Save original startup.lua
if fs.exists(startupFile) then
    fs.move(startupFile, tempFile)
    print("Original startup.lua moved to " .. tempFile)
else
    print("No original startup.lua found.")
end

-- Create the onb flag for next boot
local f = fs.open(flagFile, "w")
f.write("1")
f.close()
print("Flag file created: " .. flagFile)

print("Ready to run the Opus installer.")
sleep(1)
fs.move("nova/packages/Startup_Restore.lua", "nova/packages/sr.lua")
print("Once in Opus open shell and run temp/sn.lua and, once in Nova run sr.")
sleep(1.8)
shell.run("nova/packages/Opus_Installer.lua")