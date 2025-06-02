subroutine Linear3D_InternalWrapper(imgIn, iSizIn, jSizIn, kSizIn, ijk, nPts, imgOut, iSizOut, jSizOut, kSizOut)
  
  use iso_fortran_env, only : dp => real64, L => int32
  use interpolation, only : Linear3D
  
  implicit none
  
  integer(kind = L), intent(in) :: iSizIn, jSizIn, kSizIn, iSizOut, jSizOut, kSizOut, nPts
  real(kind = dp), dimension(iSizIn, jSizIn, kSizIn), intent(in) :: imgIn
  real(kind = dp), dimension(3, nPts), intent(in) :: ijk
  real(kind = dp), dimension(iSizOut, jSizOut, kSizOut), intent(inout) :: imgOut

  call Linear3D(imgIn, ijk, imgOut)

end subroutine Linear3D_InternalWrapper

!======================================================================================

subroutine AttenuateESS_InternalWrapper(ssImg, enImg, density, iSiz, jSiz, kSiz, voxelSize, attn, energy, nEnergy)

  use iso_fortran_env, only : dp => real64, L => int32
  use scatter, only : AttenuateESS

  implicit none
  
  integer(kind = L), intent(in) :: iSiz, jSiz, kSiz, nEnergy
  real(kind = dp), dimension(iSiz, jSiz, kSiz), intent(inout) :: ssImg
  real(kind = dp), dimension(3), intent(in) :: voxelSize
  real(kind = dp), dimension(iSiz, jSiz, kSiz), intent(in) :: enImg, density
  real(kind = dp), dimension(nEnergy), intent(in) :: attn, energy

  call AttenuateESS(ssImg, enImg, density, voxelSize, attn, energy)

end subroutine AttenuateESS_InternalWrapper

!=======================================================================================

subroutine RDprior_InternalWrapper(iSiz, jSiz, kSiz, img, wtsSizI, wtsSizJ, wtsSizK, wts, gamma, dUdfj)

  use iso_fortran_env, only : dp => real64, L => int32
  use Gibbs, only : RDprior

  implicit none
  
  integer(kind = L), intent(in) :: isiz, jsiz, ksiz, wtsSizI, wtsSizJ, wtsSizK
  real(kind = dp), dimension(0:isiz - 1, 0:jsiz - 1, 0:ksiz - 1), intent(in) :: img
  real(kind = dp), dimension(0:isiz*jsiz*ksiz - 1), intent(inout) :: dUdfj
  real(kind = dp), dimension(0:wtsSizI - 1, 0:wtsSizJ - 1, 0:wtsSizK - 1), intent(in) :: wts
  real(kind = dp) :: gamma
  
  call RDprior(img, gamma, wts, dUdfj)
  
end subroutine RDprior_InternalWrapper

!========================================================================

subroutine RDpriorRegions_InternalWrapper(imgSiz, img, regions, gamma, dUdfj)

  use iso_fortran_env, only : dp => real64, L => int32, S => int16
  use Gibbs, only : RDpriorRegions
  
  implicit none
  
  integer(kind = L), intent(in) :: imgSiz
  real(kind = dp), dimension(0_L:imgSiz - 1_L) :: img
  integer(kind = S), dimension(0_L:imgSiz - 1_L) :: regions
  real(kind = dp), intent(in) :: gamma
  real(kind = dp), dimension(0_L:imgSiz - 1_L) :: dUdfj
  
  call RDpriorRegions(img, regions, gamma, dUdfj)

end subroutine RDpriorRegions_InternalWrapper

!=======================================================================================

subroutine QuadraticPrior_InternalWrapper(iSiz, jSiz, kSiz, img, wtsSizI, wtsSizJ, wtsSizK, wts, dUdfj)

  use iso_fortran_env, only : dp => real64, L => int32
  use Gibbs, only : QuadraticPrior

  implicit none
  
  integer(kind = L), intent(in) :: isiz, jsiz, ksiz, wtsSizI, wtsSizJ, wtsSizK
  real(kind = dp), dimension(0:isiz - 1, 0:jsiz - 1, 0:ksiz - 1), intent(in) :: img
  real(kind = dp), dimension(0:isiz*jsiz*ksiz - 1), intent(inout) :: dUdfj
  real(kind = dp), dimension(0:wtsSizI - 1, 0:wtsSizJ - 1, 0:wtsSizK - 1), intent(in) :: wts
  
  call QuadraticPrior(img, wts, dUdfj)

end subroutine QuadraticPrior_InternalWrapper

subroutine RDPprior_internalWrapper(isiz, jsiz, ksiz, src, dUdf, gamma, wtsSiz, wts, regions, mode)

  use iso_fortran_env, only : dp => real64, L => int32, S => int16
  use Gibbspriors, only : RDPprior
  
  implicit none
  
  integer(kind = L), intent(in) :: isiz, jsiz, ksiz
  real(kind = dp), dimension(isiz, jsiz, ksiz), intent(in) :: src
  real(kind = dp), dimension(isiz, jsiz, ksiz), intent(inout) :: dUdf
  real(kind = dp), intent(in) :: gamma
  integer(kind = L), intent(in) :: wtsSiz
  real(kind = dp), dimension(wtsSiz, wtsSiz, wtsSiz), intent(in) :: wts
  integer(kind = S), dimension(isiz, jsiz, ksiz), intent(in) :: regions
  integer(kind = L), intent(in) :: mode

  select case(mode)
  
    case(1_L)
      dUdf = RDPprior(src, gamma, wts)
    
    case(2_L)
      dUdf = RDPprior(src, gamma, regions = regions)
    
    case default
      continue
  
  end select


end subroutine RDPprior_internalWrapper




