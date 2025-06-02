FUNCTION gs_Detector::Init, fileName

  compile_opt idl2
  
  case 1B of
     ~Isa(fileName, /string): Message, 'Input must be string.'
     else:
  endcase
  
  if Isa(fileName, /scalar) then dataText = jg_ReadTextFile(fileName) else dataText = fileName
  
  self.sensitivityToEnergy = List()
  self.energyWindows = List()
  
  foreach line, dataText do begin
    
    if line.Trim() eq '' then continue
    
    splt = line.Split(':')
    eWinStr = splt[0]
    sensStr = splt[1]
    
    splt = eWinStr.Split(',')
    lower = DblArr(N_Elements(splt))
    upper = DblArr(N_Elements(splt))
    
    foreach w, splt, k do begin
      limits = w.Split('-')
      lower[k] = limits[0].ToDouble() 
      upper[k] = limits[1].ToDouble() 
    endforeach
    
    splt = sensStr.Split(';')
    
    energy = DblArr(N_Elements(splt))
    sens = DblArr(N_Elements(splt))
    
    foreach e, splt, k do begin
      splt1 = e.Split(',')
      energy[k] = splt1[0].ToDouble()
      sens[k] = splt1[1].ToDouble()
    endforeach
    
    self.energyWindows.Add, gs_EnergyWindow(lower, upper)
    self.sensitivityToEnergy.Add, OrderedHash(energy, sens)
    
  endforeach
  
  Return, 1

END

;================================================================================================

FUNCTION gs_Detector::Apply, oSrc, oPrj, energy, prjDist, back = back

  compile_opt idl2
  
  sens = self.GetSensToEnergy(oPrj.energyWindow, energy)
  
  Return, oSrc*sens
  
END

;================================================================================================

FUNCTION gs_Detector::GetSensToEnergy, oWin, energy

  compile_opt idl2
  
  foreach w, self.energyWindows, k do begin

    if w eq oWin then begin
      en = (self.sensitivityToEnergy[k].Keys()).ToArray()
      S = self.sensitivityToEnergy[k].Values()
      m = Min(en - energy, /absolute, iMin)
      if abs(en[iMin] - energy) lt .001D then thisSens = S[iMin] else thisSens = 0D
      Return, thisSens
    endif

  endforeach

  Message, 'No such energy window.'


END

;================================================================================================

PRO gs_Detector::Adapt, rncOld, groups, meanEnergy, absoluteLimit = absoluteLimit

  compile_opt idl2
  
  nWins = N_Elements(self.energyWindows)
  energy = rncOld.energy
  yield = rncOld.yield

  for w = 0, nWins - 1 do begin
    
    meanSens = DblArr(N_Elements(groups))
    totYield = DblArr(N_Elements(groups))
    
    foreach grp, groups, k do begin
      
      energyGrp = energy[grp]
      yldGrp = yield[grp]

      sens = DblArr(N_Elements(grp)) 
      for i = 0, N_Elements(grp) - 1 do sens[i] = self.GetSensToEnergy(self.energyWindows[w], energyGrp[i])
          
      meanSens[k] = Total(sens*yldGrp)/Total(yldGrp)
      totYield[k] = Total(yldGrp)
      
    endforeach
    
    if N_Elements(absoluteLimit) gt 0 then begin
      ii = Where(totYield*meanSens/Total(totYield*meanSens) lt absoluteLimit, count, /null)
      if count gt 0 then meanSens[ii] = 0D
    endif
    
    self.sensitivityToEnergy[w] = OrderedHash(meanEnergy, meanSens)
    
  endfor

END

;================================================================================================

FUNCTION gs_Detector::RelSens, oSrc, oWin, prjDist

  compile_opt idl2

  Return, 1D

END

;================================================================================================

PRO gs_Detector__define

  compile_opt idl2
  
  dum = {gs_Detector, sensitivityToEnergy: Obj_New(), energyWindows: Obj_New(), inherits IDL_Object}

END