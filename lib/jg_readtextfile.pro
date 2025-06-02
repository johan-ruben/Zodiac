FUNCTION jg_ReadTextFile, fileName
  
  ;Read file specified by varaible filename as text file.
  ;All lines are read. 
  
  compile_opt idl2
  
  On_Error, 2
  
  if ~Isa(fileName, /scalar, /string) then Message, 'File name must be specified as a scalar string.'
  if ~File_Test(fileName, /read) then Message, 'Unable to open ' + fileName
  
  nLines = File_Lines(fileName)
  lines = StrArr(nLines)
  
  OpenR, lun, fileName, /get_lun
  ReadF, lun, lines
  Free_Lun, lun
  
  RETURN, lines
  
END