-- bounding box setup for a pickable object
function OnAfterSceneLoaded(self)
  self:SetTraceAccuracy(Vision.TRACE_POLYGON)
end