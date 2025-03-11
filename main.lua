_W = display.contentWidth
_H = display.contentHeight
local loadSave = require("loadsave")
local composer = require("composer")

isHTML5 = system.getInfo("platform") == "html5"

if isHTML5 then
	local windowResizer = require("windowResizer")
  windowResizer:new()
end

rnd = math.random
lvl = 1
isDebug = false
numLvls = 21

function keyPressed(event)
	if event.phase == "up" and 	event.keyName == "tab" then
		if native.getProperty("windowMode") == "fullscreen" then
			native.setProperty("windowMode", "normal")
		else
			native.setProperty( "windowMode", "fullscreen" )
		end
	end
end

Runtime:addEventListener("key", keyPressed)


saveData = loadSave.loadTable("scores.json")

if saveData == nil then

	saveData = {
		locked = {
			false, true, true, true, true, true, true, -- 1
			true, true, true, true, true, true, true, -- 2
			true, true, true, true, true, true, true, -- 3
		},
	}

	-- print("highScores" .. highScores['hard'][1])
	-- print("highScores" .. highScores.hard[1])

	loadSave.saveTable(saveData, "scores.json")
end

print("saveData.locked:")
for i = 1, #saveData.locked do
  print('saveData.locked[' .. i .. "] = " .. tostring(saveData.locked[i]))
end


composer.gotoScene( "splash" )
