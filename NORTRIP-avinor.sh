#!/bin/bash

module load uemep

date_time_start_tmp=$(date '+%Y%m%d %H')
date_time_end=$(date '+%Y,%m,%d,%H,%M' -d "${date_time_start_tmp} + 12 hour")
date_time_start=$(date '+%Y,%m,%d,%H' -d "${date_time_start_tmp} - 1 hour")",10"

CONF_MOD=conf_nortrip_$(date '+%Y%m%d%H' -d "${date_time_start_tmp}").txt

# check/set lustredir variable
if [[ ! -z "${LUSTRE_DIR-}" ]]; then
   export lustredir=${LUSTRE_DIR}
   echo "using ${LUSTRE_DIR} for lustredir"
else
   export lustredir="/lustre/storeB"
   echo "using default (/lustre/storeB) for lustredir"
fi

sed "s:/lustre/store.:$lustredir:" $NORTRIP_CONFIG > $CONF_MOD

NORTRIP_multiroad_combined_v2-r8_testbinary $CONF_MOD $date_time_start $date_time_end

