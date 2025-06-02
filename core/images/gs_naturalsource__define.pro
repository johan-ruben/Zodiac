FUNCTION gs_NaturalSource::Init, imgData, voxelSize = voxelSize, radionuclide = radionuclide, nonNegative = nonNegative, regions = regions, $
  emulateMatrix = emulateMatrix, noForce = noForce

  compile_opt idl2
  
  case 1B of 
    ~Isa(regions, /scalar) || ~Obj_Valid(regions) || ~Isa(regions, 'gs_RegionMap'): Message, 'Regions must be gs_RegionMap.'
    ~Isa(emulateMatrix, /integer, /array) || (N_Elements(emulateMatrix) ne 3): Message, 'Emulated matrix size must be a three-element integer array.'
    else:
  endcase
  
  self.emulateMatrix = emulateMatrix
  self.regions = regions
  
  if KeyWord_Set(noForce) then begin
    img1 = imgData
    self.noForce = !true
  endif else begin
    
    self.noForce = !false
    if jg_Any(Size(imgData, /dimensions) ne self.regions.dataDims) then begin
      
      case 1B of
        ~Array_Equal(Size(imgData, /dimensions), self.emulateMatrix): Message, 'Data dims do not agree.'
        else:
      endcase
      img1 = Rebin(imgData, regions.dataDims, /sample)
    endif else img1 = imgData
    
    img1 = gs_ForceToVoxels(img1, self.emulateMatrix, self.regions)
    
  endelse
  
  tmp = self.gs_Source::Init(img1, voxelSize = voxelSize, radionuclide = radionuclide, nonNegative = nonNegative)
  if tmp ne 1 then Return, 0
  
  self.scaleFactor = (*self.imgData).dim/self.emulateMatrix
  
  Return, 1

END

;======================================================================================================

PRO gs_NaturalSource::GetProperty, imgData = imgData, dataDims = dataDims, voxelSize = voxelSize, natImgData = natImgData, $
  natDataDims = natDataDims, natVoxelSize = natVoxelSize, regions = regions, noForce = noForce, emulateMatrix = emulateMatrix, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(imgData) then begin
    
    if self.noForce then begin
      
      if self.isCompressed then begin
        self.gs_Source::GetProperty, imgData = imgData
      endif else begin 
        imgData = *self.imgData
      endelse
      
    endif else begin
      
      if self.isCompressed then begin
        self.gs_Source::GetProperty, imgData = imgData
        imgData = Rebin(imgData, self.emulateMatrix)
      endif else begin
        imgData = Rebin(*self.imgData, self.emulateMatrix)
      endelse
           
    endelse
    
  endif
  if Arg_Present(dataDims) then begin
    if self.noForce then datadims = self.dataDims.ToArray() else dataDims = self.emulateMatrix
  endif
  if Arg_Present(voxelSize) then begin
    if self.noForce then voxelSize = self.voxelSize else voxelSize = self.voxelSize*self.scaleFactor
  endif
  if Arg_Present(natImgData) then begin
    if self.isCompressed then begin
      self.gs_Source::GetProperty, imgData = natImgData
    endif else begin
      natImgData = *self.imgData
    endelse
  endif
  if Arg_Present(natVoxelSize) then natVoxelSize = self.voxelSize
  if Arg_Present(natDataDims) then natDataDims = self.dataDims.ToArray()
  if Arg_Present(regions) then regions = self.regions
  if Arg_Present(noForce) then noForce = self.noForce
  if Arg_Present(emulateMatrix) then emulateMatrix = self.emulateMatrix
  
  self.gs_Source::GetProperty, _extra = extra
  
END

;=================================================================================

FUNCTION gs_NaturalSource::_OverloadPlus, left, right, _extra = extra

  compile_opt idl2

  if Isa(left, /scalar) && Isa(right, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize) || ~Array_Equal(left.natVoxelSize, right.natVoxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      left.regions ne right.regions: Message, 'Regions do not agree.'
      else:
    endcase

    noForce = left.noForce || right.noForce
    nonNegative = left.nonNegative && right.nonNegative
    res = left.New(left.natImgData + right.natImgData, noForce = noForce, nonNegative = nonNegative)

  endif else if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Isa(right, /number) then begin
    
    case 1B of
      ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims) || Array_Equal(Size(right, /dimension), left.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase
    
    if ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims)) then tmp = Rebin(right, left.natDataDims) else tmp = right
    
    res = left.New(left.natImgData + tmp)
    
  endif else if Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') && Isa(left, /number) then begin
    
    case 1B of
      ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims) || Array_Equal(Size(left, /dimension), right.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase

    if  ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims)) then tmp = Rebin(left, right.natDataDims) else tmp = left
    res = left.New(tmp + right.natImgData)
  endif else Message, 'Addition not defined for operands.'

  Return, res

END


;=================================================================================

FUNCTION gs_NaturalSource::_OverloadMinus, left, right, _extra = extra

  compile_opt idl2

  if Isa(left, /scalar) && Isa(right, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize) || ~Array_Equal(left.natVoxelSize, right.natVoxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      left.regions ne right.regions: Message, 'Regions do not agree.'
      else:
    endcase

    noForce = left.noForce || right.noForce
    nonNegative = left.nonNegative && right.nonNegative
    res = left.New(left.natImgData - right.natImgData, noForce = noForce, nonNegative = nonNegative)

  endif else if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Isa(right, /number) then begin
    
    case 1B of
      ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims) || Array_Equal(Size(right, /dimension), left.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase
    
    if ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims)) then tmp = Rebin(right, left.natDataDims) else tmp = right
    
    res = left.New(left.natImgData - tmp)
    
  endif else if Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') && Isa(left, /number) then begin
    
    case 1B of
      ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims) || Array_Equal(Size(left, /dimension), right.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase

    if  ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims)) then tmp = Rebin(left, right.natDataDims) else tmp = left
    res = left.New(tmp - right.natImgData)
  endif else Message, 'Subtraction not defined for operands.'

  Return, res

END

;====================================================================================================================

FUNCTION gs_NaturalSource::_OverloadAsterisk, left, right, _extra = extra

  compile_opt idl2

  if Isa(left, /scalar) && Isa(right, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize) || ~Array_Equal(left.natVoxelSize, right.natVoxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      left.regions ne right.regions: Message, 'Regions do not agree.'
      else:
    endcase

    noForce = left.noForce || right.noForce
    nonNegative = left.nonNegative && right.nonNegative
    res = left.New(left.natImgData*right.natImgData, noForce = noForce, nonNegative = nonNegative)

  endif else if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Isa(right, /number) then begin
    
    case 1B of
      ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims) || Array_Equal(Size(right, /dimension), left.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase
    
    if ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims)) then tmp = Rebin(right, left.natDataDims) else tmp = right
    
    res = left.New(left.natImgData*tmp)
    
  endif else if Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') && Isa(left, /number) then begin
    
    case 1B of
      ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims) || Array_Equal(Size(left, /dimension), right.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase

    if  ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims)) then tmp = Rebin(left, right.natDataDims) else tmp = left
    res = right.New(tmp*right.natImgData)
  endif else Message, 'Multiplication not defined for operands.'

  Return, res

END


;=================================================================================

FUNCTION gs_NaturalSource::_OverloadSlash, left, right, _extra = extra

  compile_opt idl2

  if Isa(left, /scalar) && Isa(right, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize) || ~Array_Equal(left.natVoxelSize, right.natVoxelSize): Message, 'Voxel sizes do not agree.'
      left.radionuclide ne right.radionuclide: Message, 'Radionuclides do not agree.'
      left.regions ne right.regions: Message, 'Regions do not agree.'
      else:
    endcase

    noForce = left.noForce || right.noForce
    nonNegative = left.nonNegative && right.nonNegative
    res = left.New(left.natImgData/right.natImgData, noForce = noForce, nonNegative = nonNegative)

  endif else if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_NaturalSource') && Isa(right, /number) then begin
    
    case 1B of
      ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims) || Array_Equal(Size(right, /dimension), left.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase
    
    if ~Isa(right, /scalar) && ~(Array_Equal(Size(right, /dimension), left.natDataDims)) then tmp = Rebin(right, left.natDataDims) else tmp = right
    
    res = left.New(left.natImgData/tmp)
    
  endif else if Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_NaturalSource') && Isa(left, /number) then begin
    
    case 1B of
      ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims) || Array_Equal(Size(left, /dimension), right.dataDims)): Message, 'Matrix sizes do not agree.'
      else:
    endcase

    if  ~Isa(left, /scalar) && ~(Array_Equal(Size(left, /dimension), right.natDataDims)) then tmp = Rebin(left, right.natDataDims) else tmp = left
    res = left.New(tmp/right.natImgData)
  endif else Message, 'Division not defined for operands.'

  Return, res

END

;====================================================================

FUNCTION gs_NaturalSource::_OverloadPound, oSrc, oPSF

  compile_opt idl3
  
  self.GetProperty, imgData = imgData, dataDims = dataDims, voxelSize = voxelSize
  
  case oPSF.mode of
    
    'fft': begin
      
      f = oPSF.GetFilter(dataDims, voxelSize, padTo = dataDims*2) 
      imgPad = DblArr(dataDims*2)
      imgPad[0, 0, 0] = imgData
      fImg = FFT(imgPad)
      img = Real_Part((FFT(fimg*f, /inverse))[0:dataDims[0] - 1, 0:dataDims[1] - 1, 0:dataDims[2] - 1])*Product(dataDims*2)
    
    end
    
    'convol': begin      
      f = oPSF.GetFilter(dataDims, voxelSize)
      img = Convol(imgData, f, /edge_zero)
    end
    
    else: Message, 'Unknown filtering mode.'
    
  endcase

  Return, self.New(img)

END

;======================================================================================================

FUNCTION gs_NaturalSource::New, imgData, nonNegative = nonNegative, voxelSize = voxelSize, radionuclide = radionuclide, regions = regions, $
  emulateMatrix = emulatematrix, noForce = noForce, _extra = extra

  compile_opt idl2
  
  if N_Elements(voxelSize) gt 0 then vs = voxelSize else vs = self.voxelSize
  if N_Elements(radionuclide) gt 0 then rnc = radionuclide else rnc = self.radionuclide
  if N_Elements(regions) gt 0 then rg = regions else rg = self.regions
  if N_Elements(emulateMatrix) gt 0 then em = emulateMatrix else em = self.emulateMatrix
  if N_Elements(noForce) gt 0 then nf = noForce else nf = self.noForce
  
  Return, self.gs_Image::New(imgData, nonNegative = nonNegative, voxelSize = vs, radionuclide = rnc, regions = rg, emulateMatrix = em, noForce = nf, _extra = extra)

END

;======================================================================================================

PRO gs_NaturalSource::ToFile, fileName, compress = compress, overwrite = overwrite

  compile_opt idl3
  
  case 1B of
    ~(Isa(fileName, /scalar, /string) || Isa(fileName, /scalar, /integer)): Message, 'File name must be a scalar string.'
    else:
  endcase

  if Isa(fileName, /string) && File_Test(fileName, /regular) && ~KeyWord_Set(overwrite) then Message, 'File already exists: ' + fileName
  
  version = 'v1'
  hasRegions = Boolean(Obj_Valid(self.regions))
  
  cmp = Boolean(KeyWord_Set(compress))

  self.radionuclide.Save, string = rnc
  rncSize = StrLen(rnc)
  nRncLines = N_Elements(rnc)

  if Isa(fileName, /string) then OpenW, lun, fileName, /get_lun else lun = fileName
  WriteU, lun, version, self.dataDims.ToArray(), self.nonNegative, self.numberFormat, self.voxelSize, self.emulateMatrix, self.noForce, cmp, nRncLines, hasRegions
  for i = 0, nRncLines - 1 do WriteU, lun, rncSize[i], rnc[i]

  if cmp then begin
    imgOut = Zlib_Compress(*self.imgData, /gzip_header)
    WriteU, lun, Long64(N_Elements(imgOut))
    WriteU, lun, imgOut
  endif else begin
    WriteU, lun, *self.imgData
  endelse
  
  WriteU, lun, hasRegions
  
  if hasRegions then begin    
    self.regions.ToFile, lun, compress = compress
  endif
  
  if Isa(fileName, /string) then Free_Lun, lun
  
END

;======================================================================================================

FUNCTION gs_NaturalSource::FromFile, fileName

  compile_opt idl3, static
  
  if Isa(fileName, /string) && ~File_Test(fileName, /regular, /read) then Message, 'File does not exist: ' + fileName

  if Isa(fileName, /string) then OpenR, lun, fileName, /get_lun else lun = fileName
  
  v = BytArr(2)
  dataDims = LonArr(3)
  nonNegative = !false
  numberFormat = BytArr(6)
  voxelSize = DblArr(3)
  cmp = !false
  nRncLines = 0L
  emulateMatrix = LonArr(3)
  noForce = !false
  hasRegions = !false
  
  ReadU, lun, v
  version = String(v)
  
  if version ne 'v1' then begin
    Free_Lun, lun
    Message, 'Unknown version: ' + version
  endif
  
  ReadU, lun, dataDims, nonNegative, numberFormat, voxelSize, emulateMatrix, noForce, cmp, nRncLines, hasRegions

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
  
  ReadU, lun, hasRegions
  if hasRegions then oReg = gs_RegionMap.FromFile(lun)

  if Isa(fileName, /string) then Free_Lun, lun
  
  Return, gs_NaturalSource(img, voxelSize = voxelSize, radionuclide = rnc, nonNegative = nonNegative, regions = oReg, $
    emulateMatrix = emulateMatrix, noForce = noForce) 
  
END

;======================================================================================================

PRO gs_NaturalSource__define

  compile_opt idl2
  
  dum = {gs_NaturalSource, regions: Obj_New(), scaleFactor: LonArr(3), emulateMatrix: LonArr(3), noForce: !false, inherits gs_Source}

END