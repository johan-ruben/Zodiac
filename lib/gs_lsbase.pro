FUNCTION gs_LSbase, img, basis, nonNegative = nonNegative, orthonormal = orthonormal

  compile_opt idl3
  
  if KeyWord_Set(nonNegative) then begin
    p = gs_QPnonNegativeBase(img, basis)
  endif else begin
    p = gs_LeastSquaresBase(img, basis, orthonormal = orthonormal)
  endelse

  Return, p

END