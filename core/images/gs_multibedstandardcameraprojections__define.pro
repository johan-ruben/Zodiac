FUNCTION gs_MultiBedStandardCameraProjections::Init, oPrjs

  compile_opt idl3
  
  case 1B of
    ~jg_All(Obj_Valid(oPrjs)) || ~jg_All(Obj_Isa(oPrjs, 'gs_StandardCameraProjections')): Message, 'Projections msut be gs_StandardCameraProjections.'
    else:
  endcase
  
  self.oPrjs = List(oPrjs, /extract)
  self.nBeds = self.oPrjs.Count()  
  
  Return, 1
  
END

;============================================================================

PRO gs_MultiBedStandardCameraProjections::GetProperty, oPrjs = oPrjs, nBeds = nBeds
  compile_opt idl3
  
  if Arg_Present(oPrjs) then begin
    if self.nBeds eq 1 then oPrjs = self.oPrjs[0] else oPrjs = self.oPrjs.ToArray()
  endif
  
  if Arg_Present(nBeds) then nBeds = self.nBeds
    
END

;============================================================================

FUNCTION gs_MultiBedStandardCameraProjections::_OverloadPlus, left, right

  compile_opt idl3
  
  case 1B of
    ~Isa(left, /scalar) || ~Obj_Isa(left, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
    ~Isa(right, /scalar) || ~Obj_Isa(right, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
     else:
  endcase
  
  if left.nBeds ne right.nBeds then Message, 'Number of bed postions do not agree.'
  
  prjOut = ObjArr(left.nBeds)
  for i = 0, left.nBeds - 1 do prjOut[i] = left.oprjs[i] + right.oprjs[i]

  Return, gs_MultiBedStandardCameraProjections(prjOut)

END

;============================================================================

FUNCTION gs_MultiBedStandardCameraProjections::_OverloadMinus, left, right

  compile_opt idl3

  case 1B of
    ~Isa(left, /scalar) || ~Obj_Isa(left, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
    ~Isa(right, /scalar) || ~Obj_Isa(right, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
    else:
  endcase

  if left.nBeds ne right.nBeds then Message, 'Number of bed postions do not agree.'

  prjOut = ObjArr(left.nBeds)
  for i = 0, left.nBeds - 1 do prjOut[i] = left.prjs[i] - right.prjs[i]

  Return, gs_MultiBedStandardCameraProjections(prjOut)

END

;==============================================================================

FUNCTION gs_MultiBedStandardCameraProjections::_OverloadAsterisk, left, right

  compile_opt idl3

  case 1B of
    ~Isa(left, /scalar) || ~Obj_Isa(left, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
    ~Isa(right, /scalar) || ~Obj_Isa(right, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
    else:
  endcase

  if left.nBeds ne right.nBeds then Message, 'Number of bed postions do not agree.'

  prjOut = ObjArr(left.nBeds)
  for i = 0, left.nBeds - 1 do prjOut[i] = left.oprjs[i] *right.oprjs[i]

  Return, gs_MultiBedStandardCameraProjections(prjOut)

END

;============================================================================

FUNCTION gs_MultiBedStandardCameraProjections::_OverloadSlash, left, right

  compile_opt idl3

  case 1B of
    ~Isa(left, /scalar) || ~Obj_Isa(left, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
    ~Isa(right, /scalar) || ~Obj_Isa(right, 'gs_MultiBedStandardCameraProjections'): Message, 'Operands must be scalar.'
    else:
  endcase

  if left.nBeds ne right.nBeds then Message, 'Number of bed postions do not agree.'

  prjOut = ObjArr(left.nBeds)
  for i = 0, left.nBeds - 1 do prjOut[i] = left.prjs[i]/right.prjs[i]

  Return, gs_MultiBedStandardCameraProjections(prjOut)

END

;============================================================================

FUNCTION gs_MultiBedStandardCameraProjections::New, oPrjs

  compile_opt idl3
  
  Return, gs_MultiBedStandardCameraProjections(oPrjs)

END

;============================================================================

PRO gs_MultiBedStandardCameraProjections__define

  compile_opt idl3
  
  dum = {gs_MultiBedStandardCameraProjections, oPrjs: Obj_New(), nBeds: 0L, inherits gs_ProjectionContainer}

END