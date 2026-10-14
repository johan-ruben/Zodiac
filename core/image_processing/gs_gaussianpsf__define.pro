FUNCTION gs_GaussianPSF::Init, fwhm = fwhm, mode = mode, dataDims = dataDims, voxelSize = voxelSize

  compile_opt idl3
  
  tmp = self.gs_GaussianFilter::Init(fwhm = fwhm, nDimensions = N_Elements(dataDims), mode = mode)
  
  if tmp eq 0 then Return, 0
  
  case 1B of
    ~Isa(dataDims, /integer, /array): Message, 'Data dims must be an integer array.'
    ~Isa(voxelSize, /float, /array) || (N_Elements(voxelSize) ne self.nDimensions): Message, 'Voxel size must be a floating-point array with number of elements equal to number of dimensions.' 
    else:
  endcase
  
  self.dataDims = Ptr_New(Long(dataDims))
  self.voxelSize = Ptr_New(Double(voxelSize))
  
  self.psf = Ptr_New(self.gs_GaussianFilter::GetFilter(*self.datadims, *self.voxelSize, padTo = *self.dataDims*2))
  
  Return, 1
  
END

;===========================================================

PRO gs_GaussianPSF::CleanUp

  compile_opt idl3
  
  self.gs_GaussianFilter::CleanUp
  if Ptr_Valid(self.dataDims) then Ptr_Free, self.dataDims
  if Ptr_Valid(self.voxelSize) then Ptr_Free, self.dataDims
  if Ptr_Valid(self.psf) then Ptr_Free, self.psf

END

;=====================================================================

PRO gs_GaussianPSF::GetProperty, voxelSize = voxelSize, dataDims = dataDims, _ref_extra = extra

  compile_opt idl3
  
  if Arg_Present(voxelSize) then voxelSize = *self.voxelSize
  if Arg_Present(dataDims) then dataDims = *self.dataDims
  
  self.gs_GaussianFilter::GetProperty, _extra = extra
  
END

;==========================================================

FUNCTION gs_GaussianPSF::GetFilter, dataDims, binSize, padTo = padTo

  compile_opt idl3
  
  case 1B of
    ~Array_Equal(dataDims, *self.dataDims): Message, 'Datadims do not agree.'
    ~Array_Equal(binSize, *self.voxelSize): Message, 'Voxel size do not agree.'
    ~Array_Equal(padTo, *self.dataDims*2): Message, 'Datadims do not agree.'
    else:
  endcase
  
  Return, *self.psf
  
END

;==========================================================

PRO gs_GaussianPSF__define

  compile_opt idl3
  
  dum = {gs_GaussianPSF, voxelSize: Ptr_New(), $
    dataDims: Ptr_New(), psf: Ptr_New(), $
    inherits gs_GaussianFilter}

END