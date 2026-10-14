FUNCTION gs_IterativeYang::Init, oSrc, oRegions, oPSF

  compile_opt idl3

  case 1B of
    ~Isa(oSrc, /scalar) || ~Obj_Valid(oSrc) || ~Obj_Isa(oSrc, 'gs_Source'): Message, 'Source must be gs_Source.'
    ~Isa(oRegions, /scalar) || ~Obj_Valid(oRegions) || ~Obj_Isa(oRegions, 'gs_RegionMap'): Message, 'Source must be gs_Source.'
    ~Isa(oPSF, /scalar) || ~Obj_Valid(oPSF) || ~Obj_Isa(oPSF, 'gs_Filter'): Message, 'PSF must be gs_Filter.'
    else:
  endcase
  
  self.preserve = !false
  self.oSrc = oSrc
  self.oRegions = oRegions
  self.oPSF = oPSF
  self.srcIn = oSrc
  
  self.nIters = 0
  
  Return, 1
  
END

;===========================================

PRO gs_IterativeYang::GetProperty, nIters = nIters, oSrc = oSrc

  compile_opt idl3
  
  if Arg_Present(nIters) then nIters = self.nIters
  if Arg_Present(oSrc) then oSrc = self.oSrc

END

;===========================================

PRO gs_IterativeYang::Run, iters, verbose = verbose

  compile_opt idl3
  
  names = self.oRegions.names
  nRegions = N_Elements(names)
    
  for it = 1, iters do begin
        
    oSrcN = gs_NaturalSource(self.oSrc.imgData, voxelSize = self.oSrc.voxelSize*Double(self.oSrc.dataDims)/Double(self.oRegions.dataDims), $
      radionuclide = self.oSrc.radionuclide, emulateMatrix = self.oSrc.dataDims, regions = self.oRegions)
    
    s = oSrcN.Source()
    
    ss = s#self.oPSF
    
    oSrcNew = self.srcIn*gs_SafeDivision(s, ss, max = 1D6)
    
    self.oSrc = oSrcNew
    self.nIters++
    
    if KeyWord_Set(verbose) then Print, self.nIters, format = 'Finished iterations %I.'
    
  endfor

END

;===========================================

PRO gs_IterativeYang__define

  compile_opt idl3
  
  dum = {gs_IterativeYang, nIters: 0L, oSrc: Obj_New(), srcIn: Obj_New(), $
    oPSF: Obj_New(), oRegions: Obj_New(), preserve: !false, inherits IDL_Object}

END