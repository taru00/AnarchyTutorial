
-- line types for cover targets
LINE_TYPE_LOW_WALL = 0
LINE_TYPE_HIGH_WALL = 1

-- low and high wall docking type
g_wallDock = 
{
	m_lineTypes = {LINE_TYPE_LOW_WALL, LINE_TYPE_HIGH_WALL},
	m_condition =	function(dockPointToPos, pos, forward, edgeNormal) 
						return ((dockPointToPos:dot3(forward) < 0.5)  and
								(math.abs(dockPointToPos[2]) < 0.2))
					end,
	m_maxDistance = 3,
	m_minDistance = 0
}

g_coverToCoverDock = 
{
	m_lineTypes = {LINE_TYPE_LOW_WALL, LINE_TYPE_HIGH_WALL},
	m_condition =	function(dockPointToPos, pos, forward, edgeNormal)
						local right = hkVector4.new()
						right:setCross(forward, UP_DIRECTION)
						local rightDistance = dockPointToPos:dot3(right)
						
						return  (	(math.abs(forward:dot3(dockPointToPos)) < 0.1) and
								(	( (rightDistance < 0) and (hkbGetVariable("IntoCoverStartState") == 0) ) or
									( (rightDistance > 0) and (hkbGetVariable("IntoCoverStartState") == 1) ) ) )
					end,
	m_maxDistance = 6,
	m_minDistance = 1
}

-- searches for a line to dock to in the world.  if one is found an animation is picked based on
-- the line type and the character's current velocity.
function takeCover()	

	-- search for a line to dock to
	local line, distance = g_lineWorld:findLineToDockTo( g_wallDock )
	
	-- if a line was found dock to it
	if( line ~= nill ) then
		-- create and assign a line docking object which will constrain the character to the line
		setLineDockingTarget( line )
	
		-- pick the correct height animation based on the box type
		if( line.m_lineType == LINE_TYPE_HIGH_WALL ) then
			hkbSetVariable("DockingHeightSelector", 1)
		else
			hkbSetVariable("DockingHeightSelector", 0)
		end
		
		-- pick the correct speed animation based on the velocity of the character
		local speed = hkbGetCharacterControllerVelocity():length3()
		if( (speed > 2.5) and (distance > 1) ) then
			hkbSetVariable("DockingSpeedSelector", 1)
		else
			hkbSetVariable("DockingSpeedSelector", 0)
		end
		
		-- pick the correct direction
		local lineDir = hkVector4.new()
		lineDir:setSub4(line.m_b, line.m_a);
		lineDir:normalize3()
		
		if(lineDir:dot3(g_characterState.m_forward) > 0) then
			hkbSetVariable("IntoCoverStartState", 1)
		else
			hkbSetVariable("IntoCoverStartState", 0)
		end
		
		-- now that the animations are setup right, raise the docking event
		hkbFireEvent("IntoCover")				
	end
	
end

	-- updates the character when they are docked
function onUpdateInCover()

	local coverMovement =
	{
		m_exitCondition =	function()
								return	((not g_gamePad:inLeftStickInDeadZone()) and 
										((g_characterState.m_stickDirection:dot3(g_characterState.m_forward) > 0.8) or
										  (g_characterState.m_stickDirection:dot3(g_characterState.m_forward) < -0.8) ) )
							end,
		m_exitFunction =	function()
								comeOutOfCover()
							end,
		m_leftNodeName = "In Cover Height Selector Left",
		m_rightNodeName = "In Cover Height Selector Right",
		m_movementVariableName = "IntoCoverStartState"
	}
	
	updateLineMovement(coverMovement)
	
end

function coverToCover()

	if ((g_characterState.m_coverToCover == false) and
		(g_characterState.m_dockingTarget ~= nil) and
		((g_characterState.m_lineParam < 0.05) or (g_characterState.m_lineParam > 0.95)) ) then
		
		local line = g_lineWorld:findLineToDockTo( g_coverToCoverDock, -1, g_characterState.m_dockingTarget )
		
		if( line ~= nil ) then

			setLineDockingTarget( line )
			g_characterState.m_dockedSpeed = 0
			g_characterState.m_coverToCover = true
			hkbFireEvent("CoverToCover")
			
		end
	
	end
end

function onDeactivateInCover()

	g_characterState.m_dockedSpeed = 0
	g_characterState.m_coverToCover = false

end

	-- undocks from a line in the world.
function comeOutOfCover()
	
	-- raise the undock event
	if (g_characterState.m_stickDirection:dot3(g_characterState.m_forward) > 0.8) then
		-- reset the docking object
		clearDockingTarget()
		
		hkbFireEvent("ComeOutOfCover")
	else
		-- vault from a docked position
		local line = g_lineWorld:findLineToDockTo( g_lowVaultDockFromBehind )
		if(line ~= nil) then
			vaultLowWall(line, -1)
		end
	end
	
end
