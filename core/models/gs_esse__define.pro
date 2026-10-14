FUNCTION gs_ESSE::Init, scatterSource = scatterSource, attenuation = attenuation, $
  detector = detector, sensitivity = sensitivity, priDetector = priDetector, external = external

  compile_opt idl2
  
  case 1B of
    ~Isa(scatterSource, /scalar) || ~Obj_valid(scatterSource) || ~Obj_Isa(scatterSource, 'gs_ScatterSource'): Message, 'Scatter source must be gs_ScatterSource.'
    ~Isa(attenuation, /scalar) || ~Obj_valid(attenuation) || ~Obj_Isa(attenuation, 'gs_MassAttenuationCoefficients'): Message, 'Attenuation must be gs_MassAttenuationCoefficients.' 
    (N_Elements(detector) gt 0) && (~Isa(detector, /scalar) || ~Obj_valid(detector) || ~Obj_Isa(detector, 'gs_ScatterDetector')): Message, 'Detector must be gs_ScatterDetector.'
    ~Isa(sensitivity, /scalar) || ~Obj_valid(sensitivity) || ~Obj_Isa(sensitivity, 'gs_Sensitivity'): Message, 'Sensitivity must be gs_Sensitivity.'
    ~Isa(priDetector, /scalar) || ~Obj_Valid(priDetector) || ~Obj_Isa(priDetector, 'gs_detector'): Message, 'Primary detector must be gs_Detector.'
    else:
  endcase
  
  self.scatterSource = scatterSource
  self.attenuation = attenuation
  if N_Elements(detector) gt 0 then self.detector = detector
  self.sensitivity = sensitivity
  self.priDetector = priDetector
  if N_Elements(external) gt 0 then self.external = Boolean(external) else self.external = !false
  
  Return, 1

END

;=======================================================================

FUNCTION gs_ESSE::Apply, oSrc, oPrjRaw, oMotion

  compile_opt idl2
  
  prjOutAll = List()
   
  for b = 0, oPrjRaw.nBeds - 1 do begin
    
    if Obj_Isa(oPrjRaw, 'gs_ProjectionContainer') then oPrj = oPrjRaw.oPrjs[b] else oPrj = oPrjRaw
    
    oSSen = self.scatterSource.GetScatterSource(oSrc, oPrj, oMotion)
    isEqual = Lambda(eWin1, eWin2: eWin1 eq eWin2)
    oSS = OSSen[0]
    oEn = oSSen[1]
    
    if self.external then begin
      if !cpu.tpool_nthreads gt 1 then shared = 'C:\Users\johan\pollux\idl\gray.dll' else $
        shared = 'C:\Users\johan\pollux\idl\gray_single.dll'
    endif
      
    nSS = N_Elements(oSS[0])
    prjWins = List((oSS[0])[0].prjWindow)
    for i = 1, nSS - 1 do begin
      if ~jg_Any((prjWins.Map(isEqual, (oSS[0])[i].prjWindow)).ToArray()) then prjWins.Add, (oSS[0])[i].prjWindow
    endfor
    
    prjDataDims = oPrj.dataDims
    if N_Elements(prjDataDims) lt 3 then prjDataDims = [prjDataDims, 1]
    prjImg = DblArr([prjDataDims, N_Elements(prjWins)])
    
    foreach ss, oSS, p do begin
      
      oDens = self.scatterSource.transformer.Apply(self.scatterSource.densDistribution, -oPrj.prjAngles[p], oPrj.cor[*, p], ss[0].voxelSize, ss[0].dataDims, axialOffset = -oPrj.axialOffset[p])
      oSrcR = self.scatterSource.transformer.Apply(oSrc, -oPrj.prjAngles[p], oPrj.cor[*, p], ss[0].voxelSize, ss[0].dataDims, axialOffset = -oPrj.axialOffset[p], /noforce)
      en = oEn[p]
      
      for i = 0, nSS - 1 do begin
        ssImg =  Double(ss[i].imgData)
        sens = self.sensitivity.Sensitivity(oSrc.radionuclide, ss[i].prjWindow) 
        
        if self.external then $
          tmp = Call_External(shared, 'ATTENUATEESS_WRAPPER', ssImg, Double(en[i].imgData), Double(oDens.imgData), $
            ss[i].dataDims[0], ss[i].dataDims[1], ss[i].dataDims[2], Double(ss[i].voxelSize), Double(self.attenuation.coefficients), $
            Double(self.attenuation.energy), N_Elements(self.attenuation.energy)) else $
          gs_AttenuateESS, ssImg, en[i].imgData, oDens.imgData, ss[i].voxelSize, self.attenuation.energy, self.attenuation.coefficients
        
        thisSS = ss[i].New(ssImg)
        
        if Obj_Valid(self.detector) then thisSS = self.detector.Apply(thisSS, en[i], oPrj, oPrj.prjDist[p])
        iWin = Where((prjWins.Map(isEqual, ss[i].prjWindow)).ToArray(), count, /null)
        if count eq 1 then iWin = iWin[0] else Message, 'Window error.' 
        prjImg[*, *, p, iWin] += Total(thisSS.imgData, 1)*Total(oSrc.imgData)*Product(oSrc.voxelSize)*oPrj.prjTime[p]*sens*self.priDetector.RelSens(oSrcR, ss[i].prjWindow, oPrj.prjDist[p])
      endfor
      
    endforeach
    
    prjOut = ObjArr(N_Elements(prjWins))
    for i = 0, N_Elements(prjWins) - 1 do prjOut[i] = oPrj.New(prjImg[*, *, *, i].Reform(), energyWindow = prjWins[i])
    
    prjOutAll.Add, prjOut
    
  endfor
  
  if Obj_Isa(oPrjRaw, 'gs_ProjectionContainer') then begin
    prjOut = ObjArr(N_Elements(prjOutAll[0]))
    for p = 0, N_Elements(prjOutAll[0]) - 1 do begin
      bedPrjs = ObjArr(N_Elements(prjOutAll)) 
      for b = 0, N_Elements(prjOutAll) - 1 do bedPrjs[b] = prjOutAll[b, p]
      prjOut[p] = oPrjRaw.New(bedPrjs)
    endfor
  endif else prjOut = (prjOutAll.ToArray())[*]
  
  Return, prjOut
  
END

;=======================================================================

PRO gs_ESSE__define

  compile_opt idl2
  
  dum = {gs_ESSE, scatterSource: Obj_New(), attenuation: Obj_New(), detector: Obj_New(), external: !false, sensitivity: Obj_New(), priDetector: Obj_New(), inherits gs_Scatter}

END