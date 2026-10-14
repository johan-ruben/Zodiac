FUNCTION gs_CheckOrthonormailty, b, order, tolerance = tolerance

  compile_opt idl3
  
  if N_Elements(tolerance) eq 0 then tol = 1D-6 else tol = tolerance
  nVxls = N_Elements(b[0, 0, 0])
  A = DblArr((order + 1)^3, nVxls)

  for k = 0, order do for j = 0, order do for i = 0, order do A[i + j*(order + 1) + k*(order + 1)^2, *] = b[i, j, k]
  
  T = Transpose(A)##A
  Return, Array_Equal(T, Identity((order + 1)^3, /double), tolerance = tol)


END