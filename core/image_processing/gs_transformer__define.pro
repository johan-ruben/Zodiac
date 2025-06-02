FUNCTION gs_Transformer::Init, nDimensions = nDimensions, stepSize = stepSize, interpolator = interpolator

  compile_opt idl2
  
  case 1B of
    ~Obj_Valid(interpolator) || ~Obj_Isa(interpolator, 'gs_Interpolator'): Message, 'Interpolator must be gs_Interpolator.'
    ~Isa(nDimensions, /scalar, /integer): Message, 'Number of dimensions must be a scalar integer.'
    nDimensions ne interpolator.nDimensions: Message, 'Number of dimensions for transformer and interpolator do not match.'
    ~Isa(stepSize, /scalar, /float): Message, 'Step size must be a scalar float.'
    else:
  endcase
  
  self.nDimensions = nDimensions
  self.interpolator = interpolator
  self.stepSize = Double(stepSize)
  
  Return, 1
  
END

;==============================================================================

PRO gs_Transformer::GetProperty, nDimensions = nDimensions, interpolator = interpolator, stepSize = stepSize

  compile_opt idl2
  
  if Arg_Present(nDimensions) then nDimensions = self.nDimensions
  if Arg_Present(interpolator) then interpolator = self.interpolator
  if Arg_Present(stepSize) then stepSize = self.stepSize

END

;==============================================================================

PRO gs_Transformer__define

  compile_opt idl2
  
  dum = {gs_Transformer, interpolator: Obj_New(), stepSize: 0D, nDimensions: 0L, inherits IDL_Object}

END