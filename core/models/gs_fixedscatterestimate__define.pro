FUNCTION gs_FixedScatterEstimate::Init, src, prj, allowNoSource = allowNoSource

  compile_opt idl3
  
  case 1B of
    
    jg_any(~Obj_Valid(src)) || jg_Any(~Obj_Isa(src, 'gs_Source')): Message, 'Sources must be gs_source.'
    jg_any(~Obj_Valid(prj)) || jg_Any(~Obj_Isa(prj, 'gs_Projections')): Message, 'Projections must be gs_projections.'
    N_Elements(src) ne N_Elements(prj): Message, Message, 'Number of sources and projections do not match.'
    else:
    
  endcase
  
  self.src = List(src, /extract)
  self.prj = List(prj, /extract)
  
  if KeyWord_Set(allowNoSource) then self.allowNoSource = !true else self.allowNoSource = !false
  
  Return, 1

END

;=========================================================================

FUNCTION gs_FixedScatterEstimate::Apply, oSrc, oPrj

  compile_opt idl3
  
  foreach s, self.src, k do begin
    if s.radionuclide eq oSrc.radionuclide then begin
      thisSrc = s
      break
    endif 
  endforeach
  
  if N_Elements(thisSrc) gt 0 then begin
    
    ii = Where(Max(Rebin(Reform(oPrj.prjAngles, 1, oPrj.nProjections), self.prj[k].nProjections, oPrj.nProjections) eq $
      Rebin(self.prj[k].prjAngles, self.prj[k].nProjections, oPrj.nProjections), dimension = 2),cnt, /null)
      
    if cnt ne oPrj.nProjections then Message, 'No such projetion angles.'
    
    Return, oPrj.New(self.prj[k].imgData[*, *, ii])
    
  endif else if self.allowNoSource then begin
    
    Return, oPrj.New(Make_Array(oPrj.dataDims, type = StrCmp(self.prj.numberFormat, 'single', /fold_case) ? 4 : 5))
    
  endif else Message, 'No such source.'

END

;=========================================================================

PRO gs_FixedScatterEstimate__define

  compile_opt idl3
  
  dum = {gs_FixedScatterEstimate, src: Obj_New(), prj: Obj_New(), allowNoSource: !false, inherits gs_Scatter}

END