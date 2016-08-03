-- Commented Corona Particles

return {
  
  emitterType = 0,  -- 0 = gravity, 1 = radial
  maxParticles = 64,
  configName = "",
  duration = -1, -- -1 = Forever, X = Number of seconds
  textureFileName = "particles/template.png",
  yCoordFlipped = 1,  
  _locked = false,  

  -- Gravity based particles
  gravityx = 0,
  gravityy = 0,
  particleLifespan = 2,
  particleLifespanVariance = 1,
  angle = 270,
  angleVariance = 30,
  speed = 80,
  speedVariance = 30,  
  sourcePositionVariancex = 0,
  sourcePositionVariancey = 0,
  startParticleSize = 64,
  startParticleSizeVariance = 32,
  finishParticleSize = 0,
  finishParticleSizeVariance = 0,    
  rotationStart = 0,
  rotationStartVariance = 0,  
  rotationEnd = 0,
  rotationEndVariance = 0,  

  -- Radial based particles
  maxRadius = 100,
  maxRadiusVariance = 0,
  minRadius = 0,
  minRadiusVariance = 0,
  radialAccelVariance = 0,
  radialAcceleration = 0,
  rotatePerSecond = 0,
  rotatePerSecondVariance = 0,
  tangentialAccelVariance = 0,
  tangentialAcceleration = 0,

  -- Color
  startColorRed = 1,
  startColorGreen = 1,
  startColorBlue = 1,
  startColorAlpha = 1,
  startColorVarianceRed = 0,
  startColorVarianceGreen = 0,
  startColorVarianceBlue = 0,
  startColorVarianceAlpha = 0,

  finishColorRed = 1,
  finishColorGreen = 1,
  finishColorBlue = 1,
  finishColorAlpha = 1,
  finishColorVarianceRed = 0,
  finishColorVarianceGreen = 0,
  finishColorVarianceBlue = 0,
  finishColorVarianceAlpha = 0,

  -- Drawmode
  --  0   : Zero - Blends using 0.
  --  1   : One - Blends using 1.
  --  768 : SourceColor - Blends using source color.
  --  769 : OneMinusSourceColor - Blends using 1-source color.
  --  770 : SourceAlpha - Blends using the source alpha channel.
  --  771 : OneMinusSourceAlpha - Blends using 1-the source alpha channel.
  --  772 : DestinationAlpha - Blends using the destination alpha channel.
  --  773 : OneMinusDestinationAlpha - Blends using 1-the destination alpha channel.
  --  774 : DestinationColor - Blends using the destination color.
  --  775 : OneMinusDestinationColor -Blends using 1-the destination color.
  --  776 : SourceAlphaSaturate - Blends using the source alpha saturation.

  blendFuncSource = 770,
  blendFuncDestination = 1,

}