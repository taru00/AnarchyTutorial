
-- bounding box setup for a pickable object
function OnAfterSceneLoaded(self)
  
  self:SetTraceAccuracy(Vision.TRACE_POLYGON)
  
  self:GetComponentOfType("vHavokRigidBody"):SetFriction(0.5f + Util:GetRandFloat(0.5f))
  self:GetComponentOfType("vHavokRigidBody"):SetRestitution(0)
  self:GetComponentOfType("vHavokRigidBody"):SetMass(1)
  
  G.blocks = G.blocks + 1
  G.blockList[G.blocks] = self
  
end