FUNCTION gs_GaussianFilter::Init, fwhm = fwhm, nDimensions = nDimensions, mode = mode

  compile_opt idl2
  
  tmp = self.gs_Filter::Init(nDimensions = nDimensions, mode = mode)
  if tmp ne 1 then Return, 0
  
  case 1B of
    ~Isa(fwhm, /float): Message, 'FWHM must be a floating-point number.'
    else:
  endcase
  
  if Isa(fwhm, /scalar) then fwhmExp = Replicate(fwhm, self.nDimensions) else fwhmExp = fwhm
  
  case 1B of
    N_Elements(fwhmExp) ne self.nDimensions: Message, 'Dimensionality miss-match.'
    else:
  endcase
  
  self.fwhm = Ptr_New(fwhmExp)
  
  Return, 1

END

;=====================================================================================

PRO gs_gaussianFilter::CleanUp

  compile_opt idl2
  
  if Ptr_Valid(self.fwhm) then Ptr_Free, self.fwhm
  
  self.gs_Filter::CleanUp

END

;=====================================================================================

PRO gs_GaussianFilter::GetProperty, fwhm = fwhm, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(fwhm) then fwhm = *self.fwhm
  
  self.gs_Filter::GetProperty, _extra = extra

END 

;=====================================================================================

FUNCTION gs_GaussianFilter::GetFilter, dataDims, binSize, padTo = padTo

  compile_opt idl2
  
  case 1B of
    ~Isa(binSize, /float, /array): Message, 'Bin-size must be a floating-point array.' 
    N_Elements(binSize) ne self.nDimensions: Message, 'Dimensionality mis-match.'
    ~Isa(dataDims, /integer, /array): Message, 'Data dims must be an integer array.'
    N_Elements(dataDims) ne self.nDimensions: Message, 'Dimensionality mis-match'
    else:
  endcase
  
  sDev = *self.fwhm/(2D*sqrt(2D*alog(2D)))
  
  case self.nDimensions of
    1: begin
      x = DindGen(dataDims[0], start = -Double(dataDims[0]/2D))*binSize[0]
      g = exp(-x^2/(2D*sDev[0]^2))
    end
    2: begin
      x =  Rebin(DindGen(dataDims[0], start = -Double(dataDims[0]/2D))*binSize[0], dataDims)
      y =  Rebin(DindGen(1, dataDims[1], start = -Double(dataDims[1]/2D))*binSize[1], dataDims)
      g = exp(-x^2/(2D*sDev[0]^2) - y^2/(2D*sDev[1]))
    end
    3: begin
      x =  Rebin(DindGen(dataDims[0], start = -Double(dataDims[0]/2D))*binSize[0], dataDims)
      y =  Rebin(DindGen(1, dataDims[1], start = -Double(dataDims[1]/2D))*binSize[1], dataDims)
      z =  Rebin(DindGen(1, 1, dataDims[2], start = -Double(dataDims[2]/2D))*binSize[2], dataDims)
      g = exp(-x^2/(2D*sDev[0]^2) - y^2/(2D*sDev[1])  - z^2/(2D*sDev[2]))
    end
  endcase
  
  g = g/Total(g)
  
  if StrCmp(self.mode, 'fft', /fold_case) then begin
    if N_Elements(padTo) gt 0 then begin
      g1 = DblArr(padTo)
      case self.nDimensions of
        1: g1[0] = g
        2: g1[0, 0] = g
        3: g1[0, 0, 0] = g
      endcase
      g = g1
    endif
    g = Shift(g, -dataDims/2)
    g = FFT(g, /overwrite)
  endif
  
  Return, g
  
END

;=====================================================================================

PRO gs_GaussianFilter__define

  compile_opt idl2
  
  dum = {gs_GaussianFilter, fwhm: Ptr_New(), inherits gs_Filter}

END