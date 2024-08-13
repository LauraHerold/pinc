#!/bin/bash -l
#SBATCH --job-name=GLOB_MIN
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=lherold@mpa-garching.mpg.de
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=5  
#SBATCH --time=00:30:00
#SBATCH -N 1
#SBATCH -p p.test
#SBATCH --output=/u/lherold/Pk/MontePython/log/2024_08_13_PL_Asimov_w0_GLOB_MIN.log

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
MODE=GLOB_MIN
PARAM=/u/lherold/Pk/MontePython/montepython/input/2024_Wilks_test/PlikLiteTTTEE_fixed-Apl-tau_w0.param
OUT=/freya/ptmp/mpa/lherold/2024_08_13_PL_Asimov_w0
BF=/freya/ptmp/mpa/lherold/None/None.bestfit
BF2=/freya/ptmp/mpa/lherold/2024_08_13_PL_Asimov_w0/2024_08_13_PL_Asimov_w0.bestfit
COV=/u/lherold/Pk/MontePython/chains_LCDMext/Final_MCMCs/None/None.covmat
MP=/u/lherold/Pk/MontePython/montepython/MontePython.py
CONF=/u/lherold/Pk/MontePython/wilks_check.conf/Wilks_asimov.conf
N=2000
RE_RUN=
RESTART=

if [[ $BF == *None.bestfit ]]; then
    if [[ $COV == *None.covmat ]]; then
	FLAGS="-p $PARAM -o $OUT --conf $CONF"
    else
        FLAGS="-p $PARAM -o $OUT --conf $CONF -c $COV"
    fi
else
    if [[ $COV == *None.covmat ]]; then
        FLAGS="-p $PARAM -o $OUT --conf $CONF -b $BF"
    else
        FLAGS="-p $PARAM -o $OUT --conf $CONF -b $BF -c $COV"
    fi
fi
echo $FLAGS
    
###################################################                                         
#                     MCMC                        #
################################################### 


if [ "$MODE" = MCMC ] || [ "$MODE" = 1 ]; then
    if [ "$RE_RUN" = True ]; then
	# Run with restart
	srun python $MP run $FLAGS -N $N -j fast --restart $RESTART
    else
	# Run to initialize
	srun python $MP run $FLAGS -N 5 -f 1.0 -j fast
	# Run N times
	srun python $MP run $FLAGS -N $N -f 1.0  -j fast
    fi
    exit
fi

################################################### 
#     Simulated annealing-like minimization       #
###################################################  

# Details can be adapted if needed
srun python $MP $FLAGS -N $N -f 0.5 -T 0.1
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV --conf $CONF -N $((${N}+1)) -f 0.1 -T 0.005
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV --conf $CONF -N $((${N}+2)) -f 0.05 -T 0.001
python $MP info $OUT --minimal
srun python $MP -p $PARAM -o $OUT --bestfit $BF2 --covmat $COV --conf $CONF -N 1003 -f 0.03 -T 0.0005
python $MP info $OUT --minimal
