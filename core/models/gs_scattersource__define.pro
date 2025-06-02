FUNCTION gs_ScatterSource::Init, densDistribution, energyWindows, radionuclide

  compile_opt idl2
  
  case 1B of
    ~Isa(densDistribution, /scalar) || ~Obj_Valid(densDistribution) || ~Obj_Isa(densDistribution, 'gs_Density'): Message, 'Density distribution must be gs_Density.'
    jg_Any(~Obj_Valid(energyWindows)) || jg_Any(~Obj_Isa(energyWindows, 'gs_EnergyWindow')): Message, 'Energy window must be gs_EnergyWindow.'
    jg_Any(~Obj_Valid(radionuclide)) || jg_Any(~Obj_Isa(radionuclide, 'gs_Radionuclide')): Message, 'Radionuclide must be gs_Radionuclide.'
    else:
  endcase
  
  self.energyWindows = List(energyWindows, /extract)
  self.densDistribution = densDistribution
  self.radionuclide = List(radionuclide, /extract)
  
  Return, 1
  
END

;=========================================================================

PRO gs_ScatterSource::GetProperty, densDistribution = densDistribution, energyWindows = energyWindows, radionuclide = radionuclide

  compile_opt idl2
  
  if Arg_Present(densDistribution) then densDistribution = self.densDistribution
  if Arg_Present(energyWindows) then energyWindows = self.energyWindows
  if Arg_Present(radionuclide) then radionuclide = self.radionuclide

END

;=========================================================================

PRO gs_ScatterSource__define
  
  compile_opt idl2
  
  dum = {gs_ScatterSource, densDistribution: Obj_New(), energyWindows: Obj_New(), radionuclide: Obj_New(), inherits IDL_Object}

END