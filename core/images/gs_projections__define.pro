FUNCTION gs_Projections::Init, imgData, energyWindow = energyWindow, pixSiz = pixSiz, nonNegative = nonNegative

  compile_opt idl2
  
  tmp = self.gs_Image::Init(imgData, nonNegative = nonNegative)
  if tmp ne 1 then Return, 0
  
  if N_Elements(pixSiz) gt 0 then begin
    
    case 1B of
      ~(Isa(pixSiz, /number, /array) && (N_Elements(pixSiz) eq 2)): Message, 'Pixel size must be two-element array.'
      jg_Any(pixSiz le 0.): Message, 'Pixel size must be positive.'
      else:
    endcase
    
    self.pixSiz = Double(pixSiz)
    
  endif else self.pixSiz = 1D
  
  case 1B of
    ~Obj_Valid(energyWindow) || ~Obj_Isa(energyWindow, 'gs_EnergyWindow'): Message, 'Energy window must be suppled as gs_EnergyWindow.'
    (self.nDimensions ne 2) && (self.nDimensions ne 3) && ~Obj_Isa(self, 'gs_DynamicStandardCameraProjections'): Message, 'Projection dimensionality error.'
    else:
  endcase
  
  self.energyWindow = energyWindow
  
  self.mtxSiz = self.dataDims[0:1].ToArray()
  self.nProjections = self.nDimensions eq 2 ? 1 : self.dataDims[2]
  
  Return, 1

END

;=======================================================================================

PRO gs_Projections::CleanUp

  compile_opt idl2
  
  self.gs_Image::CleanUp

END

;=======================================================================================================

PRO gs_Projections::GetProperty, pixSiz = pixSiz, mtxSiz = mtxSiz, nProjections = nProjections, energyWindow = energyWindow, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(pixSiz) then pixSiz = self.pixSiz
  if Arg_Present(mtxSiz) then  mtxSiz = self.mtxSiz
  if Arg_Present(nProjections) then nProjections = self.nProjections
  if Arg_Present(energyWindow) then energyWindow = self.energyWindow
  
  self.gs_Image::GetProperty, _extra = extra

END

;=======================================================================================================

FUNCTION gs_Projections::_OverloadPlus, left, right, _extra = extra

  case 1B of
    Isa(left, /number):
    Obj_Valid(left) && Obj_Isa(left, 'gs_Projections'): 
    else: Message, 'Addition not defined for operands.'
  endcase
  
  case 1B of
    Isa(right, /number):
    Obj_Valid(right) && Obj_Isa(right, 'gs_Projections'):   
    else: Message, 'Addition not defined for operands.'
  endcase
  
  if  Obj_Valid(left) && ~Obj_Isa(left, 'gs_Projections') && Obj_Valid(right) && ~Obj_Isa(right, 'gs_Projections') then begin
    case 1B of
      (left.pixSiz ne right.pixSiz): Message, 'Pixel sizes do not agree.'
      else: pixSiz = left.pixSiz
    endcase
    energyWindow = left.energyWindow + right.energyWindow
  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Projections') then begin
    pixSiz = left.pixSiz
    energyWindow = left.energyWindow
  endif else begin
    pixSiz = right.pixSiz
    energyWindow = right.energyWindow
  endelse
  
  Return, self.gs_Image::_OverloadPlus(left, right, pixSiz = pixSiz, energyWindow = energyWindow, _extra = extra)

END

;=======================================================================================================

FUNCTION gs_Projections::_OverloadPound, left, right, _extra = extra

  compile_opt idl2
  
  if Obj_Valid(left) && Obj_Isa(left, 'gs_Filter') then filter = left else if Obj_Valid(right) && Obj_Isa(right, 'gs_Filter') then filter = right else Message, 'Operation not defined.'
  
  if StrCmp(filter.mode, 'fft', /fold_case) then begin
    f = filter.GetFilter(self.mtxSiz, self.pixSiz, padTo = self.mtxSiz*2)
    prj = DblArr(self.dataDims.ToArray())
    for i = 0, self.nProjections - 1 do begin
      imgPad = DblArr(self.mtxSiz*2)
      imgPad[0, 0] = (*self.imgData)[*, *, i]
      prj[*, *, i] = Real_Part((FFT(FFT(imgPad)*f, /inverse))[0:self.mtxSiz[0] - 1, 0:self.mtxSiz[1] - 1])*Product(self.mtxSiz*2)
    endfor
  endif else begin
    f = filter.GetFilter(self.mtxSiz, self.pixSiz)
    prj = DblArr(self.dataDims)
    for i = 0, self.nProjections - 1 do begin
      prj[*, *, i] = Convol((*self.imgData)[*, *, i], f, /edge_zero)
    endfor
  endelse

  className = Tag_Names(self, /structure_name)
  
  Return, Obj_New(className, prj, energyWindow = self.energyWindow, pixSiz = self.pixSiz, nonNegative = self.nonNegative, _extra = extra)

END

;=======================================================================================================

FUNCTION gs_Projections::_OverloadMinus, left, right, _extra = extra

  case 1B of
    Obj_Valid(left) && Obj_Isa(left, 'gs_Projections'):
    Isa(left, /number):
    else: Message, 'Subtraction not defined for operands.'
  endcase

  case 1B of
    Obj_Valid(right) && Obj_Isa(right, 'gs_Projections'):
    Isa(right, /number):
    else: Message, 'Subtraction not defined for operands.'
  endcase

  if  Obj_Valid(left) && ~Obj_Isa(left, 'gs_Projections') && Obj_Valid(right) && ~Obj_Isa(right, 'gs_Projections') then begin
    case 1B of
      (left.pixSiz ne right.pixSiz): Message, 'Pixel sizes do not agree.'
      else: pixSiz = left.pixSiz
    endcase
    energyWindow = left.energyWindow + right.energyWindow
  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Projections') then begin
    pixSiz = left.pixSiz
    energyWindow = left.energyWindow
  endif else begin
    pixSiz = right.pixSiz
    energyWindow = right.energyWindow
  endelse

  Return, self.gs_Image::_OverloadMinus(left, right, pixSiz = pixSiz, energyWindow = energyWindow, _extra = extra)

END

;=======================================================================================================

FUNCTION gs_Projections::_OverloadMinusUnary, _extra = extra

  compile_opt idl2
  
  Return, self.gs_Image::_OverloadMinusUnary(pixsiz = self.pixSiz, energyWindow = self.energyWindow, _extra = extra)

END

;=======================================================================================================

FUNCTION gs_Projections::_OverloadAsterisk, left, right, _extra = extra
  
  compile_opt idl2
  
  case 1B of
    Obj_Valid(left) && Obj_Isa(left, 'gs_Projections'):
    Isa(left, /number):
    else: Message, 'Multiplication not defined for operands.'
  endcase

  case 1B of
    Obj_Valid(right) && Obj_Isa(right, 'gs_Projections'):
    Isa(right, /number):
    else: Message, 'Subtraction not defined for operands.'
  endcase

  if  Obj_Valid(left) && ~Obj_Isa(left, 'gs_Projections') && Obj_Valid(right) && ~Obj_Isa(right, 'gs_Projections') then begin
    case 1B of
      (left.pixSiz ne right.pixSiz): Message, 'Pixel sizes do not agree.'
      else: pixSiz = left.pixSiz
    endcase
    energyWindow = left.energyWindow + right.energyWindow
  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Projections') then begin
    pixSiz = left.pixSiz
    energyWindow = left.energyWindow
  endif else begin
    pixSiz = right.pixSiz
    energyWindow = right.energyWindow
  endelse

  Return, self.gs_Image::_OverloadAsterisk(left, right, pixSiz = pixSiz, energyWindow = energyWindow, _extra = extra)

END

;=======================================================================================================

FUNCTION gs_Projections::_OverloadSlash, left, right, _extra = extra

  case 1B of
    Obj_Valid(left) && Obj_Isa(left, 'gs_Projections'):
    Isa(left, /number):
    else: Message, 'Division not defined for operands.'
  endcase

  case 1B of
    Obj_Valid(right) && Obj_Isa(right, 'gs_Projections'):
    Isa(right, /number):
    else: Message, 'Division not defined for operands.'
  endcase

  if  Obj_Valid(left) && ~Obj_Isa(left, 'gs_Projections') && Obj_Valid(right) && ~Obj_Isa(right, 'gs_Projections') then begin
    case 1B of
      (left.pixSiz ne right.pixSiz): Message, 'Pixel sizes do not agree.'
      else: pixSiz = left.pixSiz
    endcase
    energyWindow = left.energyWindow + right.energyWindow
  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Projections') then begin
    pixSiz = left.pixSiz
    energyWindow = left.energyWindow
  endif else begin
    pixSiz = right.pixSiz
    energyWindow = right.energyWindow
  endelse

  Return, self.gs_Image::_OverloadSlash(left, right, pixSiz = pixSiz, energyWindow = energyWindow, _extra = extra)

END

;=======================================================================================================

FUNCTION gs_Projections::New, imgData, nonNegative = nonNegative, pixSiz = pixSiz, energyWindow = energyWindow, _extra = extra

  compile_opt idl2
  
  if N_Elements(pixSiz) gt 0 then ps = pixSiz else ps = self.pixSiz
  if N_Elements(energyWindow) gt 0 then eWin = energyWindow else eWin = self.energyWindow
  
  Return, self.gs_Image::New(imgData, nonNegative = nonNegative, pixSiz = ps, energyWindow = eWin, _extra = extra)

END

;====================================================================================

FUNCTION gs_Projections::Expand, nSl

  compile_opt idl3
  
  case 1B of
    ~Isa(nSl, /integer) || (N_Elements(nSl) gt 2): Message, 'Number of slices must be an integer with at most two elements.'
    else:
  endcase
  
  if N_Elements(nSl) eq 1 then nSlcs = Replicate(nSl, 2) else nSlcs = nSl

  img = *self.imgData
  dDims = img.dim
  if nSlcs[0] gt 0 then inf = [Make_Array(dDims[0], nSlcs[0], dDims[2], type = img.typeCode)] else inf = !null
  if nSlcs[1] gt 0 then sup = [Make_Array(dDims[0], nSlcs[1], dDims[2], type = img.typeCode)] else sup = !null
  imgExp = [[inf], [img],[sup]]
  
  axialOffset = self.axialOffset.ToArray() - (nSlcs[0] - nSlcs[1])*self.pixSiz[1]/2.
   
  Return, self.New(imgExp, axialOffset = axialOffset)

END

;=======================================================================================================

FUNCTION gs_Projections::Crop, nSl

  compile_opt idl3

  case 1B of
    ~Isa(nSl, /integer) || (N_Elements(nSl) gt 2): Message, 'Number of slices must be an integer with at most two elements.'
    else:
  endcase

  if N_Elements(nSl) eq 1 then nSlcs = Replicate(nSl, 2) else nSlcs = nSl

  img = *self.imgData
  dDims = img.dim
 
  imgCrp = img[*, nSlcs[0]: dDims[1] - nSlcs[1] - 1, *]

  axialOffset = self.axialOffset.ToArray() + (nSlcs[0] - nSlcs[1])*self.pixSiz[1]/2.

  Return, self.New(imgCrp, axialOffset = axialOffset)

END

;=======================================================================================================

PRO gs_Projections__define

  compile_opt idl2
  
  dum = {gs_Projections, pixSiz: DblArr(2), mtxSiz: LonArr(2), nProjections: 0L, energyWindow: Obj_New(), inherits gs_Image}

END