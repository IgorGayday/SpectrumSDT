!-----------------------------------------------------------------------
!  PESprint (pesprint.f)
!  Prints PES in APH and valence coordinates.
!  Author: Alexander Teplukhin
!-----------------------------------------------------------------------
program pesprint
  use config
  use input_params_mod
  use pes

  implicit none
  integer n1,n2,n3
  real*8 min1,max1,min2,max2,min3,max3
  real*8,allocatable::g1(:),g2(:),g3(:)
  integer iam,nprocs
  logical optgrid
  logical sdtcalc
  type(input_params) :: params

  call init_parameters(params)
  if(optgrid)then
    call load_optgrids
  else
    call load_equgrids
  endif
  call calc_pots(n1,n2,n3,g1,g2,g3,3)
  call blacs_pinfo(iam,nprocs)
  call blacs_setup(iam,nprocs)
  if(iam==0)then
    if(sdtcalc)then
      open(1,file='potvib.dat',form='unformatted')
      write(1)potvib
      close(1)

      if (params % print_potential == 1) then
        call prnt_potvib
        call prnt_pottot
      end if
    else
      call prnt_potvib
      call prnt_pottot
    endif
  endif
  call blacs_exit(0)

contains

!-----------------------------------------------------------------------
!  Loads parameters.
!-----------------------------------------------------------------------
  subroutine init_parameters(params)
    implicit none
    type(input_params), intent(inout) :: params

    inquire(file='grid1.dat',exist=optgrid)
    inquire(file='spectrumsdt.config',exist=sdtcalc)
    if(sdtcalc)then
      params = process_user_settings('spectrumsdt.config')
      call init_pots(params)
    else
      stop 'Error: spectrumsdt.config does not exist' 
    endif
  end subroutine

!-----------------------------------------------------------------------
!  Loads equidistant grids.
!-----------------------------------------------------------------------
  subroutine load_equgrids
    implicit none
    integer i1,i2,i3
    allocate(g1(n1),g2(n2),g3(n3))
    do i1=1,n1
      g1(i1) = min1 + (i1-1)*(max1-min1)/(n1-1)
    enddo
    do i2=1,n2
      g2(i2) = min2 + (i2-1)*(max2-min2)/(n2-1)
    enddo
    do i3=1,n3
      g3(i3) = min3 + (i3-1)*(max3-min3)/(n3-1)
    enddo
  end subroutine

!-----------------------------------------------------------------------
!  Loads optimized grids in APH coordinates.
!-----------------------------------------------------------------------
  subroutine load_optgrids
    implicit none
    integer i
    open(1,file='grid1.dat')
    read(1,*)n1
    allocate(g1(n1))
    do i=1,n1
      read(1,*)g1(i)
    enddo
    close(1)
    open(1,file='grid2.dat')
    read(1,*)n2
    allocate(g2(n2))
    do i=1,n2
      read(1,*)g2(i)
    enddo
    close(1)
    open(1,file='grid3.dat')
    read(1,*)n3
    allocate(g3(n3))
    do i=1,n3
      read(1,*)g3(i)
    enddo
    close(1)
  end subroutine
  
end program
