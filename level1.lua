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
local pSpeed = 5
local pJumpHeight = -.7

local player=display.newRect(screenW/2,screenH-450,pSize*.7,pSize)
player.anchorY=1
player:setFillColor(1,0,0)
player.posDirs = {"L","R"}
player.dir = ""

--world
local World={}
local BlockTypes={"d","g","s"}

--camera
local camera = perspective.createView()
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
	local height = 5
	for i=1,22 do
		World[i]={}
		height=height + math.random(-2,2)
		if height<1 then height = 1 end
		for j=1,height do
			local blkType = BlockTypes[math.random(#BlockTypes)]
			World[i][j]=blkType
			-- World[i][j]=display.newRect(0,0,85,85)
			-- World[i][j].blockType="d"
			-- World[i][j].x,World[i][j].y = i*85,screenH-j*85
			-- physics.addBody(World[i][j],"static",{bounce=0})
		end
	end
	print(#World)
	CreateWorld(World)
end

function CreateWorld(worldArray)	
	for i=1,#World do
		for j=1,#World[i] do
			local tmpBlkType = World[i][j]
			--World[i][j]=nil
			if type(tmpBlkType)~= "table"  then 
			print("A::" .. tmpBlkType)
			World[i][j]=display.newRect(0,0,85,85)
			World[i][j].blockType=tmpBlkType
			World[i][j].x,World[i][j].y = i*85,screenH-j*85
			physics.addBody(World[i][j],"static",{bounce=0})
			if World[i][j].blockType=="g" then
				World[i][j]:setFillColor(0,1,0)
			elseif World[i][j].blockType=="d" then
				World[i][j]:setFillColor(1,0,1)
			elseif World[i][j].blockType=="s" then
				World[i][j]:setFillColor(.4,.4,.4)
			end
			end
		end
		print("end line")
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
			--print("kajsdc" .. World[i][j].blockType)
				file:write(World[i][j].blockType)
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
		for i=1,22 do
			local line = file:read("*l")
			if string.len(line) > 0 then
				print(string.len(line))
				World[i]={}
				for j=1,string.len(line) do
					-- World[i][j]=display.newRect(0,0,85,85)
					-- World[i][j].blockType="d"
					-- World[i][j].x,World[i][j].y = i*85,screenH-j*85
					-- physics.addBody(World[i][j],"static",{bounce=0})
					
					World[i][j]=line:sub(j,j)--string.sub(
				end
			end
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
	--pResetPhysics()
	
	sceneGroup:insert(player)
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