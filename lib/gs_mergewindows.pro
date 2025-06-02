FUNCTION gs_MergeWindows, lower, upper

  compile_opt idl2
  
  n = N_Elements(lower)
  dataType = Size(lower, /type)
  
  case 1B of
    N_Elements(upper) ne n: Message, 'Array length mis-match.'
    Size(upper, /type) ne dataType: Message, 'Data types do not match'
    else:
  endcase
  
  lowerList = List(lower, /extract)
  upperList = List(upper, /extract)
  removeList = List()
  
  for i = 0, n - 1 do begin
    for j = i + 1, n - 1 do begin
      if (lowerList[i] eq lowerList[j]) && (upperList[i] eq upperList[j]) then removeList.Add, i
    endfor
  endfor
  
  if removeList.Count() gt 0 then begin
    lowerList.Remove, removeList.ToArray()
    upperList.Remove, removeList.ToArray()
    n = lowerList.Count()
  endif
  
  removeListLower = List()
  removeListUpper = List()
  
  for i = 0, n - 1 do begin
    for j = 0, i - 1 do begin
      if (lowerList[i] gt lowerList[j]) && (lowerList[i] lt upperList[j]) then Message, 'Overlapping windows not allowed.'
      if lowerList[i] eq upperList[j] then begin
        removeListLower.Add, j
        removeListUpper.Add, i
      endif
    endfor
  endfor
  
  if removeListLower.Count() gt 0 then begin
    
    upperList.Swap, removeListLower.ToArray(), removeListUpper.ToArray()
    lowerList.Swap, removeListUpper.ToArray(), removeListLower.ToArray()
    lr = lowerList.Remove(removeListLower.ToArray())
    ur = upperList.Remove(removeListUpper.ToArray())
    
    n = lowerList.Count()
  endif
  
  iSrt = Sort(lowerList.ToArray())
  lowerList = lowerList[iSrt]
  upperList = upperList[iSrt]
  
  winList = List()
  
  for i = 0, n - 1 do begin
    winList.Add, [lowerList[i], upperList[i]]
  endfor
  
  Return, winList

END