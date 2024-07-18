#!/bin/bash

set -e 

MODULENAME=nortrip-roadweather

usage="Usage: $(basename "$0") [ACTION] [VERSION_NAME]

both action and version name are required arguments
possible actions:
- CREATE : creates $MODULENAME/[VERSION_NAME] and installs https://gitlab.met.no/elina1/create_nortrip_input in the module venv
- UPDATE_PACKAGE : re-installs https://gitlab.met.no/elina1/create_nortrip_input into $MODULENAME/[VERSION_NAME]
- UPDATE_NORTRIP : compiles and copies the executable/config/job script files in the expected paths in the module
- ONLY_COPY_FILES : copies the executable/config/job script files in the expected paths in the module
- ALL : CREATE + UPDATE_NORTRIP"


die () {
    echo "$usage" >&2
    exit 1
}

[ "$#" -eq 2 ] || die 

echo "target module is $MODULENAME/$2"


#---------------------------
func_create_module_version()
    {
	/modules/rhel8/user-apps/python/python-3.10.4/bin/python3 -m venv /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/venv --upgrade-deps
	mkdir /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/bin
	mkdir /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/share

	MODULEFILE=/modules/MET/rhel8/user-modules/fou-modules/"$MODULENAME"/"$2"

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
	sed -i "s/VERSION_NAME/$2/g" "$MODULEFILE"
    }


#-----------------------------
func_install_python_package()
    {
	module use /modules/MET/rhel8/user-modules/fou-modules

	if module load "$MODULENAME"/"$2"; then
	    pipv=$(which pip)
	    if [[ "$pipv" != /modules/rhel8/user-apps/fou-modules/$MODULENAME/$2/venv/bin/pip ]]; then
		echo "something is wrong: pip is $pipv" >&2
		exit 1
	    else 
		pip install --force "git+ssh://git@gitlab.met.no/elina1/create_nortrip_input.git"
	    fi
	fi
	module unload "$MODULENAME"/"$2"
    }


#----------------------
func_compile_nortrip()
    {
        executable=NORTRIP_multiroad_combined_v2-r8_testbinary

	# if there is already an executable store the hash for later comparison
	if [ -f "$executable" ]; then
	    m1=$(stat -c '%Y' "$executable") 
	else
	    m1="null"
	fi

	# try to compile
	module use /modules/MET/rhel8/user-modules/fou-modules
	module load netcdf-fortran/4.6.0_intel2022

        rm *.o
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
    }


#-----------------
func_copy_files()
    {
	executable=NORTRIP_multiroad_combined_v2-r8_testbinary
	modulevroot=/modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"
	modulevshare=/modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/share
	modulevbin=/modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/bin

	# check that module structure is in place

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

	if module load "$MODULENAME"/"$2"; then
	    echo "module $MODULENAME/$2 is loadable, unloading it now"
	    module unload "$MODULENAME"/"$2"
	else 
	   echo "WARNING: $MODULENAME/$2 does not appear to be loadable"
	fi

	cp NORTRIP_config_avinor_forecast.txt /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/share/
	cp NORTRIP_multiroad_combined_v2-r8_testbinary /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/bin/
	cp NORTRIP-avinor.sh /modules/rhel8/user-apps/fou-modules/"$MODULENAME"/"$2"/bin/
    }



case "$1" in
	CREATE )
		echo "creating the module version and installing the python package"
		func_create_module_version $1 $2
		func_install_python_package $1 $2
		;;
	UPDATE_PACKAGE )
		echo "reinstalling the python package"
		func_install_python_package $1 $2
		;;
	UPDATE_NORTRIP )
		echo "compiling and copying files"
		func_compile_nortrip $1 $2
		func_copy_files $1 $2
		;;
	ONLY_COPY_FILES )
		echo "only copying files"
		func_copy_files $1 $2
		;;
	ALL )
		func_create_module_version $1 $2
		func_install_python_package $1 $2
		func_compile_nortrip $1 $2
		func_copy_files $1 $2
		;;
	*)
		die
		;;
esac
 
