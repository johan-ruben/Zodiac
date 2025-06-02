FUNCTION gs_MassAttenuationCoefficients::Init, name, energy, coefficients

  compile_opt idl2
  
  case 1B of
    ~Isa(name, /scalar, /string): Message, 'Material name must be a scalar string'
    ~Isa(energy, /float, /array): Message, 'Energy must be a floating-point array.'
    ~Isa(coefficients, /float, /array): Message, 'Mass-attenuation coefficients must be a floating-point array.'
    N_Elements(energy) ne N_Elements(coefficients): Message, 'Energy and coefficients must have the same number of elements.'
    else:
  endcase
  
  self.name = name
  self.energy = Ptr_New(Double(energy))
  self.coefficients = Ptr_New(Double(coefficients))
  
  Return, 1

END

;=================================================================================

PRO gs_MassAttenuationCoefficients::CleanUp

  compile_opt idl2
  
  if Ptr_Valid(self.energy) then Ptr_Free, self.energy
  if Ptr_Valid(self.coefficients) then Ptr_Free, self.coefficients

END

;=================================================================================

PRO gs_MassAttenuationCoefficients::GetProperty, name = name, energy = energy, coefficients = coefficients

  compile_opt idl2
  
  if Arg_Present(name) then name = self.name
  if Arg_Present(energy) then energy = *self.energy
  if Arg_Present(coefficients) then coefficients = *self.coefficients
  
END

;==================================================================================

FUNCTION gs_MassAttenuationCoefficients::MassAttenuation, energy, _extra = extra
  
  compile_opt idl2
  
  case 1B of
    ~Isa(energy, /float): Message, 'Energy must be floating point.'
    else:
  endcase

  muOverRho = Interpol(*self.coefficients, *self.energy, energy, _strict_extra = extra)
  
  Return, muOverRho

END

;============================================================================================

FUNCTION gs_MassAttenuationCoefficients::_OverloadEQ, left, right

  compile_opt idl2
  
  case 1B of
    ~Obj_Valid(left) && ~Obj_Isa(left, 'gs_MassAttenuationCoefficients'): Message, 'Equality not defined for operands.'
    ~Obj_Valid(right) && ~Obj_Isa(right, 'gs_MassAttenuationCoefficients'): Message, 'Equality not defined for operands.'
    else:
  endcase

  Return, (left.name eq right.name) && Array_Equal(left.energy, right.energy) && Array_Equal(left.coefficients, right.coefficients)

END

;============================================================================================

FUNCTION gs_MassAttenuationCoefficients::_OverloadNE, left, right

  compile_opt idl2

  Return, ~self._OverloadEQ(left, right)
  
END

;============================================================================================

PRO gs_MassAttenuationCoefficients__define

  compile_opt idl2
  
  dum = {gs_MassAttenuationCoefficients, name: '', energy: Ptr_New(), coefficients: Ptr_New(), inherits IDL_Object}

END