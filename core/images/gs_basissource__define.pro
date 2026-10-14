FUNCTION gs_BasisSource::Init, imgDataIn, emulateMatrix = emulateMatrix, basis = basis, nonNegative = nonNegative, leastSquares = leastSquares, nonRegionData = nonRegionData, _extra = extra
  
  compile_opt idl3
  
  case 1B of
    (~Isa(imgDataIn, /float, /array) || (Size(imgDataIn, /n_dimensions) ne 3)) && (~Obj_Isa(imgDataIn, 'OrderedHash')): Message, 'Image data must be a three-dimensional floating-point array'
    ~Isa(emulateMatrix, /integer, /array) || (N_Elements(emulateMatrix) ne 3): Message, 'Emulated matrix size must be a three-element integer array.'
    ~Isa(basis, /scalar) || ~Obj_Valid(basis) || ~Obj_Isa(basis, 'gs_Basis'): Message, 'Basis must be gs_Basis.'
    else:
  endcase
  
  if KeyWord_Set(nonNegative) then self.nonNegative = !true else self.nonNegative = !false
  regDataDims = basis.regions.dataDims
  
  if ~Isa(imgDataIn, /float) && Obj_Isa(imgDataIn, 'OrderedHash') then begin
    
    imgData = DblArr(regDataDims)
    
    foreach fxyz, imgDataIn, nme do begin
      
      ii = basis.regions.Indices(nme)
      
      foreach fxy, fxyz, i do begin
        foreach fx, fxy, j do begin
          foreach f, fx, k do begin
            imgData[ii] += f*basis[nme, i, j, k]
          endforeach
        endforeach
      endforeach
      
    endforeach
    
    ii = basis.regions.Indices(/undefined, count = nv)
    if nv gt 0 then imgData[ii] = nonRegionData
    
  endif else begin
    
    imgDataDims = Size(imgDataIn, /dimensions)
    if ~Array_Equal(imgDataDims, regDataDims) && Array_Equal(imgDataDims, emulateMatrix) then begin

      imgData = Rebin(imgDataIn, regDataDims, /sample)

    endif else imgData = imgDataIn
    
  endelse

  im = imgData
  imgData = gs_ForceToVoxels(imgData, emulateMatrix, basis.regions, /setToZero)
  self.emulateMatrix = emulateMatrix
  self.basis = basis
  
  self.coordinates = ~Isa(imgDataIn, /float) ? OrderedHash(imgDataIn.Keys(), imgDataIn.Values()) : gs_LSbase(im, self.basis, nonNegative = self.nonNegative, orthonormal = self.basis.orthonormal)
  
  foreach fxyz, self.coordinates, nme do begin 
   
    ii = self.basis.regions.Indices(nme)
   
    foreach fxy, fxyz, i do begin
      foreach fx, fxy, j do begin
        foreach f, fx, k do begin       
          imgData[ii] += f*self.basis[nme, i, j, k]          
        endforeach
      endforeach
    endforeach
   
  endforeach
  
  tmp = self.gs_Source::Init(imgData, voxelSize = self.basis.voxelSize, nonNegative = nonNegative, _extra = extra)
  if tmp eq 0 then Return, 0
  
  Return, 1
  
END

;====================================================================================================

PRO gs_BasisSource::CleanUp

  compile_opt idl3
  
  if Obj_Valid(self.coordinates) then Obj_Destroy, self.coordinates

END

;====================================================================================================

PRO gs_BasisSource::GetProperty, imgData = imgData, natImgData = natImgData, dataDims = dataDims, natDataDims = natDataDims, voxelSize = voxelSize, $
  natVoxelSize = natVoxelSize, basis = basis, _ref_extra = extra

  compile_opt idl3
  
  if Arg_Present(imgData) then imgData = Rebin(*self.imgData, self.emulateMatrix)
  if Arg_Present(natImgData) then natImgData = *self.imgData
  if Arg_Present(dataDims) then dataDims = self.emulateMatrix
  if Arg_Present(natDataDims) then natDataDims = Size(*self.imgData, /dimensions)
  if Arg_Present(voxelSize) then voxelSize = self.voxelSize*Double(Size(*self.imgData, /dimensions))/Double(self.emulateMatrix)
  if Arg_Present(natVoxelSize) then natVoxelSize = self.voxelSize
  if Arg_Present(basis) then basis = self.basis
  
  self.gs_Source::GetProperty, _extra = extra
  
END

;====================================================================================================

FUNCTION gs_BasisSource::_OverloadBracketsRightSide, isRange, nme, i, j, k

  compile_opt idl3
  
  if jg_Any(isRange) then Message, 'Ranges not allowed in this context.'
  
  Return, self.coordinates[nme, i, j, k]

END

;====================================================================================================

FUNCTION gs_BasisSource::New, imgData, basis = basis, emulateMatrix = emulateMatrix, _extra = extra

  compile_opt idl3
  
  if N_Elements(basis) gt 0 then b = basis else b = self.basis
  if N_Elements(emulateMatrix) gt 0 then em = emulateMatrix else em = self.emulateMatrix
  
  Return, self.gs_Source::New(imgData, basis = b, emulateMatrix = em, _extra = extra)
  
END

;===================================================================================================

FUNCTION gs_BasisSource::_OverloadPlus, left, right 

  compile_opt idl3
  
  if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_BasisSource') then begin
    
    case 1B of
      
      Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_BasisSource'): begin       
        im = left.natImgData + right.natImgData
        nn = Boolean(left.nonNegative && right.nonNegative)
        Return, left.New(im, nonNegative = nn)      
      end
      
      Isa(right, /float): begin
        
        if Isa(right, /array) then begin
          if ~Array_Equal(right.dim, left.natDataDims) then Message, 'Addition not defined for operands.'
        endif
        
        im = left.natImgDat + right
        Return, left.New(im)
        
      end
      
      else: Message, 'Addition not defined for operands.'
      
    endcase
    
  endif else Return, right + left

END

;======================================================================================

FUNCTION gs_BasisSource::_OverloadAsterisk, left, right 

  compile_opt idl3
  
  voxelWise = !true
  
  if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_BasisSource') then begin

    case 1B of

      Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_BasisSource'): begin
        
        nn = Boolean(left.nonNegative && right.nonNegative)
        
        if voxelWise then begin
          img = left.natImgData*right.natImgData
          Return, left.New(img, nonNegative = nn, nonRegionData = nonRegion)
        endif else begin
        
          bleft = left.basis
          ff = OrderedHash()
          
          foreach nme, bleft.regions.names do begin
            odr = bleft.GetOrder(nme)
            for k = 0, odr do for j = 0, odr do for i = 0, odr do ff[nme, i, j, k] = left[nme, i, j, k]*right[nme, i, j, k]
          endforeach
          ii = bleft.regions.Indices(/undefined, count = nv)
          if nv gt 0 then nonRegion = left.natImgData[ii]*right.natImgData[ii]
     
          Return, left.New(ff, nonNegative = nn, nonRegionData = nonRegion)     
           
        endelse
      
      end

      Isa(right, /float) && (Isa(right, /scalar) || Array_Equal(left.natDataDims, right.dim)): begin
        
        im = left.natImgDat*right
        Return, left.New(im)

      end

      else: Message, 'Multiplication not defined for operands.'

    endcase

  endif else Return, right*left

END

;======================================================================================

FUNCTION gs_BasisSource::_OverloadSlash, left, right

  compile_opt idl3

  voxelWise = !true

  if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_BasisSource') then begin

    case 1B of

      Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_BasisSource'): begin

        nn = Boolean(left.nonNegative && right.nonNegative)

        if voxelWise then begin
          img = left.natImgData/right.natImgData
          Return, left.New(img, nonNegative = nn, nonRegionData = nonRegion)
        endif else begin

          bleft = left.basis
          ff = OrderedHash()

          foreach nme, bleft.regions.names do begin
            odr = bleft.GetOrder(nme)
            for k = 0, odr do for j = 0, odr do for i = 0, odr do ff[nme, i, j, k] = left[nme, i, j, k]/right[nme, i, j, k]
          endforeach
          ii = bleft.regions.Indices(/undefined, count = nv)
          if nv gt 0 then nonRegion = left.natImgData[ii]/right.natImgData[ii]

          Return, left.New(ff, nonNegative = nn, nonRegionData = nonRegion)

        endelse

      end

      Isa(right, /float) && (Isa(right, /scalar) || Array_Equal(left.natDataDims, right.dim)): begin

        im = left.natImgDat/right
        Return, left.New(im)

      end

      else: Message, 'Division not defined for operands.'

    endcase

  endif else if Isa(left, /float) && (Isa(left, /scalar) || Array_Equal(right.natDataDims, left.dim)) then begin
    im = left/right.natImgDat
    Return, right.New(im)    
  endif else Message, 'Division not defined for operands.'

END

;======================================================================================

FUNCTION gs_BasisSource::Source, nonNegative = nonNegative

  compile_opt idl3
  
  self.GetProperty, imgData = imgData, voxelSize = voxelSize, radionuclide = radionuclide, nonNegative = nn
  if N_Elements(nonNegative) gt 0 then nn = nonNegative
  Return, gs_Source(imgData, voxelSize = voxelSize, radionuclide = radionuclide, nonNegative = nonNegative)

END

;===================================================================================================

FUNCTION gs_BasisSource::_OverloadPound, oSrc, oFilter

  compile_opt idl3
  
  s = oSrc.Source()
  sf = self.gs_Source._OverloadPound(s, oFilter)
  Return, self.New(sf.imgData)

END

;====================================================================================================

PRO gs_BasisSource::ToFile, fileName, compress = compress, overwrite = overwrite

  compile_opt idl3
  
  if File_Test(fileName, /regular) && ~KeyWord_Set(overwrite) then Message, 'File already exists: ' + fileName
  OpenW, lun, fileName, /get_lun
  
  cmp = Boolean(KeyWord_Set(compress))
  WriteU, lun, 'bsv01', self.emulateMatrix, self.nonNegative, self.numberFormat, cmp
  bsClass = Obj_Class(self.basis)
  nTokens = Fix(StrLen(bsClass))
  WriteU, lun, nTokens, bsClass
  
  self.basis.ToFile, lun, compress = compress
  
  self.radionuclide.Save, string = rncStr
  nRnc = N_Elements(rncStr)
  WriteU, lun, Long(nRnc)
  foreach line, rncStr do PrintF, lun, line
  
  nRegions = N_Elements(self.coordinates)
  WriteU, lun, Long(nRegions)
  
  foreach fxyz, self.coordinates, nme do begin
    
    nmeLen = Fix(StrLen(nme))
    WriteU, lun, nmeLen
    nOrders = self.basis.GetOrder(nme)
    WriteU, lun, Long(nOrders)
    WriteU, lun, nme
    foreach fxy, fxyz, i do begin
      foreach fx, fxy, j do begin
        foreach f, fx, k do begin
          WriteU, lun, Long(i), Long(j), Long(k), Double(self.coordinates[nme, i, j, k])
        endforeach
      endforeach
    endforeach
    
  endforeach
  
  ii = self.basis.regions.Indices(/undefined, count = cnt)
  WriteU, lun, Long(cnt)
  
  if cnt gt 0 then begin
    
    if cmp then begin
      d = Zlib_Compress((*self.imgData)[ii], /gzip_header)
      nBytes = Long(N_Elements(d))
      WriteU, lun, nBytes, d
    endif else begin
      WriteU, lun, (*self.imgData)[ii]
    endelse
    
  endif
  
  Free_Lun, lun
  
END

;====================================================================================================

FUNCTION gs_BasisSource::FromFile, fileName, _basis = _basis

  compile_opt idl3, static
  
  if ~File_Test(fileName, /regular, /read) then Message, 'File does not exist: ' + fileName
  OpenR, lun, fileName, /get_lun
  
  sgn = BytArr(5)
  emulateMatrix = LonArr(3)
  nonNegative = !false
  numberFormatB = BytArr(6)
  cmp = !false
  nRegions = 0L
  
  ReadU, lun, sgn, emulateMatrix, nonNegative, numberFormatB, cmp
  if String(sgn) ne 'bsv01' then begin
    errorMsg = 'File is not a basis source file.'
    goto, ERROR
  endif
  
  numberFormat = String(numberFormatB)
  nTokens = 0S
  ReadU, lun, nTokens
  clBytes = BytArr(nTokens)
  ReadU, lun, clBytes
  bsClass = String(clBytes)
  
  if N_Elements(_basis) gt 0 then begin
    
    case bsClass of
      'GS_FOURIERBASIS': !null = gs_FourierBasis.FromFile(lun, /skip)
      else: begin
        errorMsg = 'Unknown basis type: ' + bsClass
        goto, ERROR
      end
    endcase
    
    basis = _basis
    
  endif else begin
    case bsClass of
      'GS_FOURIERBASIS': basis = gs_FourierBasis.FromFile(lun)
      else: begin
        errorMsg = 'Unknown basis type: ' + bsClass
        goto, ERROR
      end
    endcase
    
  endelse
  
  nRnc = 0L
  ReadU, lun, nRnc
  rncStr = StrArr(nRnc)
  for i = 0, nRnc - 1 do begin
    str = ''
    ReadF, lun, str
    rncStr[i] = str
  endfor
  
  rnc = gs_Radionuclide.Restore(rncStr, /string)
   
  ReadU, lun, nRegions 
  coordinates = OrderedHash()
  
  for r = 0, nRegions - 1 do begin
    
    nTokens = 0S
    ReadU, lun, nTokens
    nOrders = 0L
    ReadU, lun, nOrders
    
    nmeB = BytArr(nTokens)
    ReadU, lun, nmeB
    nme = String(nmeB)
    
    for k = 0, nOrders do for j = 0, nOrders do for i = 0, nOrders do begin
      f = 0D
      ii = 0L
      jj = 0L
      kk = 0L
      ReadU, lun, ii, jj, kk, f
      coordinates[nme, ii, jj, kk] = f
    endfor
    
  endfor
  
  count = 0L
  ReadU, lun, count
  if count gt 0 then begin
    
    if cmp then begin
      nBytes = 0L
      ReadU, lun, nBytes
      d = BytArr(nBytes)
      ReadU, lun, d
      data = Zlib_Uncompress(d, /gzip_header, type = StrCmp(numberFormat, 'single') ? 4 : 5)
    endif else begin 
      if StrCmp(numberFormat, 'single') then data = FltArr(count) else data = DblArr(count)
      ReadU, lun, data
    endelse
    
  endif
  
  Free_Lun, lun
  
  Return, gs_BasisSource(coordinates, emulateMatrix = emulateMatrix, basis = basis, nonRegionData = data, nonNegative = nonNegative, radionuclide = rnc)
  
  ERROR:
  
  Free_Lun, lun
  Message, errorMsg
  
END

;====================================================================================================

PRO gs_BasisSource__define

  compile_opt idl3
  
  dum = {gs_BasisSource, emulateMatrix: LonArr(3), basis: Obj_New(), coordinates: Obj_New(), inherits gs_Source}

END