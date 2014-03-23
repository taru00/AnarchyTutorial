

function setLineDockingTarget( line )
	
	if(line.m_rotation == nil) then
		hkbAssignLineDockingTarget( line.m_a, line.m_b )
	else
		hkbAssignLineDockingTarget( line.m_a, line.m_b, line.m_rotation )
	end
	
	g_characterState.m_dockingTarget = line
	
end

function setPlaneDockingTarget( plane )
	
	hkbAssignPlaneDockingTarget( plane )
	g_characterState.m_dockingTarget = plane
end

function clearDockingTarget()

	hkbAssignNullDockingTarget()
	g_characterState.m_dockingTarget = nil
	
end

