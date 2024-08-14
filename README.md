# pinc
Simple simulated-annealing minimizer to compute **p**rofiles **in** **c**osmology, i.e. profile likelihoods or global bestfits with [MontePython](https://github.com/brinckmann/montepython_public) and (any version of) [CLASS](https://github.com/lesgourg/class_public). 

We provide all notebooks to reproduce the plots in https://arxiv.org/abs/24... in `asymptotic checks`.

## Instructions
- The `pinc` scripts can be simply copied into any existing `MontePython` installation but need to be adapted by hand to the system and submission protocol (here `slurm`). 
- A covariance matrix from a previous MCMC increases the speed of convergence; for models with many parameters it is helpful to compute a covariance with the parameter of interest *fixed* to different values to obtain a more accurate estimate of the step size for the minimization (can be done with the `MCMC` flag)
- We also provide a *preliminary* analysis script `pinc.py` to compute confidence intervals, which can be used as a diagnostic; for examples on how to compute confidence intervals, see [PLs.ipynb](https://github.com/LauraHerold/pinc/blob/main/asymptotic_checks/notebooks_profiles_Planck%2BBOSS/PLs.ipynb)
