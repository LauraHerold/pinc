import sys
import numpy as np
from scipy.optimize import curve_fit
from scipy.optimize import fsolve
from scipy import interpolate
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

# Parameters
ignore_border = False

# Read data from pl_output file
pl_output = str(sys.argv[1])
x_name = str(sys.argv[2])
x_array, logL_array = np.loadtxt(pl_output+".txt")
chi2_array = 2*logL_array
N_x = len(x_array)
mid_x = x_array[int(N_x/2)]
Delta_x = x_array[-1]-x_array[0]

# Define parabola
def parab(x, a,b,c):
    return a + b * (x-c)**2.

# Table for Neyman construction in terms of LR test statistic in units of sigma (i.e. sigma=1)             
mu_FC = np.array([    0.0000, 0.0500, 0.1000, 0.1500, 0.2000, 0.2500, 0.3000, 0.3500, 0.4000, 0.4500, 0.5000, 0.5500, 0.6000, 0.6500, 0.7000, 0.7500, 0.8000, 0.8500, 0.9000, 0.9500, 1.0000, 1.0500, 1.1000, 1.1500, 1.2000, 1.2500, 1.3000, 1.3500, 1.4000, 1.4500, 1.5000, 1.5500, 1.6000, 1.6500, 1.7000, 1.7500, 1.8000, 1.8500, 1.9000, 1.9500, 2.0000, 2.0500, 2.1000, 2.1500, 2.2000, 2.2500, 2.3000, 2.3500, 2.4000, 2.4500, 2.5000, 2.5500, 2.6000, 2.6500, 2.7000, 2.7500, 2.8000, 2.8500, 2.9000, 2.9500, 3.0000, 3.0500, 3.1000, 3.1500, 3.2000, 3.2500, 3.3000, 3.3500, 3.4000, 3.4500, 3.5000, 3.5500, 3.6000, 3.6500, 3.7000, 3.7500, 3.8000, 3.8500, 3.9000, 10.000])
tLR_68_FC = np.array([0.2444, 0.2444, 0.3438, 0.4367, 0.5181, 0.5897, 0.6530, 0.7091, 0.7586, 0.8023, 0.8407, 0.8741, 0.9029, 0.9274, 0.9480, 0.9647, 0.9780, 0.9879, 0.9948, 0.9988, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000, 1.0000])
tLR_95_FC = np.array([2.8566, 2.8566, 2.8566, 2.8566, 2.8566, 2.8566, 2.8566, 2.8570, 2.8594, 2.8680, 2.8871, 2.9182, 2.9602, 3.0105, 3.0664, 3.1258, 3.1868, 3.2483, 3.3093, 3.3690, 3.4270, 3.4829, 3.5365, 3.5874, 3.6356, 3.6809, 3.7233, 3.7626, 3.7988, 3.8320, 3.8621, 3.8891, 3.9131, 3.9340, 3.9520, 3.9670, 3.9791, 3.9884, 3.9949, 3.9987, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000, 4.0000])

# Interpolate Neyman table                                                                       
tLR_95_mu = interpolate.make_interp_spline(mu_FC, tLR_95_FC)
tLR_68_mu = interpolate.make_interp_spline(mu_FC, tLR_68_FC)

# Fit parabola     
[a,b,c], pcov = curve_fit(parab, x_array, chi2_array, p0=[chi2_array[int(N_x/2)], chi2_array[int(N_x/2)], mid_x], maxfev=1000000)
fit_x = np.linspace(mid_x-10*Delta_x, mid_x+10*Delta_x, 500)
fit_y = b * (fit_x-c)**2.
chi2_min = a
MLE_x = c
ordinate = a + b*c**2

# Find intersection of parabola with \Delta\chi^2 = 1
def intersec1(x):
    return b * (x-c)**2. -1
zeros = fsolve(intersec1, x0=[mid_x-10*Delta_x, mid_x+10*Delta_x])
sigma = (zeros[1]-zeros[0])/2.
x0 = MLE_x/sigma
x1 = zeros[0]/sigma
x2 = zeros[1]/sigma

# Compute 68% CL interval
if (x2>mu_FC[-1]) or ignore_border:
    text_68 = "68 percent confidence interval (graphical construction): %(centr).5f \pm %(err).5f"%{"centr":MLE_x, "err":sigma}

else:
    def intersec1_border(x):
        return a+b * (x-c)**2. - ordinate - tLR_68_mu(x/sigma)
    [x1_bord, x2_bord] = fsolve(intersec1_border, x0=[mid_x-10*Delta_x, mid_x+10*Delta_x])
    if (x1_bord > 0) and (round(x1_bord, 8) != round(x2_bord,8)):
        sigma1 = MLE_x - x1_bord
        sigma2 = x2_bord - MLE_x
        text_68 = "68 percent confidence interval (border-corrected graphical construction): %(centr).5f - %(err1).5f + %(err2).5f"%{"centr":MLE_x, "err1":sigma1, "err2":sigma2}
    else:
        text_68 = "68 percent confidence interval (border-corrected graphical construction): < %(lim).5f"%{"lim":x2_bord}
        
# Compute 95% CL interval
if (x2>mu_FC[-1]) or ignore_border:
    text_95 = "95 percent confidence interval (graphical construction): %(centr).5f \pm %(err).5f"%{"centr":MLE_x, "err":2*sigma}

else:
    def intersec2_border(x):
        return a+b * (x-c)**2. - ordinate - tLR_95_mu(x/sigma)
    [x1_bord, x2_bord] = fsolve(intersec2_border, x0=[mid_x-20*Delta_x, mid_x+20*Delta_x])
    if (x1_bord > 0) and (round(x1_bord, 8) != round(x2_bord,8)):
        sigma1 = MLE_x - x1_bord
        sigma2 = x2_bord - MLE_x
        text_95 = "95 percent confidence interval (border-corrected graphical construction): %(centr).5f - %(err1).5f + %(err2).5f"%{"centr":MLE_x, "err1":sigma1, "err2":sigma2}
    else:
        text_95 = "95 percent confidence interval (border-corrected graphical construction): < %(lim).5f"%{"lim":x2_bord}

# Print
print(text_68)
print(text_95)
f = open(pl_output+".txt", "a")
f.write("\n"+text_68+"\n")
f.write("\n"+text_95+"\n")
f.close()

# Plot
plt.ioff()
fig=plt.figure()
plt.plot(x_array, chi2_array-chi2_min, marker="d", ls="", color="teal")
plt.plot(fit_x, fit_y, color="teal", ls='-')
plt.xlabel(x_name)
plt.ylabel(r"$\Delta\chi^2$")
plt.ylim(0, np.max(chi2_array)-np.min(chi2_array)+2)
plt.xlim(mid_x - Delta_x, mid_x + Delta_x)
plt.savefig(pl_output+".pdf", format="PDF")
