module Gibbs

  use iso_fortran_env, only : dp => real64, L => int32, S => int16
  implicit none

  private
  public RDprior, RDpriorRegions, QuadraticPrior  
  
  contains
  
  function RDPderivative(img, q, gamma, wts) result(dUdfj)
    
    !---Input arguments-------
    real(kind = dp), dimension(0:, 0:, 0:), intent(in) :: img, wts
    integer(kind = L), intent(in) :: q
    real(kind = dp), intent(in) :: gamma
    
    !---Output arguments------
    real(kind = dp) :: dUdfj
    
    !---Local variables-------
    integer(kind = L) :: i, j, k, ii, jj, kk
    real(kind = dp) :: fj, fq, denom, w
    integer(kind = L), dimension(0:2) :: dataDims, wtsDims
    
    dataDims = [size(img, dim = 1), size(img, dim = 2), size(img, dim = 3)]
    wtsDims = [size(wts, dim = 1), size(wts, dim = 2), size(wts, dim = 3)]
    
    i = mod(q, dataDims(0))
    j = mod(q, dataDims(0)*dataDims(1))/dataDims(0)
    k = q/(dataDims(0)*dataDims(1))
    
    fj = img(i, j, k)
    dUdfj = 0.0_dp
    
    do kk = k - wtsDims(2)/2, k + wtsDims(2)/2
      if ((kk < 0_L) .or. (kk >= dataDims(2))) cycle
      do jj = j - wtsDims(1)/2, j + wtsDims(1)/2
        if ((jj < 0_L) .or. (jj >= dataDims(1))) cycle
        do ii = i - wtsDims(0)/2, i + wtsDims(0)/2
          if ((ii < 0_L) .or. (ii >= dataDims(0))) cycle
          fq = img(ii, jj, kk)
          if ((fj - fq) == 0.0_dp) cycle
          denom = ((fj + fq) + gamma*abs(fj - fq))**2
          if (denom == 0.0_dp) cycle
          w = wts(ii - i + wtsDims(0)/2, jj - j + wtsDims(1)/2, kk - k + wtsDims(2)/2)
          dUdfj = dUdfj + w*(2.0_dp*(fj - fq)*((fj + fq) + gamma*abs(fj - fq)) - &
            (fj - fq)**2*(1.0_dp + gamma*sign(1.0_dp, fj - fq)))/denom  
        end do
      end do
    end do
  
    do kk = k - wtsDims(2)/2, k + wtsDims(2)/2
      if ((kk < 0_L) .or. (kk >= dataDims(2))) cycle
      do jj = j - wtsDims(1)/2, j + wtsDims(1)/2
        if ((jj < 0_L) .or. (jj >= dataDims(1))) cycle
        do ii = i - wtsDims(0)/2, i + wtsDims(0)/2
          if ((ii < 0_L) .or. (ii >= dataDims(0))) cycle
          fq = img(ii, jj, kk)
          if ((fj - fq) == 0.0_dp) cycle
          denom = ((fq + fj) + gamma*abs(fq - fj))**2
          if (denom == 0.0_dp) cycle
          w = wts(ii - i + wtsDims(0)/2, jj - j + wtsDims(1)/2, kk - k + wtsDims(2)/2)
          dUdfj = dUdfj + w*(-2.0_dp*(fq - fj)*((fq + fj) + gamma*abs(fq - fj)) - &
            (fq - fj)**2*(1.0_dp - gamma*sign(1.0_dp, fq - fj)))/denom  
        end do
      end do
    end do
  
  end function RDPderivative
  
  !===================================================================================
  
  subroutine RDprior(img, gamma, wts, dUdfj)
  
    !---Input arguments-------
    real(kind = dp), dimension(0:, 0:, 0:), intent(in) :: img, wts
    real(kind = dp), intent(in) :: gamma
    
    !---Output arguments------
    real(kind = dp), dimension(0:), intent(inout) :: dUdfj
    
    !---Local parameters---
    integer(kind = L) :: j, n
    
    n = size(img)
    dUdfj = 0.0_dp
    
    do j = 0_L, n - 1_L
      dUdfj(j) = RDPderivative(img, j, gamma, wts)
    end do
     
  end subroutine RDprior
  
  !============================================================
  
  function RDPderivativeRegions(img, q, regions, lbl, gamma) result(dUdfj)
  
    !---Input arguments--------------------
    real(kind = dp), dimension(0:), intent(in) :: img
    integer(kind = L), intent(in) :: q
    integer(kind = S), dimension(0:), intent(in) :: regions
    integer(kind = S), intent(in) :: lbl
    real(kind = dp), intent(in) :: gamma
    
    !---Output arguments--------------------
    real(kind = dp) :: dUdfj
    
    !---Local variables---------------------
    real(kind = dp) :: fj, fq, w, denom
    integer(kind = L) :: n, i, k
    
    fj = img(q)
    n = size(img)
    
    dUdfj = 0.0_dp
    k = 0_L
    
    do i = 0_L, n - 1_L
    
      if (regions(i) /= lbl) cycle
      
      k = k + 1_L
      fq = img(i)
      
      if ((fj - fq) == 0.0_dp) cycle
      denom = ((fj + fq) + gamma*abs(fj - fq))**2
      if (denom == 0.0_dp) cycle
      dUdfj = dUdfj + (2.0_dp*(fj - fq)*((fj + fq) + gamma*abs(fj - fq)) - &
        (fj - fq)**2*(1.0_dp + gamma*sign(1.0_dp, fj - fq)))/denom

    end do
  
    do i = 0_L, n - 1_L
    
      if (regions(i) /= lbl) cycle
      
      fq = img(i)
      
      if ((fj - fq) == 0.0_dp) cycle
      denom = ((fq + fj) + gamma*abs(fq - fj))**2
      if (denom == 0.0_dp) cycle
      dUdfj = dUdfj + (-2.0_dp*(fq - fj)*((fq + fj) + gamma*abs(fq - fj)) - &
        (fq - fj)**2*(1.0_dp - gamma*sign(1.0_dp, fq - fj)))/denom
    
    end do
    
    w = 1.0_dp/real(k - 1_L, kind = dp)
    
    dUdfj = dUdfj*w
    
  end function RDPderivativeRegions
  
  !============================================================
  
  subroutine RDpriorRegions(img, regions, gamma, dUdfj)
  
    !---Input arguments--------------------
    real(kind = dp), dimension(0:), intent(in) :: img
    integer(kind = S), dimension(0:), intent(in) :: regions
    real(kind = dp), intent(in) :: gamma
    
    !---Output arguments-------------------
    real(kind = dp), dimension(0:), intent(inout) :: dUdfj
    
    !---Local variables--------------------
    integer(kind = L) :: n, i 
    integer(kind = S) :: lb
      
    n = size(img)
    dUdfj = 0.0_dp
    
    !open(unit = 1, action = 'write', file = 'C:\users\johan\lu177_pollux\debug.txt')
    
    do i = 0_L, n - 1
    
      if (regions(i) == 0_S) cycle     
      lb = regions(i)
      
      dUdfj(i) = RDPderivativeRegions(img, i, regions, lb, gamma)
       
    end do
    !close(1)
  end subroutine RDpriorRegions
  
  !=================================================================
  
  function QuadraticPriorDerivative(img, q, wts) result(dUdfj)
  
    !---Input variables---
    real(kind = dp), dimension(0:, 0:, 0:), intent(in) :: img, wts
    integer(kind = L), intent(in) :: q
  
    !---Output variables---
    real(kind = dp) :: dUdfj
    
    !---Local variables---
    integer(kind = L) :: i, j, k, ii, jj, kk
    integer(kind = L), dimension(0:2) :: dataDims, wtsDims
    real(kind = dp) :: fq, fj, w
    
    dataDims = [size(img, dim = 1), size(img, dim = 2), size(img, dim = 3)]
    wtsDims = [size(wts, dim = 1), size(wts, dim = 2), size(wts, dim = 3)]
    
    i = mod(q, dataDims(0))
    j = mod(q, dataDims(0)*dataDims(1))/dataDims(0)
    k = q/(dataDims(0)*dataDims(1))
    
    fj = img(i, j, k)
    dUdfj = 0.0_dp
    
    do kk = k - wtsDims(2)/2, k + wtsDims(2)/2
      if ((kk < 0_L) .or. (kk >= dataDims(2))) cycle
      do jj = j - wtsDims(1)/2, j + wtsDims(1)/2
        if ((jj < 0_L) .or. (jj >= dataDims(1))) cycle
        do ii = i - wtsDims(0)/2, i + wtsDims(0)/2
          if ((ii < 0_L) .or. (ii >= dataDims(0))) cycle
          fq = img(ii, jj, kk)
          w = wts(ii - i + wtsDims(0)/2, jj - j + wtsDims(1)/2, kk - k + wtsDims(2)/2)
          dUdfj = dUdfj + w*(fj - fq) 
        end do
      end do
    end do
  
    do kk = k - wtsDims(2)/2, k + wtsDims(2)/2
      if ((kk < 0_L) .or. (kk >= dataDims(2))) cycle
      do jj = j - wtsDims(1)/2, j + wtsDims(1)/2
        if ((jj < 0_L) .or. (jj >= dataDims(1))) cycle
        do ii = i - wtsDims(0)/2, i + wtsDims(0)/2
          if ((ii < 0_L) .or. (ii >= dataDims(0))) cycle
          fq = img(ii, jj, kk)
          w = wts(ii - i + wtsDims(0)/2, jj - j + wtsDims(1)/2, kk - k + wtsDims(2)/2)
          dUdfj = dUdfj - w*(fq - fj)  
        end do
      end do
    end do
     
  end function QuadraticPriorDerivative
  
  !=================================================================
  
  subroutine QuadraticPrior(img, wts, dUdfj)
    
    !---Input parameters---
    real(kind = dp), dimension(0:, 0:, 0:), intent(in) :: img, wts
    
    !---Output parameters---
    real(kind = dp), dimension(0:), intent(inout) :: dUdfj
    
    !---Local variables-----
    integer(kind = L) :: n, j
    
    n = size(img)
    dUdfj = 0.0_dp
    
    do j = 0_L, n - 1_L
    
      dUdfj(j) = QuadraticPriorDerivative(img, j, wts)
    
    end do
  
  end subroutine QuadraticPrior
  
  
end module Gibbs