FUNCTION gs_EsSource::Init, imgData, nonNegative = nonNegative, voxelSize = voxelSize, srcWindow = srcWindow, prjWindow = prjWindow

  compile_opt idl2
  
  tmp = self.gs_Image::Init(imgData, nonNegative = nonNegative)
  if tmp eq 0 then Return, 0
  
  case 1B of
    ~Isa(voxelSize, /float) || N_Elements(voxelSize) ne 3: Message, 'Voxel size must be three-element floating point array.' 
    ~Isa(srcWindow, /scalar) || ~Obj_Valid(srcWindow) || ~Obj_Isa(srcWindow, 'gs_EnergyWindow'): message, 'Source window must be gs_EnergyWindow.'
    ~Isa(prjWindow, /scalar) || ~Obj_Valid(prjWindow) || ~Obj_Isa(prjWindow, 'gs_EnergyWindow'): message, 'Projection window must be gs_EnergyWindow.'
    else:
  endcase
  
  self.voxelSize = voxelSize
  self.srcWindow = srcWindow
  self.prjWindow = prjWindow
  
  Return, 1

END

;========================================================================================================================================

PRO gs_EsSource::GetProperty, voxelSize = voxelSize, srcWindow = srcWindow, prjWindow = prjWindow, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(voxelSize) then voxelSize = self.voxelSize
  if Arg_Present(srcWindow) then srcWindow = self.srcWindow
  if Arg_Present(prjWindow) then prjWindow = self.prjWindow
  
  self.gs_Image::GetProperty, _extra = extra

END

;========================================================================================================================================

FUNCTION gs_EsSource::New, imgData, voxelSize = voxelSize, srcWindow = srcWindow, prjWindow = prjWindow, nonNegative = nonNegative

  compile_opt idl2
  
  if N_Elements(voxelSize) gt 0 then vs = voxelSize else vs = self.voxelSize
  if N_Elements(srcWindow) gt 0 then srcW = srcWindow else srcW = self.srcWindow
  if N_Elements(prjWindow) gt 0 then prjW = prjWindow else prjW = self.prjWindow

  Return, self.gs_Image::New(imgData, nonNegative = nonNegative, voxelSize = vs, srcWindow = srcW, prjWindow = prjW)
  
END

;========================================================================================================================================

PRO gs_EsSource__define

  compile_opt idl2
  
  dum = {gs_EsSource, voxelSize: DblArr(3), srcWindow: Obj_New(), prjWindow: Obj_New(), inherits gs_Image}

END