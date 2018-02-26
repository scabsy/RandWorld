-- TO DO
-- ****************level loading
-- load section as player walks - mostly done
--	-works with pre-generated level - not infinite
-- save any changes from mining to file as player leave area

-- ****************mining
-- make each block mineable (click within distance, block has health)
-- inventory

-- ****************crafting system
-- make recipes for certain things (3x3 grid)
-- ui to craft


-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local composer = require( "composer" )
local perspective = require( "perspective" )
local scene = composer.newScene()

-- include Corona's "physics" library
local physics = require "physics"
-- physics.setDrawMode("hybrid")

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX

----------------------------------LOCAL VARIABLES---------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
--player
local pSize = 80
local pSpeed = 3
local pJumpHeight = -.35

local player=display.newRect(0,0,pSize*.4,pSize)
player.anchorY=1
player:setFillColor(1,0,0)
player.posDirs = {"L","R"}
player.dir = ""

--world
local World={}
local WorldDisplay = {}
local BlockTypes={"d","g","s"}
local blockSize = 60
local levelWidth = 1000
local currentSection = 1
local loadedSecCount = 3
local sectionSize = 25

--camera
local camera = perspective.createView()

--UI
local memoryTxt
local memory
----------------------------------------------------------------------------------------------------------------

----------------------------------SHARE FUNCTIONS---------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
-----------player
--movement
function pMove()
	if player.dir=="L" then
		player.x = player.x - pSpeed
	elseif player.dir=="R" then
		player.x = player.x + pSpeed
	end
	
	local sectionRangeMin = (currentSection - 1) * sectionSize * blockSize - blockSize/2
	local sectionRangeMax = (currentSection) * sectionSize * blockSize + blockSize/2
	
	if player.x<sectionRangeMin then
		currentSection = currentSection-1
		print("G")
		CreateWorld()
	end
	if player.x>sectionRangeMax then
		currentSection = currentSection+1
		print("H")
		CreateWorld()
	end
end

function pJump()
	player:applyLinearImpulse(0,pJumpHeight*(player.height/pSize),player.x, player.y)
end

function pCrouch()
	-- physics.removeBody(player)
	player.height=pSize*.7
	-- physics.addBody(player,"dynamic",{bounce=0})
	-- player.isFixedRotation=true	
	-- player.gravityScale=6
end

function pStandUp()
	-- physics.removeBody(player)
	player.height=pSize
	-- physics.addBody(player,"dynamic",{bounce=0})
	-- player.isFixedRotation=true	
	-- player.gravityScale=3
end

function CheckOnGround(e)
	
end

--reset player physics
function pResetPhysics()
	player.isFixedRotation=true	
	player.gravityScale=3
end
--remove movement functions
function StopMovement()
	Runtime:removeEventListener("enterFrame", pMove)
end

-----------world
function GenerateWorld()
	local height = 25
	for i=1,levelWidth do
		World[i]={}
		height=height + math.random(-2,2)
		if height<1 then height = 1 end
		for j=1,height do
			local blkType = BlockTypes[math.random(#BlockTypes)]
			World[i][j]=blkType
		end
	end
	--print(#World)
	CreateWorld(World)
end

function CreateWorld(worldArray)	
	-- for i=1,#World do
	local wdNum = 1
	for k,v in pairs(WorldDisplay) do
		for i=1,#WorldDisplay[k] do
			-- print(WorldDisplay[k][i].blockType)
			camera:remove(WorldDisplay[k][i])
			WorldDisplay[k][i]=nil
		end
	end
	-- camera:layer(2) = {}
	-- WorldDisplay=nil
	-- WorldDisplay={}
	local minSec = ((currentSection-2)*sectionSize)+1
	local maxSec = ((currentSection)*sectionSize)+sectionSize
	if minSec<1 then minSec=1 end
	if maxSec>levelWidth then maxSec=levelWidth end
	
	for i=minSec,maxSec do
		WorldDisplay[wdNum]={}
		for j=1,#World[i] do
			local tmpBlkType = World[i][j]
			--World[i][j]=nil
			if type(tmpBlkType)~= "table"  then 
				WorldDisplay[wdNum][j]=display.newRect(0,0,blockSize,blockSize)
				WorldDisplay[wdNum][j].blockType=tmpBlkType
				WorldDisplay[wdNum][j].x,WorldDisplay[wdNum][j].y = (i*blockSize)-blockSize/2,(screenH-j*blockSize)+blockSize/2
				physics.addBody(WorldDisplay[wdNum][j],"static",{bounce=0})
				if WorldDisplay[wdNum][j].blockType=="g" then
					WorldDisplay[wdNum][j]:setFillColor(0,1,0)
				elseif WorldDisplay[wdNum][j].blockType=="d" then
					WorldDisplay[wdNum][j]:setFillColor(1,0,1)
				elseif WorldDisplay[wdNum][j].blockType=="s" then
					WorldDisplay[wdNum][j]:setFillColor(.4,.4,.4)
				end
				
				camera:add(WorldDisplay[wdNum][j],2)
			end
		end
		wdNum = wdNum+1
		--print("end line")
	end	
	
	SaveWorld()
end

function SaveWorld()
	local path = system.pathForFile("world.txt",system.DocumentsDirectory)
	local file,errorString = io.open(path,"w")
	if not file then
		print("File error: " .. errorString)
	else		
		for i=1,#World do
			for j=1,#World[i] do
				file:write(World[i][j])
			end
			if i<#World then
				file:write("\n")
			end
		end
		io.close(file)
	end
	file =nil
end

function LoadWorld()
	local path = system.pathForFile("world.txt",system.DocumentsDirectory)
	local file,errorString = io.open(path,"r")
	if not file then
		print("File error: " .. errorString)
		GenerateWorld()
	else
		World={}
		local lineN = 0
		for i=1,levelWidth do			
			local line = file:read("*l")
			-- lineN=lineN+1
			-- if lineN >= currentSection*sectionSize then
				-- if lineN > currentSection*sectionSize + sectionSize then
					-- break
				-- end
				
				if string.len(line) > 0 then
					-- print(string.len(line))
					World[i]={}
					for j=1,string.len(line) do
						World[i][j]=line:sub(j,j)
					end
				end
			-- end
		end
		io.close(file)
	end
	file=nil
	
	CreateWorld(World)
end

--key input
local function onKeyEvent( event )
	if event.keyName=="a" or event.keyName=="A" then
		if event.phase=="down" then
			StopMovement()
			player.dir=player.posDirs[1]
			Runtime:addEventListener("enterFrame", pMove)
		else
			StopMovement()
		end
		-- player.x = player.x - pSpeed
	end
	
	if event.keyName=="d" or event.keyName=="D" then
		if event.phase=="down" then
			StopMovement()
			player.dir=player.posDirs[2]
			Runtime:addEventListener("enterFrame", pMove)
		else
			StopMovement()
		end
		-- player.x = player.x + pSpeed
	end
	
	if event.keyName=="w" or event.keyName=="W" then
		if event.phase=="down" then
			pJump()
		end
	end
	
	if event.keyName=="s" or event.keyName=="S" then
		if event.phase=="down" then
			pCrouch()
		elseif event.phase=="up" then
			pStandUp()
		end
	end
    -- If the "back" key was pressed on Android, prevent it from backing out of the app
    if ( event.keyName == "back" ) then
        if ( system.getInfo("platform") == "android" ) then
            return true
        end
    end
    -- IMPORTANT! Return false to indicate that this app is NOT overriding the received key
    -- This lets the operating system execute its default handling of the key
    return false
end

--Sleep timer
local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

local maxMem = 0
function ShowMemory()
	memoryTxt=collectgarbage("count")
	if memoryTxt> maxMem then maxMem=memoryTxt end
	memory.text="System memory: " .. string.format("%.00f",maxMem) .. "KB"
end
-- function FollowPlayer()
	-- scene
-- end
----------------------------------------------------------------------------------------------------------------


function scene:create( event )
	local sceneGroup = self.view
	physics.start()
	physics.pause()

	-- We need physics started to add bodies, but we don't want the simulaton
	-- running until the scene is on the screen.
	--load map
	LoadWorld()
	
	
	physics.addBody(player,"dynamic",{bounce=0})	
	player.isFixedRotation=true	
	player.gravityScale=3
	player.x, player.y = WorldDisplay[1][1].x,-#WorldDisplay[1]*blockSize+screenH
	-- player.x, player.y = (sectionSize*currentSection*blockSize),-#World[1]*blockSize+screenH
	--pResetPhysics()
	
	memory=display.newText("ASCASDC",screenW/2,100, native.systemFont,16)
	memory:setFillColor(1,1,1)
	
	camera:add(player,1)
	-- for i=1,#World do
	-- for i=1,sectionSize do
		-- for j=1,#WorldDisplay[i] do
			-- camera:add(WorldDisplay[i][j],2)
		-- end
	-- end
	
	-- camera:setBounds(0,levelWidth*blockSize-screenW/2,-3300,screenH/2)
	camera:setBounds(screenW/2,levelWidth*blockSize-screenW/2,-3300,screenH/2)
	
	camera.damping=10
	camera:setFocus(player)
	camera:track()
	-- sceneGroup:insert(player)
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase
	
	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		-- 
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()
		
		Runtime:addEventListener( "key", onKeyEvent )
		Runtime:addEventListener( "enterFrame", ShowMemory )
	end
end

function scene:hide( event )
	local sceneGroup = self.view
	
	local phase = event.phase
	
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.stop()
		Runtime:removeEventListener( "key", onKeyEvent )
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end	
	
end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	-- 
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view
	
	package.loaded[physics] = nil
	physics = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene