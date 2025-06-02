FUNCTION gs_Interpolator::Init, nDimensions = nDimensions

  compile_opt idl2
  
  case 1B of
    ~Isa(nDimensions, /scalar, /integer): Message, 'Number of dimensions mist be a scalar integer.'
    else:
  endcase

  self.nDimensions = Long(nDimensions)
  
  Return, 1

END

;====================================================================

PRO gs_Interpolator::GetProperty, nDimensions = nDimensions

  compile_opt idl2
  
  if Arg_Present(nDimensions) then nDimensions = self.nDimensions

END

;====================================================================

PRO gs_Interpolator__define

  compile_opt idl2
  
  dum = {gs_Interpolator, nDimensions: 0L, Inherits IDL_Object}


END