# notes on operational runs for SmartKjemi/Avinor

The NORTRIP executable compiled from this repo is used in production via the `nortrip-roadweather` module. The module also contains a venv where the package https://gitlab.met.no/elina1/create_nortrip_input, which creates the necessay input for NORTRIP from Frost, is installed. 

## create or update module version

Via the deployment script `module_deployment.sh` it is possible to create a complete new version of the module from scratch or selectively update parts of an existing version

```
Usage: module_deployment.sh [ACTION] [VERSION_NAME]

both action and version name are required arguments
possible actions:
- CREATE : creates nortrip-roadweather/[VERSION_NAME] and installs https://gitlab.met.no/elina1/create_nortrip_input in the module venv
- UPDATE_PACKAGE : re-installs https://gitlab.met.no/elina1/create_nortrip_input into nortrip-roadweather/[VERSION_NAME]
- UPDATE_NORTRIP : compiles and copies the executable/config/jobscript files in the expected paths in the module
- ONLY_COPY_FILES : copies the executable/config/job script files in the expected paths in the module
- ALL : CREATE + UPDATE_NORTRIP
```

so for example to only update the python package in version `2024-07.666` (assumed existing):   
`./module_deployment.sh UPDATE_PACKAGE 2024-07.666` 

## deployment to production

The default version of the module (used in ecflow) is `prod` which is a symlink in `/modules/rhel8/user-apps/fou-modules/nortrip-roadweather/`.  
So the roll-out to production of a newly created version happens via updating the symlink.
