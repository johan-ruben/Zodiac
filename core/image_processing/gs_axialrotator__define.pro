FUNCTION gs_AxialRotator::Init, interpolator = interpolator, stepSize = stepSize

  compile_opt idl2
  
  tmp = self.gs_Transformer::Init(nDimensions = 3, interpolator = interpolator, stepSize = stepSize) 
  Return, tmp
  
END

;=======================================================================================

FUNCTION gs_AxialRotator::Apply, oImg, theta, pivot, spacing, dataDims, noForce = noForce, axialOffset = axialOffset

  compile_opt idl2
  
  case 1B of
    ~Isa(theta, /scalar, /float): Message, 'Rotation angle must be scalar floating point.'
    ~Isa(pivot, /float) || (N_Elements(pivot) ne 2): Message, 'Pivot must be a two-element floating-point array.'
    ~Isa(spacing, /float) || ((N_Elements(spacing) ne 2) && (N_Elements(spacing) ne 3)): Message, 'Spacing must be a two-element floating-point array.'
    ~Isa(dataDims, /integer) || ((N_Elements(dataDims) ne 2) && (N_Elements(dataDims) ne 3)): Message, 'Data dimensions must be a two-element integer array.'
    else:
  endcase
  
  if N_Elements(spacing) eq 2 then begin
    voxSiz = [self.stepSize, spacing]
  endif else begin
    voxSiz = spacing
  endelse
  
  if N_Elements(dataDims) eq 2 then begin
    dSz = [Ceil(oImg.dataDims[0]*oImg.voxelSize[0]/voxSiz[0]), dataDims[0], dataDims[1]] 
  endif else begin
    dSz = dataDims
  endelse
  
  x = (Rebin((DindGen(dSz[0], start = -dSz[0]/2D) + .5D)*voxSiz[0], dSz[0:1]))[*]
  y = (Rebin((DindGen(1, dSz[1], start = -dSz[1]/2D) + .5D)*voxSiz[1], dSz[0:1]))[*]
  
  xy = [[x], [y]]
  
  R = [[cos(theta*!const.dtor), -sin(theta*!const.dtor)], [sin(theta*!const.dtor), cos(theta*!const.dtor)]]
  xyR = R##xy
  
  xR = Rebin(Reform(xyR[*, 0], dSz[0:1]), dSz)
  yR = Rebin(Reform(xyR[*, 1], dSz[0:1]), dSz)
  zR = Rebin((DindGen(1, 1, dSz[2], start = -dSz[2]/2D) + .5D)*voxSiz[2], dSz)
  if N_Elements(axialOffset) gt 0 then zR -= axialOffset
  
  Return, self.interpolator.Apply(oImg, xR, yR, zR, voxelSize = voxSiz, noForce = noForce)
  
END 

;=======================================================================================

PRO gs_AxialRotator__define

  compile_opt idl2
  
  dum = {gs_AxialRotator, inherits gs_Transformer}

END