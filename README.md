# UFS Short-Range Weather Application

The Unified Forecast System (UFS) is a community-based, coupled, comprehensive Earth modeling system. It is designed to be the source system for NOAA’s operational numerical weather prediction applications while enabling research, development, and contribution opportunities for the broader weather enterprise. For more information about the UFS, visit the UFS Portal at https://ufscommunity.org/.

The UFS includes multiple applications (see a complete list at https://ufscommunity.org/science/aboutapps/) that support different forecast durations and spatial domains. This documentation describes the UFS Short-Range Weather (SRW) Application release v2.0.0, which targets predictions of atmospheric behavior on a limited spatial domain and on time scales from minutes to several days. The development branch of the application is continually evolving as the system undergoes open development. The SRW App v2.0.0 represents a snapshot of this continuously evolving system. 

The SRW Application v2.0.0 includes a prognostic atmospheric model, pre- and post-processing, and a community workflow for running the system end-to-end. These components are documented within this User's Guide and supported through a community forum (https://forums.ufscommunity.org/). New and improved capabilities for this release include the addition of a verification package (METplus) for both deterministic and ensemble simulations and support for four Stochastically Perturbed Perturbation (SPP) schemes. Future work will expand the capabilities of the application to include data assimilation (DA) and a forecast restart/cycling capability.

The UFS SRW App User's Guide associated with the development branch is at: https://ufs-srweather-app.readthedocs.io/en/develop/, while the guide specific to the SRW App v2.0.0 release can be found at: https://ufs-srweather-app.readthedocs.io/en/release-public-v2/. The repository is at: https://github.com/ufs-community/ufs-srweather-app.

For instructions on how to clone the repository, build the code, and run the workflow, see:
https://github.com/ufs-community/ufs-srweather-app/wiki/Getting-Started

UFS Development Team. (2022, June 23). Unified Forecast System (UFS) Short-Range Weather (SRW) Application (Version v2.0.0). Zenodo. https://doi.org/10.5281/zenodo.6505854
