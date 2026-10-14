FUNCTION gs_ForceToVoxels, img, emulateDataDims, regions, setToZero = setToZero

  compile_opt idl2

  dataDims = img.dim
  imgEst = img

  if N_Elements(regions) gt 0then begin
    foreach lbl, regions.names do begin
      ii = regions.Indices(lbl)
      imgEst[ii] = !values.f_nan
    endforeach
  endif
  
  voxelRatio = img.dim/emulateDataDims
  
  krnl = Make_Array(voxelRatio, type = img.typeCode, value = 1)
  if Size(krnl, /n_dimensions) eq 2 then krnl = Reform(krnl, voxelRatio)
  imgEst = Rebin((Reverse(Reverse(Reverse(Convol(Reverse(Reverse(Reverse(imgEst, 1), 2), 3), krnl, /nan, missing = 0, /normalize, center = 0, /edge_mirror), 1), 2), 3))[0:*:voxelRatio[0], 0:*:voxelRatio[1], 0:*:voxelRatio[2]], dataDims, /sample)
  
  if N_Elements(regions) gt 0 then begin
    
    if KeyWord_Set(setToZero) then begin
      foreach lbl, regions.names do begin
        ii = regions.Indices(lbl)
        imgEst[ii] = 0  
      endforeach
    endif else begin
    
      foreach lbl, regions.names do begin
        ii = regions.Indices(lbl)
        imgEst[ii] = Mean(img[ii])    
      endforeach
      
    endelse
    
  endif

  Return, imgEst

END