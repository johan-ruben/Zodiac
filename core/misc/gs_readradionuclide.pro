FUNCTION gs_ReadRadionuclide, compund, lowerLimit = lowerLimit

  compile_opt idl2
  
  if compund.Matches('\.isd$') then isd =  jg_ReadISDfile(compund, halfLife = halfLife, /double) else isd = jg_ReadISDfile(GetEnv('SMC_DIR') + compund + '.isd', halfLife = halfLife, /double)
  
  isd[0, *] = Abs(isd[0, *])
  if N_Elements(lowerLimit) gt 0 then begin
    ii = Where(isd[0, *] ge lowerLimit, count, /null)
    if count eq 0 then Message, 'No emission lines.'
    isd = isd[*, ii]
  endif
  
  rnc = gs_Radionuclide(isd[0, *].Reform(), isd[1, *].Reform(), halfLife = halfLife)
  
  Return, rnc

END