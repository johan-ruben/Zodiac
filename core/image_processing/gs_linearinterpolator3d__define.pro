FUNCTION gs_LinearInterpolator3D::Init

  compile_opt idl2
  
  tmp = self.gs_Interpolator::Init(nDimensions = 3L)
  
  if tmp ne 1 then Return, 0 else Return, 1

END

;===========================================================================

FUNCTION gs_LinearInterpolator3D::Apply, oImg, x, y, z, voxelSize = voxelSize, noForce = noForce

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
  
  dataDimsOut = Size(x, /dimensions)
  imgOut = DblArr(dataDimsOut)
  
  gfortran = !true
  
  if gfortran then begin
    shared = Routine_Dir() + 'ggray.dll'
    entry = 'linear3d_wrapper_' 
    
    if ~File_Test(shared) then shared = jg_AddSlash((shared.Split(Path_Sep() eq '\' ? '\\' : '/'))[0:-4].Join(Path_Sep()) + Path_Sep() + 'lib') + 'ggray.dll'
    
  endif else begin
    if !cpu.tpool_nthreads gt 1 then shared = 'C:\Users\johan\idl_pro\jg_pro\pollux\gray.dll' else $
       shared = 'C:\Users\johan\idl_pro\jg_pro\pollux\gray_single.dll'
       entry = 'LINEAR3D_WRAPPER'
  endelse
  
  i = Double(x[*])/oImg.voxelSize[0] - 0.5D + oImg.dataDims[0]/2D
  j = Double(y[*])/oImg.voxelSize[1] - 0.5D + oImg.dataDims[1]/2D
  k = Double(z[*])/oImg.voxelSize[2] - 0.5D + oImg.dataDims[2]/2D
  nPts = dataDimsOut[0]*dataDimsOut[1]*dataDimsOut[2]
  ijk = [Transpose(i), Transpose(j), Transpose(k)]
  
  tmp = Call_External(shared, entry, Double(oImg.imgData), oImg.dataDims[0], oImg.dataDims[1],oImg.dataDims[2], ijk, nPts, imgOut, dataDimsOut[0], dataDimsOut[1], dataDimsOut[2])
  
  Return, oImg.New(imgOut, voxelSize = voxelSize, noForce = noForce)
  
END

;===========================================================================

PRO gs_LinearInterpolator3D__define

  compile_opt idl2
  
  dum = {gs_LinearInterpolator3D, inherits gs_Interpolator}

END