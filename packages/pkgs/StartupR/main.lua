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
print("Delete Opus_Nova_Dual and depenency's")
term.write("  (y/n): ")
local answer = read():lower()

if answer == "y" or answer == "yes" then
    print("Deleting Opus_Nova_Dualboot")
    fs.delete("nova/packages/Opus_Nova_Dualboot.lua")
    print("Deleting depenency's")
    print("Deleting Startup_Restore")
    fs.delete("nova/packages/sr.lua")
    print("Deleting Opus_Installer")
    fs.delete("nova/packages/Opus_Installer.lua")
elseif answer == "n" or answer == "no" then
    print("Rename sr to Startup_Restore")
    fs.move("nova/packages/sr.lua, nova/packages/Startup_Restore.lua")
    sleep(0.7)
    print("Rebooting...")
    os.reboot()
else
print("Choose Y/N")
end

end
