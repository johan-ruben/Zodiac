FUNCTION gs_Density::Init, imgData, voxelSize = voxelSize, nonNegative = nonNegative

  compile_opt idl2
  
  dum = self.gs_Image::Init(imgData, nonNegative = nonNegative)
  if dum ne 1 then Return, 0
  
  case 1B of
    ~Isa(voxelSize, /float, /array): Message, 'Voxel size must be a three-elemnt floating point array.'
    jg_Any(voxelSize le 0.): Message, 'Voxel size must be positive.'
    else:
  endcase
  
  self.voxelSize = voxelSize
  
  Return, 1

END

;=============================================================

PRO gs_Density::GetProperty, voxelSize = voxelSize, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(voxelSize) then voxelSize = self.voxelSize
  
  self.gs_Image::GetProperty, _extra = extra

END

;=============================================================

FUNCTION gs_Density::_OverloadPlus, left, right

  compile_opt idl2
  
  if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Obj_Valid(right) && Obj_Isa(right, 'gs_Density') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Isa(right, /number) then begin
    voxelSize = left.voxelSize
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Density') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
  endif else Message, 'Addition not defined for operands.'

  Return, self.gs_Image::_OverloadPlus(left, right, voxelSize = voxelSize)

END

;=============================================================

FUNCTION gs_Density::_OverloadMinus, left, right

  compile_opt idl2

  if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Obj_Valid(right) && Obj_Isa(right, 'gs_Density') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Isa(right, /number) then begin
    voxelSize = left.voxelSize
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Density') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
  endif else Message, 'Subtraction not defined for operands.'

  Return, self.gs_Image::_OverloadMinus(left, right, voxelSize = voxelSize)

END

;=============================================================

FUNCTION gs_Density::_OverloadAsterisk, left, right

  compile_opt idl2

  if Isa(left, /scalar) && Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Isa(right, /scalar) && Obj_Valid(right) && Obj_Isa(right, 'gs_Density') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Isa(right, /number) then begin
    voxelSize = left.voxelSize
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Density') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
  endif else Message, 'Multiplication not defined for operands.'

  Return, self.gs_Image::_OverloadAsterisk(left, right, voxelSize = voxelSize)

END

;=============================================================

FUNCTION gs_Density::_OverloadSlash, left, right

  compile_opt idl2

  if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Obj_Valid(right) && Obj_Isa(right, 'gs_Density') then begin

    case 1B of
      ~Array_Equal(left.voxelSize, right.voxelSize): Message, 'Voxel sizes do not agree.'
      else:
    endcase

    voxelSize = left.voxelSize

  endif else if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Isa(right, /number) then begin
    voxelSize = left.voxelSize
  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Density') && Isa(left, /number) then begin
    voxelSize = right.voxelSize
  endif else Message, 'Division not defined for operands.'

  Return, self.gs_Image::_OverloadSlash(left, right, voxelSize = voxelSize)

END

;=============================================================

FUNCTION gs_Density::_overloadPound, left, right

  if Obj_Valid(left) && Obj_Isa(left, 'gs_Density') && Obj_Valid(right) && Obj_Isa(right, 'gs_Filter') then begin

    img = left.imgData

    if StrCmp(right.mode, 'fft') then begin
      filter = right.GetFilter(left.dataDims, left.voxelSize, padTo = left.dataDims*2)
      img1 = DblArr(left.dataDims*2)
      img1[0, 0, 0] = img
      img = FFT(img1, /overwrite)
      img = Real_Part((FFT(img*filter, /inverse))[0:left.dataDims[0] - 1, 0:left.dataDims[1] - 1, 0:left.dataDims[2] - 1])*Product(left.dataDims*2)
    endif else begin
      filter = right.GetFilter(left.dataDims, left.voxelSize)
      img = Convol(img, filter, /edge_zero)
    endelse

  endif else if Obj_Valid(right) && Obj_Isa(right, 'gs_Density') && Obj_Valid(left) && Obj_Isa(left, 'gs_Filter') then begin

    img = right.imgData

    if StrCmp(left.mode, 'fft') then begin
      filter = left.GetFilter(left.dataDims, right.voxelSize, padTo = right.dataDims*2)
      img1 = DblArr(right.dataDims*2)
      img1[0, 0, 0] = img
      img = FFT(img1, /overwrite)
      img = Real_Part((FFT(img*filter, /inverse))[0:right.dataDims[0] - 1, 0:right.dataDims[1] - 1, 0:right.dataDims[2] - 1])*Product(right.dataDims*2)
    endif else begin
      filter = left.GetFilter(right.dataDims, right.voxelSize)
      img = Convol(img, filter, /edge_zero)
    endelse

  endif else Message, 'Operation not defined.'

  Return, self.New(img)

END

;=============================================================

FUNCTION gs_Density::New, imgData, nonNegative = nonNegative, voxelSize = voxelSize, _extra = extra

  compile_opt idl2
  
  if N_Elements(voxelSize) gt 0 then vs = voxelSize else vs = self.voxelSize
  
  Return, self.gs_Image::New(imgData, nonNegative = nonNegative, voxelSize = vs, _extra = extra)

END

;=============================================================

PRO gs_Density__define

  compile_opt idl2
  
  dum = {gs_Density, voxelSize: DblArr(3), inherits gs_Image}

END