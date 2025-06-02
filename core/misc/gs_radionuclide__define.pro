FUNCTION gs_Radionuclide::Init, energy, yield, halfLife = halfLife

  compile_opt idl2
  
  case 1B of
    Isa(energy, /null): ;Pass
    ~Isa(energy, /float): Message, 'Energy must be floating point.'
    jg_Any(energy le 0.): Message, 'Energy must be greater than 0.'
    else:
  endcase
  
  self.energy = List(energy, /extract)
  
  case 1B of
    ~Isa(yield, /null) && ~Isa(yield, /float): Message, 'Yield must be floating point.'
    ~Isa(yield, /null) && jg_Any(yield le 0.): Message, 'Yield must be greater than 0.'
    N_Elements(yield) ne self.energy.Count(): Message, 'Number of elements do not match for energy and yield.'
    else:
  endcase
  
  self.yield = List(yield, /extract)
  
  if N_Elements(halfLife) gt 0 then begin
    
    case 1B of
      ~Isa(halfLife, /scalar, /float): Message, 'Half-life must be a scalar float.'
      halfLife le 0: Message, 'Half-life must be greater than 0.'
      else:
    endcase
    
    self.halfLife = Double(halfLife)
    
  endif else self.halfLife = !values.d_infinity
  
  Return, 1  

END

;================================================================================================

PRO gs_Radionuclide::GetProperty, halfLife = halfLife, energy = energy, yield = yield, count = count

  compile_opt idl2
  
  if Arg_Present(halfLife) then halfLife = self.halfLife
  if Arg_Present(energy) then energy = self.energy.ToArray()
  if Arg_Present(yield) then yield = self.yield.ToArray()
  if Arg_Present(count) then count = self.energy.Count() 
  
END

;================================================================================================

FUNCTION gs_Radionuclide::GetRange, arg

  compile_opt idl2
  
  case 1B of
    ~Isa(arg, /float, /array) || (N_Elements(arg) ne 2): Message, 'Message argument must be a two-element floating-point array.'
    else:
  endcase
  
  energy = self.energy.ToArray()
  yield = self.yield.ToArray()
  ii = Where((energy ge arg[0]) and (energy lt arg[1]), /null)
  
  Return, gs_Radionuclide(energy[ii], yield[ii], halfLife = self.halfLife)
  
END

;================================================================================================

FUNCTION gs_Radionuclide::_OverloadEQ, left, right

  compile_opt idl2
  
  case 1B of
    ~Obj_Valid(left) || ~Obj_Isa(left, 'gs_Radionuclide'): Message, 'Equality not defined for operands.'
    ~Obj_Valid(right) || ~Obj_Isa(right, 'gs_Radionuclide'): Message, 'Equality not defined for operands.'
    else:    
  endcase
  
  Return, Array_Equal(left.energy, right.energy, tolerance = 1D-3) && Array_Equal(left.yield, right.yield, tolerance = 1D-6) && (left.halfLife eq right.halfLife)
   
END

;================================================================================================

FUNCTION gs_Radionuclide::_OverloadNE, left, right

  compile_opt idl2

  Return, ~self._OverloadEQ(left, right)

END

;================================================================================================

PRO gs_Radionuclide::Save, fileName, string = string

  compile_opt idl2
  
  n = N_Elements(self.energy)
  
  if ~Arg_Present(string) then begin
    OpenW, lun, fileName, /get_lun
    PrintF, lun, self.halfLife
    
    for i = 0, n - 1 do PrintF, lun, self.energy[i].ToString(), self.yield[i].ToString(), format = '%S,%S'
    
    Free_Lun, lun
  endif else begin
    string = StrArr(n + 1)
    string[0] = self.halfLife.ToString()
    for i = 1, n do string[i] = String(self.energy[i - 1].ToString(), self.yield[i - 1].ToString(), format = '%S,%S')
  endelse
  
END

;================================================================================================

FUNCTION gs_Radionuclide::Restore, fileName, string = string

  compile_opt idl2, static

  if KeyWord_Set(string) then rnc = fileName else rnc = jg_ReadTextFile(fileName)
  halfLife = rnc[0].ToDouble()
  
  energy = DblArr(N_Elements(rnc) - 1)
  yield = DblArr(N_Elements(rnc) - 1)
  
  for i = 1, N_Elements(rnc) - 1 do begin
    splt = rnc[i].Split(',')
    energy[i - 1] = splt[0].ToDouble()
    yield[i - 1] = splt[1].ToDouble()
  endfor
  
  Return, gs_Radionuclide(energy, yield, halfLife = halfLife)
  
END

;================================================================================================

PRO gs_Radionuclide__define

  compile_opt idl2
  
  dum = {gs_Radionuclide, energy: Obj_New(), yield: Obj_New(), halfLife: 0D, inherits IDL_object}

END