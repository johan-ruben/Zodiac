subroutine Linear3D_wrapper(argc, argv)

  use iso_fortran_env, only : LL => int64
  
  !DEC$ ATTRIBUTES DLLEXPORT :: Linear3D_wrapper
    
  implicit none
  
  !GCC$ ATTRIBUTES DLLEXPORT :: Linear3D_wrapper
  
  integer(kind = LL) :: argc
  integer(kind = LL), dimension(*) :: argv
  
  call Linear3D_InternalWrapper(%val(argv(1)), %val(argv(2)), %val(argv(3)), %val(argv(4)), %val(argv(5)), %val(argv(6)), &
    %val(argv(7)), %val(argv(8)), %val(argv(9)), %val(argv(10)))

end subroutine Linear3D_wrapper

!=========================================================================

subroutine AttenuateESS_wrapper(argc, argv)

  use iso_fortran_env, only : LL => int64
  
  !DEC$ ATTRIBUTES DLLEXPORT :: AttenuateESS_wrapper
  
  implicit none

  integer(kind = LL) :: argc
  integer(kind = LL), dimension(*) :: argv
  
  call AttenuateESS_InternalWrapper(%val(argv(1)), %val(argv(2)), %val(argv(3)), %val(argv(4)), %val(argv(5)), %val(argv(6)), &
    %val(argv(7)), %val(argv(8)), %val(argv(9)), %val(argv(10)))
   
end subroutine AttenuateESS_wrapper

!==========================================================================
  
subroutine RDprior_wrapper(argc, argv)

  use iso_fortran_env, only : LL => int64
  
  !DEC$ ATTRIBUTES DLLEXPORT :: RDprior_wrapper
  
  implicit none
  
  integer(kind = LL) :: argc
  integer(kind = LL), dimension(*) :: argv
  
  call RDprior_InternalWrapper(%val(argv(1)), %val(argv(2)), %val(argv(3)), %val(argv(4)), %val(argv(5)), %val(argv(6)), &
    %val(argv(7)), %val(argv(8)), %val(argv(9)), %val(argv(10)))
  
end subroutine RDprior_wrapper

!==========================================================================
  
subroutine RDpriorRegions_wrapper(argc, argv)

  use iso_fortran_env, only : LL => int64
  
  !DEC$ ATTRIBUTES DLLEXPORT :: RDpriorRegions_wrapper
  
  implicit none
  
  integer(kind = LL) :: argc
  integer(kind = LL), dimension(*) :: argv
  
  call RDpriorRegions_InternalWrapper(%val(argv(1)), %val(argv(2)), %val(argv(3)), %val(argv(4)), %val(argv(5)))
  
end subroutine RDpriorRegions_wrapper

!==========================================================================
  
subroutine QuadraticPrior_wrapper(argc, argv)

  use iso_fortran_env, only : LL => int64
  
  !DEC$ ATTRIBUTES DLLEXPORT :: QuadraticPrior_wrapper
  
  implicit none
  
  integer(kind = LL) :: argc
  integer(kind = LL), dimension(*) :: argv
  
  call QuadraticPrior_InternalWrapper(%val(argv(1)), %val(argv(2)), %val(argv(3)), %val(argv(4)), %val(argv(5)), %val(argv(6)), &
    %val(argv(7)), %val(argv(8)), %val(argv(9)))
  
end subroutine QuadraticPrior_wrapper

!==========================================================================

subroutine RDPprior_wrapper(argc, argv)

  use iso_fortran_env, only : LL => int64
  
  !DEC$ ATTRIBUTES DLLEXPORT :: RDPprior_wrapper
  
  implicit none
  
  integer(kind = LL) :: argc
  integer(kind = LL), dimension(*) :: argv
  
  call RDPprior_InternalWrapper(%val(argv(1)), %val(argv(2)), %val(argv(3)), %val(argv(4)), %val(argv(5)), %val(argv(6)), &
    %val(argv(7)), %val(argv(8)), %val(argv(9)), %val(argv(10)))
  
  
end subroutine RDPprior_wrapper

subroutine score_wrapper(argc, argv)

  use iso_fortran_env, only : LL => int64
    
  implicit none
  
  !GCC$ ATTRIBUTES DLLEXPORT :: score_wrapper
  
  integer(kind = LL) :: argc
  integer(kind = LL), dimension(*) :: argv
  
  call score_InternalWrapper(%val(argv(1)), %val(argv(2)), %val(argv(3)), %val(argv(4)), %val(argv(5)), %val(argv(6)), &
    %val(argv(7)))
  
end subroutine score_wrapper