FUNCTION gs_Reconstructor::Init, oPrjs, oSrcs, fwd, bck, startScatter, stopScatter, saver = saver

  compile_opt idl2
  
  case 1B of
    jg_Any(~Obj_Valid(oPrjs)) || jg_Any(~(Obj_Isa(oPrjs, 'gs_Projections') or Obj_Isa(oPrjs, 'gs_ProjectionContainer'))): Message, 'Projection data must be gs_Projections.'
    jg_Any(~Obj_Valid(oSrcs)) || jg_Any(~Obj_Isa(oSrcs, 'gs_Source')): Message, 'Sources data must be gs_Source.'
    ~Isa(fwd, /scalar) || ~Obj_Valid(fwd) || ~Obj_Isa(fwd, 'gs_InterpolationBasedProjector'): Message, 'Projector must be gs_InterpolationBasedProjector'
    ~Isa(bck, /scalar) || ~Obj_Valid(bck) || ~Obj_Isa(bck, 'gs_InterpolationBasedBackprojector'): Message, 'Projector must be gs_InterpolationBasedBackprojector'
    else:
  endcase
  
  if N_Elements(startScatter) gt 0 then scStart = startScatter else scStart = 1
  if N_Elements(stopScatter) gt 0 then scStop = stopScatter else scStop = !values.d_infinity
  
  case 1B of 
    ~Isa(scStart, /integer): Message, 'Scatter start must be an integer.'
    ~Isa(scStop, /number): Message, 'Scatter stop must be numeric.'
    N_Elements(scStart) ne N_Elements(scStop): Message, 'Scatter start and stop must have the same number of elements.'
    else:
  endcase
  
  if N_Elements(saver) gt 0 then self.saver = List(saver, /extract) else self.saver = List()

  self.oPrjs = List(oPrjs, /extract)
  self.oSrcs = OrderedHash('source' + StrTrim(SindGen(N_elements(oSrcs), start = 1), 2), oSrcs)
  self.fwd = fwd
  self.bck = bck
  self.startScatter = List(scStart, /extract)
  self.stopScatter = List(scStop, /extract)
  for i = 0, self.stopScatter.Count() - 1 do begin
    if Finite(self.stopScatter[i]) then self.stopScatter[i] = Round(self.stopScatter[i])
  endfor
  
  self.nIters = 0L
  self.isAsleep = !false
  
  Return, 1

END

;================================================================================

PRO gs_Reconstructor::CleanUp

  compile_opt idl2
  
  if Obj_Valid(self.startScatter) then Obj_Destroy, self.startScatter
  if Obj_Valid(self.stopScatter) then Obj_Destroy, self.stopScatter

END

;=================================================================================

PRO gs_Reconstructor::GetProperty, oSrcs = oSrcs, nIters = nIters, temporaryDirectory = temporaryDirectory, isAsleep = isAsleep

  compile_opt idl2
  
  if Arg_Present(oSrcs) then oSrcs = (self.oSrcs)[*]
  if Arg_Present(nIters) then nIters = self.nIters
  if Arg_Present(isAsleep) then isAsleep = self.isAsleep
END

;=================================================================================

PRO gs_Reconstructor::Sleep

  compile_opt idl3
  
  if ~self.isAsleep then begin
    srcNames = self.oSrcs.Keys()
    foreach nme, srcNames do begin
      self.oSrcs[nme].Compress
    endforeach
    self.isAsleep = !true
  endif

END

;=================================================================================

PRO gs_Reconstructor::Awake

  if self.isAsleep then begin
    srcNames = self.oSrcs.Keys()
    foreach nme, srcNames do begin
      self.oSrcs[nme].Uncompress
    endforeach
    self.isAsleep = !false 
  endif


END

;=================================================================================

PRO gs_Reconstructor__define

  compile_opt idl2
  
  dum = {gs_Reconstructor, oSrcs: Obj_New(), oPrjs: Obj_New(), fwd: Obj_New(), bck: Obj_New(), nIters: 0L, startScatter: Obj_New(), stopScatter: Obj_New(), $
    saver: Obj_New(), isAsleep: !false, inherits IDL_Object}

END