FUNCTION jg_ReadIsdFile, fileName, halfLife = halfLife, double = double

  compile_opt idl2
  
  txt = jg_ReadTextFile(fileName)
  data = []
  
  foreach line, txt do begin     
    if line.Matches('^[[:blank:]]*#') || line.Matches('EnergyLevels', /fold_case) || line.Matches('PhotonEnergies', /fold_case) then continue  
    if line.Matches('halflife:', /fold_case) then begin
      splt = line.Split(':')
      halfLife = Double(splt[1])
    endif else begin
      if KeyWord_Set(double) then data = [[data], [Double((StrSplit(line, ' ', /extract))[0:1])]] else data = [[data], [Float(StrSplit(line, ' ', /extract))]] 
    endelse
  endforeach
  
  Return, data

END