PRO jg_PolluxExampleTc

  compile_opt idl3
  
  ;Locate directory
  dir = Routine_Dir()
  
  ;Read projection data and store in a gs_StandardCameraProjections object
  prj = Read_Binary(dir + 'spheres_tc_tot_w1_8.img', data_dims = [128, 128, 60], data_type = 4)
  oWin = gs_EnergyWindow(129.5, 150.5)
  oPrj = gs_StandardCameraProjections(prj, pixSiz = [0.442, 0.442], prjTime = Replicate(45., 60), cor = DblArr(2, 60), prjDist = Replicate(16., 60), prjAngles = DindGen(60)*6. + 90., energyWindow = oWin,  /nonNegative)

  ;Read density map and store as gs_density. File data is in g/L and is rescaled to g/mL
  dns = Read_Binary(dir + 'density.dat', data_dims = [512, 512, 128], data_type = 2)/1000.
  oDens = gs_Density(dns, voxelSize = [0.1105, 0.1105, 0.442], /nonNegative)

  ;Define the radionuclide for the source
  oRNC = gs_ReadRadionuclide('tc99m', lowerLimit = 120.)

  ;Make an initial estimate as a cylinder filled with 1.0. Store as gs_source
  src = Rebin(Double(Shift(Dist(128, 128), -64, -64) le 64.), 128, 128, 128)
  oSrc = gs_Source(src, voxelSize = Replicate(oPrj.pixSiz[0], 3), radionuclide = oRNC, /nonNegative)

  ;Define an interpolator for the geometric transfomrations.
  oInt = gs_LinearInterpolator3D()

  ;The density map is in a rather small voxel size. Regrid to the same size as the SPECT image
  ;to speed up the reconstruction.
  oRgrd = gs_Regrider3D(voxelSize = oDens.voxelSize*[4, 4, 1], dataDims = oDens.dataDims/[4, 4, 1], interpolator = oInt)
  oDensRg = oRgrd.Apply(oDens)

  ;The geometrical transfromation for the reconstruction is an axial rotator.
  oRot = gs_AxialRotator(interpolator = oInt, stepSize = oPrj.pixSiz[0])

  ;The geometry concists of water. Read mass-attenuation coefficients from file and store in
  ;a gs_AttenuationData object.
  oAcoeff = gs_AttenuationFromFile('h2o')
  oAttData = gs_AttenuationData(oAcoeff)

  ;There is just one material, so the whole image is a single region.
  oRegDns = gs_RegionMap(Replicate(1S, 128, 128, 128), names = ['h2o'], labels = [1S])

  ;Wrap the whole attenuationg eometry as a gs_MatterDistribution object
  ;The attenuating geomtry is filtered with a Gaussian filter with 1 cm FWHM.
  oMatter = gs_MatterDistribution(oDensRg, oRegDns, attCoeff = oAttData, filter = gs_GaussianFilter(fwhm = 1.0, nDimensions = 3, mode = 'fft'))

  ;Set up a gs_Attenautor object for modelling attenuation.
  oAttenuation = gs_Attenuator(densityDist = oMatter, transformer = oRot)

  ;Read projection data from the scatter window
  scaWinWidth = 129.5 - 121.1
  prjSW = Read_Binary(dir + 'spheres_tc_tot_w2_8.img', data_dims = [128, 128, 60], data_type = 4)

  ;Rescale the scatter-window projections to a scatter estimate for the main window.
  ;The scatter estimate is filtered with a Gaussian with 0.5 cm FWHM.
  prjSca = prjSW*((oPrj.energyWindow.GetLimits(/upper) - oPrj.energyWindow.GetLimits())[0]/scaWinWidth)/2.
  oPrjScaEst = oPrj.New(prjSca)#gs_GaussianFilter(FWHM = 0.5, nDimensions = 2, mode = 'fft')

  ;Define a scatter estimator using the window-based scatter estimate.
  oSca = gs_FixedScatterEstimate(oSrc, oPrjScaEst)

  ;Define the detector model. We'll only model one energy, so the weight does not matter.
  oDet = gs_GeometricParallelDetector(['129.5-150.5:140.511, 1.0', '#', 'hole width: 0.150', 'collimator depth: 3.5', 'intrinsic FWHM: 0.42', 'gap: 0.79375', 'hole shape: hex'], pixelSize = oPrj.pixSiz, stepSize = oPrj.pixSiz[0], dataDims = oPrj.mtxSiz, maxDist = 128.*oPrj.pixSiz[0])

  ;Define a sensitivity object. For simplicity we'll set the senstivity to unity.
  oSens = gs_Sensitivity(oPrj.energyWindow, oSrc.radionuclide, 1.)

  ;Define the full models for the pjojector and back-projector.
  oFwd = gs_InterpolationBasedProjector(transform = oRot, attenuation = oAttenuation, scatter = oSca, detector = oDet, sensitivity = oSens)
  oBck = gs_InterpolationBasedBackProjector(transform = oRot, attenuation = oAttenuation, detector = oDet, sensitivity = oSens)

  ;Define the OS-EM reconstruction object with 10 subsets. Offload the normalization
  ;to temporary files.
  oRec = gs_OSEMreconstructor(oPrj, oSrc, oFwd, oBck, nSubs = 10, /normInFile)

  ;Reconstruct with 4 iterations, printing a message after each subset.
  oRec.Run, 4, /verbose

  ;Save result to file
  oRec.oSrcs['source1'].ToFile, dir + 'test_tc99m.src', /compress, /overwrite

END