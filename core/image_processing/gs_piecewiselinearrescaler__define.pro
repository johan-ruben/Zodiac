FUNCTION gs_PiecewiseLinearRescaler::Init, names, slope, intercept

  compile_opt idl2
  
  case 1B of
    ~Isa(names, /string, /array): Message, 'Names must be a string array.'
    ~Isa(slope, /float, /array): Message, 'Slopes must be supplied as a floating-point array.'
    ~Isa(intercept, /float, /arra): message, 'Intercepts must be supplied as a floating-point array.'
    N_Elements(slope) ne N_Elements(names) || N_Elements(intercept) ne N_Elements(names): Message, 'Number of segments do not agree.'
    else:
  endcase

  self.names = List(names, /extract)
  self.slope = List(slope, /extract)
  self.intercept = List(intercept, /extract)
  
  Return, 1

END

;=========================================================================================

PRO gs_PiecewiseLinearRescaler::CleanUp

  compile_opt idl2
  
  if Obj_Valid(self.names) then Obj_Destroy, self.names
  if Obj_Valid(self.slope) then Obj_Destroy, self.slope
  if Obj_Valid(self.intercept) then Obj_Destroy, self.intercept

END

;=========================================================================================

PRO gs_PiecewiseLinearRescaler::GetProperty, names = names, slope = slope, intercept = intercept

  compile_opt idl2
  
  if Arg_Present(names) then names = self.names.ToArray()
  if Arg_Present(slope) then slope = self.slope.ToArray()
  if Arg_Present(intercept) then intercept = self.intercept.ToArray()

END

;=========================================================================================

FUNCTION gs_PiecewiseLinearRescaler::Rescale, data, name

  compile_opt idl2
  
  jj = Where(StrCmp(self.names.ToArray(), name, /fold_case), count, /null)
  if count ne 1 then Message, 'No such segment: ' + name else jj = jj[0]
  
  Return, data*self.slope[jj] + self.intercept[jj]

END

;=========================================================================================

PRO gs_PiecewiseLinearRescaler__define

  compile_opt idl2
  
  dum = {gs_PiecewiseLinearRescaler, names: Obj_New(), slope: Obj_New(), intercept: Obj_New(), inherits gs_Rescaler}

END