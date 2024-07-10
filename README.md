# notes on operational runs for SmartKjemi/Avinor

The NORTRIP executable compiled from this repo is used in production via the `nortrip-roadweather` module. The module also contains a venv where the package https://gitlab.met.no/elina1/create_nortrip_input, which creates the necessay input for NORTRIP from Frost, is installed. 

## new module version

The creation of an entirely new module version, `2024-07.666` for the sake of this example, happens in 2 steps: 
- creation of the module and installation of the python package  
  ```
  ./create_module_version.sh 2024-07.666
  ```
- compilation and copy of the executable, the job script and the config file to the module 
  ```
  ./deploy_to_module_version.sh 2024-07.666
  ```

## deployment to production

The default version of the module (used in ecflow) is `prod` which is a symlink in `/modules/rhel8/user-apps/fou-modules/nortrip-roadweather/`.  
So the roll-out to production of a newly created version happens via updating the symlink.
