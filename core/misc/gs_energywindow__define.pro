FUNCTION gs_EnergyWindow::Init, lower, upper

  compile_opt idl2
  
  case 1B of
    ~Isa(lower, /number) || Isa(lower, /complex) || ~Isa(upper, /number) || Isa(upper, /complex): Message, 'Window limits must be real numbers.'
    N_Elements(lower) ne N_Elements(upper): Message, 'Window limits size mis-match.' 
    jg_Any(lower lt 0.): Message, 'Energy limits must be non-negative.'
    jg_Any(lower gt upper): Message, 'Lower limits must be lower than upper limits.'
    else:
  endcase  

  self.windowLimits = gs_MergeWindows(lower, upper)
  
  Return, 1

END

;=====================================================================

PRO gs_EnergyWindow::CleanUp

  compile_opt idl2
  
  if Obj_Valid(self.windowLimits) then Obj_Destroy, self.windowLimits

END

;=====================================================================

FUNCTION gs_EnergyWindow::InWindow, energy

  compile_opt idl2
  
  n = self.windowLimits.Count()
  inside = !false
  
  for i = 0, n - 1 do begin
    if (energy ge self.windowLimits[i, 0]) && (energy lt self.windowLimits[i, 1]) then begin
      inside = !true
      break
    endif
  endfor

  Return, inside

END

;=====================================================================

FUNCTION gs_EnergyWindow::GetLimits, upper = upper

  compile_opt idl2
  
  n = self.windowLimits.Count()
  
  lm = DblArr(n)
  
  for i = 0, n - 1 do begin
    if KeyWord_Set(upper) then lm[i] = self.windowLimits[i, 1] else lm[i] = self.windowLimits[i, 0]
  endfor
  
  Return, lm
  
END

;=====================================================================

FUNCTION gs_EnergyWindow::_OverloadPlus, left, right

  compile_opt idl2
  
  case 1B of
    ~Obj_Valid(left) || ~Obj_Isa(left, 'gs_EnergyWindow') || ~Obj_Valid(right) || ~Obj_Isa(right, 'gs_EnergyWindow'): Message, 'Addition not defined for operands.'
    else:
  endcase
  
  Return, gs_EnergyWindow([left.GetLimits(), right.getLimits()], [left.GetLimits(/upper), right.getLimits(/upper)])

END

;=====================================================================

FUNCTION gs_EnergyWindow::_OverloadEQ, left, right

  compile_opt idl2 

  case 1B of
    ~Obj_Valid(left) || ~Obj_Valid(right): Message, 'Equality not defined for operands.'
    ~Obj_Isa(left, 'gs_EnergyWindow') || ~Obj_Isa(right, 'gs_EnergyWindow'): Message, 'Equality not defined for operands.'
    else:
  endcase
  
  Return, Array_Equal(left.GetLImits(), right.GetLimits(), tolerance = 1D-2) and Array_Equal(left.GetLImits(/upper), right.GetLimits(/upper), tolerance = 1D-2)

END

;=====================================================================

FUNCTION gs_EnergyWindow::_OverloadPrint

  compile_opt idl2
  
  n = self.windowLimits.Count()
  
  str = StrArr(n)
  for i = 0, n - 1 do begin
    str[i] = StrJoin([self.windowLimits[i, 0].ToString(), self.windowLimits[i, 1].ToString()], ', ')
  endfor
  
  Return, str

END


;=====================================================================

FUNCTION gs_EnergyWindow::_OverloadImpliedPrint, varName

  compile_opt idl2

  Return, self._OverloadPrint()

END

;=====================================================================

FUNCTION gs_EnergyWindow::_OverloadHelp, varName

  compile_opt idl2
  
  str = [varName, 'gs_EnergyWindow', 'n = ' + (self.windowLimits.Count()).ToString()]
  Return, [str, self._OverloadPrint()]


END

;=====================================================================

PRO gs_EnergyWindow__define

  compile_opt idl2
  
  dum = {gs_EnergyWindow, windowLimits: Obj_New(), inherits IDL_Object}

END