
-- Until Cheyenne updates Lmod version to >=8.3.7
-- emulate load_any with try_load + isloaded() combo
function my_load_any(pkg1, pkg2)
   try_load(pkg1)
   if not isloaded(pkg1) then
      load(pkg2)
   end
end

load("jasper/2.0.25")
load("zlib/1.2.11")
my_load_any("png/1.6.35", "libpng/1.6.37")

my_load_any("netcdf/4.7.4", "netcdf-c/4.7.4")
my_load_any("netcdf/4.7.4", "netcdf-fortran/4.5.4")
my_load_any("pio/2.5.3", "parallelio/2.5.2")
my_load_any("esmf/8.3.0b09", "esmf/8.2.0")
load("fms/2022.01")

load("bufr/11.7.0")
load("bacio/2.4.1")
load("crtm/2.3.0")
load("g2/3.4.5")
load("g2tmpl/1.10.0")
load("ip/3.3.3")
load("sp/2.3.3")
load("w3emc/2.9.2")

my_load_any("gftl-shared/v1.5.0", "gftl-shared/1.5.0")
my_load_any("yafyaml/v0.5.1", "yafyaml/0.5.1")
my_load_any("mapl/2.22.0-esmf-8.3.0b09", "mapl/2.11.0-esmf-8.2.0")

load("nemsio/2.5.4")
load("sfcio/1.4.1")
load("sigio/2.3.2")
load("w3nco/2.4.1")
load("wrf_io/1.2.0")

load("ncio/1.1.2")
load("wgrib2/2.0.8")
