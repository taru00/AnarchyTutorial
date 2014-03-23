
-- define the line type for a railing
LINE_TYPE_RAILING = 4

-- vaulting target selection
g_lowVaultDock = 
{
	m_lineTypes = {LINE_TYPE_RAILING},
	m_condition =	function(dockPointToPos, pos, forward, edgeNormal)
						local heightDiff = dockPointToPos[2]
						dockPointToPos[2] = 0
						dockPointToPos:normalize3()
						return ((dockPointToPos:dot3(forward) < -0.4) and 
								(heightDiff < 0.0) and
								(heightDiff > -1.75)) 
					end,
	m_maxDistance = 4,
	m_minDistance = 0
}

g_lowVaultDockFromBehind = 
{
	m_lineTypes = {LINE_TYPE_RAILING},
	m_condition =	function(dockPointToPos, pos, forward, edgeNormal)
						local heightDiff = dockPointToPos[2]
						dockPointToPos[2] = 0
						dockPointToPos:normalize3()
						return ((dockPointToPos:dot3(forward) > 0.4) and 
								(heightDiff < 0.0) and
								(heightDiff > -1.75)) 
					end,
	m_maxDistance = 4,
	m_minDistance = 0
}

	-- searches for a low wall to vault over.  If it finds one it initiates the target
	-- and returns true, otherwise it returns false
function vaultLowWall(line, distance)

	-- if a line was found dock to it
	if( line ~= nil and not hkbIsNodeActive("Idle To Sword") ) then
	
		-- we want to jump over the wall from either side, which means we need to rotate the quaternion
		-- if we are on the "wrong" side of the wall
		
		-- if the edge normal is in line with the characters forward vector then flip the rotation
		if (line.m_edgeNormal:dot3(g_characterState.m_forward) > 0) then
			local r = line.m_rotation
			line.m_rotation = hkQuaternion.new(-r[0], -r[1], -r[2], r[3])
		end
		
		
		-- set the correct incoming direction
		local vaultFromRight = hkbGetVariable("IsRightFootForward")
		
		-- if the distance is less than 0, then the condition for mirroring is oppisite
		-- what it usually is
		if(distance < 0) then
			vaultFromRight = 1 - vaultFromRight
			line.m_rotation = nil
		end
		
		if(vaultFromRight == 0) then
			hkbSetVariable("VaultFromLeft", 0)
		else
			hkbSetVariable("VaultFromLeft", 1)
		end
		
		-- select appropriate animation
		if (distance < 0) then
			hkbSetVariable("VaultingSelector", 2)
		elseif (distance < 2.5) then
			hkbSetVariable("VaultingSelector", 1)
		else
			hkbSetVariable("VaultingSelector", 0)
		
		end
		
		-- assign the docking object
		setLineDockingTarget( line )
	
		hkbFireEvent("Vault")
		
		if (hkbIsNodeActive("Idle Sword")) then 
			hkbFireEvent("SheathSwordFast")
		end
		
		return true
	end
	
	return false
end

function onActivateEndVault()
	
	-- find a spot on the floor to land on
	local from = hkVector4.new()		
	local to = hkVector4.new()
			
	from:setAddMul4( g_characterState.m_currentPos, g_characterState.m_forward, 1.5 )
	from[2] = from[2] + 0.25
	to:setAddMul4(from, UP_DIRECTION, -20)

	-- cast a ray to find the point on the geometry
	local hit, hitFraction, hitNormal, hitPosition = hkbCastRay(from, to)
	
	-- move a bit above the ground
	--hitPosition[2] = hitPosition[2] + 0.1
	
	-- assign the spot on the floor to the docking object
	local plane = hkVector4.new(UP_DIRECTION)
	plane[3] = plane:dot3(hitPosition)
	setPlaneDockingTarget( plane )
	
end

function onEndVaultHandleEvent()

	-- get the name of the event that was raised	
	local eventName = hkbGetHandleEventName()
		
	-- perform the correct action
	if( eventName == "VaultOutEnd" ) then	
	
		-- reset the docking object
		clearDockingTarget()
	
	end
	
end