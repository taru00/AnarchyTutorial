
function onDemandBundlesUpdate()
	-- Call the Default onUpdate function of this Project.
	onUpdateRoot()
	
	-- Handle OnDemandLoading Specific Behavior.
	
	-- Determine if we need to load the 'Hero_Cover_Bundle' Bundle.
    local coverZoneDistance = hkbGetVariable("CoverZoneLoadDistance");
    
	if (coverZoneDistance <= 0) then
		hkbSetVariable("CoverBundleIsActive", false)
	end
	
    local coverDock = { 
		m_lineTypes = {LINE_TYPE_LOW_WALL, LINE_TYPE_HIGH_WALL},
		m_condition = function(dockPointToPos, pos, forward, edgeNormal)
					  return (dockPointToPos:dot3(forward) < 0.5)  
					  end,
		m_maxDistance = coverZoneDistance,
		m_minDistance = 0
	}
	
	local checkLine, checkDistance = g_lineWorld:findLineToDockTo( coverDock )
	if ( checkLine ~= nill) then
		hkbSetVariable("CoverBundleIsActive", true)
	else
		hkbSetVariable("CoverBundleIsActive", false)
	end
	
end
