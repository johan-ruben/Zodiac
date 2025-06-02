FUNCTION gs_InterpolationBasedBackprojector::Init, transform = transform, attenuation = attenuation, $
  detector = detector, scatter = scatter, sensitivity = sensitivity, adjustAxial = adjustAxial, axialAdjustmentLength = axialAdjustmentLength

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
  
  Return, 1

END

;============================================================================

FUNCTION gs_InterpolationBasedBackprojector::Bck, oPrjs, oSrcs

  compile_opt idl2
  
  case 1B of
    jg_Any(~Obj_Valid(oSrcs)) || jg_Any(~Obj_Isa(oSrcs, 'gs_Source')): Message, 'Source must be gs_Source.'
    jg_Any(~Obj_Valid(oPrjs)) || jg_Any(~(Obj_Isa(oPrjs, 'gs_Projections') or Obj_Isa(oPrjs, 'gs_ProjectionContainer'))): Message, 'Projections must be gs_Projections.'
    else:
  endcase

  oSrcOut = ObjArr(N_Elements(oSrcs))

  for i = 0, N_Elements(oSrcOut) - 1 do begin
    oSrcOut[i] = oSrcs[i].New(DblArr(oSrcs[i].dataDims), /noForce)
  endfor

  foreach oSrc, oSrcs, k do begin
    
    foreach oPrjAll, oPrjs do begin
      
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
            endwhile
  
          endif
  
          oPrj = oPrjRaw.Expand(axialAdjustmentSlices)
          
        endif else oPrj = oPrjRaw
        
        interpDataDims = oSrc.dataDims
        interpVoxSiz = oSrc.voxelSize  
        srcData = Dblarr(oSrc.dataDims)
  
        sens = self.sensitivity.Sensitivity(oSrc.radionuclide, oPrj.energyWindow)
        
        if sens eq 0. then continue
        
        normYld = 0D
        
        foreach energy, oSrc.radionuclide.energy, j do begin
          
          eSens = self.detector.GetSensToEnergy(oPrj.energyWindow, energy)
          if eSens eq 0D then continue
          
          normYld += oSrc.radionuclide.yield[j]*eSens
          
          for i = 0, oPrj.nProjections - 1 do begin
            
            oSrc1 = oSrc.New(Rebin(Reform(oPrj.imgData[*, *, i], 1, oPrj.mtxSiz[0], oPrj.mtxSiz[1]), oSrc.dataDims[0], oPrj.mtxSiz[0], oPrj.mtxSiz[1]), $
              voxelSize = [oSrc.voxelSize[1], oPrj.pixSiz], /noForce)
            
            oSrc1 = self.detector.Apply(oSrc1, oPrj, energy, oPrj.prjDist[i], /back)
            if Obj_Valid(self.attenuation) then oSrc1 = self.attenuation.Apply(oSrc1, energy, oPrj.prjAngles[i], oPrj.cor[*, i], axialOffset = oPrj.axialOffset[i])
            
            oSrc1 = self.transform.Apply(oSrc1, oPrj.prjAngles[i], oPrj.cor[*, i], interpVoxSiz, interpDataDims, axialOffset = oPrj.axialOffset[i])*oPrj.prjTime[i]*oSrc.radionuclide.yield[j]*eSens
            srcData += oSrc1.imgData          
          endfor
  
        endforeach
        
        if normYld gt 0D then oSrcOut[k] += srcData*sens/normYld
      
      endfor
    endforeach
    
    if Obj_Isa(oSrc, 'gs_NaturalSource') then oSrcOut[k] = oSrcOut[k].New(oSrcOut[k].imgData, noForce = 0)
       
  endforeach

  if N_Elements(oSrcOut) eq 1 then Return, oSrcOut[0] else Return, oSrcOut

END

;============================================================================

PRO gs_InterpolationBasedBackprojector__define

  compile_opt idl2
  
  dum = {gs_InterpolationBasedBackProjector, transform: Obj_New(), attenuation: Obj_New(), detector:Obj_New(), $
    scatter: Obj_New(), sensitivity: Obj_New(), adjustAxial: !false, axialAdjustmentLength: 0L, inherits IDL_Object}

END