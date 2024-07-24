#!/bin/bash -l
#SBATCH --job-name=0.7_MIN
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lherold@mpa-garching.mpg.de
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=5  
#SBATCH --time=24:00:00
#SBATCH -N 1
#SBATCH -p p.24h
#SBATCH --output=/u/lherold/Pk/MontePython/log/2024_07_02_PL_PlanckLite_LCDM_h_MIN_0.7.log

#### Needs to be adapted by the system
# Source Planck clik likelihood
source /u/lherold/Pk/MontePython/data/Planck2018/code/plc_3.0/plc-3.01/bin/clik_profile.sh
# Load modules
module load intel/19.0.4
module load impi/2019.4
module load anaconda/3/2019.03
# Some cluster-specific settings
export PYTHONUNBUFFERED=true
export OMP_NUM_THREAD="5"
export OMP_THREAD_LIMIT="5"

##### No changes needed from here on (bash script edits the following parameters)

# Paramters
MODE=MIN
OUT=/freya/ptmp/mpa/lherold/2024_07_02_PL_PlanckLite_LCDM_h_MIN_0.7
BF=/u/lherold/Pk/MontePython/chains_LCDMext/Final_MCMCs/2024_06_21_MCMC_LCDM_Planck+BAO/2024_06_21_MCMC_LCDM_Planck+BAO.bestfit
BF2=/freya/ptmp/mpa/lherold/2024_07_02_PL_PlanckLite_LCDM_h_MIN_0.7/2024_07_02_PL_PlanckLite_LCDM_h_MIN_0.7.bestfit
COV=/u/lherold/Pk/MontePython/chains_LCDMext/Final_MCMCs/2024_06_21_MCMC_LCDM_Planck+BAO/2024_06_21_MCMC_LCDM_Planck+BAO.covmat
PARAM=/u/lherold/Pk/MontePython/montepython/input/2024_Wilks_test/PL_PlanckLite_LCDM_h_0.7.param
N=1000000
RE_RUN=False
RESTART=/freya/ptmp/mpa/lherold/2023_12_03_PL_PlanckBAO_Omega_k_MCMC_0.000/2023-12-03_100000__1.txt
MP=


###################################################                                                                                            
#                     MCMC                        #
################################################### 


if [ "$MODE" = MCMC ] || ["$MODE" = 1]; then
    if [ "$RE_RUN" = True ]; then
	# Run with restart
	srun python $MP run -p $PARAM -N $N -j fast --restart $RESTART
    else
	if [[ $BF_COV == None* ]]; then
	    echo "No covariance and bestfit given."
	    # Run to initialize
	    srun python $MP run -p $PARAM -o $OUT -N 5 -f 1.0 -j fast
	    # Run N times
	    srun python $MP run -p $PARAM -o $OUT -N $N -f 1.0  -j fast
	else
	    # Run to initialize
	    srun python $MP run -p $PARAM -o $OUT -N 5 -f 1.0 -j fast -c $COV -b $BF
	    # Run N times
	    srun python $MP run -p $PARAM -o $OUT -N $N -f 1.0  -j fast -c $COV -b $BF 
	fi
    fi
    exit
fi


################################################### 
#     Simulated annealing-like minimization       #
###################################################  


srun python $MP -p $PARAM -o $OUT --bestfit $BF --covmat $COV -N 5000 -f 0.5 -T 0.1
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV -N 5001 -f 0.1 -T 0.005
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV -N 5002 -f 0.05 -T 0.001
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV -N 1003 -f 0.03 -T 0.0005
python $MP info $OUT --minimal
