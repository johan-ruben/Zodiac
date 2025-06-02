FUNCTION gs_Attenuator::Init, densityDist = densityDist, transformer = transformer

  compile_opt idl2
  
  case 1B of
    ~Obj_Valid(densityDist) || ~Obj_Isa(densityDist, 'gs_MatterDistribution'): Message, 'Density distribution must be a gs_MatterDistribution.'
    ~Obj_Valid(transformer) || ~Obj_Isa(transformer, 'gs_Transformer'): Message, 'Transformer be a gs_Transformer.'
    else:
  endcase
  
  self.densityDist = densityDist
  self.transformer = transformer
  
  Return, 1

END

;===================================================================================

FUNCTION gs_Attenuator::Apply, oSrc, energy, angle, pivot, axialOffset = axialOffset
  
  compile_opt idl2
  
  muDist = self.densityDist.Getmu(energy)
  muDist = self.Transformer.Apply(muDist, angle, pivot, oSrc.voxelSize, oSrc.dataDims, axialOffset = axialOffset)
  
  att = Reverse(Total(Reverse(muDist.imgData, 1), 1, /cumulative)*muDist.voxelSize[0] - muDist.imgData*muDist.voxelSize[0]/2D, 1)
  
  Return, oSrc.New(oSrc.imgData*exp(-att))
  
END 

;===================================================================================

PRO gs_Attenuator__define

  compile_opt idl2
  
  dum = {gs_Attenuator, densityDist: Obj_New(), transformer: Obj_New(), inherits IDL_Object}

END