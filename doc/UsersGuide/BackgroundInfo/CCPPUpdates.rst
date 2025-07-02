:orphan:
.. _CCPPUpdates:

================================================
CCPP Updates for the SRW App v3.0.0 Release
================================================

Here is what's new in CCPP Physics for the UFS SRW v3.0.0 public release. For a more expanded look and to view the bibliography, please view the CCPP UFS-SRW v3.0.0 documentation `here <https://dtcenter.ucar.edu/GMTB/UFS_SRW_App_v3.0.0/sci_doc/index.html>`__.

General Updates
=================

* New supported suites: ``RRFS_sas`` and ``HRRR_gf`` suites 
* Community Land Model (CLM) Lake Model in ``HRRR``, ``HRRR_gf`` and ``RRFS_sas`` suites
* New SRW Smoke and Dust Scheme in HRRR, ``HRRR_gf`` and ``RRFS_sas`` suites
* New photochem interface, which replaces ozphys_2015 and h2ophys

.. note::

    Suite ``RRFS_v1bet``, which were supported with UFS-SRW v2.2.0, have been replaced with ``RRFS_sas``.

Thompson Microphysics Scheme
==============================

* Ice generation supersaturation requirement reduced from 0.25 to 0.15 to generate more ice at the upper levels and reduce the outgoing longwave radiation bias
* Cloud number concentration divided into two parts (over land and others). Number concentration over ocean reduced to a smaller number (50/ cm3) from its previous default (100/ cm3). Both changes were made to increase the downward shortwave radiative flux and reduce the negative bias off coastal regions including the Southeast Pacific
* To reduce the high bias in downward shortwave (DSW), radiative flux over land has been increased from 100/ cm3 to 150/ cm3. The convective cloud ice radius in radiation_clouds has been reduced from 50 μm to 25 μm. The 2020 summer HRv4 test results show a reduction in the high DSW bias over land and a corresponding reduction in the low bias of upward shortwave and radiative flux at the top of the atmosphere
* Small fixes to the minimum size of snow and collision constants


NoahMP Land Surface Model
===========================

* Option for using the unified frozen precipitation fraction in NoahMP
* Diagnostic 2-meter temperature and humidity now based on vegetation and bare-ground tiles (new namelist option ``iopt_diag``)
* Bug fixes for GFS-based thermal roughness length scheme
* New soil color dataset introduced to improve soil albedo to reduce the large warm bias found in the Sahel desert
* Wet leaf contribution factor is included
* Leaf-area index now depends on momentum roughness length
* Soil thermal conductivity enhancement: To reduce persistent nighttime and early morning warm surface temperature bias in GFS models, a new lookup table developed from the PNNL soil carbon dataset and VIIRS surface type data is included, and the effects of soil organic matter (SOM) on soil thermal properties have been accounted for. GFSv17 prototype tests show that including SOM results in better simulation of ground heat flux, reducing heat storage in the soil during the day, and mitigating the nighttime warm bias, particularly over the Great Plains.
* Evapotranspiration adjustment: The aquifer hydraulic conductivity has been updated to use the algorithm average rather than the harmonic average. This increases the amount of water uptake by the soil layer, improving evapotranspiration modeling
* Snow aging at night: Fixed an issue to allow snow aging to occur at night, ensuring more realistic snow dynamics
* Unit correction for potential evaporation: corrected the unit for potential evaporation from W/m2 to mm/s to ensure proper unit consistency and accuracy in the model
* Glacier albedo computation is fixed


RUC Land Surface Model
========================

* Initialization of land and ice emissivity and albedo with consideration of partial snow cover
* Initialization of water vapor mixing ratio over land ice
* Initialization of fractions of soil and vegetation types in a grid cell
* Changes in the computation of a flag for sea ice: set to true only if ``flag_ice=.false``. (atmosphere uncoupled from the sea ice model)
* Separate variable for sea ice, for example: ``snowfallac`` is replaced with ``snowfallac_ice``
* Solar angle dependence of albedo for snow-free land
* Stochastic physics perturbations (SPP) introduced for emissivity, albedo and vegetation fraction
* Coefficient in soil resistance formulation (Sakaguchi and Zeng, 2009) raised from 0.7 to 1.0 to increase soil resistance to evaporation
* Computation of snow cover fraction and snow thermal conductivity updated
* Cap snow for points at high elevations where all year round skin temperatures are close to 0ºC. Snow density for these points will be 3000/7.5=400 kg/m3
* Update the RUC LSM deep soil temperature from climatology to real forecast
* The output of surface runoff is changed from instantaneous to accumulated surface runoff

GFS Scale-Aware TKE-EDMF PBL and Cumulus Schemes
==================================================

* Implementation of a parameterization for environmental wind shear effect in the GFS TKE-EDMF PBL and cumulus schemes to reduce the negative hurricane intensity biases.
* Entrainment rates are enhanced proportionally to the sub-cloud or PBL mean TKE (turbulent kinetic energy) when TKE is larger than a threshold value
* Increased entrainment rate as a function of vegetation fraction and surface roughness length to enhance the underestimated CAPE forecasts in the GFS (Han et al. 2024)
* Implementation of a positive definite mass-flux scheme and a method for removing the negative tracers (Han et al. 2022)
* Introduction of a new closure based on a prognostic evolution of the convective updraft area fraction in both shallow and deep convection (Bengtsson et al. 2022)
* Introduction of 3D effects of cold-pool dynamics and stochastic initiation using self-organizing cellular automata stochastic convective organization scheme (not supported in SCM; Bengtsson et al. 2021 [16])
* Introduction of environmental wind shear effect and subgrid TKE dependence in convection, to seek improvements in hurricane forecast prediction (Han et al. 2024)
* Introduction of stricter convective initiation criteria to allow for more CAPE to build up to address a low CAPE bias in GFSv16 (Han et al. 2021)
* Reduction of convective rain evaporation rate to address a systematic cold bias near the surface in GFSv16 (Han et al. 2021)
* A scale adaptive solution of improving convection/radiation interaction is proposed and tested for SFS application to address too much cloud shielding and a drift in SST

MYNN-EDMF PBL Scheme
======================

* Small increase of buoyancy length scale in convective environment
* Patch for ensuring non-zero cloud fractions for all grid cells where cloud mixing ratio is greater than 1e-6 or ice mixing ratio is greater than 1e-9
* Exclude qs to calculate theta tendency

Subgrid-Scale (SGS) Clouds Scheme
===================================

* Bug fix for cloud condensate input into RRTMG radiation
* New code section for use with SAS cumulus scheme
* Cloud fraction now computed as a mix between the area-dependent form and the modified Chaboureau and Bechtold (2005) form
* Adjusted limit for the boundary flux functions

MYNN Surface-layer Scheme
===========================

* Reintroduce friction velocity averaging over water to reduce noise in 10-m winds in the hurricane regime

Grell-Freitas Scale and Aerosol Aware Convection Scheme
=========================================================

* Update for aerosol-awareness (experimental and not supported)
* Scale-awareness turned off when explicit microphysics is not active anywhere in the column
* Convection is completely suppressed at grid points where the MYNN PBL sheme produces shallow convection
* Radar reflectivity considers mass flux PDF as well as whether scale-awareness is turned on at the gird point in equation
* Add a new parameter ``gf_coldstart`` to control whether GF will be cold started or not.

Unified Gravity Wave Physics Scheme
=====================================

* Replacement of the resolution-dependent effective grid spacing (``cdmbgwd``) with a constant (=6dx)
* Removal of the planetary boundary layer height in determining the reference level
* Weakening of the momentum stress over land ice to reduce the negative wind biases
* Introduction of a launching level to avoid the underestimation of the blocked stress
* Introduction of damped breaking to prevent the wind reversal in the lower troposphere
* Suppression of gravity wave breaking in the upper atmosphere (over 7.5 hPa) to avoid numerical instability
* Revision in sub-grid orography data considering the mathematical definition of moments
* Drag suite: change alpha to 35 - 0.0759 becomes 0.2214

Radiation
==========

* Coupling of GOCART aerosols with radiation (iaer=2011)
* Convective cloud water (liquid water + ice water) added to the calculations of cloud water path and ice water path for radiation cloud properties

NSSL Cloud Microphysics Scheme
===============================

* Updated with 3-moment option
