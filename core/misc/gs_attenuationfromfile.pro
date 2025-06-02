FUNCTION gs_AttenuationFromFile, fileName, scatter = scatter

  compile_opt idl2
  
  dir = File_DirName(fileName)
  if dir eq '.' then jg_ReadCr3File, fileName, crossTable, nameInFile = name else jg_ReadCr3File, File_BaseName(fileName), crossTable, dir = dir, nameInFile = name
  
  energy = Reform(crossTable[0, *])
  
  if KeyWord_Set(scatter) then coefficients = Total(crossTable[2:3, *], 1) else $
    coefficients = Total(crossTable[1:*, *], 1)
  
  Return, gs_MassAttenuationCoefficients(name, energy, coefficients)
  
END