FUNCTION gs_VanCittert::Init, oSrc, oPSF, oSrcEst, relax = relax

  compile_opt idl3
  
  case 1B of
    ~Isa(oSrc, /scalar) || ~Obj_Valid(oSrc) || ~Obj_Isa(oSrc, 'gs_Source'): Message, 'Source must be a scalar gs_Source.'
    ~Isa(oPSF, /scalar) || ~Obj_Valid(oPSF) || ~Obj_Isa(oPSF, 'gs_Filter'): Message, 'PSF must be ascalar gs_Filter.'
    else:
  endcase
  
  if N_Elements(relax) gt 0 then relaxator = relax else relaxator = gs_DummyRelaxator()
  
  case 1B of
    ~Isa(relaxator, /scalar) || ~Obj_Valid(relaxator) || ~Obj_Isa(relaxator, 'gs_Relaxator'): Message, 'Relaxator must be gs_Relaxator.'
    else:
  endcase
  
  self.oSrc = oSrc
  self.oSrcIn = N_Elements(oSrcEst) gt 0 ? oSrcEst : oSrc
  self.oPSF = oPSF
  self.relax = relaxator
  self.nIters = 0
  
  Return, 1

END

;====================================================

PRO gs_VanCittert::CleanUp

  compile_opt idl3

  if Obj_Valid(self.oSrc) && self.nIters gt 0 then Obj_Destroy, self.oSrc

END

;===================================================

PRO gs_Vancittert::GetProperty, nIters = nIters, oSrc = oSrc

  compile_opt idl3

  if Arg_Present(nIters) then nIters = self.nIters
  if Arg_Present(oSrc) then oSrc = self.oSrc

END

;=========================================================

PRO gs_VanCittert::Run, nIters, verbose = verbose

  compile_opt idl3

  for it = 1, nIters do begin

    ;---Forward
    if Obj_Isa(self.oSrc, 'gs_NaturalSource') then begin
      oSrc = self.oSrc.Source(nonNegative = 0) 
    endif else if obj_Isa(self.oSrc, 'gs_BasisSource') then begin
      oSrc = self.oSrc.Source(nonNegative = 0)
    endif else begin
      oSrc = self.oSrc.New(self.oSrc.imgData, nonNegative = 0)
    endelse
    
    oPrj = oSrc#self.oPSF
    
    ;---Compare
    d = self.oSrcIn - oPrj

    ;---Back
    u = d#self.oPSF

    ;---Update
    
    if Obj_Isa(self.oSrc, 'gs_NaturalSource') || Obj_Isa(self.oSrc, 'gs_BasisSource') then begin
      oSrcNew = self.oSrc + Rebin(self.relax.Get(1., self.nIters + 1)*u.imgData, self.oSrc.natDataDims, /sample)
    endif else begin
      oSrcNew = self.oSrc + self.relax.Get(1., self.nIters + 1)*u.imgData
    endelse 
    
    self.oSrc = oSrcNew
    self.nIters++

    if KeyWord_Set(verbose) then Print, self.nIters, format = 'Finished iteration %I'

  endfor

END

;===================================================

PRO gs_VanCittert__define

  compile_opt idl3
  
  dum = {gs_VanCittert, nIters: 0L, oSrc: Obj_New(), oSrcIn: Obj_New(), $
    oPSF: Obj_New(), relax: Obj_New(), inherits IDL_object}

END