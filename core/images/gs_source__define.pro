FUNCTION gs_Source::Init, imgData, nonNegative = nonNegative, voxelSize = voxelSize, radionuclide = radionuclide

  compile_opt idl2
  
  if Size(imgData, /n_dimensions) eq 2 then tmp = self.gs_Image::Init(Reform(imgData, [Size(imgData, /dimensions), 1]), nonNegative = nonNegative) else $
    tmp = self.gs_Image::Init(imgData, nonNegative = nonNegative)
  
  if self.nDimensions ne 3 then Message, 'Source must be three-dimensional.'
  
  if N_Elements(voxelSize) gt 0 then begin
    
    case 1B of
      ~Isa(voxelSize, /float, /array) || (N_Elements(voxelSize) ne 3): Message, 'Voxel size must be a three-element floating array.'
      else:
    endcase
    
    self.voxelSize = voxelSize
    
  endif else self.voxelSize = 1D

  case 1B of
    ~Obj_Valid(radionuclide) || ~Obj_Isa(radionuclide, 'gs_Radionuclide'): Message, 'Radionuclide must be of type gs_Radionuclide.'
    else:
  endcase
  
  self.radionuclide = radionuclide
  
  Return, 1
    
END

;===========================================================================================

PRO gs_Source::CleanUp

  compile_opt idl2
  
  self.gs_Image::CleanUp

END

;===========================================================================================

PRO gs_Source::GetProperty, voxelSize = voxelSize, radionuclide = radionuclide, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(voxelSize) then voxelSize = self.voxelSize
  if Arg_Present(radionuclide) then radionuclide = self.radionuclide
  
  self.gs_Image::GetProperty, _extra = extra

END

;===========================================================================================

FUNCTION gs_Source::_OverloadPlus, left, right, _extra = extra

  compile_opt idl2
  
  if Isa(left, /scalar) && Isa(right, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Obj_Valid(right) && Obj_Isa(right, 'gs_Source') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize
    radionuclide = left.radionuclide

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Isa(right, /number) then begin
    voxelSize = left.voxelSize 
    radionuclide = left.radionuclide   
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Source') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
    radionuclide = right.radionuclide
  endif else Message, 'Addition not defined for operands.'

  Return, self.gs_Image::_OverloadPlus(left, right, voxelSize = voxelSize, radionuclide = radionuclide, _extra = extra)

END

;===========================================================================================

FUNCTION gs_Source::_OverloadMinus, left, right

  compile_opt idl2

  if Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Obj_Valid(right) && Obj_Isa(right, 'gs_Source') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize
    radionuclide = left.radionuclide

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Isa(right, /number) then begin
    voxelSize = left.voxelSize
    radionuclide = left.radionuclide
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Source') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
    radionuclide = right.radionuclide
  endif else Message, 'Subtraction not defined for operands.'

  Return, self.gs_Image::_OverloadMinus(left, right, voxelSize = voxelSize, radionuclide = radionuclide)

END

;===========================================================================================

FUNCTION gs_Source::_OverloadMinusUnary

  compile_opt idl2
  
  Return, self.gs_Image::_OverloadMinusUnary(voxelSize = self.voxelSize, radionuclide = self.radionuclide)

END

;===========================================================================================

FUNCTION gs_Source::_OverloadAsterisk, left, right

  compile_opt idl2

  if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_Source') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize
    radionuclide = left.radionuclide

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Isa(right, /number) then begin
    voxelSize = left.voxelSize
    radionuclide = left.radionuclide
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Source') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
    radionuclide = right.radionuclide
  endif else Message, 'Multiplication not defined for operands.'

  Return, self.gs_Image::_OverloadAsterisk(left, right, voxelSize = voxelSize, radionuclide = radionuclide)

END

;===========================================================================================

FUNCTION gs_Source::_OverloadSlash, left, right

  compile_opt idl2

  if Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Obj_Valid(right) && Obj_Isa(right, 'gs_Source') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize
    radionuclide = left.radionuclide

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Isa(right, /number) then begin
    voxelSize = left.voxelSize
    radionuclide = left.radionuclide
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Source') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
    radionuclide = right.radionuclide
  endif else Message, 'Division not defined for operands.'

  Return, self.gs_Image::_OverloadSlash(left, right, voxelSize = voxelSize, radionuclide = radionuclide)

END

;===========================================================================================

FUNCTION gs_Source::_OverloadPound, left, right

  compile_opt idl2
  
  if Obj_Valid(left) && Obj_Isa(left, 'gs_Source') && Obj_Valid(right) && Obj_Isa(right, 'gs_Filter') then begin
    
    img = left.imgData
    
    if StrCmp(right.mode, 'fft') then begin
      filter = right.GetFilter(left.dataDims, left.voxelSize, padTo = left.dataDims*2)
      img1 = DblArr(left.dataDims*2)
      img1[0, 0, 0] = Temporary(img)
      img = FFT(Temporary(img1), /overwrite)
      img = Real_Part((FFT(Temporary(img)*Temporary(filter), /inverse))[0:left.dataDims[0] - 1, 0:left.dataDims[1] - 1, 0:left.dataDims[2] - 1])*Product(left.dataDims*2)
    endif else begin
      filter = right.GetFilter(left.dataDims, left.voxelSize)
      img = Convol(img, filter, /edge_zero)
    endelse
    
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Source') && Obj_Valid(left) && Obj_Isa(left, 'gs_Filter') then begin
    
    img = right.imgData

    if StrCmp(left.mode, 'fft') then begin
      filter = left.GetFilter(left.dataDims, right.voxelSize, padTo = right.dataDims*2)
      img1 = DblArr(right.dataDims*2)
      img1[0, 0, 0] = Temporary(img)
      img = FFT(Temporary(img1), /overwrite)
      img = Real_Part((FFT(Temporary(img)*Temporary(filter), /inverse))[0:right.dataDims[0] - 1, 0:right.dataDims[1] - 1, 0:right.dataDims[2] - 1])*Product(right.dataDims*2)
    endif else begin
      filter = left.GetFilter(right.dataDims, right.voxelSize)
      img = Convol(img, filter, /edge_zero)
    endelse
      
  endif else Message, 'operation not defined.'
  
  Return, gs_Source(Temporary(img), nonNegative = self.nonNegative, voxelSize = self.voxelSize, radionuclide = self.radionuclide)

END

;===========================================================================================

FUNCTION gs_Source::GetRegion, regions, name

  compile_opt idl2
  
  Return, self.gs_Image::GetRegion(regions, name, voxelSize = voxelSize, radionuclide = radionuclide)

END

;===========================================================================================

FUNCTION gs_Source::Rescale, rescaler, regions

  compile_opt idl2

  Return, self.gs_Image::Rescale( rescaler, regions, voxelSize = voxelSize, radionuclide = radionuclide)

END

;===========================================================================================

FUNCTION gs_Source::New, imgData, nonNegative = nonNegative, voxelSize = voxelSize, radionuclide = radionuclide, _extra = extra
  
  compile_opt idl2
  
  if N_Elements(voxelSize) gt 0 then vs = voxelSize else vs = self.voxelSize
  if N_Elements(radionuclide) gt 0 then rnc = radionuclide else rnc = self.radionuclide
  
  Return, self.gs_Image::New(imgData, nonNegative = nonNegative, voxelSize = vs, radionuclide = rnc, _extra = extra)

END

;===========================================================================================

PRO gs_Source::ToFile, fileName, compress = compress, overwrite = overwrite

  compile_opt idl3
  
  case 1B of
     ~Isa(fileName, /scalar, /string) && ~Isa(fileName, /scalar, /integer): Message, 'File name must be a scalar string or a LUN.'
     else:
  endcase

  if Isa(fileName, /string) && File_Test(fileName, /regular) && ~KeyWord_Set(overwrite) then Message, 'File already exists.'
  
  cmp = Boolean(KeyWord_Set(compress))
  
  self.radionuclide.Save, string = rnc
  rncSize = StrLen(rnc)
  nRncLines = N_Elements(rnc)
  
  if Isa(fileName, /string) then OpenW, lun, fileName, /get_lun else lun = fileName
  WriteU, lun, self.dataDims.ToArray(), self.nonNegative, self.numberFormat, self.voxelSize, cmp, nRncLines
  for i = 0, nRncLines - 1 do WriteU, lun, rncSize[i], rnc[i] 
  
  if cmp then begin
    
    imgOut = Zlib_Compress(*self.imgData, /gzip_header)
    WriteU, lun, Long64(N_Elements(imgOut))
    WriteU, lun, imgOut
    
  endif else begin
    
    WriteU, lun, *self.imgData
    
  endelse
  
  if Isa(fileName, /string) then Free_Lun, lun
 
END

;===========================================================================================

FUNCTION gs_Source::FromFile, fileName

  compile_opt idl3, static
  
  if Isa(fileName, /string) && ~File_Test(fileName, /regular, /read) then Message, 'File does not exist: ' + fileName
  
  if Isa(fileName, /string) then OpenR, lun, fileName, /get_lun else lun = fileName
  
  dataDims = LonArr(3)
  nonNegative = !false
  numberFormat = BytArr(6)
  voxelSize = DblArr(3)
  cmp = !false
  nRncLines = 0L
  ReadU, lun, dataDims, nonNegative, numberFormat, voxelSize, cmp, nRncLines
  
  rncStr = StrArr(nRncLines)
  
  for i = 0, nRncLines - 1 do begin
    len = 0L
    ReadU, lun, len
    tmp = BytArr(len)
    ReadU, lun, tmp
    rncStr[i] = String(tmp)
  endfor
  
  rnc = gs_Radionuclide.Restore(rncStr, /string)
  
  dType = StrCmp(numberFormat, 'single', /fold_case) ? 4 : 5
  
  if cmp then begin
    
    nBytes = 0LL
    ReadU, lun, nBytes
    
    imgCompress = BytArr(nBytes)
    ReadU, lun, imgCompress
    img = Zlib_Uncompress(imgCompress, /gzip_header, type = dType, $
      dimensions = dataDims)    
    
  endif else begin
    
    img = Make_Array(dataDims, type = dType)
    ReadU, lun, img
    
  endelse
  
  if Isa(fileName, /string) then Free_Lun, lun
  
  Return, gs_Source(img, voxelSize = voxelSize, nonNegative = nonNegative, $
    radionuclide = rnc)
  
END

;===========================================================================================

PRO gs_Source__define

  compile_opt idl2
  
  dum = {gs_Source, voxelSize: DblArr(3), radionuclide: Obj_New(), inherits gs_Image}

END