FUNCTION gs_ConstantBackground::Init, energyWindows, bkgIntensity

  compile_opt idl3
  
  case 1B of
    jg_any(~Obj_Valid(energyWindows) || ~Obj_Isa(energyWindows, 'gs_EnergyWindow')): Message, 'Energy windows must be gs_EnergyWindow'
    ~Isa(bkgIntensity, /float): Message, 'Background must be floating point.'
    N_Elements(energyWindows) ne N_Elements(bkgIntensity): Message, 'Number of elements does not match.'
    else:
  endcase
  
  self.bkgIntensity = List(bkgIntensity, /extract)
  self.energyWindows = List(energyWindows, /extract)
  
  Return, 1

END

;=========================================================================

FUNCTION gs_ConstantBackground::Get, oPrj

  compile_opt idl3
  
  n = N_Elements(self.energyWindows)
  for i = 0, n - 1 do begin    
    if self.energyWindows[i] eq oPrj.energyWindow then begin
      iWin = i
      break
    endif
  endfor
  
  if N_Elements(iWin) eq 0 then Message, 'No such window.'
  factor = self.bkgIntensity[iwin]
  
  t = oPrj.prjTime
  pixSiz = oPrj.pixSiz
  
  cPrj = Replicate(factor*Product(pixSiz), oPrj.dataDims)*Rebin(Reform(t, 1, 1, N_Elements(t)), oPrj.dataDims)

  Return, oPrj.New(cPrj)

END

;=========================================================================

PRO gs_ConstantBackground__define

  compile_opt idl3
  
  dum = {gs_ConstantBackground, energyWindows: Obj_New(), bkgIntensity: Obj_New(), inherits gs_Background}

END