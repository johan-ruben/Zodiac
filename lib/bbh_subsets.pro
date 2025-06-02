;+
  ; :Description:
  ;    Oranizes a given number of projections into subsets for OS-EM. The return value is a 2-dimensional array
  ;    with nSubAngles columns and nPrj/nSubAngles rows
  ;
  ; :Params:
  ;    nPrj: Total number of projections
  ;    nSubAngles: Number of projections per subset
  ;
  ; :Example:
  ;
  ; sub = bbh_Subsets(64, 8)
  ; Returns subsets for 64 projections with 8 projections per subset 
  ;
  ; :Author: Johan
  ;-
FUNCTION bbh_Subsets, nPrj, nSubAngles

  compile_opt idl2
  
  On_Error, 2
  
  nSubsets = Long(nPrj)/Long(nSubAngles)
  
  if nSubsets*nSubAngles ne nPrj then Message, 'The number of subsets times the number of projections per subset must equal the total number of projections.'
  
  ;---The algoritm for deviding into subsets only works for integer powers of 2. 
  k = Ceil(ALog(nSubAngles)/ALog(2.))
  nSubAnglesPo2 = 2^k
  n = nSubAnglesPo2
  
  
  ;---Translation from simind_mlem
  bitReverse2 = LindGen(nSubAnglesPo2)
  
  
  ;Iftime see if this part can be vectorized
  L = 1
  
  for q = 0, k - 1 do begin
    
    n /= 2
    for j = 0, L - 1 do bitreverse2[L + j] = bitreverse2[j] + n  
    L *= 2
    
  endfor
  
  ;---Remove extra projections if originally not integer power of 2
  
  validInd = Where(bitReverse2*nSubSets lt nPrj, countValid, /null)
  if countValid gt 0 then bitReverse1 = bitReverse2[validInd] else Message, 'Cannot transfer reduced sets. Talk to Johan about this error'    
  
  ;---Repeat for diiferent starting angles
  
  prjOrder = Rebin(bitReverse1, nSubAngles, nSubSets)*nSubSets + (LindGen(nSubAngles, nSubSets)/Long(nSubAngles))

  RETURN, prjOrder

END