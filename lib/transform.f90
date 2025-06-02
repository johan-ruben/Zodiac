module transformation
  
  use iso_fortran_env, only : dp => real64, L => int32
  
  implicit none
  
  private
  public :: Rotate2D
  
  contains
  
  subroutine Rotate2D(orgDataDims, orgVoxSiz, newDataDims, newVoxSiz, theta, pivot, ijk)
    
    !---input variables
    integer(kind = L), dimension(3), intent(in) :: orgDataDims
    real(kind = dp), dimension(3), intent(in) :: orgVoxSiz
    integer(kind = L), dimension(3), intent(in) :: newDataDims
    real(kind = dp), dimension(3), intent(in) :: newVoxSiz
    real(kind = dp), intent(in) :: theta
    real(kind = dp), dimension(2), intent(in) :: pivot
    
    !---Output variables
    real(kind = dp), dimension(:, :), intent(inout) :: ijk
    
    !---Local variables
    real(kind = dp), dimension(0:newDataDims(1) - 1, 0:newDataDims(1) - 1) :: x, y
    real(kind = dp), dimension(2) :: tmpxy
    real(kind = dp), dimension(2) :: tmpijk
    
    integer(kind = L) :: i, j, k, m
    real(kind = dp), dimension(2, 2) :: rot
    
    do i = 0_L, newDataDims(1) - 1_L
      x(i, :) = (i - real(newDataDims(1), kind = dp)/2.0_dp + 0.5_dp)*newVoxSiz(1)
    end do
    
    do j = 0_L, newDataDims(2) - 1_L
      y(:, j) = (j - real(newDataDims(2), kind = dp)/2.0_dp + 0.5_dp)*newVoxSiz(2)
    end do
    
    x = x - pivot(1)
    y = y - pivot(2)
    
    rot(1, 1) = cos(theta) ; rot(1, 2) = sin(theta)
    rot(2, 1) = -sin(theta); rot(2, 2) = cos(theta)
    
    do j = 0_L, newDataDims(1) - 1_L
      do i = 0_L, newDataDims(2) - 1_L
        
        m = i + j*newDataDims(1) + 1_L
        tmpxy = MatMul(rot, [x(i, j), y(i, j)])
        
        tmpijk = [(tmpxy(1) + pivot(1) - newVoxSiz(1)/2.0_dp)/orgVoxSiz(1), &
                  (tmpxy(2) + pivot(2) - newVoxSiz(2)/2.0_dp)/orgVoxSiz(2)] + orgDataDims(1:2)/2.0_dp 
        
        do k = 0_L, newDataDims(3) - 1
          ijk(m + k*newDataDims(1)*newDataDims(2), 1) = tmpijk(1) - 0.25_dp 
          ijk(m + k*newDataDims(1)*newDataDims(2), 2) = tmpijk(2) - 0.25_dp          
        end do
        
      end do
    end do
    
    do k = 1_L, newDataDims(3)
      m = (k - 1_L)*newDataDims(1)*newDataDims(2) + 1_L
      ijk(m : m + newDataDims(1)*newDataDims(3) - 1_L, 3) = ((k - 1_L) - &
        newDataDims(3)/2.0_dp)*newVoxSiz(3)/orgVoxSiz(3) + orgDataDims(3)/2.0_dp - 0.25_dp
    end do
  
  end subroutine Rotate2D


end module transformation

!================================================================================================================================

module interpolation

  use iso_fortran_env, only : dp => real64, L => int32
  
  implicit none
  
  private
  public :: Linear3D
  
  contains
  
  subroutine Linear3D(orgImg, ijk, newImg)
  
    !---Input variables
    real(kind = dp), dimension(:, :, :), intent(in) :: orgImg
    real(kind = dp), dimension(:, :), intent(in) :: ijk
    
    !---Output variables
    real(kind = dp), dimension(:, :, :), intent(inout) :: newImg
    
    !---Local variables
    integer(kind = L) :: nPts, i, ii, jj, kk
    real(kind = dp) :: c000, c001, c010, c100, c011, c110, c101, c111
    real(kind = dp) :: c00, c01, c10, c11
    real(kind = dp) :: c0, c1
    integer(kind = L) :: x0, x1, y0, y1, z0, z1
    real(kind = dp) :: xd, yd, zd
    integer(kind = L), dimension(3) :: mxSiz, orgDataDims, newDataDims
    
    nPts = Size(ijk, dim = 2)
    orgDataDims = [Size(orgImg, dim = 1), Size(orgImg, dim = 2), Size(orgImg, dim = 3)]
    newDataDims = [Size(newImg, dim = 1), Size(newImg, dim = 2), Size(newImg, dim = 3)]
    mxSiz = orgDataDims 
    
    !open(1, file = 'debug.txt')
    
    do i = 1_L, nPts
    
      x0 = Floor(ijk(1, i)) + 1_L
      x1 = Ceiling(ijk(1, i)) + 1_L
      y0 = Floor(ijk(2, i)) + 1_L
      y1 = Ceiling(ijk(2, i)) + 1_L
      z0 = Floor(ijk(3, i)) + 1_L
      z1 = Ceiling(ijk(3, i)) + 1_L
      
      xd = ijk(1, i) - x0  + 1.0_dp
      yd = ijk(2, i) - y0  + 1.0_dp
      zd = ijk(3, i) - z0  + 1.0_dp
      
      if ((x0 >= 1_L) .and. (y0 >= 1_L) .and. (z0 >= 1_L) .and. (x0 <= mxSiz(1)) .and. (y0 <= mxSiz(2)) .and. (z0 <= mxSiz(3))) then
        c000 = orgImg(x0, y0, z0)
      else
        c000 = 0.0_dp
      end if
      
      if ((x1 >= 1_L) .and. (y0 >= 1_L) .and. (z0 >= 1_L) .and. (x1 <= mxSiz(1)) .and. (y0 <= mxSiz(2)) .and. (z0 <= mxSiz(3))) then
        c100 = orgImg(x1, y0, z0)
      else
        c100 = 0.0_dp
      end if 
      
      if ((x0 >= 1_L) .and. (y1 >= 1_L) .and. (z0 >= 1_L) .and. (x0 <= mxSiz(1)) .and. (y1 <= mxSiz(2)) .and. (z0 <= mxSiz(3))) then
        c010 = orgImg(x0, y1, z0)
      else
        c010 = 0.0_dp
      end if
      
      if ((x0 >= 1_L) .and. (y0 >= 1_L) .and. (z1 >= 1_L) .and. (x0 <= mxSiz(1)) .and. (y0 <= mxSiz(2)) .and. (z1 <= mxSiz(3))) then
        c001 = orgImg(x0, y0, z1)
      else
        c001 = 0.0_dp
      end if
      
      if ((x1 >= 1_L) .and. (y1 >= 1_L) .and. (z0 >= 1_L) .and. (x1 <= mxSiz(1)) .and. (y1 <= mxSiz(2)) .and. (z0 <= mxSiz(3))) then
        c110 = orgImg(x1, y1, z0)
      else
        c110 = 0.0_dp
      end if
      
      if ((x1 >= 1_L) .and. (y0 >= 1_L) .and. (z1 >= 1_L) .and. (x1 <= mxSiz(1)) .and. (y0 <= mxSiz(2)) .and. (z1 <= mxSiz(3))) then
        c101 = orgImg(x1, y0, z1)
      else
        c101 = 0.0_dp
      end if
      
      if ((x0 >= 1_L) .and. (y1 >= 1_L) .and. (z1 >= 1_L) .and. (x0 <= mxSiz(1)) .and. (y1 <= mxSiz(2)) .and. (z1 <= mxSiz(3))) then
        c011 = orgImg(x0, y1, z1)
      else
        c011 = 0.0_dp
      end if
      
      if ((x1 >= 1_L) .and. (y1 >= 1_L) .and. (z1 >= 1_L) .and. (x1 <= mxSiz(1)) .and. (y1 <= mxSiz(2)) .and. (z1 <= mxSiz(3))) then
        c111 = orgImg(x1, y1, z1)
      else
        c111 = 0.0_dp
      end if
      
      c00 = c000*(1.0_dp - xd) + c100*xd
      c01 = c001*(1.0_dp - xd) + c101*xd
      c10 = c010*(1.0_dp - xd) + c110*xd
      c11 = c011*(1.0_dp - xd) + c111*xd
      
      c0 = c00*(1.0_dp - yd) + c10*yd
      c1 = c01*(1.0_dp - yd) + c11*yd
      
      ii = Mod(i - 1_L, newDataDims(1))
      jj = Mod(i - 1_L, newDataDims(1)*newDataDims(2))/newDataDims(1)
      kk = (i - 1_L)/(newDataDims(1)*newDataDims(2))
      
      newImg(ii + 1_L, jj + 1_L, kk + 1_L) = c0*(1.0_dp - zd) + c1*zd
      
    end do
  
    !close(1)
  
  end subroutine Linear3D

end module interpolation

