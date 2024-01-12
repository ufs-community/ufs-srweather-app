:orphan:

.. _CCPPUpdates:

================================================
CCPP Updates for the SRW App v2.2.0 Release
================================================

Here is what's new in CCPP Physics for the UFS SRW v2.2.0 public release. 

General Updates
=================

* Added RAP suite (``FV3_RAP``) as a new supported suite (documentation `here <https://dtcenter.ucar.edu/GMTB/UFS_SRW_App_v2.2.0/sci_doc/rap_suite_page.html>`__)
* Added the Community Land Model (CLM) lake model in the HRRR suite (``FV3_HRRR``)

Thompson Microphysics Scheme
==============================

* Reduced ice generation supersaturation requirement from 0.25 to 0.15 to generate more ice at the upper levels and reduce the outgoing longwave radiation bias
* Divided cloud number concentration into two parts (over land and others). Reduced number concentration over ocean to a smaller number (50/L) from its previous default (100/L). Both changes were made to reduce excessive surface downward shortwave radiative flux off coastal regions including the Southeast Pacific
* Implemented small fixes to the minimum size of snow and collision constants

.. note:: 
   
   The above improvements were tested with the non-aerosol option, so results with the aerosol-aware Thompson (used in the SRW App) may vary.


NoahMP Land Surface Model
===========================

* Option for using the unified frozen precipitation fraction in NoahMP.
* Diagnostic 2-meter temperature and humidity now based on vegetation and bare-ground tiles (new namelist option ``iopt_diag``)
* Bug fixes for GFS-based thermal roughness length scheme
* New soil color dataset introduced to improve soil albedo to reduce the large warm bias found in the Sahel desert
* Wet leaf contribution factor is included
* Leaf-area index now depends on momentum roughness length


RUC Land Surface Model
========================

* Initialization of land and ice emissivity and albedo with consideration of partial snow cover
* Initialization of water vapor mixing ratio over land ice
* Initialization of fractions of soil and vegetation types in a grid cell
* Changes in the computation of a flag for sea ice: set to true only if ``flag_cice=.false`` (atmosphere uncoupled from the sea ice model).
* Separate variables for sea ice, for example: ``snowfallac`` is replaced with ``snowfallac_ice``
* Solar angle dependence of albedo for snow-free land
* Coefficient in soil resistance formulation (Sakaguchi and Zeng, 2009) raised from 0.7 to 1.0 to increase soil resistance to evaporation
* Computation of snow cover fraction and snow thermal conductivity updated

GFS Scale-Aware TKE-EDMF PBL and Cumulus Schemes
==================================================

* Parameterization to represent environmental wind shear effect added to reduce excessively high hurricane intensity
* Entrainment rates enhanced proportionally to the sub-cloud or PBL-mean TKE when TKE is larger than a threshold value
* Entrainment rate is increased as a function of vegetation fraction and surface roughness length to enhance underestimated CAPE

MYNN-EDMF PBL Scheme
======================

* Small increase of buoyancy length scale in convective environments
* Patch for ensuring non-zero cloud fractions for all grid cells where cloud mixing ratio is greater than 1e-6 or ice mixing ratio is greater than 1e-9

Subgrid-Scale (SGS) Clouds Scheme
===================================

* Bug fix for cloud condensate input into RRTMG radiation
* New code section for use with SAS convection scheme
* Cloud fraction now computed as a mix between the area-dependent form and the modified Chaboureau and Bechtold (2005) form
* Adjusted limit for the boundary flux functions

MYNN Surface-layer Scheme
===========================

* Reintroduced friction velocity averaging over water to reduce noise in 10-m winds in the hurricane regime

Grell-Freitas Scale and Aerosol Aware Convection Scheme
=========================================================

* Update for aerosol-awareness (experimental)
* Scale-awareness turned off when explicit microphysics is not active anywhere in the column
* Convection is completely suppressed at grid points where the MYNN PBL scheme produces shallow convection
* Radar reflectivity considers mass flux PDF as well as whether scale-awareness is turned on at the grid point in question

Unified Gravity Wave Physics Scheme
=====================================

* Optional diagnostic for tendencies computed. They can be switched on by setting the following namelist variables to ``“.true.”``: ``ldiag3d`` and ``ldiag_ugwp``


.. attention:: 
   
   The improvements in Thompson cloud microphysics, NoahMP land surface model, GFS TKE-EDMF and cumulus schemes were tested in the UFS global configuration, so results in the UFS limited-area configuration (SRW) may vary. 