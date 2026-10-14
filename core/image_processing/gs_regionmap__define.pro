FUNCTION gs_RegionMap::Init, regions, names = names, labels = labels

  compile_opt idl2
  
  case 1B of
    ~Isa(regions, /integer, /array): Message, 'Regions must be an integer array.'
    else:
  endcase
  
  self.nDimensions = Size(regions, /n_dimensions)
  self.dataDims = List(Size(regions, /dimensions), /extract) 
  self.regions = Ptr_New(Fix(regions))
  
  if N_Elements(labels) gt 0 then begin
    unqReg = labels
  endif else unqReg = (*self.regions).Uniq()
  
  ii = Where(unqReg ne 0S, count, /null)
  if count gt 0 then unqReg = unqReg[ii]
  nRegions = N_Elements(unqReg)
  nms = 'region' + StrTrim(SindGen(nRegions, start = 1), 2)

  if N_Elements(names) gt 0 then nms[0] = names 
  
  if N_Elements(nms) eq 1 then self.keys = OrderedHash(nms[0], unqReg[0]) else self.keys = OrderedHash(nms, unqReg)
  
  Return, 1  

END 

;======================================================================================================================================

PRO gs_RegionMap::CleanUp

  compile_opt idl2
  
  if Ptr_Valid(self.regions) then Ptr_Free, self.regions
  if Obj_Valid(self.dataDims) then Obj_Destroy, self.dataDims
  if Obj_Valid(self.keys) then Obj_Destroy, self.keys

END

;======================================================================================================================================

PRO gs_RegionMap::GetProperty, dataDims = dataDims, names = names, regions = regions, labels = labels

  compile_opt idl2
  
  if Arg_Present(dataDims) then dataDims = self.dataDims.ToArray()
  if Arg_Present(names) then names = (self.keys.Keys()).ToArray()
  if Arg_Present(regions) then regions = *self.regions
  if Arg_Present(labels) then labels = (self.keys.Values()).ToArray()
  
END

;=======================================================================================================================================

FUNCTION gs_RegionMap::_OverloadEQ, left, right

  compile_opt idl2
  
  case 1B of
    Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_RegionMap') && Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_RegionMap'):
    else: Message, 'Equality not defined for operands.'
  endcase
  
  Return, Array_Equal(left.dataDims, right.dataDims) && Array_Equal(left.regions, right.regions) && Array_Equal(left.names, right.names)

END

;=======================================================================================================================================

FUNCTION gs_RegionMap::_OverloadNE, left, right

  compile_opt idl2

  Return, ~self._OverloadEQ(left, right)

END


;=======================================================================================================================================

FUNCTION gs_RegionMap::Indices, name, count = count, undefined = undefined
  
  compile_opt idl2
  
  if KeyWord_Set(undefined) then begin
    ii = Where(*self.regions eq 0S, count, /null)
  endif else begin
    if ~self.keys.HasKey(name) then Message, 'No such region.'
    ii = Where(*self.regions eq self.keys[name], count, /null)
  endelse
    
  Return, ii

END

;=========================================================================================

PRO gs_RegionMap::ToFile, fileName, overwrite = overwrite, compress = compress

  compile_opt idl3
  
  if Isa(fileName, /string) && File_Test(fileName) && ~KeyWord_Set(overwrite) then Message, 'File already exists: ' + fileName 

  if Isa(fileName, /string) then OpenW, lun, fileName, /get_lun else lun = fileName
  
  cmp = Boolean(KeyWord_Set(compress))
  nameStr = StrJoin((self.keys.Keys()).ToArray(), ',')
  nameLen = Long(StrLen(nameStr))
  regLables = Fix((self.keys.Values()).ToArray())

  WriteU, lun, self.nDimensions, self.dataDims.ToArray(), nameLen, nameStr, regLables, cmp
  
  if cmp then begin
    reg = Zlib_Compress(*self.regions, /gzip_header)
    nBytes = Long64(N_Elements(reg))
    WriteU, lun, nBytes, reg
  endif else WriteU, lun, *self.regions
  
  if Isa(fileName, /string) then Free_Lun, lun  

END

;==========================================================================================

FUNCTION gs_RegionMap::FromFile, fileName

  compile_opt idl3, static
  
  if Isa(fileName, /string) then OpenR, lun, fileName, /get_lun else lun = fileName
  
  nDimensions = 0L
  nameLen = 0L
  cmp = !false
  
  ReadU, lun, nDimensions
  dataDims = LonArr(nDimensions)
  ReadU, lun, dataDims, nameLen
  nameBytes = BytArr(nameLen)
  ReadU, lun, nameBytes
  names = (String(nameBytes)).Split(',')
  nRegions = N_Elements(names)
  lables = IntArr(nRegions)
  ReadU, lun, lables, cmp
  
  if cmp then begin
    nBytes = 0LL
    ReadU, lun, nBytes
    regionsCompress = BytArr(nBytes)
    ReadU, lun, regionsCompress
    regions = Zlib_Uncompress(regionsCompress, type = 2, dimensions = dataDims, /gzip_header)
  endif else begin
    regions = IntArr(dataDims)
    ReadU, lun, regions
  endelse
  
  if Isa(fileName, /string) then Free_Lun, lun
  
  Return, gs_RegionMap(regions, names = names, labels = lables)
  
END

;======================================================================================================================================

PRO gs_RegionMap::Add, ii, name, remove = remove

  compile_opt idl3
  
  if KeyWord_Set(remove) then begin
    (*self.regions)[ii] = 0S
    rmKeys = []
    foreach iNr, self.keys, lbl do begin
      if ~(*self.regions).HasValue(iNr) then rmKeys = [rmKeys, lbl]
    endforeach
    if N_Elements(rmKeys) gt 0 then self.keys.Remove, rmKeys
    Return
  endif
  
  iNr = Max(*self.regions) + 1S
  if N_Elements(name) gt 0 then nme = name else nme = 'region ' + iNr.ToString()
  (*self.regions)[ii] = iNr
  self.keys[name] = iNr

END

;======================================================================================================================================

PRO gs_RegionMap::Merge, nme1, nme2, newName

  compile_opt idl3
  
  case 1 of
    ~Isa(nme1, /scalar, /string) || ~Isa(nme2, /scalar, /string): Message, 'Region names must be scalar strings.'
    ~self.HasRegion(nme1): Message, 'Region does nost exist: ' + nme1 
    ~self.HasRegion(nme2): Message, 'Region does nost exist: ' + nme2
    (N_Elements(newName) gt 0) && ~Isa(newName, /scalar, /string): Message, 'Region names must be a scalar string.'
    else:
  endcase
  
  if N_Elements(newName) eq 0 then begin
    ii = self.Indices(nme1)
    iNr = self.keys[nme2]
    (*self.regions)[ii] = iNr
    self.keys.Remove, nme1
  endif else begin
    ii = [self.Indices(nme1), self.Indices(nme2)]
    iNr = self.keys[nme2]
    (*self.regions)[ii] = iNr
    self.keys.Remove, [nme1, nme2]
    self.keys[newName] = iNr
  endelse

END

;======================================================================================================================================

FUNCTION gs_RegionMap::Mask, name
  
  compile_opt idl3
  
  ii = self.Indices(name, count = count)
  msk = BytArr(self.dataDims.ToArray())
  if count gt 0 then msk[ii] = 1B
  
  Return, msk
  
END

;====================================================================================

FUNCTION gs_RegionMap::HasRegion, name

  compile_opt idl3
  
  nmes = (self.keys.Keys()).ToArray()
  Return, Boolean(nmes.HasValue(name))
  
END

;======================================================================================================================================

PRO gs_RegionMap__define

  compile_opt idl2
  
  dum = {gs_RegionMap, regions: Ptr_New(), dataDims: Obj_New(), nDimensions: 0L, keys: Obj_New(), inherits IDL_Object}

END