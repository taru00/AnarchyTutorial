G.useRemoteInput = false and (Application:GetPlatformName() == "WIN32DX9" or Application:GetPlatformName() == "WIN32DX11")

function OnAfterSceneLoaded(self)
  self.cameraMap = Input:CreateMap("CameraMap")
  self.w, self.h = Screen:GetViewportSize()
  
  if G.useRemoteInput then
    --RemoteInput:StartServer('RemoteGui')
    --RemoteInput:InitEmulatedDevices()
    --RemoteInput:DebugDrawTouchPoints(Vision.VColorRef(255,0,0))
    
    self.cameraMap:MapTrigger("Orbit", {0, 0, self.w, self.h}, "CT_TOUCH_ANY")
    self.cameraMap:MapTrigger("X", {0, 0, self.w, self.h}, "CT_TOUCH_NORM_X")
    self.cameraMap:MapTrigger("Y", {0, 0, self.w, self.h}, "CT_TOUCH_NORM_Y")
  else
    --RemoteInput:StopServer()
    --RemoteInput:DeinitEmulatedDevices()
    
    self.cameraMap:MapTrigger("X", "MOUSE", "CT_MOUSE_NORM_X")
    self.cameraMap:MapTrigger("Y", "MOUSE", "CT_MOUSE_NORM_Y")
    self.cameraMap:MapTrigger("Orbit", "MOUSE", "CT_MOUSE_RIGHT_BUTTON")
  end
  
  self.pitchChange = 50
  self.pitch = -10
  local orientation = self:GetOrientation()
  orientation.y = self.pitch + self.pitchChange / 2
  self:SetOrientation(orientation)
end

function OnBeforeSceneUnloaded(self)
  Input:DestroyMap(self.cameraMap);
end

function OnThink(self)
  local targetPosition = Game:GetEntity("PlayerStone"):GetPosition()
  self:SetPosition(targetPosition)

  if self.cameraMap:GetTrigger("Orbit")>0  then

    local speed = 80 * Timer:GetTimeDiff()
    local x = self.cameraMap:GetTrigger("X")
    local y = self.cameraMap:GetTrigger("Y")
    local orientation = self:GetOrientation()

    if (x > 0.85)  then
      orientation.x = orientation.x + speed
    end
    if (x  < 0.15) then
      orientation.x = orientation.x - speed
    end
    if (y < 0.15)and (orientation.y < 55) then
      orientation.y = orientation.y + speed
    end
    if (y > 0.85) and (orientation.y > 15) then
      orientation.y = orientation.y - speed
    end
    
    self:SetOrientation(orientation)
  end    
end