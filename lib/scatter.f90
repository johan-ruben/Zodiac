module Scatter

  use iso_fortran_env, only : dp => real64, L => int32, S => int16
  implicit none
  private
  public AttenuateESS
  
  contains
  
  function LinInterp(x, y, xp) result(yp)
  
    !---Input varaibles
    real(kind = dp), dimension(0:), intent(in) :: x
    real(kind = dp), dimension(0:), intent(in) :: y
    real(kind = dp), intent(in) :: xp
    
    !---Output variables
    real(kind = dp) :: yp
    
    !---Locl variables
    integer(kind = L) :: i, n
    real(kind = dp) :: x1, x2
    real(kind = dp) :: y1, y2, k, m
    
    n = Size(x)
    
    x1 = -1.0_dp
    x2 = -1.0_dp
    
    do i = 0_L, n - 2_L 
      if ((x(i) <= xp) .and. (x(i + 1) > xp)) then
        x1 = x(i)
        x2 = x(i + 1)
        y1 = y(i)
        y2 = y(i + 1)
        exit
      end if
    end do
    
    if (x1 == -1.0_dp) then
      yp = y(n - 1)
      return
    end if
    
    k = (y2 - y1)/(x2 - x1)
    m = y1 - k*x1
    
    yp = k*xp + m 
    
  end function LinInterp
  
  !==============================================================================================
  
  subroutine AttenuateESS(ssImg, enImg, density, voxelSize, attn, energy)
       
    !---Input variables
    real(kind = dp), dimension(0:, 0:, 0:), intent(in) :: enImg, density
    real(kind = dp), dimension(0:2), intent(in) :: voxelSize
    real(kind = dp), dimension(0:), intent(in) :: attn
    real(kind = dp), dimension(0:), intent(in) :: energy
    
    !----Combined input and output
    real(kind = dp), dimension(0:, 0:, 0:), intent(inout) :: ssImg
    
    !---Local variables
    integer(kind = L), dimension(0:2) :: dataDims
    integer(kind = L) :: i, j, k
    real(kind = dp) :: muSum
    
    dataDims = [Size(ssImg, dim = 1), Size(ssImg, dim = 2), Size(ssImg, dim = 3)]
    
    do k = 0_L, dataDims(2) - 1_L
      do j = 0_L, dataDims(1) - 1_L
        do i = 0_L, dataDims(0) - 1_L
          
          if (enImg(i, j, k) /= enImg(i, j, k)) cycle
          muSum = (Sum(density(i:, j, k)) - density(i, j, k)/2.0_dp)*voxelSize(0)*LinInterp(energy, attn, enImg(i, j, k))
          ssImg(i, j, k) = ssImg(i, j, k)*exp(-muSum)
                  
        end do
      end do
    end do

  end subroutine AttenuateESS

end module scatter