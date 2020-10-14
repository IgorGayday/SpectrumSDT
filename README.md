A parallel Fortran program for calculation of ro-vibrational energy levels and lifetimes of 3-atomic systems in hyperspherical (APH) coordiantes.

# Building

0. Prerequisites
    1. Make sure the following packages are installed: `build-essential`, `python3-dev`, `cmake`, `gfortran`, `mpich`, `libblas-dev`, `liblapack-dev`.  
    Tested with `gfortran 9.3.0` and `mpich 3.3.2`.
    2. Make sure you machine has at least 2GB of RAM (for compilation)

1. Clone the repo
`git clone https://github.com/IgorGayday/SpectrumSDT`  
This example assumes the repo is cloned into `~/SpectrumSDT`

2. Build the libraries

    1. fdict
    ```
    cd ~/SpectrumSDT/libs/fdict
    make
    ```

    2. FTL
    ```
    cd ~/SpectrumSDT/libs/ftl
    make
    PREFIX=build make install
    ```

    3. PETSc
    ```
    cd ~/SpectrumSDT/libs/petsc
    export PETSC_DIR=$PWD
    export PETSC_ARCH=debug_64
    ./configure --with-scalar-type=complex --with-64-bit-indices
    make all
    ```

    4. SLEPc
    ```
    cd ~/SpectrumSDT/libs/slepc
    export SLEPC_DIR=$PWD
    ./configure
    make all
    ```

3. Build the main program  
`cd ~/SpectrumSDT`

    1. Specify custom compiler options (optional)  
    Default compiler options are specified in `compiler_options_default.cmake`.  
    You can create a file named `compiler_options.cmake` to specify your custom compile options instead of the default ones.  
    A few presets for different compilers can be found in the `compiler_options_alternative` folder.

    2. Build the executable  
    Note: do not move the executable to another folder since some paths are resolved relative to its location.  
    ```
    mkdir build && cd build
    cmake ..
    make spectrumsdt
    ```

# A basic example of running (ozone)

1. Generate the grids
```
mkdir ~/SpectrumSDT_runs && cd ~/SpectrumSDT_runs
cp ~/SpectrumSDT/config_examples/grids.config spectrumsdt.config
~/SpectrumSDT/build/spectrumsdt
```
After this, `pes.in` file should be generated. This file specifies a total number of points and a list of APH coordinates where the value of electronic potential is required.
Before proceeding to the next stage, user should provide file `pes.out` with the values of potential at the requested coordinates in atomic units of energy (Hartree).

2. Calculate the values of PES. Here we will use an example program that reads `pes.in` and uses the PES of ozone calculated by Dawes et al. to generate `pes.out`. First, compile the program:
```
cd ~/SpectrumSDT/PES/ozone/
mkdir build && cd build
bash ../compile_pesprint.sh
```
Now run:
```
cd ~/SpectrumSDT_runs
mpiexec -n <n_procs> ~/SpectrumSDT/PES/ozone/build/pesprint 686
```
Replace `<n_procs>` with however many MPI tasks you want to use. After this, `pes.out` is generated and we can proceed to the main calculations.

3. Setup SpectrumSDT directory structure
```
mkdir J_0 && cd J_0
cp ~/SpectrumSDT/config_examples/spectrumsdt.config .
```
Edit spectrumsdt.config and replace `username` in the paths. Then execute:  
`~/SpectrumSDT/scripts/init_spectrum_folders.py -K 0`

4. Calculate basis
```
cd K_0/even/basis
mpiexec -n <n_procs> spectrumsdt
```
Here `<n_procs>` has to be equal to the number of points in `~/SpectrumSDT_runs/grid_rho.dat` (16 in this example).  
In `use_fix_basis_jk = 1` mode (enabled in this example), basis of the other symmetry has to be computed as well.  
```
cd ../../odd/basis
mpiexec -n 16 spectrumsdt
```

5. Calculate basis cross terms (overlaps)
```
cd ../../even/overlaps
mpiexec -n <n_procs> spectrumsdt
```

6. Calculate eigenpairs
```
cd ../eigencalc
mpiexec -n <n_procs> spectrumsdt
```
Lowest 50 rovibrational energy levels of ozone-686 J=0 will be printed into `states.fwc` file.
