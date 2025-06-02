FUNCTION jg_AddSlash, path

Compile_Opt idl2

slash = Path_Sep()

pathOut = path
if slash eq '\' then begin
  if ~StRegEx(pathOut, '\' + slash + '$', /boolean) then pathOut += slash
endif else if ~StRegEx(pathOut, slash + '$', /boolean) then pathOut += slash

RETURN, pathOut

END 