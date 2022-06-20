#!/bin/bash
#SBATCH --job-name=bumpy_test
#SBATCH --output=bumpy_test_%j.out
#SBATCH --nodes=5
#SBATCH --ntasks-per-node=40
#SBATCH --mem=32GB
#SBATCH --partition=compute
# Load the default OpenMPI module.
# Load the default OpenMPI module.
echo "SLURM_JOBID="$SLURM_JOBID
echo "SLURM_JOB_NODELIST"=$SLURM_JOB_NODELIST
echo "SLURM_NNODES"=$SLURM_NNODES
echo "SLURMTMPDIR="$SLURMTMPDIR
echo "Date              = $(date)"
echo "Hostname          = $(hostname -s)"
echo ""
echo "Number of Nodes Allocated      = $SLURM_JOB_NUM_NODES"
echo "Number of Tasks Allocated      = $SLURM_NTASKS"
echo "Number of Cores/Task Allocated = $SLURM_CPUS_PER_TASK"
echo "Working Directory = $(pwd)"
echo "working directory = "$SLURM_SUBMIT_DIR

# Run the hellompi program with mpirun. The -n flag is not required;
# mpirun will automatically figure out the best configuration from the
# Slurm environment variables.
source /lustre/oneApi/setvars.sh intel64 --force
export PATH=/lustre/apps/gromacs-intel/2020.6/bin:$PATH
export LD_LIBRARY_PATH=/lustre/apps/gromacs-intel/2020.6/lib64:$LD_LIBRARY_PATH

# generate a system and try to grompp it with topology and index
folder="dummy_test_files"

rm $folder/*.tpr $folder/*.gro $folder/test*

python3 bumpy.py -f $folder/flat_input.pdb -s sphere -z 10.5 -o $folder/test_start.pdb -p $folder/test_start.top -n $folder/test_start.ndx   --dummy_grid_thickness 50 -g r_sphere:100   --gen_dummy_particles

echo '#include "toppar/martini_v2.0_ions.itp"' | cat - $folder/test_start.top > temp && mv temp $folder/test_start.top
echo '#include "toppar/martini_v2.0_lipids_all_201506.itp"' | cat - $folder/test_start.top > temp && mv temp $folder/test_start.top
echo '#include "martini_dummy.itp"'              | cat - $folder/test_start.top > temp && mv temp $folder/test_start.top


mpiexec.hydra -n 40 --ppn 200  gmx_impi_s grompp -f $folder/step6.0_equilibration.mdp -p $folder/test_start.top -n $folder/test_start.ndx -c $folder/test_start.pdb -o $folder/test_minimization.tpr
mpiexec.hydra -n 40 --ppn 200  gmx_impi_s mdrun -deffnm $folder/test_minimization #-nsteps 40 -v
mpiexec.hydra -n 40 --ppn 200  gmx_impi_s grompp -f $folder/step7_production.mdp -p $folder/test_start.top -n $folder/test_start.ndx -c $folder/test_minimization.gro -o $folder/test_grompp_production.tpr



if [ $? -eq 0 ]; then
	echo 'Success'
else
	echo 'Failure :('
fi

rm $folder/*#              # #*# mdout.mdp 

exit
