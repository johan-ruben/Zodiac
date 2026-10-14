FUNCTION gs_Basis::Init, regions, voxelSize, origin

  compile_opt idl3
  
  case 1B of
    ~Isa(regions, /scalar) || ~Obj_Valid(regions) || ~Obj_Isa(regions, 'gs_RegionMap'): Message, 'Regions must be supplied as a gs_RegionMap.'
    ~Isa(voxelSize, /float, /array) || (N_Elements(voxelSize) ne 3): Message, 'Voxel size must be a three-elment floating point array.'
    ~Obj_Valid(origin) || ~Obj_Isa(origin, 'OrderedHash'): Message, 'Origin must be set as an ordered hash.'
    else:
  endcase
  
  self.regions = regions
  self.voxelSize = Double(voxelSize)
  self.origin = OrderedHash(origin.Keys(), origin.Values())
  self.dataDims = Long(self.regions.dataDims)

  self.x = Ptr_New(Rebin(DindGen(self.dataDims[0])*self.voxelSize[0], self.dataDims))  
  self.y = Ptr_New(Rebin(DindGen(1, self.dataDims[1])*self.voxelSize[1], self.dataDims))
  self.z = Ptr_New(Rebin(DindGen(1, 1, self.dataDims[2])*self.voxelSize[2], self.dataDims))
  
  Return, 1

END

;============================================================

PRO gs_Basis::CleanUp

  compile_opt idl3
  
  if Obj_Valid(self.origin) then Obj_Destroy, self.origin
  if Ptr_Valid(self.x) then Ptr_Free, self.x
  if Ptr_Valid(self.y) then Ptr_Free, self.y
  if Ptr_Valid(self.z) then Ptr_Free, self.z

END

;============================================================

PRO gs_Basis::GetProperty, voxelSize = voxelSize, dataDims = dataDims, regions = regions

  compile_opt idl3
  
  if Arg_Present(voxelSize) then voxelSize = self.voxelSize
  if Arg_Present(dataDims) then dataDims = self.dataDims
  if Arg_Present(regions) then regions = self.regions

END

;============================================================

FUNCTION gs_Basis::_overloadEQ, left, right

  compile_opt idl3
  
  case 1B of
    ~Isa(left, /scalar) || ~Obj_valid(left) || ~Obj_Isa(left, 'gs_Basis'): Message, 'Equality not defined for operands.'
    ~Isa(right, /scalar) || ~Obj_valid(right) || ~Obj_Isa(right, 'gs_Basis'): Message, 'Equality not defined for operands.'
    Obj_Class(left) ne Obj_Class(right): Message, 'Equality not defined for operands.'
    else:
  endcase
  
  if left.regions ne right.regions then Return, 0B
  if ~Array_Equal(left.voxelSize, right.voxelSize) then Return, 0B
  
  Return, 1

END

;============================================================

PRO gs_Basis__define

  compile_opt idl3
  
  dum = {gs_Basis, regions: Obj_New(), origin: Obj_New(), dataDims: LonArr(3), voxelSize: DblArr(3), x: Ptr_New(), y: Ptr_New(), z: Ptr_New(), inherits IDL_object}

END