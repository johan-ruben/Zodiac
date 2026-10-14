FUNCTION gs_LeastSquaresBase, img, basis, orthonormal = orthonormal

  compile_opt idl3
  
  names = basis.regions.names
  p = OrderedHash()
  
  foreach nme, names do begin
    
    ii = basis.regions.Indices(nme, count = nVxls)
    order = basis.GetOrder(nme)
    Y = Transpose(img[ii])
    A = DblArr((order + 1)^3, nVxls)
    
    for k = 0, order do for j = 0, order do for i = 0, order do A[i + j*(order + 1) + k*(order + 1)^2, *] = basis[nme, i, j, k]
    
    if KeyWord_Set(orthonormal) then begin
      F = Transpose(A)##Y
    endif else begin
    
      sts = 0
      if order gt 0 then  F = La_Invert(Transpose(A)##A, status = sts)##Transpose(A)##Y else F = (1./(Transpose(A)##A))##Transpose(A)##Y
      if sts ne 0 then begin
        F = DblArr(1, (order + 1)^3)
        F[0] = Transpose(A[0, *])##Y
      endif
      
    endelse
    
    for k = 0, order do for j = 0, order do for i = 0, order do p[nme, i, j, k] = F[i + j*(order + 1) + k*(order + 1)^2]
  
  endforeach

  Return, p

END