FUNCTION gs_CTimage::Init, imgData, voxelSize = voxelSize, system = system, voltage = voltage, $
  nonNegative = nonNegative
  
  ;nonNegative has no effect

  compile_opt idl2
  
  tmp = self.gs_Image::Init(imgData)
  
  case 1B of
    ~Isa(system, /scalar, /string): Message, 'System must be a scalar string.'
    ~Isa(voltage, /scalar, /float): Message, 'Votage must be a scalar floating-point number.'
    ~Isa(voxelSize, /float, /array): Message, 'Voxel size must be a three-elemnt floating point array.'
    jg_Any(voxelSize le 0.): Message, 'Voxel size must be positive.'
    self.nDimensions ne 3: Message, 'Image must be three-dimensional.'
    else:
  endcase
  
  self.system = system
  self.voltage = voltage
  self.voxelSize = voxelSize
  
  Return, 1  

END

;===================================================================================

PRO gs_CTimage::GetProperty, voxelSize = voxelSize, system = system, voltage = voltage, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(voxelSize) then voxelSize = self.voxelSize
  if Arg_Present(system) then system = self.system
  if Arg_Present(voltage) then voltage = self.voltage
  
  self.gs_Image::GetProperty, _extra = extra

END

;====================================================================================

FUNCTION gs_CTimage::ToDensity, rescaler, regions

  compile_opt idl2
  
  rscl = self.Rescale(rescaler, regions, system = self.system, voltage = self.voltage, voxelSize = self.voxelSize)
  
  Return, gs_Density(rscl.imgData, voxelSize = self.voxelSize, /nonNegative)

END

;====================================================================================

FUNCTION gs_CTimage::New, imgData, system = system, voxelSize = voxelSize, voltage = voltage, _extra = extra

  compile_opt idl2
  
  if N_Elements(system) eq 0 then sys = self.system else sys = system
  if N_Elements(voxelSize) eq 0 then vSz = self.voxelSize else vSz = voxelSize
  if N_Elements(voltage) eq 0 then vge = self.voltage else vge = voltage 
  Return, self.gs_Image::New(imgData, system = sys, voxelSize = vSz, voltage = vge, _extra = extra)

END

;====================================================================================

PRO gs_CTimage__define

  compile_opt idl2
  
  dum = {gs_CTimage, voxelSize: DblArr(3), system: '', voltage: 0D, inherits gs_Image}

END