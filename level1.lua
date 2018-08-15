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
native.setProperty("windowMode", "fullscreen")
--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX

----------------------------------LOCAL VARIABLES---------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
--player
local pSize = 80
local pSpeed = 3
local pJumpHeight = -.35
local player={}
player[1]=display.newRect(0,0,pSize*.4,pSize*.4)
player[2]=display.newRect(0,0,pSize*.4,pSize*.2)
player[3]=display.newRect(0,0,pSize*.4,pSize)
player[1].anchorY=1
player[2].anchorY=0
player[3].anchorY=1
player[1]:setFillColor(1,0,0)
player[2]:setFillColor(0,0,1)
player[3]:setFillColor(0,1,0)
player.posDirs = {"L","R"}
player.dir = ""
player.crouchAmt=pSize*.6
player.canMove=true
player.prevLocX = 0

player[1].alpha=0
player[2].alpha=0
-- player[3].alpha=0.2

--world
local World={}
local WorldDisplay = {}
local BlockTypes={"d","g","s"}
local blockSize = 60
local currentSection = 3
local loadedSecCount = 3
local sectionSize = 17
local darkness
local darknessAlpha


local maxWorldWidth = 1020
local maxWorldHeight = 96
--camera
local camera = perspective.createView()

--UI
local memoryTxt
local memory
local clockTime
local clockTimeTxt
----------------------------------------------------------------------------------------------------------------

----------------------------------SHARE FUNCTIONS---------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
-----------player
--movement
function pMove()
	if player.canMove then
		player.prevLocX=player[1].x
		if player.dir=="L" then
			player[1].x = player[1].x - pSpeed
			player[2].x = player[1].x
		elseif player.dir=="R" then
			player[1].x = player[1].x + pSpeed
			player[2].x = player[1].x
		end
		
		local sectionRangeMin = (currentSection - 1) * sectionSize * blockSize - blockSize
		local sectionRangeMax = (currentSection) * sectionSize * blockSize + blockSize
		
		if player[1].x<sectionRangeMin then
			currentSection = currentSection-1
			print("G")
			CreateWorld()
		end
		if player[1].x>sectionRangeMax then
			currentSection = currentSection+1
			print("H")
			CreateWorld()
		end
	else
		player[1].x=player.prevLocX
		player[2].x=player.prevLocX
		player[3].x=player.prevLocX
	end
end

function playerHeadCollision(self,e)
	if e.phase=="began" then
		player.canMove=false
	else
		player.canMove=true
	end
end

function pJump()
	player[1]:applyLinearImpulse(0,pJumpHeight*((player[1].height*.6)/pSize),player[1].x, player[1].y)
end

function pCrouch()
	player.crouchAmt=pSize*.3
	player[3].height=pSize*.6
end

function pStandUp()
	player.crouchAmt=pSize*.6
	
	player[3].height=pSize
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

function GetPlayerGridLoc()
	local GridLoc={math.floor(player[1].x/blockSize)+1,-math.floor(player[1].y/blockSize)}
	return GridLoc
end

-----------world

--create block
function CreateBlock(blkType)
	local block=display.newRect(0,0,blockSize,blockSize)
	
	if blkType~="c" then
		physics.addBody(block,"static",{bounce=0})
	else
		block.alpha=0.1
	end
	
	block.blockType=blkType
	if block.blockType=="g" then
		block:setFillColor(0,.6,0)
	elseif block.blockType=="d" then
		block:setFillColor(.5,.3,.05)
	elseif block.blockType=="s" then
		block:setFillColor(.4,.4,.4)
	elseif block.blockType=="b" then
		block:setFillColor(.1,.1,.1)
	end
				
	block.WorldLoc = {i,j}
	block.durability=100
	
	block:addEventListener("mouse",mineOnTouch)
	-- block:addEventListener("touch",placeOnTouch)
	
	return block
end

function SetBlock(block,blkType)
	if blkType~="c" then		
		block.alpha=1
		physics.addBody(block,"static",{bounce=0})		
	else
		physics.removeBody(block)	
		block:setFillColor(1)		
		block.alpha=0.1
	end
	
	block.blockType=blkType
	if block.blockType=="g" then
		block:setFillColor(0,.6,0)
	elseif block.blockType=="d" then
		block:setFillColor(.5,.3,.05)
	elseif block.blockType=="s" then
		block:setFillColor(.4,.4,.4)
	elseif block.blockType=="b" then
		block:setFillColor(.1,.1,.1)
	end
	
	World[block.WorldLoc[1]][block.WorldLoc[2]]=blkType
	block.durability=100
	
	-- print(player.x,player.y)
	-- print(GetPlayerGridLoc()[1],GetPlayerGridLoc()[2])
end

--mining
local mineTarget
function mineBlock()
	--local tBlock = e.target
	if mineTarget ~= nil then
		if mineTarget.blockType~="b" then
			if mineTarget.durability>0 then
				mineTarget.durability = mineTarget.durability - 100
				mineTarget.alpha = mineTarget.durability/100 + .1
				if mineTarget.durability <= 0 then
					SetBlock(mineTarget,"c")
					Runtime:removeEventListener("enterFrame",mineBlock)
				end
			end
		end
	end
end

local wasPriButDown = false
local wasSecButDown = false
function mineOnTouch(e)	
	mineTarget=e.target
	
	local distToTargetX = mineTarget.WorldLoc[1] - GetPlayerGridLoc()[1]
	local distToTargetY = mineTarget.WorldLoc[2] - GetPlayerGridLoc()[2]
	
	local distToTarget = math.sqrt((distToTargetX * distToTargetX) + (distToTargetY * distToTargetY))
	
	if distToTarget<2.5 then
		if e.isPrimaryButtonDown then
			if not wasPriButDown then
				wasPriButDown = true
				if mineTarget.blockType~="c" then
					Runtime:addEventListener("enterFrame",mineBlock)
				end
			end
		elseif not e.isPrimaryButtonDown then
			wasPriButDown = false
			
			Runtime:removeEventListener("enterFrame",mineBlock)
			if mineTarget~=nil then
				if mineTarget.blockType~="c" then
					mineTarget.durability=100
					mineTarget.alpha=1
				end
			end
		end
		
		if e.isSecondaryButtonDown then
			if not wasSecButDown then
				wasSecButDown = true
				if mineTarget.blockType=="c" then
					if GetPlayerGridLoc()[1]~=mineTarget.WorldLoc[1] or (GetPlayerGridLoc()[2]~=mineTarget.WorldLoc[2] and GetPlayerGridLoc()[2]+1~=mineTarget.WorldLoc[2]) then
						SetBlock(mineTarget,"d")
					end
				end
			end
		elseif not e.isSecondaryButtonDown then
			wasSecButDown = false
		end
	
	end
end

function GenerateWorld()
	local height = maxWorldHeight/2+math.random(-5,5)
	
	--Generate base world
	for i=1,maxWorldWidth do
		World[i]={}
		height=height + math.random(-2,2)
		if height<maxWorldHeight/3 then height = maxWorldHeight/3 end
		if height>maxWorldHeight/3*2 then height=maxWorldHeight/3*2 end
		World[i].height=height
		-- print(i,height,World[i].height)
		for j=1,maxWorldHeight do
			if j <= height then
				-- local blkType = BlockTypes[math.random(#BlockTypes)]
				World[i][j]="p"
			else
				World[i][j]="c"
			end
		end		
	end
	
	--set base block types
	for i=1,maxWorldWidth do
		local rowHeight = math.floor(World[i].height)
		for j=1,rowHeight do
			-- local dirtHeight = math.floor((World[i].height-1)-math.random(World[i].height/3))
			local dirtHeight = rowHeight-(rowHeight/3)-math.random(-5,5)
			local stoneHeight = dirtHeight-(rowHeight/3)-math.random(-5,5)
			if j>=dirtHeight then
				World[i][j]="d"
			end
			
			if j<dirtHeight then -- and j>stoneHeight then
				World[i][j]="s"
			end
		
			if j==rowHeight then
				World[i][j]="g"
			end
			
			if j<=1+math.random(0,2) then
				World[i][j]="b"
			end
		end
	end
	
	--generate caves
	local maxCaveHeight = 2
	local caveCount = math.random(50,100)
	
	for i=10,caveCount do		
		local rowHeight = math.floor(World[i].height)
		local caveStart = {math.random(1, maxWorldWidth),math.floor(rowHeight/2+math.random(-5,5))}
		print(caveStart[2])
		for j=1, math.random(50) do--math.random(-maxCaveHeight,0),math.random(0,maxCaveHeight) do
			for k=math.random(-maxCaveHeight,0),math.random(0,maxCaveHeight) do
				if World[caveStart[1]+j][caveStart[2]+k]~="b" then
					World[caveStart[1]+j][caveStart[2]+k]="c"
				end
			end
			-- print(caveStart[2])
			caveStart[2] = caveStart[2] + math.random(-maxCaveHeight,maxCaveHeight)
			-- print(caveStart[2])
		end
		
	end
	
	CreateWorld(World)
end

function CreateWorld(worldArray)

	SaveWorld()	
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
	if maxSec>maxWorldWidth then maxSec=maxWorldWidth end
	
	for i=minSec,maxSec do
		WorldDisplay[wdNum-sectionSize]={}
		for j=1,#World[i] do
			local tmpBlkType = World[i][j]
			--World[i][j]=nil
			if type(tmpBlkType)~= "table"  then 
				WorldDisplay[wdNum-sectionSize][j]=CreateBlock(tmpBlkType)
				WorldDisplay[wdNum-sectionSize][j].x,WorldDisplay[wdNum-sectionSize][j].y = (i*blockSize)-blockSize/2,(-j*blockSize)+blockSize/2					
				WorldDisplay[wdNum-sectionSize][j].WorldLoc = {i,j}
				
				camera:add(WorldDisplay[wdNum-sectionSize][j],2)
			end
		end
		wdNum = wdNum+1
	end	
	
	
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
		for i=1,maxWorldWidth do			
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

local cycleSpeed=0.0005
local darknessBright=0
local darknessDark=1
function DayNightCycle()
	clockTime=clockTime+(1/30)
	if clockTime>1440 then clockTime=0 end
	
	local hour = math.floor(clockTime/60)
	local minute = clockTime%60
	clockTimeTxt.text="Time: " .. string.format("%02d",hour) .. ":" .. string.format("%02d",math.floor(minute))--clockTime
	
	
	
	if hour >= 19 or hour <= 6 then
			-- print(minute%5)
		-- if minute%5 <= 0.3 then
			darknessAlpha = darknessAlpha + cycleSpeed
			if darknessAlpha > darknessDark then darknessAlpha=darknessDark end
		-- end
	else
		darknessAlpha = darknessAlpha - cycleSpeed
		
		if darknessAlpha < darknessBright then darknessAlpha=darknessBright end
	end
	
	darkness.alpha=darknessAlpha
	
		-- print(darkness.alpha,darknessAlpha)
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
	
	local playerScreenX,playerScreenY=player[1]:localToContent(0,0)
	-- print(playerScreenX/screenW)
	darkness.fill.effect.center={playerScreenX/screenW,playerScreenY/screenH}
	-- print(player:localToContent(0,0),player.x,player.x%1920)
	
	
	-- player[2].x=player[1].x
	player[3].x=player[1].x
	player[2].y=player[1].y-player[1].height-player.crouchAmt
	player[3].y=player[1].y
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
	
	darkness=display.newRect(screenW/2, screenH/2,screenW, screenH)
	darkness:setFillColor(0,0,0,.97)
		
	darkness.fill.effect="filter.iris"
	darkness.fill.effect.aperture=.2
	darkness.fill.effect.aspectRatio=1.5--player.width/player.height
	darkness.fill.effect.smoothness=.5
	-- darkness.alpha=darknessDark
	darkness.alpha=darknessBright
	darknessAlpha=darkness.alpha
	
	physics.addBody(player[1],"dynamic",{bounce=0})	
	physics.addBody(player[2],"dynamic",{bounce=0})	
	player[1].isFixedRotation=true	
	player[2].isFixedRotation=true	
	player[3].isFixedRotation=true	
	player.gravityScale=3
	player[1].x, player[1].y = WorldDisplay[1][1].x,-#WorldDisplay[1]*blockSize+screenH
	player[2].x = WorldDisplay[1][1].x
	player[3].x = WorldDisplay[1][1].x
	player[2].collision=playerHeadCollision
	player[2]:addEventListener("collision")
	-- player.x, player.y = (sectionSize*currentSection*blockSize),-#World[1]*blockSize+screenH
	--pResetPhysics()
	
	memory=display.newText("ASCASDC",screenW/2,100, native.systemFont,16)
	memory:setFillColor(1,1,1)
	
	clockTime=19*60+45
	clockTimeTxt=display.newText("ASCASDC",screenW-200,100, native.systemFont,16)
	clockTimeTxt:setFillColor(1,1,1)
	
	camera:add(player[1],1)
	camera:add(player[2],1)
	camera:add(player[3],1)
	-- for i=1,#World do
	-- for i=1,sectionSize do
		-- for j=1,#WorldDisplay[i] do
			-- camera:add(WorldDisplay[i][j],2)
		-- end
	-- end
	
	-- camera:setBounds(0,maxWorldWidth*blockSize-screenW/2,-3300,screenH/2)
	camera:setBounds(screenW/2,maxWorldWidth*blockSize-screenW/2,-maxWorldHeight*blockSize,-screenH/2)
	
	camera.damping=10
	camera:setFocus(player[3])
	camera:track()
	
	
		Runtime:addEventListener( "key", onKeyEvent )
		Runtime:addEventListener( "enterFrame", ShowMemory )
		Runtime:addEventListener( "enterFrame", DayNightCycle )
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