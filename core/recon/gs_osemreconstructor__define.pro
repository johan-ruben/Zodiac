FUNCTION gs_OSEMreconstructor::Init, oPrjs, oSrcs, fwd, bck, startScatter, stopScatter, saver = saver, $
  nSubs = nSubs, normInFile = normInFile, prior = prior, temporaryDirectory = temporaryDirectory

  compile_opt idl2
  
  tmp = self.gs_Reconstructor::Init(oPrjs, oSrcs, fwd, bck, startScatter, stopScatter, saver = saver)
  if tmp ne 1 then Return, 0
  
  if N_Elements(nSubs) eq 0 then ns = 1 else ns = nSubs
  case 1B of
    ~Isa(ns, /scalar, /integer): Message, 'Number of subsets must be a scalar integer.'
    else:
  endcase
  
  if N_Elements(prior) gt 0 then begin
    
    case 1B of
       ~Isa(prior, /scalar) || ~Obj_Valid(prior) || ~Obj_Isa(prior, 'gs_Gibbsprior'): Message, 'Prior must be gs_Gibbsprior.'
       else: 
    endcase
    
    self.prior = prior
  endif
  
  self.nSubs = ns
  self.subs = gs_Subseter(self.oPrjs.ToArray(), self.nSubs)
  self.nrm = gs_OSEMNormalizer((self.subs)[*], self.oSrcs, self.bck, fromFile = normInFile, temporaryDirectory = temporaryDirectory)
  
  Return, 1
  
END

;==================================================================================================

PRO gs_OSEMreconstructor::GetProperty, nSubs = nSubs, nrm = nrm, subs = subs, _ref_extra = extra

  compile_opt idl2
  
  if Arg_Present(nSubs) then nSubs = self.nSubs
  if Arg_Present(nrm) then nrm = self.nrm
  if Arg_Present(subs) then subs = self.subs
  self.gs_Reconstructor::GetProperty, _extra = extra

END

;==================================================================================================

PRO gs_OSEMreconstructor::Run, nIters, subset = subset, verbose = verbose

  compile_opt idl2
  
  if self.isAsleep then Message, 'Reconstructor is asleep-'
  
  srcNames = (self.oSrcs.Keys()).ToArray()
  
  for it = 1, nIters do begin
    
    doScatter = !false
    
    for s = 0, self.startScatter.Count() - 1 do begin
      if ((self.nIters + 1) ge self.startScatter[s]) && ((self.nIters + 1) le self.stopScatter[s]) then begin
        doScatter = !true
        break
      endif
    endfor
    
    noScatter = ~doScatter
    
    foreach oPrjSub, self.subs, prjName do begin
      
      if N_Elements(subset) gt 0 && prjName ne subset then continue
      
      oPrjEst = self.fwd.Fwd((self.oSrcs.Values()).ToArray(), oPrjSub, noScatter = noScatter, name = prjName + '_' + (self.oSrcs.Keys()).ToArray())
      
      oRatio = ObjArr(N_Elements(oPrjSub))
      for iPrj = 0, N_Elements(oPrjSub) - 1 do oRatio[iPrj] = gs_SafeDivision(oPrjSub[iPrj], oPrjEst[iPrj], max = 1D6)
      
      oBck = self.bck.Bck(oRatio, (self.oSrcs.Values()).ToArray())
      
      iSrc = 0
      oNew = ObjArr(self.oSrcs.Count())
      foreach oSrc, self.oSrcs, srcName do begin
        nrmMap = self.nrm.Get(prjName, srcName)
        if Obj_Valid(self.prior) then begin
          mx = Max(nrmMap)
          nrmMap *= (1. + self.prior.Apply(oSrc))
          nrmMap >= 0D
        endif
        oUpdate = gs_SafeDivision(oBck[iSrc], nrmMap, max = 1D6)       
        oNew[iSrc] = oSrc*oUpdate
        iSrc++
      endforeach
      
      srcNames = self.oSrcs.Keys()
      for iSrc = 0, self.oSrcs.Count() - 1 do self.oSrcs[srcNames[iSrc]] = oNew[iSrc]
      if KeyWord_Set(verbose) then Print, it, prjName, format = 'Finished %I %S'
      
    endforeach 
    
    self.nIters++
    
    foreach oSave, self.saver do oSave.Apply, self
    
  endfor

END

;==================================================================================================

PRO gs_OSEMreconstructor::_Inject, oSrcs

  compile_opt idl3
  
  sNames = self.oSrcs.Keys()
  foreach nme, sNames, i do self.oSrcs[nme] = oSrcs[i]

END

;==================================================================================================

;=================================================================================

PRO gs_OSEMReconstructor::Unload

  compile_opt idl3

  foreach oSrc, self.oSrcs do begin
    oSrc.Unload, self.nrm.tempDir, /directory
  endforeach

END

;=================================================================================

PRO gs_OSEMReconstructor::Reload

  compile_opt idl3

  foreach oSrc, self.oSrcs do begin
    oSrc.Reload
  endforeach

END

;===================================================================================================

PRO gs_OSEMreconstructor__define

  compile_opt idl2
  
  dum = {gs_OSEMreconstructor, nSubs: 0L, subs: Obj_New(), nrm: Obj_New(), prior: Obj_New(), inherits gs_Reconstructor}

END