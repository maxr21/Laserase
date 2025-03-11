local composer = require( "composer" )
local loadSave = require("loadsave")

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------
local world1Top = {0.2, 0.2, 1,}
local world1Bottom = {0.6, 0.6, 1,}

local world3Top = {0.7, 0.7, 0.7,}
local world3Bottom = {0.2, 0.2, 0.2,}

local click = audio.loadSound( "zapsplat_household_fan_desk_speed_switch_dial_click_turn_three_positions_002_26838.mp3" )
local bgMusic = audio.loadStream("music_zapsplat_on_the_up_120.mp3" )

local bgImage, bgImage2, bgImage3
local square
local bg
local lvlButtons = {}
local bgGroup
local scrollButtonL
local scrollButtonR
local scrolling = false
local counter = 0
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function updateGame (event)
  counter = counter + 0.03

  local frac = bgGroup.x/(-2*_W)

  local paint = {
    type = "gradient",
    color1 = {
      (1-frac)*world1Top[1]+frac*world3Top[1],
      (1-frac)*world1Top[2]+frac*world3Top[2],
      (1-frac)*world1Top[3]+frac*world3Top[3],

    },
    color2 = {
      (1-frac)*world1Bottom[1]+frac*world3Bottom[1],
      (1-frac)*world1Bottom[2]+frac*world3Bottom[2],
      (1-frac)*world1Bottom[3]+frac*world3Bottom[3],

    },
    direction = "down",

  }

  bg.fill = paint

  bgImage.fill.effect.xTexels = 0 + math.sin(counter)*8
  bgImage.fill.effect.yTexels = 0 + math.cos(counter)*8

  bgImage2.fill.effect.xTexels = 0 + math.sin(counter)*8
  bgImage2.fill.effect.yTexels = 0 + math.cos(counter)*8

  bgImage3.fill.effect.xTexels = 0 + math.sin(counter)*8
  bgImage3.fill.effect.yTexels = 0 + math.cos(counter)*8

end

function scrollingComplete ()
  print("WORKED scroll")


  scrolling = false
  if bgGroup.x >= 0 then
    scrollButtonL.alpha = 0.5
  else
    scrollButtonL.alpha = 1
  end


  if bgGroup.x <= -3000 then
    scrollButtonR.alpha = 0.5
  else
    scrollButtonR.alpha = 1
  end


end


function lvlTouch (event)
  if event.phase == "ended" then
    print(event.target.id)
    lvl = event.target.id
    audio.play( click )

    composer.gotoScene( "game", {effect = "zoomInOut", time = 1000} )
  end
end


function scrollTchL (e)
  if e.phase == "ended" then
    print("L touch")

    if bgGroup.x < 0  and scrolling == false then
      scrolling = true
        audio.play(click)
        transition.to( bgGroup, {time = 1000, x = bgGroup.x + _W, onComplete = scrollingComplete, transition = easing.inOutQuad} )
        transition.to(scrollButtonL, { time = 100, alpha = 0.5})
        transition.to(scrollButtonR, { time = 100, alpha = 0.5})

    end
  end
end

function scrollTchR (e)
  if e.phase == "ended" then

    print("R touch")
    print(bgGroup.x, scrolling)
    if bgGroup.x >= -3000 and scrolling == false then
      print(">-3000")
        scrolling = true
        transition.to( bgGroup, {time = 1000, x = bgGroup.x - _W, onComplete = scrollingComplete, transition = easing.inOutQuad} )
        transition.to(scrollButtonR, { time = 100, alpha = 0.5})
        transition.to(scrollButtonL, { time = 100, alpha = 0.5})
        audio.play( click )

    end
  end
end

local function resetGame (event)
  if event.action == 'clicked' then
    if event.index == 1 then
      saveData = nil

      saveData = {
    		locked = {
    			false, true, true, true, true, true, true, -- 1
    			true, true, true, true, true, true, true, -- 2
    			true, true, true, true, true, true, true, -- 3
    		},
    	}
      loadSave.saveTable(saveData, "scores.json")

      composer.gotoScene( 'splash' )
      bgGroup.x = 0
      print('reset')
    elseif event.index == 2 then
      print('no reset')
    end
  end
end

local function askReset (event)
  if event.phase == 'ended' then
    native.showAlert( 'New Player?', 'Do you want to reset game progress?' , {'Yes', 'No'} , resetGame)
  end
end

-- create()
function scene:create( event )

    audio.play(bgMusic, {loops = -1})

    local sceneGroup = self.view
    bgGroup = display.newGroup()
    sceneGroup:insert(bgGroup)
    -- Code here runs when the scene is first created but has not yet appeared on screen
    bg =display.newRect(bgGroup, 0, 0.5*_H, _W*3, _H )
    bg.anchorX = 0

    bgImage = display.newImageRect( bgGroup, "city.png", _W, _H )

    bgImage.fill.effect = "filter.colorChannelOffset"

    bgImage.fill.effect.xTexels = 0
    bgImage.fill.effect.yTexels = 8

    bgImage.x = 0.5*_W
    bgImage.y = 0.5*_H

    bgImage2 = display.newImageRect(bgGroup, "house.png", _W, _H)
    bgImage2.x = _W*1.5
    bgImage2.y = 0.5*_H

    bgImage2.fill.effect = "filter.colorChannelOffset"

    bgImage2.fill.effect.xTexels = 0
    bgImage2.fill.effect.yTexels = 8

    bgImage3 = display.newImageRect( bgGroup, "factory.png", _W, _H )
    bgImage3.x = _W*2.5
    bgImage3.y = _H*0.5

    bgImage3.fill.effect = "filter.colorChannelOffset"

    bgImage3.fill.effect.xTexels = 0
    bgImage3.fill.effect.yTexels = 8

    local verticesR = {0.85*_W, 0.5*_H, 0.8*_W, 0.45*_H, 0.8*_W, 0.55*_H}
    scrollButtonR = display.newPolygon(sceneGroup, 0.9*_W, 0.15*_H,verticesR)
    scrollButtonR.strokeWidth = 5
    scrollButtonR:setStrokeColor(0,0,0)


    local verticesL = {0.05*_W, 0.5*_H, 0.1*_W, 0.45*_H, 0.1*_W, 0.55*_H}
    scrollButtonL = display.newPolygon( sceneGroup, 0.1*_W, 0.15*_H,verticesL)
    scrollButtonL.alpha = 0.5
    scrollButtonL.strokeWidth = 5
    scrollButtonL:setStrokeColor(0,0,0)

    local titleShadow = display.newText( {parent = sceneGroup, x = 0.508*_W, y = 0.858*_H, text = "LASERASE:\nDemoliton in the future", fontSize = 100, font = "MajorMonoDisplay-Regular.ttf"} )
    titleShadow:setFillColor(0, 0, 0, 0.5)
    local title = display.newText( {parent = sceneGroup, x = 0.5*_W, y = 0.85*_H, text = "LASERASE:\nDemoliton in the future", fontSize = 100, font = "MajorMonoDisplay-Regular.ttf"} )


    local paint = {
      type = "gradient",
      color1 = world1Top,
      color2 = world1Bottom,
      direction = "down",

    }

    bg.fill = paint

    local lvlPos = {
      0.1*_W, 0.55*_H,
      0.45*_W, 0.2*_H,
      0.5*_W, 0.55*_H,
      0.65*_W, 0.75*_H,
      0.75*_W, 0.75*_H,
      0.9*_W ,0.3*_H,
      0.95*_W, 0.65*_H,



      1.1*_W, 0.65*_H,
      1.2*_W, 0.3*_H,
      1.28*_W, 0.7*_H,
      1.4*_W, 0.7*_H,
      1.5*_W, 0.7*_H,
      1.65*_W, 0.7*_H,
      1.8*_W, 0.65*_H,



      2.1*_W, 0.65*_H,
      2.3*_W, 0.65*_H,
      2.4*_W, 0.65*_H,
      2.5*_W, 0.3*_H,
      2.6*_W, 0.75*_H,
      2.77*_W, 0.75*_H,
      2.9*_W, 0.45*_H,
    }
    for i = 1, numLvls do
      lvlButtons[i] = display.newImageRect( bgGroup, "lvl_select.png", 0.05*_W, 0.05*_W )
      lvlButtons[i].x =  lvlPos[2*i-1]
      lvlButtons[i].y =  lvlPos[2*i]
      lvlButtons[i].rotation = math.random(-10, 10)
      lvlButtons[i].id = i
      local lvlNum = display.newText({parent = bgGroup, text = i, x = lvlPos[2*i-1], y = lvlPos[2*i], fontSize = 75, font = "ZCOOLKuaiLe-Regular.ttf"})
      lvlNum:setFillColor(0)
    end

    local tabInstructionSh = display.newText( {parent = sceneGroup, x = 0.505*_W, y = 0.085*_H, text = "Tab = Toggle Fullscreen", fontSize = 75, font = "KoHo-Medium.ttf" } )
    tabInstructionSh:setFillColor(0,0,0)
    tabInstructionSh.alpha = 0.7


    local tabInstruction = display.newText( {parent = sceneGroup, x = 0.5*_W, y = 0.08*_H, text = "Tab = Toggle Fullscreen", fontSize = 75, font = "KoHo-Medium.ttf" } )

    local resetsquare = display.newRoundedRect(sceneGroup, 95, 40, 150, 60, 15)
    local resetButton = display.newText({parent = sceneGroup, x = resetsquare.x, y = resetsquare.y, text = 'Reset?', fontSize = 45,})
    -- resetButton.anchorX = 0
    -- resetButton.anchorY = 0
    resetButton:setFillColor(1,1,1)
    resetsquare:setFillColor(0,0,0,0.3)
    resetsquare.strokeWidth = 2
    resetButton:addEventListener('touch', askReset)
end


-- show()
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
      scrollingComplete()


      for i = 1, numLvls do
        if saveData.locked[i] == true and isDebug == false then
          print(i, "locked")
          lvlButtons[i]:setFillColor(1,0,0)

        else
          lvlButtons[i]:setFillColor(1,1,1)
        end
      end

    elseif ( phase == "did" ) then
        -- Code here runs when the scene is entirely on screen


        scrollButtonL:addEventListener("touch", scrollTchL)
        scrollButtonR:addEventListener("touch", scrollTchR)

        Runtime:addEventListener("enterFrame", updateGame)
        for i = 1,numLvls do
          if saveData.locked[i] == false or isDebug == true then
            print(i, "unlocked")
            lvlButtons[i]:addEventListener("touch", lvlTouch)
          end
        end

    end
end


-- hide()
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        scrollButtonR:removeEventListener("touch", scrollTchR)
        scrollButtonL:removeEventListener("touch", scrollTchL)
        Runtime:removeEventListener("enterFrame", updateGame)

        for i = 1,numLvls do
          lvlButtons[i]:removeEventListener("touch", lvlTouch)
        end
    end
end


-- destroy()
function scene:destroy( event )

    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
