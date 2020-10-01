module input_params_mod
  use iso_fortran_env, only: real64
  implicit none

  type :: input_params
    ! Behavior control
    character(:), allocatable :: stage ! basis, overlaps, eigencalc or properties
    integer :: rovib_coupling ! enables/disables rovib_coupling coupling. 0 or 1
    integer :: fix_basis_jk ! use basis set with the same fixed values of J and K for all calculations

    ! Grids
    real(real64) :: grid_rho_from
    real(real64) :: grid_rho_to
    integer :: grid_rho_npoints

    real(real64) :: grid_theta_from
    real(real64) :: grid_theta_to
    integer :: grid_theta_npoints

    real(real64) :: grid_phi_from
    real(real64) :: grid_phi_to
    integer :: grid_phi_npoints

    ! System
    character(:), allocatable :: molecule ! isotope composition, like 686
    integer :: J ! Total angular momentum quantum number
    integer :: K(2) ! Boundaries of K-range for rovib_coupling calculation. In symmetric top rotor both values should be the same
    integer :: parity ! 0(+) or 1(-)
    integer :: symmetry ! 0 (even, cos, +) or 1 (odd, sin, -). In case of coupled hamiltonian means symmetry of K=0, even when K=0 is not included.

    ! Basis
    integer :: basis_size_phi ! number of sines or cosines for 1D step
    real(real64) :: cutoff_energy ! solutions with energies higher than this are discarded from basis
    character(:), allocatable :: basis_root_path ! path to root folder for basis calculations
    integer :: basis_J ! J and K of basis set
    integer :: basis_K

    ! Eigencalc
    integer :: num_states ! desired number of eigenstates from eigencalc
    integer :: ncv ! number of vectors in arnoldi basis during eigencalc
    integer :: mpd ! maximum projected dimension, slepc only
    integer :: max_iterations ! maximum number of iterations during eigencalc
    
    ! CAP
    character(:), allocatable :: cap_type
    
    ! Paths
    character(:), allocatable :: grid_path ! path to folder with grid calculations
    character(:), allocatable :: root_path ! path to root folder for main calculations
    character(:), allocatable :: channels_root ! path to folder with channels data

    ! Debug
    integer :: sequential ! triggers sequential execution
    integer :: enable_terms(2) ! 1st digit - coriolis, 2nd - asymmetric
    integer :: optimized_mult ! disables matrix-vector multiplication optimizations
    character(:), allocatable :: debug_mode
    character(:), allocatable :: test_mode
    character(:), allocatable :: debug_param_1
  end type
end module