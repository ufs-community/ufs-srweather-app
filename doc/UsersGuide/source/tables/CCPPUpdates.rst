:orphan:

.. _CCPPUpdates:

================================================
CCPP Updates for the SRW App v2.1.0 Release
================================================

Here is what's new in CCPP Physics for the UFS SRW v2.1.0 public release. These changes are expected to improve the performance of the RRFS_v1beta, HRRR, and WoFS_v0 suites.

RRFS_v1beta, HRRR, and WoFS Suites:
================================================

MYNN-EDMF PBL scheme:
   * Added the ability to configure the MYNN-EDMF PBL scheme to function at closure level 2.5, 2.6 (current default), or 3.0 closure and included a partial-condensation scheme. 
   * Reverted to Tian-Kuang lateral entrainment, which reduces a high relative humidity bias found in some HRRR cases.
   * Reduced the entrainment rate for momentum.
   * Removed the first-order form of the Chaboureau and Bechtold (CB2002) stratiform cloud fraction calculation---it now only uses a higher form of CB.
   * Changed CB to use absolute temperature instead of "liquid" temperature (CB2002).
   * Added variable ``sm3d``---a stability function for momentum.

MYNN Surface Layer Scheme:
   * Moved four internal parameters to namelist options:

      * ``isftcflux``: flag for thermal roughness lengths over water in MYNN-SFCLAY
      * ``iz0tlnd``: flag for thermal roughness lengths over land in MYNN-SFCLAY
      * ``sfclay_compute_flux``: flag for computing surface scalar fluxes in MYNN-SFCLAY
      * ``sfclay_compute_diag``: flag for computing surface diagnostics in MYNN-SFCLAY

Subgrid Scale Clouds Interstitial Scheme:
   * Separated frozen subgrid clouds into snow and ice categories.
   * Added CB2005 as a new cloud fraction option. 
RRTMG:
   * Removed cloud fraction calculations for the MYNN-EDMF scheme, since cloud fraction is already defined in the subgrid scale cloud scheme used by MYNN-EDMF.

HRRR Suite:
================================================

RUC Land Surface Model:
   * In the computation of soil resistance to evaporation, the soil moisture field capacity factor changed from 0.7 to 1. This change will reduce direct evaporation from bare soil.

GSL Drag Suite:
   * Removed limits on the standard deviation of small-scale topography used by the small-scale GWD and turbulent orographic form drag (TOFD) schemes; removed the height limitation of the TOFD scheme.

Removed the  “sfc_nst” scheme from the suite to avert a cooling SST trend that had a negative impact on surface variables in the coastal regions.

RRFS_v1beta Suite:
================================================

Noah-MP Land Surface Model:
   * Added a connection with the MYNN surface layer scheme via namelist option ``opt_sfc=4``.

GFS_v16 Suite:
================================================

GFS saSAS Deep Convection and saMF Shallow Cumulus Schemes:
   * Added a new prognostic updraft area fraction closure in saSAS and saMF (Bengtsson et al., 2022). It is controlled via namelist option ``progsima`` (set to ``false`` by default) and an updated field table including ``sigmab``.

