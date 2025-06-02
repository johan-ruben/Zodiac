FUNCTION jg_Any, array

  compile_opt idl2
  
  if N_Elements(array) eq 0 then RETURN, !false
  ans = Boolean((Boolean(array)).HasValue(!true))
  
  RETURN, ans

END