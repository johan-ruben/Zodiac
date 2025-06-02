PRO gs_AttenuateESS, ssImg, enImg, densImg, voxelSize, atnEnergy, atnMuRho

  compile_opt idl3
  
  rDensImg = Reverse(densImg, 1)
  pDens = Reverse(Total(rDensImg, 1, /cumulative)*voxelSize[0] - rDensimg*voxelSize[0]/2D, 1)
  
  ii = Where(Finite(enImg), count, /null, complement = jj, nComplement = cCount)
  
  if count gt 0 then begin
    muEn = Interpol(atnMuRho, atnEnergy, enImg[ii]) > 0.
    pDens[ii] *= muEn
  endif
  
  if cCount gt 0 then pDens[jj] = 0.
  if Min(pDens) lt 0. then STOP
  ssImg *= exp(-pDens)

END