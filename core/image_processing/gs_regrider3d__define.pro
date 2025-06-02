FUNCTION gs_Regrider3D::Init, voxelSize = voxelSize, dataDims = dataDims, interpolator = interpolator

  compile_opt idl3
  
  case 1B of
    ~Isa(voxelSize, /float, /array) || (N_Elements(voxelSize) ne 3): Message, 'Voxel size must be a three-element floating-point array.'
    ~Isa(dataDims, /integer, /array) || (N_Elements(dataDims) ne 3): Message, 'Data dims must be a three-element integer array.'
    ~Isa(interpolator, /scalar) || ~Obj_Valid(interpolator) || ~Obj_Isa(interpolator, 'gs_Interpolator'): Message, 'Interpolator must be gs_interpolator.'
    else:  
  endcase
  
  self.voxelSize = voxelSize
  self.dataDims = dataDims
  self.interpolator = interpolator
  
  self.x = Ptr_New(Rebin(DindGen(self.dataDims[0], start = -self.dataDims[0]/2. + .5)*self.voxelSize[0], self.dataDims))
  self.y = Ptr_New(Rebin(DindGen(1, self.dataDims[1], start = -self.dataDims[1]/2. + .5)*self.voxelSize[1], self.dataDims))
  self.z = Ptr_New(Rebin(DindGen(1, 1, self.dataDims[2], start = -self.dataDims[2]/2. + .5)*self.voxelSize[2], self.dataDims))
  
  Return, 1
  
END

;=======================================================================================

PRO gs_Regrider3D::CleanUp

  compile_opt idl3
  
  if Ptr_Valid(self.x) then Ptr_Free, self.x
  if Ptr_Valid(self.y) then Ptr_Free, self.y
  if Ptr_Valid(self.z) then Ptr_Free, self.z

END

;==========================================================================================

PRO gs_Regrider3D::GetProperty, voxelSize = voxelSize, dataDims = dataDims

  compile_opt idl3
  
  if Arg_Present(voxelSize) then voxelSize = self.voxelSize
  if Arg_Present(dataDims) then dataDims = self.dataDims 
  
END

;==========================================================================================

FUNCTION gs_Regrider3D::Apply, oImg

  compile_opt idl3
  
  case 1B of
    ~Isa(oImg, /scalar) || ~Obj_Valid(oImg) || ~Obj_Isa(oImg, 'gs_Image') || (oImg.nDimensions ne 3): Message, 'Image must be a three-dimensional gs_image.'
    else:  
  endcase

  Return, self.interpolator.Apply(oImg, *self.x, *self.y, *self.z, voxelSize = self.voxelSize)

END

;==========================================================================================

PRO gs_Regrider3D__define

  compile_opt idl3
  
  dum = {gs_Regrider3D, voxelSize: DblArr(3), dataDims: LonArr(3), x: Ptr_New(), y: Ptr_New(), z: Ptr_New(), interpolator: Obj_New(), inherits IDL_Object} 

END