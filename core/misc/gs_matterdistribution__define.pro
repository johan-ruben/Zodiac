FUNCTION gs_MatterDistribution::Init, dImg, regions, attCoeff = attCoeff, filter = filter

  compile_opt idl2
  
  case 1B of
    
    ~Obj_Valid(dImg) || ~Obj_Isa(dImg, 'gs_Density'): Message, 'Density image must be gs_Density.'
    ~Obj_Valid(regions) || ~Obj_Isa(regions, 'gs_RegionMap'): Message, 'Region map must be gs_RegionMap.'
    dImg.nDimensions ne 3: Message, 'Density image must be three-dimensional.'
    ~Array_Equal(dImg.dataDims, regions.dataDims): Message, 'Matrix-ize mis-match.'
    ~Obj_Valid(attCoeff) || ~Obj_Isa(attCoeff, 'gs_AttenuationData'): Message, 'Attenuation coefficients must be supplied as gs_AttenuationData.'
    
    else:
    
  endcase
  
  self.voxelSize = dImg.voxelSize
  self.attCoeff = attCoeff
  
  self.components = OrderedHash()
  
  foreach name, regions.names do begin  
    if Obj_Valid(filter) && Obj_Isa(filter, 'gs_Filter') then self.components[name] = dImg.GetRegion(regions, name, voxelSize = dImg.voxelSize)#filter else self.components[name] = dImg.GetRegion(regions, name, voxelSize = dIMg.voxelSize)
  endforeach
   
  Return, 1
  
END

;================================================================================================================

PRO gs_MatterDistribution::CleanUp

  if Obj_Valid(self.components) then begin
    foreach cmp, self.components do Obj_Destroy, cmp
    Obj_Destroy, self.components  
  endif

END

;================================================================================================================

FUNCTION gs_MatterDistribution::GetMu, energy

  compile_opt idl2
  
  k = 0
  
  foreach cmp, self.components, name do begin
    if k eq 0 then mu = gs_Density(DblArr(cmp.dataDims), voxelSize = self.voxelSize)
    mu = mu + cmp*self.attCoeff[name].MassAttenuation(energy)
    k++
  endforeach
  
  Return, gs_Mu(mu.imgData, voxelSize = mu.voxelSize)

END

;=============================================================================================

FUNCTION gs_MatterDistribution::GetDens

  compile_opt idl2
  
  k = 0

  foreach cmp, self.components, name do begin
    if k eq 0 then d = gs_Density(DblArr(cmp.dataDims), voxelSize = self.voxelSize)
    d = d + cmp
    k++
  endforeach
  
  Return, d
  
END

;================================================================================================================

PRO gs_MatterDistribution__define

  compile_opt idl2
  
  dum = {gs_MatterDistribution, components: Obj_New(), voxelSize: DblArr(3), attCoeff: Obj_New(), inherits IDL_Object}

END