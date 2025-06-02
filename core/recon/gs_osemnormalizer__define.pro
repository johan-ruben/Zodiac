FUNCTION gs_OSEMNormalizer::Init, oPrjs, oSrcs, backProjector, fromFile = fromFile, $
  temporaryDirectory = temporaryDirectory, adjustAxial = adjustAxial, axialAdjustmentLength = axialAdjustmentLength

  compile_opt idl2
  
  self.fromFile = !false
  if KeyWord_Set(fromFile) then begin
    self.fromFile = !true
  endif
  
  self.nrm = OrderedHash()
  
  if N_Elements(temporaryDirectory) gt 0 then self.tempDir = jg_AddSlash(temporaryDirectory) else self.tempDir = GetEnv('LUNDATEMP') 
  
  foreach oPrjSet, oPrjs, prjName do begin
    
    nrmPrjArray = ObjArr(N_Elements(oPrjSet))
    foreach oPrj, oPrjSet, k do begin
      if Obj_Isa(oPrj, 'gs_ProjectionContainer') then begin
        oP = oPrj.oPrjs 
        for b = 0, oPrj.nBeds - 1 do oP[b] = oP[b].New(Replicate(1D, oP[b].dataDims))
        nrmPrjArray[k] = oPrj.New(oP)
      endif else begin
        nrmPrjArray[k] = oPrj.New(Replicate(1D, oPrj.dataDims))
      endelse
    endforeach
    
    foreach oSrc, oSrcs, sourceName do begin
      
      bck = backProjector.Bck(nrmPrjArray, oSrc)
      
      if self.fromFile then begin
        
        tmpFilePath = self.tempDir + Strtrim(prjName, 2) + '_' + StrTrim(sourceName, 2) + '.nrm'
        OpenW, lun, tmpFilePath, /get_lun
        if Obj_Isa(bck, 'gs_NaturalSource') then WriteU, lun, bck.natImgData else WriteU, lun, bck.imgData
        Free_Lun, lun
          
        ShmMap, dimension = Obj_Isa(bck, 'gs_NaturalSource') ? bck.natDataDims : bck.dataDims, /double, get_name = shName, fileName = tmpFilePath          
        self.nrm[prjName, sourceName] = shName
   
      endif else begin
        if Obj_Isa(bck, 'gs_NaturalSource') then self.nrm[prjName, sourceName] = bck.natImgData else self.nrm[prjName, sourceName] = bck.imgData
      endelse
      
    endforeach    
  endforeach

  Return, 1

END

;==========================================================================

PRO gs_OSEMNormalizer::GetProperty, tempDir = tempDir

  compile_opt idl3
  
  if Arg_Present(tempDir) then tempDir = self.tempDir

END

;==================================================================================================

FUNCTION gs_OsemNormalizer::Get, prjName, srcName

  compile_opt idl2
  
  if self.fromFile then begin
    shmName = self.nrm[prjName, srcName]
    nrm = ShmVar(shmName)
  endif else begin
    nrm = self.nrm[prjName, srcName]
  endelse

  Return, nrm
  
END

;==================================================================================================

PRO gs_OSEMNormalizer::CleanUp

  compile_opt idl2
  
  if self.fromFile then begin
    
    foreach set, self.nrm, prjName do begin
      foreach shmName, set, srcName do begin
        ShmUnmap, shmName
        File_Delete, self.tempDir +  Strtrim(prjName, 2) + '_' + StrTrim(srcName, 2) + '.nrm'
      endforeach
    endforeach
    
  endif
  
  if Obj_Valid(self.nrm) then Obj_Destroy, self.nrm

END

;==================================================================================================

PRO gs_OSEMNormalizer__define

  compile_opt idl2
  
  dum = {gs_OSEMNormalizer, nrm: Obj_New(), fromFile: !false, tempDir: '', inherits IDL_Object}

END