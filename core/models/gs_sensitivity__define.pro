FUNCTION gs_Sensitivity::Init, energyWindow, radionuclide, sensitivity

  compile_opt idl2
  
  case 1B of
    jg_Any(~Obj_valid(energyWindow)) || jg_Any(~Obj_Isa(energyWindow, 'gs_EnergyWindow')): Message, 'Energy window must be gs_EnergyWindow.'
    jg_Any(~Obj_valid(radionuclide)) || jg_Any(~Obj_Isa(radionuclide, 'gs_Radionuclide')): Message, 'Radionuclides must be gs_Radionuclide.'
    ~Isa(sensitivity, /float): Message, 'Sensitivity must be floating point.'
    else:
  endcase
  
  self.energyWindow = List(energyWindow, /extract)
  self.radionuclide = List(radionuclide, /extract)
  self.sensitivity = Ptr_New(Double(sensitivity))
  
  Return, 1
  
END

;=======================================================================

FUNCTION gs_Sensitivity::Sensitivity, rnc, eWin

  compile_opt idl2
  
  isEqual = Lambda(arg, cmp: arg eq cmp)
  bRnc = (self.radionuclide.Map(isEqual, rnc)).ToArray()
  bWin = (self.energyWindow.Map(isEqual, eWin)).ToArray()
  
  ii = Where(bRnc and bWin, count, /null)
  if count ne 1 then Message, 'Non-unique sensitivity.'
  Return, (*self.sensitivity)[ii[0]]

END 
 
;=======================================================================

PRO gs_Sensitivity__define

  compile_opt idl2
  
  dum = {gs_Sensitivity, energyWindow: Obj_New(), radionuclide: Obj_New(), sensitivity: Ptr_New()}

END