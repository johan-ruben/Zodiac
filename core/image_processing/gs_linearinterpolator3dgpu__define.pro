FUNCTION gs_LinearInterpolator3DGPU::Init

  compile_opt idl2

  tmp = self.gs_Interpolator::Init(nDimensions = 3L)
  
  self.cp = python.Import('cupy')
  self.cuInt = python.Import('cupyx.scipy.ndimage')
  
  if tmp ne 1 then Return, 0 else Return, 1

END

;====================================================

PRO gs_LinearInterpolator3DGPU::CleanUp

  compile_opt idl3
  
  if Obj_valid(self.cp) then Obj_Destroy, self.cp
  if Obj_Valid(self.cuInt) then Obj_Destroy, self.cuInt

END

;===========================================================================

FUNCTION gs_LinearInterpolator3DGPU::Apply, oImg, x, y, z, voxelSize = voxelSize, noForce = noForce

  compile_opt idl2

  case 1B of
    ~Obj_valid(oImg) && ~Obj_Isa(oImg, 'gs_Image'): Message, 'IMage must be of type gs_Image'
    oImg.nDimensions ne self.nDimensions: Message, 'Image must be three-dimensional.'
    ~Isa(x, /float, /array) || ~Isa(y, /float, /array) || ~Isa(z, /float, /array): Message, 'Coordinates must be floating point arrays.'
    Size(x, /n_dimensions) ne 3: Message, 'Coordinates must eb 3D.'
    ~Array_Equal(Size(x, /dimensions), Size(y, /dimensions)) || ~Array_Equal(Size(x, /dimensions), Size(z, /dimensions)): Message, 'Matrix dimensions do not agree.'
    ~Isa(voxelSize, /float) || (N_Elements(voxelSize) ne 3): Message, 'Voxel sizes must be a three-elemnt floating-point array.'
    else:
  endcase


  i = Double(x)/oImg.voxelSize[0] - 0.5D + oImg.dataDims[0]/2D
  j = Double(y)/oImg.voxelSize[1] - 0.5D + oImg.dataDims[1]/2D
  k = Double(z)/oImg.voxelSize[2] - 0.5D + oImg.dataDims[2]/2D
  
  ijk = [[[[k]]], [[[j]]], [[[i]]]]
  
  cuImg = self.cp.asarray(Double(oImg.imgData))  
  imgOut = self.cp.asnumpy(self.cuInt.map_coordinates(cuImg, self.cp.asarray(ijk), order = 1, prefilter = !false))
  
  Obj_Destroy, cuImg
  
  Return, oImg.New(imgOut, voxelSize = voxelSize, noForce = noForce)

END

;===========================================================================

PRO gs_LinearInterpolator3DGPU__define

  compile_opt idl2

  dum = {gs_LinearInterpolator3DGPU, cp: Obj_New(), cuInt: Obj_New(), inherits gs_Interpolator}

END