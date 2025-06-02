FUNCTION jg_ConvolFFT, img, kernel, fftKernel = fftKernel, fftImage = fftImage, correlate = correlate

  compile_opt idl2
  
  dataTypeimg = img.typeCode
  dataTypeKernel = kernel.typeCode
  
  imgDims = img.dim
  kernelDims = kernel.dim

  totDim = imgDims + kernelDims
  
  
  ;---Pad arrays
  padImg = Make_Array(totDim, type = dataTypeImg)
  padKernel = Make_Array(totDim, type = dataTypeKernel)
  
  padImg[0, 0] = img
  padKernel[0, 0] = kernel
  
  padKernel = padKernel.Shift(-(kernelDims - 1)/2)
  
  ;---Cacluate Fourier transforms
  if N_Elements(fftImage) eq 0 then fftImage = FFT(padImg)
  if N_Elements(fftKernel) eq 0 then fftKernel = FFT(padKernel)
  
  ;---Convolve
  if KeyWord_Set(correlate) then begin
    conv = Real_Part((FFT(fftImage*Conj(fftKernel), /inverse))[0:imgDims[0] - 1, 0:imgDims[1] - 1])*(totDim[0]*totDim[1])
  endif else begin
    conv = Real_Part((FFT(fftImage*fftKernel, /inverse))[0:imgDims[0] - 1, 0:imgDims[1] - 1])*(totDim[0]*totDim[1])
  endelse
    
  Return, conv
  
END