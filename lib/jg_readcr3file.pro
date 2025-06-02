PRO jg_ReadCr3File, compoundName, crossTable, dir = dir, nameInFile = nameInFile

  compile_opt idl2
  
  On_Error, 2
  
  ;---------------Basic check of input----------------------------------------------------
  
  if (N_Elements(dir) eq 0) && ~Arg_Present(dir) then dir = GetEnv('SMC_DIR')
  
  if ~Isa(dir, /string, /scalar) then Message, 'Directory must be specified as a scalar string.'
  if ~File_Test(dir, /directory) then Message, 'Unable to find directory ' + dir 
  
  
  ;-------------Read file-----------------------------------------------------------------
  
  compoundFile = compoundName
  if ~compoundFile.Matches('\.cr3$', /fold_case) then compoundFile += '.cr3'
  
  totPath = jg_AddSlash(dir) + compoundFile
  
  if ~File_Test(totPath, /read) then Message, 'Unable to read ' + totPath
  
  nLines = File_Lines(totPath)
  cr3Lines = StrArr(nLines)
  OpenR, lun, totPath, /get_lun
  ReadF, lun, cr3Lines
  Free_Lun, lun
  
  ;-----------------------Parse file----------------------------------------
  
  ;-----------------------Find start of table-------------------------------
  nEq = 0
  lineStart = -1
  for i = 0, nLines - 1 do begin
    
    if cr3Lines[i].StartsWith('=') then nEq++
    
    if nEq eq 8 then begin
      lineStart = i + 4
      break
    endif
    
  endfor

  if lineStart lt 4 then Message, 'Unable to find start of cross sections.'
  
  crossTable = DblArr(5, nLines - lineStart + 1)
  
  tmpCross = DblArr(5)
  lineEnd = 0
  
  for i = lineStart, nLines - 1 do begin
    
    if cr3Lines[i].StartsWith('=') then begin
      lineEnd = i
      break
    endif
    
    ReadS, cr3Lines[i], tmpCross 
    crossTable[*, i - lineStart] = tmpCross
    
  endfor
  
  crossTable = crossTable[*, 0 : lineEnd - lineStart - 1]; Truncate table
  
  if Arg_Present(nameInFile) then nameInFile = (cr3Lines[0].Split(':'))[1].Trim()
  
END