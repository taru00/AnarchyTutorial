
function OnAfterSceneLoaded(self)
  self.map = Input:CreateMap()
  local w, h = Screen:GetViewportSize()

  self.map:MapTrigger("X", {0, 0, w, h}, "CT_TOUCH_ABS_X")
  self.map:MapTrigger("Y", {0, 0, w, h}, "CT_TOUCH_ABS_Y")
  self.map:MapTrigger("Pick", {0, 0, w, h}, "CT_TOUCH_ANY", {once = false})
  
  if not G.useRemoteInput then
    self.map:MapTrigger("X", "MOUSE", "CT_MOUSE_ABS_X")
    self.map:MapTrigger("Y", "MOUSE", "CT_MOUSE_ABS_Y")
    self.map:MapTrigger("Pick", "MOUSE", "CT_MOUSE_LEFT_BUTTON", {once = false})
  end
end

function OnBeforeSceneUnloaded(self)
  if useRemoteInput then
    RemoteInput:StopServer()
  end

  Input:DestroyMap(self.map);
end

function OnThink(self)

  local x = self.map:GetTrigger("X")
  local y = self.map:GetTrigger("Y")
    
  if self.map:GetTrigger("Pick")>0 then
  
    self.point = Screen:Project3D(x,y, 1000)
    
    if self.picked == nil then
      local picked = Screen:PickEntity(x,y, 50000, true)
      
      if picked ~= nil then
        -- pick an entity
        self.start = self.point
        self.picked = picked
      end
    end
  else
    self.picked = nil
    self.point = nil
  end
  
  if self.picked ~= nil and self.point ~= nil then
  
    -- only allow movement along XY plane
    --local diff = self.start.z - self.point.z
    --local cam = Game:GetCamera()
    --local camDir = self.point - cam:GetPosition()
    --camDir = camDir * (1 / camDir.z)
    --self.point = self.point + camDir * diff

    -- apply linear velocity to block
    local move = Vision.hkvVec3(0, self.point.y - self.start.y, self.start.x - self.point.x)
    if (move:getLength() > 200) then
      move:setLength(200)
    end
    self.picked:GetComponentOfType("vHavokRigidBody"):SetLinearVelocity(move * 2)
  end

  if Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11" then
    -- draw cursor
    Debug.Draw:Line2D(x,y,x+10,y+5, Vision.V_RGBA_GREEN)
    Debug.Draw:Line2D(x,y,x+5,y+10, Vision.V_RGBA_GREEN)
    Debug.Draw:Line2D(x+10,y+5,x+5,y+10, Vision.V_RGBA_GREEN)
  end
end
