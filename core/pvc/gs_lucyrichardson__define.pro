FUNCTION gs_LucyRichardson::Init, oSrc, oPSF, oSrcEst

  compile_opt idl3
  
  case 1B of
    ~Isa(oSrc, /scalar) || ~Obj_Valid(oSrc) || ~Obj_Isa(oSrc, 'gs_Source'): Message, 'Source must be a scalar gs_Source.'
    ~Isa(oPSF, /scalar) || ~Obj_Valid(oPSF) || ~Obj_Isa(oPSF, 'gs_Filter'): Message, 'PSF must be ascalar gs_Filter.'
    else:
  endcase
  
  self.oSrc = oSrc
  self.oSrcIn = N_Elements(oSrcEst)gt 0 ? oSrcEst : oSrc
  self.oPSF = oPSF
  self.nIters = 0
  
  nrmOnes = self.oSrcIn.New(Replicate(1., self.oSrcIn.dataDims))
  if Obj_Isa(self.oSrc, 'gs_BasisSource') then self.nrm = self.oSrcIn.New(Rebin((nrmOnes#self.oPSF).imgData, self.oSrc.natDataDims, /sample), voxelSize = self.oSrc.natVoxelSize) else $
    self.nrm = self.oSrc.New((nrmOnes#self.oPSF).imgData)
    
  Return, 1
  
END

;===================================================

PRO gs_LucyRichardson::CleanUp

  compile_opt idl3
  
  if Obj_Valid(self.oSrc) && self.nIters gt 0 then Obj_Destroy, self.oSrc

END

;===================================================

PRO gs_LucyRichardson::Run, nIters, verbose = verbose

  compile_opt idl3
  
  for it = 1, nIters do begin
    
    if Obj_Isa(self.oSrc, 'gs_NaturalSource') || Obj_Isa(self.oSrc, 'gs_BasisSource') then begin
      oSrc = self.oSrc.Source()
    endif else begin
      oSrc = self.oSrc
    endelse
    
    ;---Forward
    oPrj = oSrc#self.oPSF
    
    ;---Compare
    r = gs_SafeDivision(self.oSrcIn, oPrj, max = 1D6)
    
    ;---Back
    
    if Obj_Isa(self.oSrc, 'gs_NaturalSource') then begin
      u = gs_SafeDivision(self.oSrc.New((r#self.oPSF).imgData), self.nrm, max = 1D6)
    endif else if Obj_Isa(self.oSrc, 'gs_BasisSource') then begin
      u = gs_SafeDivision(Rebin((r#self.oPSF).imgData, self.oSrc.natDataDims, /sample), self.nrm.imgData, max = 1D6)
    endif else begin
      u = gs_SafeDivision(r#self.oPSF, self.nrm, max = 1D6)
    endelse
    
    ;---Update
    if Obj_Isa(self.oSrc, 'gs_BasisSource') then begin
      self.oSrc = self.oSrc*u
    endif else begin
      self.oSrc = self.oSrc*u
    endelse
    
    self.nIters++
    
    if KeyWord_Set(verbose) then Print, self.nIters, format = 'Finished iteration %I'
    
  endfor

END

;===================================================

PRO gs_LucyRichardson::GetProperty, nIters = nIters, oSrc = oSrc

  compile_opt idl3
  
  if Arg_Present(nIters) then nIters = self.nIters
  if Arg_Present(oSrc) then oSrc = self.oSrc

END

;===================================================

PRO gs_LucyRichardson__define

  compile_opt idl3
  
  dum = {gs_LucyRichardson, nIters: 0L, oSrc: Obj_New(), oSrcIn: Obj_New(), $
    oPSF: Obj_New(), nrm: Obj_New(), inherits IDL_object}


END