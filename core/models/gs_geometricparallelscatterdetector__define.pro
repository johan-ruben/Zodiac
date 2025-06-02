FUNCTION gs_GeometricParallelScatterDetector::init, fileName, pixelSize = pixelSize, dataDims = dataDims, stepSize = stepSize, maxDist = maxDist

  compile_opt idl2
  
  case 1B of
    ~Isa(fileName, /string): Message, 'File name must be a string.'
    ~Isa(pixelSize, /float, /array) || (N_Elements(pixelSize) ne 2): Message, 'Pixel size must be a two-element floating-point array.'
    ~Isa(dataDims, /integer, /array) || (N_Elements(dataDims) ne 2): Message, 'Data dims must be a two-element integer array.'
    ~Isa(stepSize, /scalar, /float): Message, 'Step size must be a scalar float.'
    ~Isa(maxDist, /scalar, /float): Message, 'Maximum distance must be a scalar float.'
    else:
  endcase
  
  if Isa(fileName, /scalar) then txt = jg_ReadTextFile(fileName) else txt = fileName
  iSplit = Where(txt.Matches('^#'), count, /null)
  if count ne 1 then Message, 'Not a valid file.' else iSplit = iSplit[0]
  
  for i = iSplit + 1, N_Elements(txt) - 1 do begin
    
    if txt[i].Trim() eq '' then continue
    
    splt = txt[i].Split(':')
    tag = splt[0]
    val = splt[1]
    
    case 1B of
      tag.Matches('^intrinsic FWHM', /fold_case): intrinsicFWHM = Double(val)
      tag.Matches('^collimator depth', /fold_case): depth = Double(val)
      tag.Matches('^hole width', /fold_case): width = Double(val)
      tag.Matches('^hole shape', /fold_case): shape = val.Trim() 
      tag.Matches('^gap', /fold_case): gap = Double(val) 
      else: Message, 'Unnown tag: ' + tag   
    endcase
    
  endfor
  
  case 1B of
    N_Elements(intrinsicFWHM) eq 0: Message, 'No intrinsic resolution provided.'
    N_Elements(depth) eq 0: Message, 'No collimator depth provided.'
    N_Elements(width) eq 0: Message, 'No collimator width provided.'
    N_Elements(shape) eq 0: Message, 'No collimator shape provided.'
    N_Elements(gap) eq 0: Message, 'No gap provided.'
    else:
  endcase
  
  self.prjDistance = List([stepSize/2D:maxDist:stepSize], /extract)
  self.fKrnls = List()
  
  foreach d, self.prjDistance do begin
    
    krnl = jg_TotalResolution(d, depth, width, gap, shape, pixelSize, $
              subsampleFactor = 16, intrinsicFWHM = intrinsicFWHM)
    krnlPad = DblArr(dataDims + krnl.dim)
    krnlPad[0, 0] = krnl
    krnlPad = Shift(krnlPad, -krnl.dim/2)
    self.fKrnls.Add, FFT(krnlPad)*Product(Double(dataDims + krnl.dim))
    
  endforeach
  
  Return, 1
  
END

;=========================================================================================================

FUNCTION gs_GeometricParallelScatterDetector::Apply, oSS, oEn, oPrj, prjDist

  compile_opt idl2
  
  img = oSS.imgData
  
  for i = 0, oSS.dataDims[0] - 1 do begin
    
    p = img[i, *, *].Reform()
    z = (Double(oSS.dataDims[0])/2D + .5D - i)*oSS.voxelSize[0] + prjDist
    minDist = Min(Abs(self.prjDistance.ToArray() - z), iMin)
    
    fKrnl = self.fKrnls[iMin]
    pPad = DblArr(fKrnl.dim)
    pPad[0, 0] = p
    fpPad = FFT(pPad)
    tmp = Real_Part(FFT(fpPad*fKrnl, /inverse))
    img[i, *, *] = tmp[0:oSS.dataDims[1] - 1, 0:oSS.dataDims[2] - 1]
        
  endfor
  
  Return, oSS.New(img)

END

;=========================================================================================================

PRO gs_GeometricParallelScatterDetector__define

  compile_opt idl2
  
  dum = {gs_GeometricParallelScatterDetector, prjDistance: Obj_New(), fKrnls: Obj_New(), pixelSize: DblArr(2), dataDims: LonArr(2), inherits gs_ScatterDetector}

END