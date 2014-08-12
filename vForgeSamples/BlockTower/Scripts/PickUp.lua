function OnAfterSceneLoaded(self)
  self.pickupMap = Input:CreateMap("PickupMap")
  local w, h = Screen:GetViewportSize()

  self.pickupMap:MapTrigger("X", {0, 0, w, h}, "CT_TOUCH_ABS_X")
  self.pickupMap:MapTrigger("Y", {0, 0, w, h}, "CT_TOUCH_ABS_Y")
  self.pickupMap:MapTrigger("Pick", {0, 0, w, h}, "CT_TOUCH_ANY", {once = false})
  
  if not G.useRemoteInput then
    self.pickupMap:MapTrigger("X", "MOUSE", "CT_MOUSE_ABS_X")
    self.pickupMap:MapTrigger("Y", "MOUSE", "CT_MOUSE_ABS_Y")
    self.pickupMap:MapTrigger("Pick", "MOUSE", "CT_MOUSE_LEFT_BUTTON", {once = false})
  end
end

function OnThink(self)

  local x = self.pickupMap:GetTrigger("X")
  local y = self.pickupMap:GetTrigger("Y")
    
  if self.pickupMap:GetTrigger("Pick")>0 then
  
    self.movedPoint = Screen:Project3D(x,y, 1000)
    
    if self.pickedEntity == nil then
      local picked = Screen:PickEntity(x,y, 50000, true)
      
      if picked ~= nil then
        -- pick an entity
        self.startPoint = self.movedPoint
        self.pickedEntity = picked
      end
    end
  else
    self.pickedEntity = nil
    self.movedPoint = nil
  end
  
  if self.pickedEntity ~= nil and self.movedPoint ~= nil then        
    Debug:PrintAt(5, 5, "movedPoint: "..tostring(self.movedPoint.x).." "..tostring(self.movedPoint.y).." ")
    Debug:PrintAt(5, 16,"startPoint: "..tostring(self.startPoint.x).." "..tostring(self.startPoint.y).." ")
    
    -- only allow movement along XY plane    
    local movedDirection = Vision.hkvVec3(self.movedPoint.x - self.startPoint.x, self.movedPoint.y - self.startPoint.y, 0)
    if (movedDirection:getLength() > 200) then
      movedDirection:setLength(200)
    end
    
    -- apply linear velocity to block    
    self.pickedEntity:GetComponentOfType("vHavokRigidBody"):SetLinearVelocity(movedDirection * 2)
  end

  if Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11" then
    -- draw cursor
    Debug.Draw:Line2D(x,y,x+10,y+5, Vision.V_RGBA_GREEN)
    Debug.Draw:Line2D(x,y,x+5,y+10, Vision.V_RGBA_GREEN)
    Debug.Draw:Line2D(x+10,y+5,x+5,y+10, Vision.V_RGBA_GREEN)
  end
end

function OnBeforeSceneUnloaded(self)
  if useRemoteInput then
    RemoteInput:StopServer()
  end

  Input:DestroyMap(self.map);
end

