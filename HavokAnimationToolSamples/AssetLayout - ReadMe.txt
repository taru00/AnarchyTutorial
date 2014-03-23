The Havok Behavior assets directory is broken into categories based on what tools work with which assets.

Resources/Behavior/ArtAssets

   Holds all DCC created files.  Examples are 3dsmax, Maya, XSI or Photoshop files.  Data in these files is exported via the Havok Content Tools 
   to Resouces/Behavior/GameAssets for use in our demos.  Not all DCC files are shipped with our demo framework so it's possible that this directory
   will be empty.
   
Resouces/Behavior/BehaviorToolAssets

   Holds all Havok Behavior Tool files.  Examples are hkp, hkpb and hkc files.  These files are exported via the Havok Behavior Tool
   to Resources/Behavior/GameAssets for use in our demos.  Projects typically use runtime assets from the Resources/Behavior/GameAssets directory.
   
Resources/Behavior/GameAssets

   Holds all runtime files.  These assets are loaded and used in our demos.
