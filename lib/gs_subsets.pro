PRO gs_BitReverse, bitReverse

  compile_opt idl3
  
  nElements = N_Elements(bitReverse)
  
  ;---Trivial case
  if nElements eq 1 then begin
    bitReverse = Fix(0, type = bitReverse.typeCode)
    Return
  endif
  
  highBit = (Where(Reverse((nElements.ToBits())), /null))[-1]

  if 2L^highBit eq nElements then nElementsExt = nElements else nElementsExt = 2L^(highBit + 1)
  
  ;From Elster and Mayer
  bitReverseExt = IndGen(nElementsExt, type = bitReverse.typeCode)
  bitReverseExt[1] = nElementsExt/2
  
  for i = 2, nElementsExt - 1, 2 do begin
    bitReverseExt[i] = Ishft(bitReverseExt[i/2], -1) ;Shift right
    bitReverseExt[i + 1] = bitReverseExt[i] xor bitReverseExt[1]
  endfor
  
  ii = Where(bitReverseExt lt nElements, /null)
  bitReverse = bitReverseExt[ii]
  
END

;=================================================

FUNCTION gs_PrjOrderReverse, nPrj, nPrjSub

  compile_opt idl3
  
  nSubsets = nPrj/nPrjSub
  if nSubsets*nPrjSub ne nPrj then Message, 'The number of angles per subset must be an even factor of the number of projections.' 
  
  prjStart = LonArr(nSubsets)
  gs_BitReverse, prjStart
  subsets = LonArr(nPrjSub, nSubsets)
  
  for j = 0, nSubsets - 1 do begin
    for i = 0, nPrjSub - 1 do begin

      subsets[i, j] = prjStart[j] + i*nSubsets

    endfor
  endfor
  
  Return, subsets
  
END

;=================================================

FUNCTION gs_PrjOrderJump, nPrj, nPrjSub

  compile_opt idl3
  
  nSubsets = nPrj/nPrjSub
  increment = nSubSets/2
  
  ;Is the input compatible?
  if (nSubsets*nPrjSub ne nPrj) then Message, "The number of subsets must be an even integer."
  if (increment*2 ne nSubsets) then Message, "The number of subsets must be an even integer."
  
  prjOffset = 0

  subsets = LonArr(nPrjSub, nSubsets)
  
  for j = 0, nSubsets - 1, 2 do begin

    for i = 0, nPrjSub - 1 do begin
  
      subsets[i, j] = i*nSubsets + prjOffset
      subsets[i, j + 1] = i*nSubsets + prjOffset + increment
  
    endfor
  
    prjOffset = prjOffset + 1
  
  endfor
  
  Return, subsets
  
END

;=================================================

FUNCTION gs_subsets, nPrj, nAnglesPerSubset

  compile_opt idl3
  
  isPowerof2 = Bit_Population(nPrj) eq 1
  nSubsets = nPrj/nAnglesPerSubset
  isEven = (nSubsets mod 2) eq 0
  
  if isPowerof2 then begin
    subs = gs_PrjOrderReverse(nPrj, nAnglesPerSubset)
  endif else if isEven then begin
    subs = gs_PrjOrderJump(nPrj, nAnglesPerSubset)
  endif else begin
    subs = gs_PrjOrderReverse(nPrj, nAnglesPerSubset)
  endelse

  Return, subs
  
END