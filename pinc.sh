#!/bin/bash

###################################################
#               Insert parameters                 #
###################################################


##### Parameter to scan in profile likelihood (PL)
# Parameter name, X, and its range to scan in PL (needs to be of data.parameters type in .param script)
XNAME=m_ncdm
XRANGE="0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.12 0.14 0.16"

##### Set mode (number or name of MODE)
# (1) MODE=MCMC: runs MCMC with parameter X fixed to the values in XRANGE
# (2) MODE=MIN: runs minimization to compute the PL in X for the values in XRANGE
# (3) MODE=GLOB_MIN: computes global minimum
# (4) MODE=ANALYSE_PL: prints the PL (after MIN has been run) - on login node
MODE=MIN

##### MontePython settings (no / after directories)
# Directory and name of MontePython .param script (the parameter X needs to be a data.parameters in the .param script)
PARAM_DIR=/u/lherold/Pk/MontePython/montepython/input/2024_Wilks_test
PARAM_NAME=Planck_Mnu_deg_mncdm.param

# Path and file name of output
OUT_DIR=/freya/ptmp/mpa/lherold
OUT_NAME=2024_07_24_PL_Planck_mncdm_deg

# Path and file name of input covariance matrix (if unavailable put None in NAME)
COV_DIR=/freya/ptmp/mpa/lherold
COV_NAME=2024_07_23_MCMC_Planck_Mnu_deg

# Path to file containing input bestfit (if unavailable put None in NAME)
BF_DIR=/freya/ptmp/mpa/lherold
BF_NAME=2024_07_23_MCMC_Planck_Mnu_deg

# If covariance/bestfit comes from the same file for every fixed value in XRANGE
ONE_COVBF_FILE=True

##### Other paramters
# Name of job script (here slurm)
JOB_SCRIPT=pinc.slurm
# Path to MontePython folder                                                                                     
MP_DIR=/u/lherold/Pk/MontePython
# Path to slurm log directory                                                                                                                  
LOG_DIR=/u/lherold/Pk/MontePython/log
# Path to .config file
CONF=/u/lherold/Pk/MontePython/default.conf

##### Parameters only for MCMC (to get good estimate of bestfit and covariance)
# Number of steps in MCMC
N=100000
# Submit jobs that that restart from OUT_DIR/OUT_NAME (if cluster kills jobs after certain amount of time)
RE_RUN=False
# If RE_RUN: Name of first restart file of first run
RESTART1=${OUT_NAME}/2023-11-26_3400000__1.txt
# If RE_RUN:  Name of first restart file of second run
RESTART2=${OUT_NAME}/2023-11-26_13400000__1.txt
# If RE_RUN:  Name of first restart file of third run
RESTART3=${OUT_NAME}/2023-11-26_23400000__1.txt

##### No changes should be necessary from here on


###################################################                                                                                            
#                 Preliminaries                   #                                                                                           
################################################### 


#### Small changes in two MontePython scripts (after running this once, these two sed commands could be removed)
# Small change to temperature treatment in montepython/sampler.py                                                                              
SRC="return loglike/command_line.temperature"
DST="return loglike"
sed -i "s|$SRC|$DST|" ${MP_DIR}/montepython/sampler.py

# Small change to temperature treatment in montepython/mcmc.py
SRC="alpha = np.exp(command_line.lklfactor*(newloglike-loglike))"
DST="alpha = np.exp(command_line.lklfactor*(newloglike-loglike)/command_line.temperature)"
sed -i "s|$SRC|$DST|" ${MP_DIR}/montepython/mcmc.py


###################################################
#                ANALYSE PL                       #
###################################################


if [ $MODE = ANALYSE_PL ] || [ $MODE = 4 ]; then

    PL_OUTPUT=${OUT_DIR}/${OUT_NAME}.txt
    printf "Profile likelihood analysis for X=${XNAME} \n \n" > PL_OUTPUT
    printf "x_array = [ $XRANGE ] \n" >> PL_OUTPUT
    
    echo " "
    echo "Printing Minimum of -logLike for "$OUT_NAME":"
    for X in ${XRANGE}
    do
	echo -n $X","
    done
    echo "]"

    
    echo -n "-logL = ["
    printf "-logL = [ " >> PL_OUTPUT
    for X in ${XRANGE}
    do
        FN=${OUT_DIR}/${OUT_NAME}_${X}/${OUT_NAME}_${X}".log"
        logL="$(grep -i "Minimum of -logLike" ${FN} | cut -d : -f 2)"
        echo -n $logL", "
	printf "$logL " >> PL_OUTPUT
    done
    echo -n "]"
    printf "] /n" >> PL_OUTPUT
    
    #python pinc.py ${PL_OUTPUT}
    echo "Full profile likelihood analysis saved to file:"
    echo "${PL_OUTPUT}"
    echo " "
    exit
fi


###################################################                                                                                            
#             COMMON SETTINGS                     #                                                                                            
###################################################  

   
##### Modify job script    
# Change mode (MIN, MCMC, ...) in job script
SRC="MODE=.*"
DST="MODE=${MODE}"
sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

# Change path to .config file
SRC="CONF=.*"
DST="CONF=${CONF}"
sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

# Change path to MontePython in job script                                                                                                     
MP=${MP_DIR}/montepython/MontePython.py
SRC="MP=.*"
DST="MP=${MP}"
sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}


###################################################
#                  GLOBAL MIN                     #
###################################################

   
if [ $MODE = GLOB_MIN ] || [ $MODE = 3 ]; then

    ##### Modify job script
    # Change batch job name in job script
    SRC="#SBATCH --job-name=.*"
    DST="#SBATCH --job-name=${MODE}"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change log file in job script
    SRC="#SBATCH --output=.*"
    DST="#SBATCH --output=${LOG_DIR}/${OUT_NAME}_${MODE}\.log"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change MontePython .param file name in job script                                                                                        
    SRC="PARAM=.*"
    DST="PARAM=${PARAM_DIR}/${PARAM_NAME}"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change output file in job script
    SRC="OUT=.*"
    DST="OUT=${OUT_DIR}/${OUT_NAME}"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change BF file in job script
    SRC="BF=.*"
    DST="BF=${BF_DIR}/${BF_NAME}/${BF_NAME}.bestfit"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change BF2 file in job script
    SRC="BF2=.*"
    DST="BF2=${OUT_DIR}/${OUT_NAME}/${OUT_NAME}.bestfit"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change covariance in job script
    SRC="COV=.*"
    DST="COV=${COV_DIR}/${COV_NAME}/${COV_NAME}.covmat"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Submit job
    JOBID=$(sbatch --parsable ${JOB_SCRIPT})
    echo "JOBID         ${JOBID}"
    
    exit
fi


###################################################
#                      PL                         #
###################################################


echo "$XNAME          job ID"
for X in $XRANGE
do
    ##### Create new parameter file for every fixed value of X
    NEW_PARAM_NAME=${OUT_NAME}_${X}.param
    cp ${PARAM_DIR}/${PARAM_NAME} ${PARAM_DIR}/${NEW_PARAM_NAME}

    # Change parameter to be scanned to cosmo_arguments and fix to value in X_RANGE
    SRC="data.parameters\['${XNAME}'\].*"
    DST="data.cosmo_arguments\['${XNAME}'\] = ${X}"
    sed -i "s|$SRC|$DST|" ${PARAM_DIR}/${NEW_PARAM_NAME}

    ##### Modify job script
    # Change batch job name in job script
    SRC="#SBATCH --job-name=.*"
    DST="#SBATCH --job-name=${X}_${MODE}"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change log file in job script
    SRC="#SBATCH --output=.*"
    DST="#SBATCH --output=${LOG_DIR}/${OUT_NAME}_${MODE}_${X}\.log"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change MontePython .param file name in job script                                                                                        
    SRC="PARAM=.*"
    DST="PARAM=${PARAM_DIR}/${NEW_PARAM_NAME}"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change output file in job script                                                                                                         
    SRC="OUT=.*"
    DST="OUT=${OUT_DIR}/${OUT_NAME}_${X}"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}
    
    # Change BF file in job script
    SRC="BF=.*"
    if [ "$ONE_COVBF_FILE" = True ]; then
	DST="BF=${BF_DIR}/${BF_NAME}/${BF_NAME}.bestfit"
    else
	DST="BF=${BF_DIR}/${BF_NAME}_${X}/${BF_NAME}_${X}.bestfit"
    fi
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change BF2 file in job script (only for minimization)
    SRC="BF2=.*"
    DST="BF2=${OUT_DIR}/${OUT_NAME}/${OUT_NAME}.bestfit"
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Change covariance file in job script
    SRC="COV=.*"
    if [ "$ONE_COVBF_FILE" = True ]; then
	DST="COV=${COV_DIR}/${COV_NAME}/${COV_NAME}.covmat"
    else
	DST="COV=${COV_DIR}/${COV_NAME}_${X}/${COV_NAME}_${X}.covmat"
    fi
    sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

    # Only for MCMC runs:
    if [ "$MODE" = MCMC ] || [ $MODE = 1 ]; then

	# Change number of steps
	SRC="N=.*"
	DST="N=${N}"
	sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

	# Change name of restart file 
	SRC="RE_RUN=.*"
	DST="RE_RUN=${RE_RUN}"
	sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}

	# Change name of restart file 
	SRC="RESTART=.*"
	DST="RESTART=${OUT_DIR}/${RESTART1}"
	sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}
    fi
    
    # Submit job
    JOBID=$(sbatch --parsable ${JOB_SCRIPT})
    echo "${X}         ${JOBID}"

    # Only for MCMC runs: submit additional restarting jobs
    if [ "$MODE" = MCMC ] || [ $MODE = 1 ]; then
        if [ "$RE_RUN" = True ]; then 
            SRC="RESTART=.*"
            DST="RESTART=${OUT_DIR}/${RESTART2}"
            sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}
            JOBID=$(sbatch --parsable -d afterany:${JOBID} ${JOB_SCRIPT})
            echo "${X}         ${JOBID}"

            SRC="RESTART=.*"
            DST="RESTART=${OUT_DIR}/${RESTART3}"
            sed -i "s|$SRC|$DST|" ${JOB_SCRIPT}
            JOBID=$(sbatch --parsable -d afterany:${JOBID} ${JOB_SCRIPT})
            echo "${X}         ${JOBID}"
	fi
    fi
done
