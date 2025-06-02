FUNCTIOn jg_TotalResolution, dist2col, colThick, colDiameter, gap, holeShape, pixelSize, $
                        subsampleFactor = subsampleFactor, intrinsicFWHM = intrinsicFWHM, $
                        energy = energy, effectiveHole = effectiveHole, voxelSource = voxelSource

  compile_opt idl2
  
  if KeyWord_Set(effectiveHole) then begin
    
    jg_ReadCr3File, 'pb_sb', crossTable
    dum = Min(crossTable[0, *] - energy, iMin, /absolute)
    mu = Total(crossTable[1:*, iMin])*1.1247D1
    colT = colThick - 2./mu
    
  endif else colT = colThick
  
  if N_Elements(subsampleFactor) eq 0 then sub = 25 else sub = Long(subsampleFactor)
  if (sub mod 2) ne 1 then sub++
  subPixelSize = pixelSize/Double(sub)
  
  geo = jg_GeometricResolution(dist2col, colT, colDiameter, gap, holeShape, subPixelSize)
  
  if KeyWord_Set(voxelSource) then begin
    mskDim = geo.dim + sub + 1
    msk = DblArr(mskDim)
    msk[mskDim[0]/2 - sub/2 : mskDim[0]/2 + sub/2, mskDim[1]/2 - sub/2 : mskDim[1]/2 + sub/2] = 1D/Double(sub^2)
    geo = jg_ConvolFFT(msk, geo)
  endif
  
  if N_Elements(intrinsicFWHM) gt 0 then begin
    
    geoDims = geo.dim ;odd
    extDims = Round(intrinsicFWHM/subPixelSize)*4 ;even 
    totDims = geoDims + extDims ;odd + even -> odd
    totDims = totDims + ((sub - (totDims mod sub)) mod sub)
    
    ii = Where((totDims mod 2) ne 1, count, /null)
    if count gt 0 then totDims[ii] += sub
    
    extGeo = DblArr(totDims)
    extGeo[(totDims[0] - geoDims[0])/2, (totDims[1] - geoDims[1])/2] = geo
    
    irf = Double(PSF_Gaussian(nDimension = 2, nPixel = extDims + 1, fwhm = intrinsicFWHM/subPixelSize, /normalize))  
    psf = jg_ConvolFFT(extGeo, irf)
    
  endif else begin
    geoDims = geo.dim
    totDims = geoDims
    totDims = totDims + ((sub - (totDims mod sub)) mod sub)
    ii = Where((totDims mod 2) ne 1, count, /null)
    if count gt 0 then totDims[ii] += sub
    psf = DblArr(totDims)
    psf[(totDims[0] - geoDims[0])/2, (totDims[1] - geoDims[1])/2] = geo
  endelse
  
  psfA = Rebin(psf, totDims/sub)*Double(sub)^2
  
  psfA = psfA/Total(psfA)
  
  Return, psfA

END