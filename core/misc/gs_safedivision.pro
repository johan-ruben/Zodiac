FUNCTION gs_SafeDivision, num, denom, max = max

  compile_opt idl2
  
  if Isa(num, /scalar) && Obj_Valid(num) && Obj_Isa(num, 'gs_ProjectionContainer') && Isa(denom, /scalar) && Obj_Valid(denom) && Obj_Isa(denom, 'gs_ProjectionContainer') then begin
    
    case 1B of
      num.nBeds ne denom.nBeds: Message, 'Number of bed positions does not agree.'
      else:
    endcase
    
    n = num.oPrjs
    d = denom.oPrjs
    r = ObjArr(num.nBeds)
    
    for b = 0, num.nBeds - 1 do r[b] = gs_SafeDivision(n[b], d[b], max = max)
  
    Return, num.New(r)
    
  endif
  
  case 1B of
    Isa(num, /number): n = num
    Isa(num, /scalar) && Obj_Valid(num) && Obj_Isa(num, 'gs_NaturalSource'): n = num.natImgData
    Isa(num, /scalar) && Obj_Valid(num) && Obj_Isa(num, 'gs_Image'): n = num.imgData
    else: Message, 'Invalid numerator.'
  endcase
  
  case 1B of
    Isa(denom, /number): d = denom
    Isa(denom, /scalar) && Obj_Valid(denom) && Obj_Isa(denom, 'gs_NaturalSource'): d = denom.natImgData
    Isa(denom, /scalar) && Obj_Valid(denom) && Obj_Isa(denom, 'gs_Image'): d = denom.imgData
    else: Message, 'Invalid denominator.'
  endcase
  
  if ~Array_Equal(Size(n, /dimensions), Size(d, /dimensions)) && ~Isa(n, /scalar) && ~Isa(d, /scalar) then Message, 'data sizes do not Match'
  
  if Isa(d, /scalar) then begin
    if d eq 0. then Message, 'Denominator is 0.'
    r = Double(n/d)
  endif else  begin
    
    r = DblArr(d.dim)
    ii = Where(d gt 0., count, /null)
    if count gt 0 then r[ii] = n[ii]/d[ii] else Message, 'Denominator is 0.'
    
  endelse
  
  if N_Elements(max) gt 0 then begin
    
    case 1B of
      ~Isa(max, /scalar, /number): Message, 'Max must be a scalar number.'
      else:
    endcase
    
    r <= max
    r >= -max
    
  endif
  
  if ~Isa(num, /number) then begin
    r = num.New(r)
  endif else if ~Isa(d, /number) then begin
    r = denom.New(r)
  endif

  Return, r

END