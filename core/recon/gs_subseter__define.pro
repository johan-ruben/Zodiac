FUNCTION gs_Subseter::Init, oPrjs, nSubs

  compile_opt idl2
  
  self.subs = OrderedHash()
  for j = 1, nSubs do self.subs['s' + j.ToString()] = List()
  
  foreach oPrj, oPrjs do begin
    
    if Obj_Isa(oPrj, 'gs_ProjectionContainer') then begin
      iSubs = gs_Subsets(oPrj.oPrjs[0].nProjections, oprj.oPrjs[0].nProjections/nSubs)
      
      for j = 0, nSubs - 1 do begin
        oP = oPrj.oPrjs
        for b = 0, oPrj.nBeds - 1 do oP[b] = oP[b].New(oP[b].imgData[*, *, iSubs[*, j]], prjAngles = oP[b].prjAngles[iSubs[*, j]], cor = oP[b].cor[*, iSubs[*, j]], $
          prjDist = oP[b].prjDist[iSubs[*, j]], axialOffset = oP[b].axialOffset[iSubs[*, j]])
        self.subs['s' + (j + 1).ToString()].Add, oPrj.New(oP)
      endfor
    
    endif else begin 
       
      iSubs = gs_Subsets(oPrj.nProjections, oprj.nProjections/nSubs)
        
      for j = 0, nSubs - 1 do begin
        
        if Obj_Isa(oPrj, 'gs_GatedStandardCameraProjections') then $
          self.subs['s' + (j + 1).ToString()].Add, oPrj.New(oPrj.imgData[*, *, iSubs[*, j]], prjAngles = oPrj.prjAngles[iSubs[*, j]], cor = oPrj.cor[*, iSubs[*, j]], $
            prjDist = oPrj.prjDist[iSubs[*, j]], axialOffset = oPrj.axialOffset[iSubs[*, j]], gateTags = oPrj.gateTags[iSubs[*, j]]) else $        
          self.subs['s' + (j + 1).ToString()].Add, oPrj.New(oPrj.imgData[*, *, iSubs[*, j]], prjAngles = oPrj.prjAngles[iSubs[*, j]], cor = oPrj.cor[*, iSubs[*, j]], $
            prjDist = oPrj.prjDist[iSubs[*, j]], axialOffset = oPrj.axialOffset[iSubs[*, j]]) 
      endfor
      
    endelse
  endforeach
  
  Return, 1

END

;============================================================================

FUNCTION gs_Subseter::_OverloadBracketsRightSide, isRange, names

  compile_opt idl2
  
  if isRange then Return, self.subs[*]
  if Isa(names, /scalar) then Return, self.subs[names].ToArray() 
  Return, self.subs[names]

END

;============================================================================

FUNCTION gs_Subseter::_OverloadForeach, val, indx

  compile_opt idl2
  
  names = (self.subs.Keys()).ToArray()
  if N_Elements(indx) eq 0 then indx = names[0] else begin
    ii = Where(StrCmp(names, indx), count, /null)
    if count ne 1 then Return, 0 else ii = ii[0] + 1
    if ii ge N_Elements(names) then Return, 0 else indx = names[ii]   
  endelse

  val = self.subs[indx].ToArray()
  
  Return, 1

END

;============================================================================

PRO gs_Subseter__define

  compile_opt idl2
  
  dum = {gs_Subseter, subs: Obj_New(), inherits IDL_Object}

END