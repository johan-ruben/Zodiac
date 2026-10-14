FUNCTION gs_InterpolationBasedProjector::Init, transform = transform, attenuation = attenuation, detector = detector, scatter = scatter, $
  sensitivity = sensitivity, background = background, adjustAxial = adjustAxial, axialAdjustmentLength = axialAdjustmentLength

  compile_opt idl2 
  
  case 1B of
    ~Obj_Valid(transform) || ~Obj_Isa(transform, 'gs_Transformer'): Message, 'Transform must be gs_Transformer.'
    transform.nDimensions ne 3: Message, 'Transform must be three-dimensional.'
    else:
  endcase
  
  self.transform = transform
  
  case 1B of
    ~Obj_Valid(detector) || ~Obj_Isa(detector, 'gs_detector'): Message, 'Detector must be of type gs_Detector.'
    else:
  endcase 
  
  self.detector = detector 
  
  case 1B of
    ~Obj_Valid(sensitivity) || ~Obj_Isa(sensitivity, 'gs_sensitivity'): Message, 'Sensitivity must be of type gs_Sensitivity.'
    else:
  endcase
  
  self.sensitivity = sensitivity
  
  if N_Elements(attenuation) then begin
    case 1B of
      ~Obj_Valid(attenuation) || ~Obj_Isa(attenuation, 'gs_Attenuator'): Message, 'Attenuation must be supplied as gs_Attenuator.'
      else:
    endcase
    self.attenuation = attenuation
  endif
  
  if N_Elements(scatter) gt 0 then begin
    case 1B of
      ~Obj_Valid(scatter) || ~Obj_Isa(scatter, 'gs_Scatter'): Message, 'Scatter must be supplied as gs_Scatter.'
      else:
    endcase
    self.scatter = scatter
  endif
  
  if N_Elements(background) gt 0 then begin
    case 1B of
      ~Isa(background, /scalar) || ~Obj_Valid(background) || ~Obj_Isa(background, 'gs_Background'): Message, 'Background must be gs_Background.'
      else:
    endcase
    self.background = background   
  endif
  
  self.adjustAxial = !false
  
  if N_Elements(adjustAxial) gt 0 then begin
    
    case 1B of
      ~Isa(adjustAxial, /scalar, /boolean) : Message, 'Axial adjustment must be a scalar Boolean.'
      else:
    endcase
    
    self.adjustAxial = adjustAxial
    
  endif
  
  self.axialAdjustmentLength = 0

  if N_Elements(axialAdjustmentLength) gt 0 then begin

    case 1B of
      ~Isa(axialAdjustmentLength, /scalar, /integer) : Message, 'Axial adjustment length must be a scalar integer.'
      else:
    endcase

    self.axialAdjustmentLength = Long(axialAdjustmentLength)

  endif
  
  self.scatterCache = OrderedHash()
  
  Return, 1

END

;=========================================================================================================================================

PRO gs_InterpolationBasedProjector::CleanUp

  compile_opt idl2
  
  if Obj_Valid(self.scatterCache) then Obj_Destroy, self.scatterCache

END

;========================================================================================================================================

PRO gs_InterpolationBasedProjector::GetProperty, scatter = scatter, sensitivity = sensitivity

  compile_opt idl3
  
  if Arg_Present(scatter) then scatter = self.scatter
  if Arg_Present(sensitivity) then sensitivity = self.sensitivity
  
END

;=========================================================================================================================================

FUNCTION gs_InterpolationBasedProjector::Fwd, oSrcs, oPrjs, oMotion, noScatter = noScatter, name = name

  compile_opt idl2
  
  case 1B of
    jg_Any(~Obj_Valid(oSrcs)) || jg_Any(~Obj_Isa(oSrcs, 'gs_Source')): Message, 'Source must be gs_Source.'
    jg_Any(~Obj_Valid(oPrjs)) || jg_Any(~(Obj_Isa(oPrjs, 'gs_Projections') or Obj_Isa(oPrjs, 'gs_ProjectionContainer'))): Message, 'Projections must be gs_Projections.'
    else:
  endcase
  
  oPrjOut = ObjArr(N_Elements(oPrjs))
  
  for i = 0, N_Elements(oPrjOut) - 1 do begin
    if Obj_Isa(oPrjs[i], 'gs_ProjectionContainer') then begin
      oP = oPrjs[i].oPrjs
      for b = 0, oPrjs[i].nBeds - 1 do oP[b] = oP[b].New(DblArr(oP[i].dataDims))
      oPrjOut[i] = oPrjs[i].New(oP)  
    endif else oPrjOut[i] = oPrjs[i].New(DblArr(oPrjs[i].dataDims))
  endfor
  
  axialAdjustmentSave = List()
  
  foreach oSrcTmp, oSrcs, iSrc do begin
    
    case 1B of
      Obj_Isa(oSrcTmp, 'gs_BasisSource'): oSrc = oSrcTmp.Source()
      else: oSrc = oSrcTmp
    endcase
        
    foreach oPrjAll, oPrjs, k do begin
      
      for b = 0, oPrjAll.nBeds - 1 do begin
        
        if Obj_Isa(oPrjAll, 'gs_ProjectionContainer') then oPrjRaw = oPrjAll.oPrjs[b] else oPrjRaw = oPrjAll
        
        if self.adjustAxial then begin
          axialAdjustmentSlices = Ceil([oSrc.dataDims[2]*oSrc.voxelSize[2]/2. - oPrjRaw.mtxSiz[1]*oPrjRaw.pixSiz[1]/2. $
            + oPrjRaw.axialOffset[0], oSrc.dataDims[2]*oSrc.voxelSize[2]/2. - oPrjRaw.mtxSiz[1]*oPrjRaw.pixSiz[1]/2. $
            - oPrjRaw.axialOffset[0]]/oPrjRaw.pixSiz[1]) > 0L
          
          if self.axialAdjustmentLength gt 0 then begin
            
            sgn = Total(axialAdjustmentSlices, /integer) + oPrjRaw.mtxSiz[1] - self.axialAdjustmentLength
            
            while (Total(axialAdjustmentSlices, /integer) + oPrjRaw.mtxSiz[1]) ne self.axialAdjustmentLength do begin
              if sgn*axialAdjustmentSlices[0] ge sgn*axialAdjustmentSlices[1] then axialAdjustmentSlices[0] -= sgn else axialAdjustmentSlices[1] -= sgn
              if axialAdjustmentSlices[0] lt 0 then begin
                axialAdjustmentSlices[0]++
                axialAdjustmentSlices[1]--
              endif
              if axialAdjustmentSlices[1] lt 0 then begin
                axialAdjustmentSlices[0]--
                axialAdjustmentSlices[1]++
              endif
            endwhile
                 
          endif
          
          oPrj = oPrjRaw.Expand(axialAdjustmentSlices) 
          axialAdjustmentSave.Add, axialAdjustmentSlices
          
        endif else oPrj = oPrjRaw
        
        interpDataDims =oPrj.mtxsiz
        interpVoxSiz = oPrj.pixSiz
        prjData = Dblarr(oPrj.dataDims)
        pixelArea = Product(oPrj.pixSiz)
        
        sens = self.sensitivity.Sensitivity(oSrc.radionuclide, oPrj.energyWindow)
        if sens eq 0. then continue
        
        yieldNrm = 0D 
        
        foreach energy, oSrc.radionuclide.energy, j do begin
          
          eSens = self.detector.GetSensToEnergy(oPrj.energyWindow, energy)
          if eSens eq 0D then continue
          yieldNrm += oSrc.radionuclide.yield[j]*eSens
          
          for i = 0, oPrj.nProjections - 1 do begin
            oSrc1 = self.transform.Apply(oSrc, -oPrj.prjAngles[i], oPrj.cor[*, i], interpVoxSiz, interpDataDims, /noForce, axialOffset = -oPrj.axialOffset[i])
            if Obj_Valid(self.attenuation) then oSrc1 = self.attenuation.Apply(oSrc1, energy, -oPrj.prjAngles[i], oPrj.cor[*, i], oMotion = oMotion, axialOffset = -oPrj.axialOffset[i])
            oSrc1 = self.detector.Apply(oSrc1, oPrj, energy, oPrj.prjDist[i])
            prjData[*, *, i] += Total(oSrc1.imgData, 1)*pixelArea*self.transform.stepSize*oPrj.prjTime[i]*oSrc.radionuclide.yield[j]        
          endfor
                    
        endforeach
        
        if self.adjustAxial then prjData = prjData[*, axialAdjustmentSlices[0] : oPrj.mtxSiz[1] - axialAdjustmentSlices[1] - 1, *]
        
        if yieldNrm gt 0D then begin
          
          if Obj_Isa(oPrjOut[k], 'gs_ProjectionContainer') then begin
            
            bedPrjs = oPrjOut[k].oPrjs
            bedPrjs[b] += prjData*sens/yieldNrm
            oPrjOut[k] = oPrjOut[k].New(bedPrjs)
            
          endif else oPrjOut[k] += prjData*sens/yieldNrm
          
        endif 
        
      endfor
      
    endforeach 
    
    if Obj_Valid(self.scatter) then begin
      if ~KeyWord_Set(noScatter) then begin
        
        oPrjTemplate = oPrjs[0]
        
        if self.adjustAxial then begin

          if Obj_Isa(oPrjtemplate, 'gs_ProjectionContainer') then begin
            bedPrjs = ObjArr(oPrjTemplate[0].nBeds)
            for p = 0, oPrjTemplate.nBeds - 1 do bedPrjs[p] = oPrjtemplate.oPrjs[p].Expand(axialAdjustmentSave[p])
            oPrjTemplate = oPrjTemplate.New(bedPrjs)
          endif else oPrjTemplate = oPrjtemplate.Expand(axialAdjustmentSave[0])
          
        endif  
        
        scaPrj = self.scatter.Apply(oSrc, oPrjTemplate, oMotion)
        if N_Elements(name) gt iSrc then begin
          self.scatterCache[name[iSrc]] = scaPrj
        endif
      endif else if N_Elements(name) gt iSrc && self.scatterCache.HasKey(name[iSrc]) then begin
         scaPrj = self.scatterCache[name[iSrc]]
      endif else continue
      
      for k = 0, N_Elements(oPrjOut) - 1 do begin
        
        scatterFound = !false
        
        for i = 0, N_Elements(scaPrj) - 1 do begin
          
          if Obj_Isa(scaPrj[i], 'gs_ProjectionContainer') then begin
            
            if scaPrj[i].oPrjs[0].energyWindow eq oPrjOut[k].oPrjs[0].energyWindow then begin
              if ~self.adjustAxial then oPrjOut[k] += scaPrj[i] else begin
                bedPrjs = ObjArr(scaPrj.nBeds)
                for p = 0, scaPrj.nBeds - 1 do bedPrjs[p] = scaPrj[i].oPrjs[p].Crop(axialAdjustmentSave[p])
                oPrjOut[k] += scaPrj.New(bedPrjs)
              endelse
                
              scatterFound = !true
              break
              
            endif
            
          endif else begin
          
            if scaPrj[i].energyWindow eq oPrjOut[k].energyWindow then begin
              if ~self.adjustAxial then oPrjOut[k] += scaPrj[i] else $
                oPrjOut[k] += scaPrj[i].Crop(axialAdjustmentSlices)
              scatterFound = !true
              break
            endif
            
          endelse
          
        endfor
        if ~scatterFound then Message, 'Cannot find scatter for window.'
      endfor
    endif
    
  endforeach
  
  if Obj_Valid(self.background) then begin
    for k = 0, N_Elements(oPrjOut) - 1 do begin
      
      if Obj_Isa(oPrjOut[k], 'gs_ProjectionContainer') then begin
        
        bedPrjs = oPrjOut[k].oPrjs
        for p = 0, oPrjOut[k].nBeds - 1 do begin          
          c = self.background.Get(bedPrjs[p])
          bedPrjs[p] += c
        endfor  
        oPrjOut[k] = oPrjOut[k].New(bedPrjs)
        
      endif else begin      
        c = self.background.Get(oPrjOut[k])
        oPrjOut[k] += c      
      endelse
    endfor   
  endif
  
  Return, oPrjOut

END 

;=========================================================================================================================================

PRO gs_InterpolationBasedProjector__define

  compile_opt idl2
  
  dum = {gs_InterpolationBasedProjector, transform: Obj_New(), attenuation: Obj_New(), detector:Obj_New(), scatter: Obj_New(), sensitivity: Obj_New(), $
    scatterCache: Obj_New(), background: Obj_New(), adjustAxial: !false, axialAdjustmentLength: 0L, $
    inherits IDL_Object}

END