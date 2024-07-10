#!/bin/bash

MODULENAME=nortrip-roadweather

usage="Usage: $(basename "$0") [VERSION NAME]

creates $MODULENAME/[VERSION NAME] 
installs https://gitlab.met.no/elina1/create_nortrip_input in the module venv
creates the paths for the executable, the job script and the config but these are deployed elsewhere"


die () {
    echo "$usage" >&2
    exit 1
}

[ "$#" -eq 1 ] || die 

/modules/rhel8/user-apps/python/python-3.10.4/bin/python3 -m venv /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/venv --upgrade-deps
mkdir /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/bin
mkdir /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$1"/share

MODULEFILE=/modules/MET/rhel8/user-modules/fou-modules/"$MODULENAME"/"$1"

cat > "$MODULEFILE" <<'EOF'
#%Module1.0#####################################################################
##

set appname  "MODULE_NAME"
set release  VERSION_NAME
set apphome  /modules/rhel8/user-apps/fou-modules/

proc ModulesDisplay {} {
  global appname release apphome

  puts stderr "\nLoads $appname version $release"
}

proc ModulesHelp { } {
  global appname modulefile apphome release

  puts stderr "The $appname modulefile defines the default system paths and"
  puts stderr "environment variables needed to use $appname release $release.\n"
  puts stderr "Python package installed in the venv from: https://gitlab.met.no/elina1/create_nortrip_input \n"
  puts stderr "NORTRIP binary compiled from: https://github.com/ecaas/NORTRIP_multiroad_combined \n"
  puts stderr "Config file from: https://github.com/ecaas/NORTRIP_multiroad_combined/blob/master/NORTRIP_config_avinor_forecast.txt \n"
}

module-whatis   "Setup for running Elin's NORTRIP code to deliver results to Avinor"

set             root                    /modules/rhel8/user-apps/fou-modules/MODULE_NAME/VERSION_NAME
prepend-path    VIRTUAL_ENV             $root/venv
prepend-path    PATH                    $root/venv/bin
prepend-path    PATH                    $root/bin

setenv NORTRIP_CONFIG       $root/share/NORTRIP_config_avinor_forecast.txt
EOF


#replace VERSION_NAME and MODULE_NAME with actual version/name
sed -i "s/MODULE_NAME/$MODULENAME/g" "$MODULEFILE"
sed -i "s/VERSION_NAME/$1/g" "$MODULEFILE"

module purge
module use /modules/MET/rhel8/user-modules/fou-modules

if module load "$MODULENAME"/"$1"; then
    pipv=$(which pip)
    if [[ "$pipv" != /modules/rhel8/user-apps/fou-modules/$MODULENAME/$1/venv/bin/pip ]]; then
        echo "something is wrong: pip is $pipv" >&2
        exit 1
    else 
        pip install --force "git+ssh://git@gitlab.met.no/elina1/create_nortrip_input.git"
    fi
fi

