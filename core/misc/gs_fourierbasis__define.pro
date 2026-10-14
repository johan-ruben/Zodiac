FUNCTION gs_FourierBasis::Init, regions, voxelSize, order = order

  compile_opt idl3
  
  names = regions.name
  self.period = OrderedHash()
  origin = OrderedHash()
  self.orthonormal = !true
  
  foreach nme, names do begin
    ii = regions.Indices(nme)
    ix = ii mod regions.dataDims[0]
    iy = (ii mod Product(regions.dataDims[0:1], /integer))/regions.dataDims[0]
    iz = ii/Product(regions.dataDims[0:1], /integer)
    self.period[nme] = Double([Max(ix) - Min(ix), Max(iy) - Min(iy), Max(iz) - Min(iz)])*voxelSize > 1.
    origin[nme] = Double([Min(ix), Min(iy), Min(iz)])*voxelSize
  endforeach
  
  tmp = self.gs_Basis::Init(regions, voxelSize, origin)
  if tmp eq 0 then Return, 0
  
  self.order = OrderedHash(names, LonArr(N_Elements(names)))
  
  if N_Elements(order) then begin
    foreach odr, order, nme do begin
      if self.order.HasKey(nme) then self.order[nme] = odr else Message, 'Unknown region: ' + nme
      nvxls = N_Elements(self.regions.Indices(nme)) 
      while (self.order[nme] + 1)^3 gt nVxls do self.order[nme] -= 1
    endforeach
  endif
  
  self.baseFunctions = OrderedHash()
  nRegions = N_Elements(self.order)
  
  for p = 0, nRegions - 1 do begin
    odr = self.GetOrder(names[p]) + 1
    repeat begin   
      self.order[names[p]] = --odr
      odr = self.GetOrder(names[p])
      bb = self._Base(names[p], odr)
      isOrtho = gs_CheckOrthonormailty(bb, odr)
      if ~isOrtho && odr eq 0 then STOP
    endrep until isOrtho
   
    self.baseFunctions[names[p]] = bb
  endfor
  
  Return, 1
    
END

;=====================================================================

FUNCTION gs_FourierBasis::_Base, name, order

  compile_opt idl3
  
  ii = self.regions.Indices(name, count = nVxls)
  origin = self.origin[name]
  period = self.period[name]
  x = (*self.x)[ii] - origin[0]
  y = (*self.y)[ii] - origin[1]
  z = (*self.z)[ii] - origin[2]
  sp = python.Import('scipy')
  
  e = OrderedHash()
  
  if order gt 0 then begin
    A = DblArr((order + 1)^3 - 1, nVxls)
    for k = 0, order do begin
      for j = 0, order do begin
        for i = 0, order do begin
  
          v = cos(!dpi*i*(2.*x + 1.)/(2.*period[0]))*cos(!dpi*j*(2.*y + 1.)/(2.*period[1]))*cos(!dpi*k*(2.*z + 1.)/(2.*period[2]))
          if k eq 0 && j eq 0 && i eq 0 then begin
            f000 = v/sqrt(Total(v^2))
          endif else begin
            v = v - Mean(v)
            nrm = sqrt(Total(v^2))
            if nrm gt 0 then v = v/nrm
            
            A[i + j*(order + 1) + k*(order + 1)^2 - 1, *] = v
            
          endelse
  
        endfor
      endfor
    endfor
    
    ee = DblArr((order + 1)^3 - 1, nVxls)
    ee1 = sp.linalg.orth(A)
    ee[0, 0] = ee1
    
    for k = 0, order do for j = 0, order do for i = 0, order do begin
      if k eq 0 && j eq 0 && i eq 0 then e[i, j, k] = f000 else $
        e[i, j, k] = ee[i + j*(order + 1) + k*(order + 1)^2 - 1, *]
    endfor
    
  endif else begin
    i = 0 & j = 0 & k = 0
    v = cos(!dpi*i*(2.*x + 1.)/(2.*period[0]))*cos(!dpi*j*(2.*y + 1.)/(2.*period[1]))*cos(!dpi*k*(2.*z + 1.)/(2.*period[2]))
    e[0, 0, 0] = v/sqrt(Total(v^2))
  endelse
 
  Return, e

END

;=====================================================================

PRO gs_FourierBasis::CleanUp

  compile_opt idl3
  
  if Obj_Valid(self.order) then Obj_Destroy, self.order
  if Obj_Valid(self.period) then Obj_Destroy, self.period
  
  self.gs_Basis::CleanUp

END

;=====================================================================

FUNCTION gs_FourierBasis::GetOrder, name

  compile_opt idl3
  
  Return, self.order[name]

END

;=====================================================================

PRO gs_FourierBasis::GetProperty, order = order, orthonormal = orthonormal, _ref_extra = extra

  compile_opt idl3
  
  if Arg_Present(order) then order = self.order
  if Arg_Present(orthonormal) then orthonormal = self.orthonormal
  self.gs_Basis::GetProperty, _extra = extra

END

;=====================================================================

FUNCTION gs_FourierBasis::_OverloadBracketsRightSide, isRange, name, orderX, orderY, orderZ

  compile_opt idl3
  
  if jg_Any(isRangeNme) then Message, 'Ranges not allowed in call.'
  
  Return, self.baseFunctions[name, orderX, orderY, orderZ]

END

;=====================================================================

FUNCTION gs_FourierBasis::_OverloadEQ, left, right

  compile_opt idl3
  
  tmp = self.gs_Basis::_OverloadEq(left, right)
  if tmp eq 0B then Return, 0B
  
  if jg_Any(left.order ne right.order) then Return, 0B
  
  Return, 1B  

END

;=====================================================================

FUNCTION gs_FourierBasis::_OverloadNE, left, right

  compile_opt idl3
  
  Return, ~(left eq right)

END

;=====================================================================

PRO gs_FourierBasis::ToFile, fileName, compress = compress, overwrite = overwrite

  compile_opt idl3
  
  if Isa(fileName, /string) then begin
    if ~KeyWord_Set(fileName) && File_Test(fileName, /regular) then Message, 'File already exists: ' + fileName
    OpenW, lun, fileName, /get_lun
  endif else lun = fileName
  
  nRegions = N_Elements(self.order)
  voxelSize = self.voxelSize
  
  WriteU, lun, 'fbv01', voxelSize, nRegions
  foreach odr, self.order, nme do begin
    WriteU, lun, Fix(StrLen(nme)), nme, odr
  endforeach
  self.regions.ToFile, lun, compress = compress
  
  if Isa(fileName, /string) then Free_Lun, lun
  
END

;=====================================================================

FUNCTION gs_FourierBasis::FromFile, fileName, skip = skip

  compile_opt idl3, static
  
  if Isa(fileName, /string) then begin
    if ~File_Test(fileName, /regular, /read) then Message, 'File does not exist: ' + fileName
    OpenR, lun, fileName, /get_lun
  endif else begin
    lun = fileName
  endelse
  
  sgn = BytArr(5)
  voxelSize = DblArr(3)
  nRegions = 0L
  
  ReadU, lun, sgn
  if String(sgn) ne 'fbv01' then begin
    errorMsg = 'File is not a basis file.'
    goto, ERROR
  endif
  
  ReadU, lun, voxelSize, nRegions
  order = OrderedHash()
  
  for i = 0, nRegions - 1 do begin
    nTokens = 0S
    ReadU, lun, nTokens
    strB = BytArr(nTokens)
    odr = 0L
    ReadU, lun, strB, odr
    nme = String(strB)
    order[nme] = odr   
  endfor
  
  oReg = gs_RegionMap.FromFile(lun)
  
  if KeyWord_Set(skip) then Return, 0
  
  Return, gs_FourierBasis(oReg, voxelSize, order = order)
  
  ERROR:
  Free_Lun, lun
  Message, errorMsg
  
END

;=====================================================================

PRO gs_FourierBasis__define

  compile_opt idl3
  
  dum = {gs_FourierBasis, order: Obj_New(), period: Obj_New(), baseFunctions: Obj_New(), orthonormal: !false, inherits gs_Basis}

END