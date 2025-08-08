-- /nova/apps/AppStore.lua
local http, fs, term, textutils, shell = http, fs, term, textutils, shell
local INDEX = "https://fozogt.github.io/NovaShell/packages/pkgs.json"

if not http then
  print("Error: HTTP API disabled"); return
end

-- fetch index
local res = http.get(INDEX)
if not res then error("Cannot fetch app index") end
local index = textutils.unserializeJSON(res.readAll())
res.close()

-- prompt
term.clear()
term.setCursorPos(1,1)
print("Nova AppStore")
print()
io.write("Search (empty=all): ")
local query = read():lower()

-- build list
local list = {}
for name,info in pairs(index) do
  if query=="" or name:lower():find(query) or info.description:lower():find(query) then
    table.insert(list, { name=name, desc=info.description })
  end
end

if #list==0 then
  print("\nNo matches."); print("Press any key to return.")
  os.pullEvent("key"); return
end

table.sort(list, function(a,b) return a.name<b.name end)

-- display
term.clear()
term.setCursorPos(1,1)
print("Results for '"..query.."':\n")
for i,app in ipairs(list) do
  print(i..". "..app.name.." - "..app.desc)
end

print("\nEnter number to toggle install/uninstall, or empty to exit.")
io.write("> ")
local sel = tonumber(read() or "")
if not sel or sel<1 or sel>#list then return end

local chosen = list[sel].name
local pkgPath = "/nova/packages/"..chosen..".lua"

-- install or uninstall
if fs.exists(pkgPath) then
  shell.run("/nova/uninstall.lua", "uninstall", chosen)
else
  shell.run("/nova/install.lua",   chosen)
end

print("\nDone. Press any key to return.")
os.pullEvent("key")
