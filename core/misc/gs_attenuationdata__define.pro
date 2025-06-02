FUNCTION gs_AttenuationData::Init, data

  compile_opt idl2
  
  self.data = List()
  self.SetProperty, data = data
  
  Return, 1

END

;=================================================================

PRO gs_AttenuationData::CleanUp

  compile_opt idl2
  
  ;Pass

END

;=================================================================

PRO gs_AttenuationData::SetProperty, data = data

  compile_opt idl2
  
  if N_Elements(data) gt 0 then begin
    case 1B of
      jg_Any(~Obj_Valid(data)) || jg_Any(~Obj_Isa(data, 'gs_MassAttenuationCoefficients')): Message, 'Data must be gs_MassAttenuationCoefficients.'
      else:
    endcase
  
    nameArray = StrArr(N_Elements(data))
    nameArray[0] = data[0].name
    for i = 1, N_Elements(data) - 1 do begin
      if jg_Any(StrCmp(nameArray[0:i - 1], data[i].name, /fold_case)) then Message, 'Duplicate material names ' + data[i].name
      nameArray[i] = data[i].name
    endfor
  
    self.data = List(data, /extract)
    
  endif

END

;=================================================================

PRO gs_AttenuationData::Add, att

  compile_opt idl2
  
  self.GetProperty, materialNames = materialNames
  
  case 1B of
    ~Obj_Valid(att) || ~Obj_Isa(att, 'gs_MassAttenuationCoefficients'): Message, 'Data type error.'
    jg_Any(StrCmp(materialNames, att.name, /fold_case)): Message, 'Material name duplicate: ' + att.name
    else:
  endcase
  
  self.data.Add, att
  
END

;=================================================================

PRO gs_AttenuationData::Remove, name

  compile_opt idl2
  
  case 1B of
    ~Isa(name, /scalar, /string): Message, 'Name must be a scalar string.'
    else:
  endcase
  
  
  self.GetProperty, materialNames = materialNames
  
  ii = Where(StrCmp(materialNames, name, /fold_case), count, /null)
  
  if count gt 0 then self.data.Remove, ii else Message, 'No such material: ' + name
  
END

;=================================================================

FUNCTION gs_AttenuationData::_OverloadBracketsRightSide, isRange, arg1

  compile_opt idl2
  
  if isRange then Message, 'Range subscripts not allowed for object.'
  if ~Isa(arg1, /scalar, /string) then Message, 'Only scalar strings allowed as subscripts.'
  
  for i = 0, N_Elements(self.data) - 1 do begin
    if StrCmp(self.data[i].name, arg1, /fold_case) then Return, self.data[i]
  endfor
  
  Message, 'No such material: ' + arg1

END

;=================================================================

PRO gs_AttenuationData::GetProperty, materialNames = materialNames, count = count

  compile_opt idl2
  
  if Arg_Present(materialNames) then begin
    n = N_Elements(self.data)
    materialNames = StrArr(n)
    for i = 0, n - 1 do materialNames[i] = self.data[i].name
  endif

  if Arg_Present(count) then count = self.data.Count()

END

;=================================================================

PRO gs_AttenuationData__define

  compile_opt idl2
  
  dum = {gs_AttenuationData, data: Obj_New(), inherits IDL_object}

END 