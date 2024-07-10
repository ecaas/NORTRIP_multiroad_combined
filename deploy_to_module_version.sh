#!/bin/bash

MODULENAME=nortrip-roadweather

usage="Usage: $(basename "$0") [VERSION NAME]

deploys to avinor-roadweather/[VERSION NAME]  
the given module version has to be created in advance
the installation of https://gitlab.met.no/elina1/create_nortrip_input in the module venv is done elsewhere"


die () {
    echo "$usage" >&2
    exit 1
}

[ "$#" -eq 1 ] || die 

executable=NORTRIP_multiroad_combined_v2-r8_testbinary
modulevroot=/modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"
modulevshare=/modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/share
modulevbin=/modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/bin


# check module structure is in place

if [ ! -d "$modulevroot" ]; then
    echo "$modulevroot does not appear to exist" >&2
    exit 1
fi

if [ ! -d "$modulevbin" ]; then
    echo "$modulevbin does not appear to exist" >&2
    exit 1
fi

if [ ! -d "$modulevshare" ]; then
    echo "$modulevshare does not appear to exist" >&2
    exit 1
fi

if module load "$MODULENAME"/"$1"; then
    echo "module $MODULENAME/$1 is loadable, purging modules now"
    module purge
else 
   echo "WARNING: the module does not appear to be loadable"
fi

# if there is already an executable store the hash for later comparison
if [ -f "$executable" ]; then
    m1=$(stat -c '%Y' "$executable") 
else
    m1="null"
fi

# try to compile
module use /modules/MET/rhel8/user-modules/fou-modules
module load netcdf-fortran/4.6.0_intel2022

make

# check if executable is there and is new

if [ ! -f "$executable" ]; then
    echo "File $executable does not exists."
    exit 1
fi

m2=$(stat -c '%Y' "$executable")

if [[ "$m1" != "null" && "$m1" == "$m2" ]] ; then
    echo "WARNING: it looks like no new executable was created" >&2
fi

echo "copying files"
cp NORTRIP_config_avinor_forecast.txt /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/share/
cp NORTRIP_multiroad_combined_v2-r8_testbinary /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/bin/
cp NORTRIP-avinor.sh /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/bin/


