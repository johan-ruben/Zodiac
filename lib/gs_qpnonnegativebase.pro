FUNCTION gs_QPnonNegativeBase, img, basis

  compile_opt idl3
  
  qp = python.Import('qpsolvers')
  names = basis.regions.names
  p = OrderedHash()
  
  foreach nme, names do begin
    
    ii = basis.regions.Indices(nme, count = nVxls)
    order = basis.GetOrder(nme)
    Y = Transpose(img[ii])
    A = DblArr((order + 1)^3, nVxls)

    for k = 0, order do for j = 0, order do for i = 0, order do A[i + j*(order + 1) + k*(order + 1)^2, *] = basis[nme, i, j, k]
    
    f000 = (Transpose(A[0, *])##Y)[0] > 0.
    if order gt 0 then begin
      Q = Transpose(A[1:*, *])##A[1:*, *] 
      c = Transpose(-Transpose(A[1:*, *])##(Y - f000*A[0, *]))
      h = f000*A[0, *].Reform()
      
      f1 = qp.solve_qp(Q, c, -A[1:*, *], h, solver = 'quadprog')
      if Isa(f1, /null) then f = [f000, DblArr((order + 1)^3 - 1)] else f = [f000, f1]

    endif else f = [f000]
    for k = 0, order do for j = 0, order do for i = 0, order do p[nme, i, j, k] = f[i + j*(order + 1) + k*(order + 1)^2]
   
  endforeach
  
  Return, p
  
END