module overlaps_extra_base_mod
  use array_1d_mod
  use array_2d_mod
  use input_params_mod
  use iso_fortran_env, only: real64
  use k_block_info_mod
  use overlaps_mod
  use parallel_utils_mod
  use path_utils_mod
  use spectrumsdt_io_mod
  use spectrumsdt_utils_mod
  implicit none

contains

!-------------------------------------------------------------------------------------------------------------------------------------------
! Checks that all required files exist.
!-------------------------------------------------------------------------------------------------------------------------------------------
  subroutine check_prerequisites(params)
    type(input_params), intent(in) :: params
    logical :: file_exists
    character(:), allocatable :: block_info_path

    block_info_path = get_block_info_path(get_sym_path_root(params % root_path, params % K(1), params % basis % symmetry))
    inquire(file = block_info_path, exist = file_exists)
    call assert(file_exists, 'Error: basis is not computed')

    ! the other symmetry is also required in this mode
    if (params % basis % fixed % enabled == 1) then
      block_info_path = get_block_info_path(get_sym_path_root(params % root_path, params % K(1), 1 - params % basis % symmetry))
      inquire(file = block_info_path, exist = file_exists)
      call assert(file_exists, 'Error: basis of both symmetries has to be computed in fixed basis mode')
    end if
  end subroutine

end module