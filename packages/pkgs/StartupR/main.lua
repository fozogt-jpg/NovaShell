-- restore_on_next_boot.lua
local fs = fs
local tempDir = "temp"
local tempFile = fs.combine(tempDir, "sn.lua")
local flagFile = fs.combine(tempDir, "onb")
local startupFile = "startup.lua"

-- If flag exists, restore startup.lua
if fs.exists(flagFile) then
    print("Restoring original startup.lua...")
    fs.delete(flagFile)

    if fs.exists(startupFile) then
        fs.delete(startupFile)
    end

    if fs.exists(tempFile) then
        fs.move(tempFile, startupFile)
        print("startup.lua restored.")
    else
        print("Error: original startup.lua not found in " .. tempFile)
    end

    print("Rebooting...")
    os.reboot()
end
