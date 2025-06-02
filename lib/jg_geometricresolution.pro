FUNCTION jg_CricleEquivalentRadius, colDiameter, holeShape

  compile_opt idl2
  
  case holeShape.ToLower() of
    
    'circ': area = !dpi*(colDiameter/2D)^2
    'square': area = colDiameter^2
    'hex': area = (Sqrt(3D)*colDiameter^2)/2D
    else: Message, 'Unknown collimator shape: ' + holeShape
    
  endcase
  
  r = Sqrt(area/!dpi)
  
  Return, r

END

;================================================================================= 

FUNCTION jg_GeometricResolution, dist2col, colThick, colDiameter, gap, holeShape, pixelSize, average = average, subsampleFactor = subsampleFactor

  compile_opt idl2
  
  
  if N_Elements(subsampleFactor) eq 0 then sf = 1 else sf = subsampleFactor
  
  
  pixSiz = pixelSize/Double(sf) 
  
  radius = jg_CricleEquivalentRadius(colDiameter, holeShape)
  
  grf0 = (dist2col + colThick + gap)*2D*radius/colThick
  
  kernelSize = 2*Ceil(grf0/pixSiz) + 1
  x = (Double((LindGen(kernelSize) mod kernelSize[0]) - Double(kernelSize[0])/2D) + 0.5D)*pixSiz[0]
  y = (Double((LindGen(kernelSize)/kernelSize[0]) - Double(kernelSize[1])/2D) + 0.5D)*pixSiz[1]
  
  r = Sqrt(x^2 + y^2)
  
  rt = r*colThick/(dist2col + colThick + gap)
  
  kernel = DblArr(kernelSize)
  ii = Where(abs(rt) le 2D*radius, count, /null)
  if count gt 0 then kernel[ii] = (2D*acos(Abs(rt[ii])/(2D*radius)) - (Abs(rt[ii])/radius)*Sqrt(1D - (Abs(rt[ii])/(2D*radius))^2))/!dpi
  
  if KeyWord_Set(average) then begin
    
    aK = jg_PixekAverageKernel(kernelSize)
    ak = ak/Total(ak)
    kernel = jg_ConvolFFT(kernel, ak) > 0    
    
  endif
  
  if sf gt 1 then kernel = Rebin(kernel, kernelSize/sf)
  
  totKernel = Total(kernel, /double);Normalize to unity
  kernel /= totKernel
  
  Return, kernel

END