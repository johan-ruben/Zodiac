FUNCTION jg_ScatterSource::Init, fileName, scatterSource = scatterSource, meanEnergy = meanEnergy, metaData = metaData

  compile_opt idl2
  
  if N_Elements(scatterSource) gt 0 then begin
    
    self.SetProperty, fileName = ''
    
    self.metaData = Dictionary(metaData.Keys(), metaData.Values()) 
    self.scatterSource = scatterSource[*]
    self.meanEnergy = meanEnergy[*]
    
    Return, 1
    
  endif
  
  if N_Elements(fileName) gt 0 then fName = fileName else fName = ''
  
  self.SetProperty, fileName = fName  
  
  Return, 1

END

;=======================================================================================

PRO jg_ScatterSource::SetProperty, fileName = fileName

  compile_opt idl2
  
  if N_Elements(fileName) gt 0 then begin
    
    case 1B of
      ~Isa(fileName, /scalar, /string): Message, 'File name must be a scalar string.'
      fileName eq '':
      ~File_Test(fileName, /read): Message, 'Cannot read file ' + fileName
      else: 
    endcase
    
    if fileName eq '' then begin
      self.metaData = Dictionary()
      self.scatterSource = List()
      self.meanEnergy = List()
    endif else begin
    
      ver = 0L
      rnc = BytArr(16)
      clm = BytArr(16)
      cmt = BytArr(128)
      nSrc = 0L
      compression = BytArr(16)
      dataDims = LonArr(3)
      voxSiz = DblArr(3)
      prjEnergyRange = DblArr(2)
      srcEnergyRange = DblArr(2)
      prjEnergyRangeList = List()
      srcEnergyRangeList = List()
      dataDimsList = List()
      voxSizList = List()
      scatterSoruce = List()
      meanEnergy = List()
      
      OpenR, lun, fileName, /get_lun
      ReadU, lun, ver
      ReadU, lun, rnc
      ReadU, lun, clm
      ReadU, lun, cmt
      ReadU, lun, nSrc
      ReadU, lun, compression
      
      for i = 0, nSrc - 1 do begin
        ReadU, lun, dataDims
        dataDimsList.Add, dataDims
      endfor
      
      for i = 0, nSrc - 1 do begin
        ReadU, lun, voxSiz
        voxSizList.Add, voxSiz
      endfor
      
      for i = 0, nSrc - 1 do begin
        ReadU, lun, prjEnergyRange
        prjEnergyRangeList.Add, prjEnergyRange
      endfor
      
      for i = 0, nSrc - 1 do begin
        ReadU, lun, srcEnergyRange
        srcEnergyRangeList.Add, srcEnergyRange
      endfor
      
      for i = 0, nSrc - 1 do begin
        case (String(compression)).Trim() of 
          'none': begin
            img = FltArr(dataDimsList[i])
            ReadU, lun, img
            scatterSoruce.Add, img
            ReadU, lun, img
            meanEnergy.Add, img
          end
          'gzip': begin
            nBytes = 0L
            ReadU, lun, nBytes
            stream = BytArr(nBytes)
            ReadU, lun, stream
            scatterSoruce.Add, zlib_uncompress(stream, /gzip_header, type = 4, dimensions = dataDImsList[i])
            ReadU, lun, nBytes
            stream = BytArr(nBytes)
            ReadU, lun, stream
            meanEnergy.Add, zlib_uncompress(stream, /gzip_header, type = 4, dimensions = dataDimsList[i])
          end
        endcase
        
      endfor
      
      Free_Lun, lun
      
      self.metaData = Dictionary('version', ver, 'radionuclide', (String(rnc)).Trim(), $
        'collimator', (String(clm)).Trim(), 'comment', String(cmt), 'numberOfSources', nSrc, 'compression',  (String(compression)).Trim(), $
        'dataDims', dataDimsList, 'voxSiz', voxSizList, 'prjEnergyRange', prjEnergyRangeList, 'srcEnergyRange', srcEnergyRangeList)
      self.scatterSource = scatterSoruce
      self.meanEnergy = meanEnergy
      
    endelse 
    
    self.fileName = fileName
        
  endif

END

;=======================================================================================

PRO jg_ScatterSource::GetProperty, fileName = fileName, metaData = metaData, scatterSource = scatterSource, meanEnergy = meanEnergy

  compile_opt idl2
  
  if Arg_Present(fileName) then fileName = self.fileName
  if Arg_Present(metaData) then metaData = self.metaData
  if Arg_Present(scatterSource) then scatterSource = self.scatterSource
  if Arg_Present(meanEnergy) then meanEnergy = self.meanEnergy

END

;=======================================================================================

FUNCTION jg_ScatterSource::_OverloadPlus, left, right

  compile_opt idl3
  
  case 1B of
    ~Isa(left, /scalar) || ~Obj_Valid(left) || ~Obj_Isa(left, 'jg_scattersource') || ~Isa(right, /scalar) || ~Obj_Valid(right) || ~Obj_Isa(right, 'jg_scattersource'): Message, 'Addition not defined for operands.'
    else:
  endcase

  metaLeft = left.metaData
  metaRight = right.metaData
  
  keys = metaLeft.Keys()
  
  foreach key, keys do begin
    
    if StrCmp(key, 'compression') then continue
    
    if jg_Any(metaLeft[key] ne metaRight[key]) then Message, 'Meta data mis-match.'
    
  endforeach
  
  ss = List()
  en = List()
  
  for i = 0, metaLeft.numberOfSources - 1 do begin
    
    ss.Add, (left.scatterSource[i] + right.scatterSource[i])
    en.Add, (left.meanEnergy[i] + right.meanEnergy[i])
    
  endfor
  
  md = Dictionary(metaLeft.Keys(), metaLeft.Values())
  md.compression = 'none'
  
  Return, jg_ScatterSource(scatterSource = ss, meanEnergy = en, metaData = md)
  
END

;=======================================================================================

FUNCTION jg_ScatterSource::_OverloadSlash, left, right

  compile_opt idl3
  
  case 1B of
    ~Isa(left, /scalar) || ~Obj_Valid(left) || ~Obj_Isa(left, 'jg_scattersource') || ~Isa(right, /scalar, /number): Message, 'Division not defined for operands.'
    else:
  endcase

  metaLeft = left.metaData
  
  ss = List()
  en = List()

  for i = 0, metaLeft.numberOfSources - 1 do begin

    ss.Add, Float(left.scatterSource[i]/right)
    en.Add, Float(left.meanEnergy[i]/right)

  endfor

  md = Dictionary(metaLeft.Keys(), metaLeft.Values())
  md.compression = 'none'

  Return, jg_ScatterSource(scatterSource = ss, meanEnergy = en, metaData = md)

END

;=======================================================================================

PRO jg_ScatterSource::ToFile, fileName, overwrite = overwrite, $
  compress = compress, comment = comment

  compile_opt idl3
  
  if File_Test(fileName, /regular) && ~KeyWord_Set(overwrite) then Message, 'File already exists: ' + fileName
  
  rnc = self.metaData.radionuclide 
  if StrLen(rnc) lt 16 then rnc = rnc + String(Replicate(32B, 16 - StrLen(rnc)))
  clm = self.metaData.collimator
  if StrLen(clm) lt 16 then clm = clm + String(Replicate(32B, 16 - StrLen(clm)))
  
  if N_Elements(comment) gt 0 then cmt = comment else cmt = self.metadata.comment
  if StrLen(cmt) lt 128 then cmt = cmt + String(Replicate(32B, 128 - StrLen(cmt)))
  nSrc = Long(self.scatterSource.Count())
  
  if KeyWord_Set(compress) then cmprs = 'gzip            ' else cmprs = 'none            '
  
  OpenW, lun, fileName, /get_lun
  WriteU, lun, 1L
  WriteU, lun, rnc
  WriteU, lun, clm
  WriteU, lun, cmt
  WriteU, lun, nSrc
  WriteU, lun, cmprs

  for i = 0, nSrc - 1 do begin
    writeU, lun, Long(self.metaData.dataDims[i])
  endfor

  for i = 0, nSrc - 1 do begin
    writeU, lun, Double(self.metaData.voxSiz[i])
  endfor

  for i = 0, nSrc - 1 do begin
    writeU, lun, Double(self.metaData.prjEnergyRange[i])
  endfor

  for i = 0, nSrc - 1 do begin
    writeU, lun, Double(self.metaData.srcEnergyRange[i])
  endfor
  
  for i = 0, nSrc - 1 do begin
    if KeyWord_Set(compress) then begin
      ss = self.scatterSource[i]
      ssc = Zlib_Compress(ss, /gzip_header)
      nBytes = N_Elements(ssc)
      WriteU, lun, nBytes
      WriteU, lun, ssc
      en = self.meanEnergy[i]
      enc = Zlib_Compress(en, /gzip_header)
      nBytes = N_Elements(enc)
      WriteU, lun, nBytes
      WriteU, lun, enc
    endif else begin
      WriteU, lun, self.scatterSource[i]
      scatterSoruce.Add, img
      WriteU, lun, self.meanEnergy[i]        
    endelse
  endfor

  Free_Lun, lun

END

;=======================================================================================

PRO jg_ScatterSource__Define

  compile_opt idl2
  
  dum = {jg_ScatterSource, fileName: '', metaData: Obj_New(), scatterSource: Obj_New(), meanEnergy: Obj_New(), inherits idl_object}

END