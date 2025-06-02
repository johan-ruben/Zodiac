FUNCTION gs_Filter::Init, nDimensions = nDimensions, mode = mode

  compile_opt idl2
  
  if N_Elements(mode) eq 0 then modeIn = 'fft' else modeIn = mode
  
  case 1B of
    ~Isa(nDimensions, /scalar, /integer): Message, 'Number of dimensions must be a scalar integer.'
    ~Isa(modeIn, /scalar, /string): Message, 'Mode must be a scalar string.'
    ~StrCmp(modeIn, 'fft', /fold_case) && ~StrCmp(mode, 'convol', /fold_case): Message, 'Only modes alloed are fft and convol.'
    else:
  endcase

  self.nDimensions = nDimensions
  self.mode = modeIn
  
  Return, 1

END

;===================================================================

PRO gs_Filter::CleanUp

  compile_opt idl2
  
  ;Pass

END

;===================================================================

PRO gs_Filter::GetProperty, nDimensions = nDimensions, mode = mode

  compile_opt idl2
  
  if Arg_Present(nDimensions) then nDimensions = self.nDimensions
  if Arg_Present(mode) then mode = self.mode
  
END

;===================================================================

PRO gs_Filter__define

  compile_opt idl2
  
  dum = {gs_Filter, nDimensions: 0L, mode: '', inherits IDL_Object}

END