CAPACITY PROFILE

FFL0 east computation was done at Huygens (cluster at KHAS) in folder sim_upgrades. [results are large, so local machines memory is not enough to deal with] 
Seed = 0:12 first then seed = 14:19 done in one Matlab file.


FFL0 East - seed = 13, for this realization, vulnerability < 15 occurs at 43715th iteration. Therefore, we need extended simulations, so to compute this we use the following data file:
⁨Macintosh HD⁩ ▸ ⁨Users⁩ ▸ ⁨denizeroglu⁩ ▸ ⁨WorkSpace⁩ ▸ ⁨powerGrids⁩ ▸ ⁨cascade⁩ ▸ ⁨fig4-simultaneousUpdates⁩ ▸ ⁨20200316_vuln⁩ ▸ ⁨ffl0⁩ ▸ ⁨4-find_capacity_profiles⁩ ▸ ⁨data⁩ ▸ ⁨east⁩
cont_east_ffl0_K_init40000-K_final80000_demandRatio1_capRatio1_toInf0_seed12

with the following code:
matObj = matfile('cont_east_ffl0_K_init40000-K_final80000_demandRatio1_capRatio1_toInf0_seed12.mat')
caps_it(13,:) = matObj.caps(3715,:);


The rest of the data is in /data folder and computations were done here.
