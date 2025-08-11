print("To Install Opus click next and at the end begin.")
sleep(1)
shell.run("nova/packages/Opus_Installer.lua")
local fs = fs
local tempDir = "temp"
local tempFile = fs.combine(tempDir, "sn.lua")
local startupFile = "startup.lua"
local optionsFile = "nova/sys/boot/options.text"
local lineToAdd = "Opus\tsys/boot/opus.lua"

-- Ensure temp folder exists
if not fs.exists(tempDir) then
    fs.makeDir(tempDir)
end

-- Step 1: Move original startup.lua → temp/sn.lua
if fs.exists(startupFile) then
    fs.move(startupFile, tempFile)
    print("Original startup.lua moved to " .. tempFile)
else
    print("No original startup.lua found, stopping.")
    return
end

-- Step 2: Wait for a NEW startup.lua to appear
print("Waiting for a new startup.lua to appear...")
while not fs.exists(startupFile) do
    sleep(0.5)
end

-- Step 3: Delete the new startup.lua
fs.delete(startupFile)
print("New startup.lua deleted.")

-- Step 4: Restore original from temp/sn.lua
if fs.exists(tempFile) then
    fs.move(tempFile, startupFile)
    print("Restored original startup.lua.")
else
    print("Error: temp/sn.lua missing!")
    return
end

-- Step 5: Append the line to options.text
local f = fs.open(optionsFile, "a")
if f then
    f.write(lineToAdd .. "\n")
    f.close()
    print("Added line to " .. optionsFile)
else
    print("Could not open " .. optionsFile)
end
