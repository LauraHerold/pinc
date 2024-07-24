#!/bin/bash -l
#SBATCH --job-name=0.16_MIN
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lherold@mpa-garching.mpg.de
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=5  
#SBATCH --time=24:00:00
#SBATCH -N 1
#SBATCH -p p.24h
#SBATCH --output=/u/lherold/Pk/MontePython/log/2024_07_24_PL_Planck_mncdm_deg_MIN_0.16.log

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
PARAM=/u/lherold/Pk/MontePython/montepython/input/2024_Wilks_test/2024_07_24_PL_Planck_mncdm_deg_0.16.param
OUT=/freya/ptmp/mpa/lherold/2024_07_24_PL_Planck_mncdm_deg_0.16
BF=/freya/ptmp/mpa/lherold/2024_07_23_MCMC_Planck_Mnu_deg/2024_07_23_MCMC_Planck_Mnu_deg.bestfit
BF2=/freya/ptmp/mpa/lherold/2024_07_24_PL_Planck_mncdm_deg/2024_07_24_PL_Planck_mncdm_deg.bestfit
COV=/freya/ptmp/mpa/lherold/2024_07_23_MCMC_Planck_Mnu_deg/2024_07_23_MCMC_Planck_Mnu_deg.covmat
MP=/u/lherold/Pk/MontePython/montepython/MontePython.py
CONF=/u/lherold/Pk/MontePython/default.conf
N=
RE_RUN=
RESTART=


###################################################                                                                                            
#                     MCMC                        #
################################################### 


if [ "$MODE" = MCMC ] || ["$MODE" = 1]; then
    if [ "$RE_RUN" = True ]; then
	# Run with restart
	srun python $MP run -p $PARAM --conf $CONF -N $N -j fast --restart $RESTART
    else
	if [[ $BF_COV == None* ]]; then
	    echo "No covariance and bestfit given."
	    # Run to initialize
	    srun python $MP run -p $PARAM -o $OUT --conf $CONF -N 5 -f 1.0 -j fast
	    # Run N times
	    srun python $MP run -p $PARAM -o $OUT --conf $CONF -N $N -f 1.0  -j fast
	else
	    # Run to initialize
	    srun python $MP run -p $PARAM -o $OUT --conf $CONF -N 5 -f 1.0 -j fast -c $COV -b $BF
	    # Run N times
	    srun python $MP run -p $PARAM -o $OUT --conf $CONF -N $N -f 1.0  -j fast -c $COV -b $BF 
	fi
    fi
    exit
fi


################################################### 
#     Simulated annealing-like minimization       #
###################################################  


srun python $MP -p $PARAM -o $OUT --bestfit $BF --covmat $COV --conf $CONF -N 5000 -f 0.5 -T 0.1
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV --conf $CONF -N 5001 -f 0.1 -T 0.005
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV --conf $CONF -N 5002 -f 0.05 -T 0.001
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV --conf $CONF -N 1003 -f 0.03 -T 0.0005
python $MP info $OUT --minimal
