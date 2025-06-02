FUNCTION gs_AbsoluteThreshold::Init, thresholds, names

  compile_opt idl3

  case 1B of
    ~Isa(thresholds, /float): Message, 'Thresholds must be floating point.'
    else:
  endcase
  
  if N_Elements(names) eq 0 then begin
    nms = 'region ' + StrTrim(SindGen(N_Elements(thresholds) + 1, start = 1), 2)
  endif else begin
    nms = names
  endelse
  
  case 1B of
    N_Elements(thresholds) ne (N_Elements(nms) - 1): Message, 'Number of names does not match the number of thresholds.'
    else:
  endcase
  
  self.thresholds = Ptr_New(thresholds)
  self.names = Ptr_New(nms)
  
  Return, 1
  
END

;==============================================================================

PRO gs_AbsoluteThreshold::CleanUp

  compile_opt idl3
  
  if Ptr_Valid(self.thresholds) then Ptr_Free, self.thresholds
  if Ptr_Valid(self.names) then Ptr_Free, self.names

END

;==============================================================================

PRO gs_AbsoluteThreshold::GetProperty, thresholds = thresholds, names = names

  compile_opt idl3
  
  if Arg_Present(thresholds) then thresholds = self.thresholds
  if Arg_Present(names) then names = self.names

END

;==============================================================================

FUNCTION gs_AbsoluteThreshold::Apply, oImg

  compile_opt idl3
  
  case 1B of
    ~Isa(oImg, /scalar) || ~Obj_Valid(oImg) || ~Obj_Isa(oImg, 'gs_Image'): Message, 'Image must be gs_Image.'
    else:
  endcase
  
  ths = *self.thresholds
  nThresholds = N_Elements(ths)
  
  reg = IntArr(oImg.dataDims)
  ii = Where(oImg.imgData lt ths[0], count, /null)
  if count gt 0 then reg[ii] = 1S
  
  for j = 0, nThresholds - 2 do begin   
    ii = Where((oImg.imgData ge ths[j]) and (oImg.imgData lt ths[j + 1]), count, /null)
    if count gt 0 then reg[ii] = Fix(j + 2)
  endfor
  
  ii = Where(oImg.imgData ge ths[-1], count, /null)
  if count gt 0 then reg[ii] = Fix(nThresholds + 1) 
  
  Return, gs_RegionMap(reg, names = *self.names, labels = IndGen(nThresholds + 1, start = 1S))
  
END

;==============================================================================

PRO gs_AbsoluteThreshold__define

  compile_opt idl3
  
  dum = {gs_AbsoluteThreshold, thresholds: Ptr_New(), names: Ptr_New(), inherits gs_Segmenter}

END