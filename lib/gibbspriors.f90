module GibbsPriors
  
  use iso_fortran_env, only : dp => real64, L => int32, S => int16
  implicit none

  private
  public RDPprior  
  
  contains

  function RDPprior(src, gamma, wts, regions) result(dUdf)
  
    !---Input variables----------------------------
    real(kind = dp), dimension(0:, 0:, 0:), intent(in) :: src
    real(kind = dp), intent(in) :: gamma
    real(kind = dp), dimension(0:, 0:, 0:), intent(in), optional :: wts
    integer(kind = S), dimension(0:, 0:, 0:), intent(in), optional :: regions
    
    !---Output------------------------------------
    real(kind = dp), dimension(0:Size(src, dim = 1) - 1_L, 0:Size(src, dim = 2)- 1_L, 0:Size(src, dim = 3) - 1_L) :: dUdf
    
    
    !---Local variables---------------------------
    integer(kind = L) :: i, j, k, p, q, r
    integer(kind = L), dimension(3) :: srcDims, wtsDims, off
    real(kind = dp) :: fi, fk, cnt
    integer(kind = S) :: thisReg, ii
    
    srcDims = [Size(src, dim = 1), Size(src, dim = 2), Size(src, dim = 3)]
    dUdf = 0.0_dp
    
   ! open(1, file = 'C:\Users\johan\pollux\idl\debug.txt')
    
    if (Present(wts) .and. .not. Present(regions)) then
      
      wtsDims = [Size(wts, dim = 1), Size(wts, dim = 2), Size(wts, dim = 3)]
      off = wtsDims/2_L
      do k = 0_L, srcDims(3) - 1_L
        do j = 0_L, srcDims(2) - 1_L 
          do i = 0_L, srcDims(1) - 1_L
          
            fk = src(i, j, k)
                 
            do r = 0_L, wtsDims(3) - 1_L
              
              if (((k + r - off(3)) < 0_L) .or. ((k + r - off(3)) >= srcDims(3))) cycle
              
              do q = 0_L, wtsDims(2) - 1_L
                
                if (((j + q - off(2)) < 0_L) .or. ((j + q - off(2)) >= srcDims(2))) cycle
                
                do p = 0_L, wtsDims(1) - 1_L
                  
                  if (((i + p - off(1)) < 0_L) .or. ((i + p - off(1)) >= srcDims(1))) cycle
                  
                  fi = src(i + p - off(1), j + q - off(2), k + r - off(3))
                  !write(1, *), i, j, k, i + p - off(1), j + q - off(2), k + r - off(3)
                  if ((fi - fk) == 0.0_dp) cycle
                  if (((fi + fk + gamma*abs(fi - fk))**2) == 0.0_dp) cycle
                  
                  dUdf(i, j, k) = dUdf(i, j, k) - wts(p, q, r)*(2.0_dp*(fi - fk)*(fi + fk + gamma*abs(fi - fk)) + &
                    (fi - fk)**2*(1.0_dp - gamma*sign(fi - fk, 1.0_dp)))/(fi + fk + gamma*abs(fi - fk))**2
                  dUdf(i + p - off(1), j + q - off(2), k + r - off(3)) = dUdf(i + p - off(1), j + q - off(2), k + r - off(3)) + &
                    wts(p, q, r)*(2.0_dp*(fi - fk)*(fi + fk + gamma*abs(fi - fk)) - (fi - fk)**2* &
                    (1.0_dp + gamma*sign(fi - fk, 1.0_dp)))/(fi + fk + gamma*abs(fi - fk))**2
                end do
              end do
            end do
          
          end do
        end do
      end do
    
    else if ((.not. Present(wts)) .and. Present(regions)) then 
    
      do k = 0_L, srcDims(3) - 1_L
        do j = 1_L, srcDims(2) - 1_L
          do i = 1_L, srcDims(1) - 1_L
            
            thisReg = regions(i, j, k)
            if (thisReg == 0_S) cycle
            
            fk = src(i, j, k)
            
            do r = 0_L, srcDims(3) - 1_L
              do q = 0_L, srcDims(2) - 1_L
                do p = 0_L, srcDims(1) - 1_L
                  
                  if (regions(p, q, r) /= thisReg) cycle
                  
                  fi = src(p, q, r)               
                  if ((fi == fk) .or. ((fi + fk + gamma*abs(fi - fk))**2 == 0.0_dp)) cycle
                  
                  dUdf(i, j, k) = dUdf(i, j, k) - (2.0_dp*(fi - fk)*(fi + fk + gamma*abs(fi - fk)) + &
                    (fi - fk)**2*(1.0_dp - gamma*sign(fi - fk, 1.0_dp)))/(fi + fk + gamma*abs(fi - fk))**2
                  dUdf(p, q, r) = dUdf(p, q, r) + (2.0_dp*(fi - fk)*(fi + fk + gamma*abs(fi - fk)) - (fi - fk)**2* &
                    (1.0_dp + gamma*sign(fi - fk, 1.0_dp)))/(fi + fk + gamma*abs(fi - fk))**2
                  
                end do
              end do
            end do 

          end do
        end do
      end do
      
      do ii = 1_S, MaxVal(regions)
        
        cnt = Count(regions == ii)
        if (cnt == 0.0_dp) cycle
        
        where(regions == ii)
        
          dUdf = dUdf/cnt
        
        end where
      
      end do
          
    end if
    
    !close(1)
    
  end function RDPprior


end module GibbsPriors