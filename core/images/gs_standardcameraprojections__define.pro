FUNCTION gs_StandardCameraProjections::Init, imgData, nonNegative = nonNegative, energyWindow = energyWindow, pixSiz = pixSiz, $
  cor = cor, prjDist = prjDist, prjTime = prjTime, prjAngles = prjAngles, nHeads = nHeads, axialOffset = axialOffset

  compile_opt idl2
  
  tmp = self.gs_Projections::Init(imgData, nonNegative = nonNegative, energyWindow = energyWindow, pixSiz = pixSiz)
  if tmp ne 1 then Return, 0
  
  if N_Elements(cor) gt 0 then begin
    
    case 1B of
      ~Isa(cor, /number, /array) || Isa(cor, /complex): Message, 'COR must be a real numeric array.'
      (Size(cor, /n_dimensions) ne 1) && (Size(cor, /n_dimensions) ne 2): Message, 'COR must be a two-dimensional array.'
      (Size(cor, /n_dimensions) eq 2 ? ((Size(cor, /dimensions))[1]) : 1) ne self.nProjections: Message, 'Dimensionality mis-match for COR.'
      (Size(cor, /dimensions))[0] ne 2: Message, 'Dimensionality mis-match for COR.'
      else:
    endcase
    corIn = Double(cor) 
  endif else corIn = Make_Array(2, self.nProjections)
  
  self.cor = List()  
  for i = 0, self.nProjections - 1 do self.cor.Add, corIn[*, i]
  
  case 1B of
    ~Isa(prjDist, /number) || Isa(prjDist, /complex): Message, 'Projection distance must be a real number.'
    N_Elements(prjDist) ne self.nProjections: Message, 'Number of projection distances must equal number of projections.'
    else:
  endcase

  self.prjDist = List(Double(prjDist), /extract)
  
  case 1B of
    ~Isa(prjTime, /number) || Isa(prjTime, /complex): Message, 'Projection time must be a real number.'
    ~Isa(prjTime, /scalar) && (N_Elements(prjDist) ne self.nProjections): Message, 'Number of projection times must equal number of projections.'
    else:
  endcase
  
  self.prjTime = List(Isa(prjTime, /scalar) ? Replicate(Double(prjTime), self.nProjections) : Double(prjTime), /extract)
  
  case 1B of
    ~Isa(prjAngles, /number) || Isa(prjAngles, /complex): Message, 'Projection angles must be a real number.'
    (N_Elements(prjAngles) ne self.nProjections): Message, 'Number of projection angles must equal number of projections.'
    else:
  endcase

  self.prjAngles = List(Double(prjAngles), /extract)
  
  if N_Elements(nHeads) gt 0 then begin
    case 1B of
      ~Isa(nHeads, /scalar, /integer): Message, 'Number of detector heads must be a scalar integer.'
      nHeads le 0: Message, 'Number of detecor heads must be greater than 0.'
      else: nHeadsIn = nHeads
    endcase   
  endif else nHeadsIn = 2
  
  self.nHeads = nHeadsIn
  
  if N_Elements(axialOffset) gt 0 then begin
    
    case 1B of
      ~Isa(axialOffset, /float, /array): Message, 'Axial offset must be a floating-point array.'
      N_Elements(axialOffset) ne self.nProjections: Message, 'Offset speocifcation does not agree with number of projections.'
      else:
    endcase
    
    self.axialOffset = List(Double(axialOffset), /extract)
    
  endif else self.axialOffset = List(DblArr(self.nProjections), /extract)
  
  Return, 1
  
END

;===================================================================================================================================

PRO gs_StandardCameraProjections::CleanUp

  compile_opt idl2
  
  if Obj_Valid(self.prjAngles) then Obj_Destroy, self.prjAngles
  if Obj_Valid(self.cor) then Obj_Destroy, self.cor
  if Obj_Valid(self.prjDist) then Obj_Destroy, self.prjDist
  if Obj_Valid(self.prjTime) then Obj_Destroy, self.prjTime
  
  self.gs_Projections::CleanUp

END

;===================================================================================================================================

PRO gs_StandardCameraProjections::GetProperty, cor = cor, prjDist = prjDist, prjTime = prjTime, prjAngles = prjAngles, $
  nHeads = nHeads, axialOffset = axialOffset, nBeds = nBeds, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(nBeds) then nBeds = 1
  if Arg_Present(cor) then cor = Reform(self.cor.ToArray(), 2, self.nProjections)
  if Arg_Present(prjDist) then prjDist = self.prjDist.ToArray()
  if Arg_Present(prjTime) then prjTime = self.prjTime.ToArray()
  if Arg_Present(prjAngles) then prjAngles = self.prjAngles.ToArray()
  if Arg_Present(nHeads) then nHeads = self.nHeads 
  if Arg_Present(axialOffset) then axialOffset = self.axialOffset.ToArray()
  
  self.gs_Projections::GetProperty, _extra = extra

END

;===================================================================================================================================

FUNCTION gs_StandardCameraProjections::_OverloadPlus, left, right, _extra = extra

  compile_opt idl2
  
  if ~Isa(left, /number) && ~Isa(right, /number) && Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') then begin
    
    case 1B of
      ~Array_Equal(left.prjAngles, right.prjAngles): Message, 'Projection angles do not agree.'
      ~Array_Equal(left.cor, right.cor): Message, 'CORs do not agree.'
      ~Array_Equal(left.prjDist, right.prjDist): Message, 'Projection distances do not agree.'
      ~Array_Equal(left.prjTime, right.prjTime): Message, 'Projection times do not agree.'
      left.nHeads ne right.nHeads: Message, 'Number of heads do not agree.'
      ~Array_Equal(left.axialOffset, right.axialOffset): Message, 'Axial Offsets do not agree.'
      else:      
    endcase
    
    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset
    
  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Isa(right, /number) then begin
    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') && Isa(left, /number) then begin
    prjAngles = right.prjAngles
    cor = right.cor
    prjDist = right.prjDist
    prjTime = right.prjTime
    nHead = right.nHeads
    axialOffset = right.axialOffset
  endif else Message, 'Addition not defined for operands.'
  
  Return, self.gs_Projections::_OverloadPlus(left, right, prjAngles = prjAngles, cor = cor, prjDist = prjDist, prjTime = prjTime, nHeads = nHead, $
    axialOffset = axialOffset, _extra = extra)

END

;===================================================================================================================================

FUNCTION gs_StandardCameraProjections::_OverloadMinus, left, right, _extra = extra

  compile_opt idl2

  if Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') then begin

    case 1B of
      ~Array_Equal(left.prjAngles, right.prjAngles): Message, 'Projection angles do not agree.'
      ~Array_Equal(left.cor, right.cor): Message, 'CORs do not agree.'
      ~Array_Equal(left.prjDist, right.prjDist): Message, 'Projection distances do not agree.'
      ~Array_Equal(left.prjTime, right.prjTime): Message, 'Projection times do not agree.'
      left.nHeads ne right.nHeads: Message, 'Number of heads do not agree.'
      ~Array_Equal(left.axialOffset, right.axialOffset): Message, 'Axial Offsets do not agree.'
      else:
    endcase

    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset
    
  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Isa(right, /number) then begin
    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') && Isa(left, /number) then begin
    prjAngles = right.prjAngles
    cor = right.cor
    prjDist = right.prjDist
    prjTime = right.prjTime
    nHead = right.nHeads
    axialOffset = right.axialOffset
  endif else Message, 'Subtraction not defined for operands'

  Return, self.gs_Projections::_OverloadMinus(left, right, prjAngles = prjAngles, cor = cor, prjDist = prjDist, prjTime = prjTime, $
    nHeads = nHead, axialPosition = axialPosition, _extra = extra)

END

;===================================================================================================================================

FUNCTION gs_StandardCameraProjections::_OverloadMinusUnary, _extra = extra

  compile_opt idl2
  
  Return, self.gs_Projections::_OverloadMinusUnary(prjAngles = self.prjAngles.ToArray(), cor = self.cor.ToArray(/transpose), $
    prjDist = self.prjDist.ToArray(), prjTime = self.prjTime.ToArray(), nHeads = self.nHeads, _extra = extra)

END

;===================================================================================================================================

FUNCTION gs_StandardCameraProjections::_OverloadAsterisk, left, right, _extra = extra

  compile_opt idl2

  if Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') then begin

    case 1B of
      ~Array_Equal(left.prjAngles, right.prjAngles): Message, 'Projection angles do not agree.'
      ~Array_Equal(left.cor, right.cor): Message, 'CORs do not agree.'
      ~Array_Equal(left.prjDist, right.prjDist): Message, 'Projection distances do not agree.'
      ~Array_Equal(left.prjTime, right.prjTime): Message, 'Projection times do not agree.'
      left.nHeads ne right.nHeads: Message, 'Number of heads do not agree.'
      ~Array_Equal(left.axialOffset, right.axialOffset): Message, 'Axial Offsets do not agree.'
      else:
    endcase

    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Isa(right, /number) then begin
    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') && Isa(left, /number) then begin
    prjAngles = right.prjAngles
    cor = right.cor
    prjDist = right.prjDist
    prjTime = right.prjTime
    nHead = right.nHeads
    axialOffset = right.axialOffset
  endif else Message, 'Multiplication not defined for operands'

  Return, self.gs_Projections::_OverloadAsterisk(left, right, prjAngles = prjAngles, cor = cor, prjDist = prjDist, $
    prjTime = prjTime, nHeads = nHead, axialOffset = axialOffset, _extra = extra)

END

;===================================================================================================================================

FUNCTION gs_StandardCameraProjections::_OverloadSlash, left, right, _extra = extra

  compile_opt idl2

  if Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') then begin

    case 1B of
      ~Array_Equal(left.prjAngles, right.prjAngles): Message, 'Projection angles do not agree.'
      ~Array_Equal(left.cor, right.cor): Message, 'CORs do not agree.'
      ~Array_Equal(left.prjDist, right.prjDist): Message, 'Projection distances do not agree.'
      ~Array_Equal(left.prjTime, right.prjTime): Message, 'Projection times do not agree.'
      left.nHeads ne right.nHeads: Message, 'Number of heads do not agree.'
      ~Array_Equal(left.axialOffset, right.axialOffset): Message, 'Axial Offsets do not agree.'
      else:
    endcase

    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_StandardCameraProjections') && Isa(right, /number) then begin
    prjAngles = left.prjAngles
    cor = left.cor
    prjDist = left.prjDist
    prjTime = left.prjTime
    nHead = left.nHeads
    axialOffset = left.axialOffset
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_StandardCameraProjections') && Isa(left, /number) then begin
    prjAngles = right.prjAngles
    cor = right.cor
    prjDist = right.prjDist
    prjTime = right.prjTime
    nHead = right.nHeads
    axialOffset = right.axialOffset
  endif else Message, 'Division not defined for operands'

  Return, self.gs_Projections::_OverloadSlash(left, right, prjAngles = prjAngles, cor = cor, prjDist = prjDist, $
    prjTime = prjTime, nHeads = nHead, axialOffset = axialOffset, _extra = extra)

END

;===================================================================================================================================

FUNCTION gs_StandardCameraProjections::_OverloadPound, left, right, _extra = extra

  compile_opt idl2
  
  Return, self.gs_Projections::_OverloadPound(left, right, prjAngles = self.prjAngles.ToArray(), cor = Reform(self.cor.ToArray(), 2, self.nProjections),$
     prjDist = self.prjDist.ToArray(), prjTime = self.prjtime.ToArray(), nHeads = self.nHeads, axialOffset = self.axialOffset.ToArray(), _extra = extra)

END

;===================================================================================================================================

FUNCTION gs_StandardCameraProjections::New, imgData, nonNegative = nonNegative, pixSiz = pixSiz, energyWindow = energyWindow, prjTime = prjTime, $
  prjAngles = prjAngles, cor = cor, prjDist = prjDist, axialOffset = axialOffset, _extra = extra

  compile_opt idl2
  
  if N_Elements(prjTime) gt 0 then pt = prjTime else pt = self.prjTime.ToArray()
  if N_Elements(prjAngles) gt 0 then pa = prjAngles else pa = self.prjAngles.ToArray()
  if N_Elements(cor) gt 0 then c = cor else c = Reform(self.cor.ToArray(), 2, self.nProjections)
  if N_Elements(prjDist) gt 0 then pd = prjDist else pd = self.prjDist.ToArray()
  if N_Elements(axialOffset) gt 0 then ao = axialOffset else ao = self.axialOffset.ToArray()
  
  Return, self.gs_Projections::New(imgData, nonNegative = nonNegative, pixSiz = pixSiz, energyWindow = energyWindow, prjTime = pt, $
    prjAngles = pa, cor = c, prjDist = pd, axialOffset = ao, _extra = extra)
  
END

;===================================================================================================================================

PRO gs_StandardCameraProjections__define

  compile_opt idl2
  
  dum = {gs_StandardCameraProjections, prjAngles: Obj_New(), cor: Obj_New(), prjDist: Obj_New(), $
    prjTime: Obj_New(), nHeads: 0L, axialOffset: Obj_New(), inherits gs_Projections}

END