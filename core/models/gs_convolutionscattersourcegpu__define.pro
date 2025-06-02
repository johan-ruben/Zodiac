FUNCTION gs_ConvolutionScatterSourceGPU::Init, densityDistribution, rncs, $
  kernels = kernels, padTo = padTo, $
  referenceDensity = referenceDensity, transformer = transformer

  compile_opt idl3

  case 1B of
    jg_Any(~Obj_Valid(kernels)) || jg_Any(~Obj_Isa(kernels, 'jg_ScatterSource')): Message, 'Kernels must be jg_ScatterSource.'
    ~Isa(padTo, /integer, /array) || (N_Elements(padTo) ne 3): Message, 'Padding must be a three-element integer array.'
    ~Isa(referenceDensity, /scalar, /float): Message, 'Reference density must be scalar float.'
    ~Isa(transformer, /scalar) || ~Obj_Valid(transformer) || ~Obj_Isa(transformer, 'gs_transformer'): Message, 'Transformer must be gs_trasnformer.'
    else:
  endcase
  
  self.cp = python.Import('cupy')
  self.cuFFT = python.Import('cupyx.scipy.fft')
  
  self.referenceDensity = referenceDensity
  self.transformer = transformer
  self.kernels = List(kernels, /extract)
  self.fkernels = List()
  self.fmeanEnergy = List()
  self.maxEnergy = List()
  
  self.srcWindows = List()
  prjWindows = List()
  radionuclide = List()

  foreach krnl, self.kernels, j do begin

    nSrc = krnl.metaData.numberOfSources

    for i = 0, nSrc - 1 do begin
      krnlPad = DblArr(krnl.metaData.dataDims[i]+ padTo)
      krnlPad[0, 0, 0] = Reverse(Reverse(Reverse(krnl.scatterSource[i], 1), 2), 3)
      krnlPad = krnlPad.Shift(-krnl.metaData.dataDims[i]/2)
      tm = self.cp.asarray(krnlPad)
      self.fkernels.Add, self.cuFFT.rfftn(tm)
      Obj_Destroy, tm

      meanEnergyPad = DblArr(krnl.metaData.dataDims[i] + padTo)
      en = krnl.meanEnergy[i]
      ii = Where(Finite(en, /nan), count, /null)
      if count gt 0 then en[ii] = 0.
      meanEnergyPad[0, 0, 0] = Reverse(Reverse(Reverse(en*krnl.scatterSource[i], 1), 2), 3)
      meanEnergyPad = meanEnergyPad.Shift(-krnl.metaData.dataDims[i]/2)
      tm = self.cp.asarray(meanEnergyPad)
      self.fmeanEnergy.Add, self.cuFFT.rfftn(tm)
      self.maxEnergy.Add, Max(en)
      obj_Destroy, tm

      prjWindows.Add, gs_EnergyWindow([krnl.metaData.prjEnergyRange[i, 0]], [krnl.metaData.prjEnergyRange[i, 1]])
      self.srcWindows.Add, gs_EnergyWindow([krnl.metaData.srcEnergyRange[i, 0]], [krnl.metaData.srcEnergyRange[i, 1]])
      radionuclide.Add, rncs[j]
    endfor

  endforeach

  tmp = self.gs_ScatterSource::Init(densityDistribution, prjWindows.ToArray(), radionuclide.ToArray())
  if tmp eq 0 then Return, 0

  Return, 1

END

;============================================================

PRO gs_ConvolutionScatterSourceGPU::CleanUp

  compile_opt idl3
  
  n = self.fkernels.Count()
  
  for i = 0, n - 1 do begin
        
    if Obj_Valid(self.fKernels[i]) then Obj_Destroy, self.fKernels[i]
    if Obj_Valid(self.fMeanEnergy[i]) then Obj_Destroy, self.fMeanEnergy[i]
    
  endfor
  
  if Obj_Valid(self.cp) then Obj_Destroy, self.cp
  if Obj_Valid(self.cuFFT) then Obj_Destroy, self.cuFFT 
  
END


;============================================================

PRO gs_ConvolutionScatterSourceGPU::GetProperty, transformer = transformer, _ref_extra = extra

  compile_opt idl3

  if Arg_Present(transformer) then transformer = self.transformer

  self.gs_ScatterSource::GetProperty, _extra = extra

END

;============================================================

FUNCTION gs_ConvolutionScatterSourceGPU::GetScatterSource, oSrc, oPrj

  compile_opt idl3

  ssList = List()
  enList = List()

  iKernels = []

  for k = 0, self.fkernels.Count() - 1 do begin

    if (self.radionuclide[k] eq oSrc.radionuclide) then iKernels = [iKernels, k]

  endfor

  if N_Elements(iKernels) eq 0 then Message, 'No such radionuclide or energy window.'

  for p = 0, oPrj.nProjections - 1 do begin

    oSrcR = self.transformer.Apply(oSrc, -oPrj.prjAngles[p], oPrj.cor[*, p], oPrj.pixSiz, oPrj.mtxSiz, axialOffset = -oPrj.axialOffset[p], /noForce)
    
    thisSS = ObjArr(N_Elements(iKernels))
    thisEn = ObjArr(N_Elements(iKernels))
    
    if Total(oSrcR.imgData) eq 0. then begin
      for i = 0, N_Elements(iKernels) - 1 do begin
        thisSS[i] = gs_EsSource(DblArr(oSrcR.dataDims), voxelSize = oSrcR.voxelSize, srcWindow = self.srcWindows[iKernels[i]], prjWindow = self.energyWindows[iKernels[i]])
        thisEn[i] = gs_EsSource(Replicate(!values.d_nan, oSrcR.dataDims), voxelSize = oSrcR.voxelSize, srcWindow = self.srcWindows[iKernels[i]], prjWindow = self.energyWindows[iKernels[i]])
      endfor
      ssList.Add, thisSS
      enList.Add, thisEn
      continue
    endif
    
    img = oSrcR.imgData/Total(oSrcR.imgData)

    for i = 0, N_Elements(iKernels) - 1 do begin
      kDims = (self.fKernels[iKernels[i]].shape).ToArray()
      if kDims[2] mod 2 eq 0 then kDims = kDims*[1, 1, 2] else kDims = kDims*[1, 1, 2] - [0, 0, 2]
      imgPad = DblArr(Reverse(kDims))
      imgPad[0, 0, 0] = img
      tm = self.cp.asarray(imgPad)
      fimgPad = self.cuFFT.rfftn(tm)      
      SS = (self.cp.asnumpy((self.cp.real(self.cuFFT.irfftn(fimgPad*self.fKernels[iKernels[i]])))))[0:oSrcR.dataDims[0] - 1, 0:oSrcR.dataDims[1] - 1, 0:oSrcR.dataDims[2] - 1]
      if oSrc.nonNegative then SS >= 0. else fimgPad = self.cuFFT.rfftn(self.cp.abs(tm))
      Obj_Destroy, tm
      
      en = (self.cp.asnumpy((self.cp.real(self.cuFFT.irfftn(fimgPad*self.fmeanEnergy[iKernels[i]])))))[0:oSrcR.dataDims[0] - 1, 0:oSrcR.dataDims[1] - 1, 0:oSrcR.dataDims[2] - 1]
      en >= 0.
            
      ii = Where(SS ne 0., count, /null, complement = jj, ncomplement = cCount)
      if count gt 0 then en[ii] = en[ii]/abs(SS[ii])
      if cCount gt 0 then en[jj] = !values.d_nan
      
      if count gt 0 then en[ii] <= self.maxEnergy[iKernels[i]]
      
      oAttR = self.transformer.Apply(self.densDistribution, -oPrj.prjAngles[p], oPrj.cor[*, p], oSrcR.voxelSize, oSrcR.dataDims, axialOffset = -oPrj.axialOffset[p])

      scl = oAttR.imgData/self.referenceDensity
      SS *= scl

      ii = Where(SS eq 0., count, /null)
      if count gt 0 then en[ii] = !values.d_nan

      if jg_Any(Finite(SS, /nan)) then STOP
      thisSS[i] = gs_EsSource(SS, voxelSize = oSrcR.voxelSize, srcWindow = self.srcWindows[iKernels[i]], prjWindow = self.energyWindows[iKernels[i]])
      thisEn[i] = gs_EsSource(en, voxelSize = oSrcR.voxelSize, srcWindow = self.srcWindows[iKernels[i]], prjWindow = self.energyWindows[iKernels[i]])

    endfor

    ssList.Add, thisSS
    enList.Add, thisEn

  endfor

  Return, [ssList, enList]

END

;============================================================

PRO gs_ConvolutionScatterSourceGPU__define

  compile_opt idl3

  dum = {gs_ConvolutionScatterSourceGPU, cp: Obj_New(), cuFFT: Obj_New(), kernels: Obj_New(), fkernels: Obj_New(), fmeanEnergy: Obj_New(), $
    srcWindows: Obj_New(), maxEnergy: Obj_New(), referenceDensity: 0., transformer: Obj_New(), inherits gs_ScatterSource}

END