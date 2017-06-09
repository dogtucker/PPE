#!/bin/bash

#----------------------------------------------------------------------------
# Sylvaine Ferrachat / Grazia Frontoso 2011
#
# Script to perform the linking of input files into the experiment directory
# for echam6-hammoz (and echam6) 
#
# This script is called jobsum_echam.sh
#
# Variables that are used in this script (and defined prior to executing it):
#
#    exp_dir="[path to your experiment directory here]"
#    log_file="[file to log the current process]"
#    hres="[horizontal resolution, e.g. T63]"
#    vres="[vertical resolution, e.g. L47]"
#    oceres="[ocean resolution, e.g. GR30]"
#    start_yyyymm="[starting date as YYYYMM]"
#    stop_yyyymm="[stopping date as YYYYMM]"
#    start_year_m1="[year before starting year]"
#    stop_year_p1="[year after stopping year]"
#    start_yyyymm_m1="[1 month before starting date as YYYYMM]"
#    stop_yyyymm_p1="[1 month after stopping date  as YYYYMM]"
#    flag_time_dep_sst_sic="[time-dependence of SST and SIC: 'false' (climatologic) or 'true']"
#    sst_sic_dataset="[SST/SIC dataset: amip2 (default) or XXXX _no other choice for the moment_]"
#    flag_CMIP5_ozon="[usage of CMIP5 ozon: 'false' (obsolete climatologic input) or 'true' (CMIP5)]"
#    flag_time_dep_sol_irr="[time-dependence of solar irradiance: 'false' (climatologic) or 'true' (time-dep)]"
#    flag_kinne_aerosols="[flag to use Kinne aerosols (radiative prop + CCN (time-dep)): 'false' (no Kinne aerosols) or 'true']"
#    flag_stenchikov_aerosols="[flag to use Stenchikov volcanic aerosols (radiative prop): 'false' (no volcano aerosols) or 'true']"
#    flag_crowley_aerosols="[flag to use crowley volcanic aerosols (radiative prop): 'false' (no volcano aerosols) or 'true']"
#    flag_submclim_aerosols="[flag to use submodel climatology volcanic aerosols (radiative prop): 'false' (no volcano aerosols) or 'true']"
#    scenario="[future climate scenarios for GHG, ozone and aerosol climatology: RCP45, XXX (case insensitive)]"
#    flag_nudg="[flag to switch on nudging: 'false' (no nudging) or 'true']"
#    flag_nudg_netcdf="[flag to switch on netcdf format for nudging: 'false' (binary) or 'true' (netcdf)]"
#    aero_dataset="[aerocom or aerocom_II (case sensitive)]" # --> only if echam6-hammoz
#
#----------------------------------------------------------------------------

#----------------------------------------------
# Machine-specific (customize your path here):
#----------------------------------------------

input_basepath=/work/n02/n02/kipling/input/ECHAM6-HAMMOZ/${input_files_version}      # where all input files except nudging data is to be found
nudg_basepath=/work/n02/n02/kipling/input/nudging                              # where all nudging data is to be found

#--------------------------------------------------
# You shouldn't need to modify the following
# unless you use a non-standard file organization
# or additional options for specific datasets 
#--------------------------------------------------

echo "----" | tee -a $log_file
echo "Starting input files linking process into $exp_dir..." | tee -a $log_file

#------------------------------
# Initialization / Flag checks
#------------------------------

  # Note: the flag_check function is stored in [toolkit root path]/lib/get_input_file_choices.sh
  #       it takes 3 or more arguments:
  #        * a logical flag for the check to be case insensitive (true) or not (false)
  #        * the string name of the variable to check (!!not the variable itself!!)
  #        * a list of all possible values

  #-- flag_time_dep_sst_sic

      # flag_time_dep_sst_sic is automatically set prior to executing this script, based on lamip:
      #   lamip=.false. --> flag_time_dep_sst_sic=false        
      #   lamip=.true.  --> flag_time_dep_sst_sic=true
      # uncomment the following line to override the automatic setting:
      # flag_time_dep_sst_sic=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_time_dep_sst_sic ] ; then
         flag_check $case_insensitive flag_time_dep_sst_sic ${possible_values[*]}
      else
         echo "Error! flag_time_dep_sst_sic is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- sst_sic_dataset

      # sst_sic_dataset is set by default to 'amip2', you may set an alternate value below:
      # uncomment the following line to override the automatic setting:
      # sst_sic_dataset=XXX

      possible_values=( amip2 ) # add additional values in case you want to use an alternate sst/sic dataset
      case_insensitive=true
      if [ ! -z $sst_sic_dataset ] ; then
         flag_check $case_insensitive sst_sic_dataset ${possible_values[*]}
      else
         echo "Error! sst_sic_dataset is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- flag_CMIP5_ozon

      # flag_CMIP5_ozon is automatically set prior to executing this script, based on io3:
      #  if io3=4   --> flag_CMIP5_ozon=true
      #  flag_CMIP5_ozon=false otherwise
      # uncomment the following line to override the automatic setting:
      # flag_CMIP5_ozon=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_CMIP5_ozon ] ; then
         flag_check $case_insensitive flag_CMIP5_ozon ${possible_values[*]}
      else
         echo "Error! flag_CMIP5_ozon is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- flag_time_dep_sol_irr

      # flag_time_dep_sol_irr is automatically set prior to executing this script, based on isolrad:
      # if isolrad=1   --> flag_time_dep_sol_irr=true
      # flag_time_dep_sol_irr=false otherwise
      # uncomment the following line to override the automatic setting:
      # flag_time_dep_sol_irr=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_time_dep_sol_irr ] ; then
         flag_check $case_insensitive flag_time_dep_sol_irr ${possible_values[*]}
      else
         echo "Error! flag_time_dep_sol_irr is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- flag_kinne_aerosols

      # flag_kinne_aerosols is automatically set prior to executing this script, based on iaero:
      # if iaero=3,5,6 or 7 --> flag_kinne_aerosols=true
      # flag_kinne_aerosols=false otherwise  
      # uncomment the following line to override the automatic setting:
      # flag_kinne_aerosols=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_kinne_aerosols ] ; then
         flag_check $case_insensitive flag_kinne_aerosols ${possible_values[*]}
      else
         echo "Error! flag_kinne_aerosols is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- flag_stenchikov_aerosols

      # flag_stenchikov_aerosols is automatically set prior to executing this script, based on iaero:
      # if iaero=5 or 6 --> flag_stenchikov_aerosols=true
      # uncomment the following line to override the automatic setting:
      # flag_stenchikov_aerosols=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_stenchikov_aerosols ] ; then
         flag_check $case_insensitive flag_stenchikov_aerosols ${possible_values[*]}
      else
         echo "Error! flag_stenchikov_aerosols is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi
   
  #-- flag_crowley_aerosols

      # flag_crowley_aerosols is automatically set prior to executing this script, based on iaero:
      # if iaero=7 --> flag_crowley_aerosols=true
      # uncomment the following line to override the automatic setting:
      # flag_crowley_aerosols=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_crowley_aerosols ] ; then
         flag_check $case_insensitive flag_crowley_aerosols ${possible_values[*]}
      else
         echo "Error! flag_crowley_aerosols is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- flag_submclim_aerosols

      # flag_submclim_aerosols is automatically set prior to executing this script, based on iaero:
      # if iaero=6 --> flag_submclim_aerosols=true
      # uncomment the following line to override the automatic setting:
      # flag_submclim_aerosols=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_submclim_aerosols ] ; then
         flag_check $case_insensitive flag_submclim_aerosols ${possible_values[*]}
      else
         echo "Error! flag_submclim_aerosols is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- scenario

      # scenario is defined in the settings file:

      possible_values=( 'rcp[0-9][0-9]' ) # add additional patterns in case you want to use an 
                                          # alternate scenario
      case_insensitive=true
      if [ ! -z $scenario ] ; then
         flag_check $case_insensitive scenario "${possible_values[*]}"
      else
         echo "Error! scenario is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- flag_nudg

      # flag_nudg is automatically set prior to executing this script, based on lnudge:
      # if lnudge=.true.  --> flag_nudg=true
      # if lnudge=.false. --> flag_nudg=false
      # uncomment the following line to override the automatic setting:
      # flag_nudg=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_nudg ] ; then
         flag_check $case_insensitive flag_nudg ${possible_values[*]}
      else
         echo "Error! flag_nudg is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- flag_nudg_netcdf

      # flag_nudg_netcdf is automatically set prior to executing this script, based on inudgformat:
      # if inudgformat=2 --> flag_nudg_netcdf=true
      # flag_nudg_netcdf=false otherwise
      # uncomment the following line to override the automatic setting:
      # flag_nudg_netcdf=XXX

      possible_values=( true false )
      case_insensitive=true
      if [ ! -z $flag_nudg_netcdf ] ; then
         flag_check $case_insensitive flag_nudg_netcdf ${possible_values[*]}
      else
         echo "Error! flag_nudg_netcdf is not defined! Please review your symlinks script!" | tee -a $log_file
         echo "Exiting"
         exit 1
      fi

  #-- aero_dataset (echam6-hammoz specific)

      # aero_dataset is defined in the settings file
      if $this_model_flag_with_hammoz ; then
         possible_values=( aerocom aerocom_II ) # add additional values in case you want to use an alternate
                                                # aerosol emissions dataset
         case_insensitive=false
         if [ ! -z $aero_dataset ] ; then
            flag_check $case_insensitive aero_dataset ${possible_values[*]}
         else
            echo "Error! aero_dataset is not defined! Please review your symlinks script!" | tee -a $log_file
            echo "Exiting"
            exit 1
         fi
      fi

#---------------------------------
# Summary of necessary variables:
#---------------------------------

echo                                                 | tee -a $log_file
echo "with:"                                         | tee -a $log_file
echo                                                 | tee -a $log_file
echo "input_basepath="$input_basepath                | tee -a $log_file
echo "nudg_basepath="$nudg_basepath                  | tee -a $log_file
echo "exp_dir="$exp_dir                              | tee -a $log_file
echo "hres="$hres                                    | tee -a $log_file
echo "vres="$vres                                    | tee -a $log_file
echo "oceres="$oceres                                | tee -a $log_file
echo "start_yyyymm="$start_yyyymm                    | tee -a $log_file
echo "stop_yyyymm="$stop_yyyymm                      | tee -a $log_file
echo "start_year_m1="$start_year_m1                  | tee -a $log_file
echo "stop_year_p1="$stop_year_p1                    | tee -a $log_file
echo "start_yyyymm_m1="$start_yyyymm_m1              | tee -a $log_file
echo "stop_yyyymm_p1="$stop_yyyymm_p1                | tee -a $log_file
echo "flag_time_dep_sst_sic="$flag_time_dep_sst_sic  | tee -a $log_file
echo "sst_sic_dataset="$sst_sic_dataset              | tee -a $log_file
echo "flag_CMIP5_ozon="$flag_CMIP5_ozon              | tee -a $log_file
echo "flag_time_dep_sol_irr"=$flag_time_dep_sol_irr  | tee -a $log_file
echo "flag_kinne_aerosols"=$flag_kinne_aerosols      | tee -a $log_file
echo "flag_stenchikov_aerosols"=$flag_stenchikov_aerosols | tee -a $log_file
echo "flag_crowley_aerosols"=$flag_crowley_aerosols       | tee -a $log_file
echo "flag_submclim_aerosols"=$flag_submclim_aerosols     | tee -a $log_file
echo "scenario"=$scenario                            | tee -a $log_file
echo "flag_nudg="$flag_nudg                          | tee -a $log_file
echo "flag_nudg_netcdf="$flag_nudg_netcdf            | tee -a $log_file

if $this_model_flag_with_hammoz ; then # echam6-hammoz specific
   echo "aero_dataset="$aero_dataset      | tee -a $log_file
fi
echo | tee -a $log_file

#---------
# Process
#---------

cd $exp_dir

#--------------------------------------
# Removing pre-existing symbolic links 
#--------------------------------------

#SF this should not be necessary, but is conserved for security (in case 'ln' is not GNU ln)

find . -type l -exec \rm -f {} \;

#--------
# ECHAM6  
#--------

ln -sf ${input_basepath}/echam6/${hres}/${hres}_O3clim2.nc                   unit.21 #!!!WARNING!!! this is only used when 
                                                                                     # io3=3 see comment in 'Time-dep ozone'
ln -sf ${input_basepath}/echam6/${hres}/${hres}${vres}_jan_spec.nc           unit.23
ln -sf ${input_basepath}/echam6/${hres}/${hres}${oceres}_jan_surf.nc         unit.24
ln -sf ${input_basepath}/echam6/${hres}/${hres}${oceres}_VLTCLIM.nc          unit.90
ln -sf ${input_basepath}/echam6/${hres}/${hres}${oceres}_VGRATCLIM.nc        unit.91
ln -sf ${input_basepath}/echam6/${hres}/${hres}_TSLCLIM2.nc                  unit.92

ln -sf  ${input_basepath}/echam6/surrta_data               rrtadata
ln -sf  ${input_basepath}/echam6/rrtmg_lw.nc               rrtmg_lw.nc
ln -sf  ${input_basepath}/echam6/hdpara.nc                 hdpara.nc
ln -sf  ${input_basepath}/echam6/hdstart.nc                hdstart.nc
ln -sf  ${input_basepath}/echam6/ECHAM6_CldOptProps.nc     ECHAM6_CldOptProps.nc

ln -sf ${input_basepath}/echam6/greenhouse_${scenario}.nc  greenhouse_gases.nc

#---------
# JS-BACH  
#---------

ln -sf  ${input_basepath}/echam6/jsbach/lctlib_nlct21.def_rev4154 lctlib.def
ln -sf  ${input_basepath}/jsbach/${hres}/jsbach_${hres}${oceres}_${ntiles}tiles_1992.nc jsbach.nc

#--------------------------
# Climatologic SST and SIC
#--------------------------

ln -sf ${input_basepath}/echam6/${hres}/amip2/${hres}_amip2sst_1979-2008_mean.nc unit.20
ln -sf ${input_basepath}/echam6/${hres}/amip2/${hres}_amip2sic_1979-2008_mean.nc unit.96

#----------------------------
# Time-dep SST & SIC 
#----------------------------

if $flag_time_dep_sst_sic ; then

   if [[ "$sst_sic_dataset" == "amip2" ]] ; then # use amip2 data

       for ((year=$start_year_m1; year<=$stop_year_p1; year++)) ; do
           ln -sf ${input_basepath}/echam6/${hres}/amip2/${hres}_amip2sst_${year}.nc sst${year}
           ln -sf ${input_basepath}/echam6/${hres}/amip2/${hres}_amip2sic_${year}.nc ice${year}
       done

   # uncomment the following in case of an alternate SST / SIC dataset:

   # elif [[ "$sst_sic_dataset" == "XXXX" ]] ; then # use XXXX data

       #for ((year=$start_year_m1; year<=$stop_year_p1; year++)) ; do
       #    ln -sf ${input_basepath}/echam6/${hres}/XXXX/XXXX.nc sst${year}
       #    ln -sf ${input_basepath}/echam6/${hres}/XXXX/XXXX.nc ice${year}
       #done
   fi

fi

#----------------
# Time-dep ozone
#----------------
#
# !!WARNING!! (SF, 2012.08)
# Due to a limitation in the current echam6 code (echam6.1.0), the only way to use climatologic CMIP5 ozone
# is to fake a time-dependent input, because the reading of 'unit.21' which is normally meant for climatologic ozone,
# is coded in a way that is only compliant to ${hres}_O3clim2.nc!! 
# Hopefully this is improved in future versions!!
#
# In order to decipher whether the user wants a *climatology* or year-dependent input, I chose to bound it
# to temp-dependent SSTs: 
#     - if $flag_time_dep_sst_sic is true (ie lamip=.true.), then ozone files will be truely year-dependent.
#     - if $flag_time_dep_sst_sic is false (ie lamip=.false.), then ozone files will all point to the ozone 
#        CMIP5 climatology
#
# This should make sense, but please adapt it if this is bad strategy for purposes!!
#

if $flag_CMIP5_ozon ; then  # ie io3=4

   for ((year=$start_year_m1; year<=$stop_year_p1; year++)) ; do

       if $flag_time_dep_sst_sic ; then  # true year-dep input, see comment above

          if [[ "$year" -lt "2009" ]] ; then # no scenario
             scenario_str=""
          else                               # take user-defined scenario
             scenario_str=`echo $scenario | tr '[:lower:]' '[:upper:]'`"_"
          fi
          ln -sf ${input_basepath}/echam6/${hres}/ozone2/${hres}_ozone_CMIP5_${scenario_str}${year}.nc ozon${year}

       else # fake year-dep input for using the CMIP5 climatology
          ln -sf ${input_basepath}/echam6/${hres}/${hres}_ozone_CMIP5_1979-1988.nc ozon${year}
       fi
   done

fi

#---------------------------
# Time-dep solar irradiance
#---------------------------

if $flag_time_dep_sol_irr ; then

   for ((year=$start_year_m1; year<=$stop_year_p1; year++)) ; do
       ln -sf ${input_basepath}/echam6/solar_irradiance/swflux_14band_${year}.nc swflux_${year}.nc
   done

fi

#-----------------------------------------------------
# Time-dep Kinne aerosols (including CCN climatology) 
#-----------------------------------------------------

if $flag_kinne_aerosols ; then

   for ((year=$start_year_m1; year<=$stop_year_p1; year++)) ; do
       if [[ "$year" -lt "2009" ]] ; then # no scenario
          scenario_str=""
       else                               # take user-defined scenario
          scenario_str=`echo $scenario | tr '[:upper:]' '[:lower:]' `"_"
       fi

       ln -sf ${input_basepath}/echam6/${hres}/aero2/${hres}_aeropt_kinne_sw_b14_fin_${scenario_str}${year}.nc aero_fine_${year}.nc
       ln -sf ${input_basepath}/echam6/${hres}/aero2/${hres}_aeropt_kinne_sw_b14_coa.nc aero_coarse_${year}.nc
       ln -sf ${input_basepath}/echam6/${hres}/aero2/${hres}_aeropt_kinne_lw_b16_coa.nc aero_farir_${year}.nc

       #>> SFtemp: prepare link for CCN data when available
       #ln -sf ${input_basepath}/echam6/${hres}/aero2/CCN_${hres}_1km-8km_${year}.nc ccn${year}.nc
       #<< SFtemp
   done

fi

#---------------------------------------
# Time-dep Stenchikov volcanic aerosols  
#---------------------------------------

if $flag_stenchikov_aerosols ; then

   for ((year=$start_year_m1; year<=$stop_year_p1; year++)) ; do

       ln -sf ${input_basepath}/echam6/${hres}/volcano_aerosols/strat_aerosol_sw_${hres}_${year}.nc strat_aerosol_sw_${year}.nc
       ln -sf ${input_basepath}/echam6/${hres}/volcano_aerosols/strat_aerosol_ir_${hres}_${year}.nc strat_aerosol_ir_${year}.nc

   done

fi

#---------------------------
# Crowley volcanic aerosols  
#---------------------------

if $flag_crowley_aerosols ; then

   ln -sf ${input_basepath}/echam6/volc_data aodreff_crow.dat  # SF note: volc_data is referred to as
                                                               # "ici5d-ad800-1999.asc" in the echam6
							       # users guide	
   ln -sf ${input_basepath}/echam6/b30w120 aero_volc_tables.dat

fi

#------------------------------------------------------------
# Submodel climatology for volcanic aerosols (e.g. from HAM)  
#------------------------------------------------------------

#SF: the following does not exist yet!
#if $flag_submclim_aerosols ; then

   #ln -sf ${input_basepath}/echam6/XXXX/XXXX.nc aoddz_ham_yyyy.nc

#fi

#-------
# ISCCP  
#-------
   
#>>SF: this is not re-implemented in echam6 yet
#ln -sf ${input_basepath}/echam6/invtau.formatted invtau.formatted
#ln -sf ${input_basepath}/echam6/tautab.formatted tautab.formatted
#<<SF
   
#-----------------
# HAMMOZ-specific
#-----------------

if $this_model_flag_with_hammoz ; then # echam6-hammoz specific
   #---------------------------------
   # HAM soil and surface properties
   #---------------------------------
   
   ln -sf ${input_basepath}/hammoz/${hres}/soilpHfrac_${hres}.nc xtsoil.nc
   ln -sf ${input_basepath}/hammoz/${hres}/xtsurf_v2_${hres}.nc surface_properties.nc
   
   #-------------------------
   # Emissions specification 
   #-------------------------

   # --> All specs taken care of by emi_spec.txt.
   # --> The setting of the basepath, emi_basepath, is handled by jobsubm_echam.sh
   
   #--------------------
   # Volcanic emissions
   #--------------------
   
   ln -sf ${input_basepath}/emissions_${aero_dataset}/explosive_volcanos.dat explosive_volcanos.dat
   ln -sf ${input_basepath}/emissions_${aero_dataset}/continuous_volcanos.dat continuous_volcanos.dat
   
   #--------------------------
   # Oceanic emissions of DMS
   #--------------------------
   
   ln -sf ${input_basepath}/emissions_${aero_dataset}/${hres}/emiss_fields_dms_sea_monthly_${hres}.nc conc_aerocom_DMS_sea.nc 
   
   #---------------------------------------------------
   # Boundary conditions for the dust emissions scheme
   #---------------------------------------------------
   
   ln -sf ${input_basepath}/hammoz/${hres}/pot_sources.${hres}.nc         dust_pot_sources.nc
   ln -sf ${input_basepath}/hammoz/${hres}/ndvi_lai_eff.12m.${hres}.nc    ndvi_lai_eff.12m.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type2.${hres}.nc          soil_type2.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type3.${hres}.nc          soil_type3.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type4.${hres}.nc          soil_type4.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type6.${hres}.nc          soil_type6.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type13.${hres}.nc         soil_type13.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type14.${hres}.nc         soil_type14.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type15.${hres}.nc         soil_type15.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type16.${hres}.nc         soil_type16.nc
   ln -sf ${input_basepath}/hammoz/${hres}/soil_type17.${hres}.nc         soil_type17.nc
   ln -sf ${input_basepath}/hammoz/${hres}/surface_rough.12m.${hres}.nc   surface_rough.12m.nc
   
   #-----------------------------------------------------
   # MEGANV2 emission factors for biogenic VOC emissions
   #----------------------------------------------------
   
   ln -sf ${input_basepath}/emissions_${aero_dataset}/${hres}/megan_emission_factors_${hres}.nc megan_emission_factors.nc
   
   #----------
   # SOA
   #----------
   # Taken care of by emi_spec.txt
   
   #----------------------------------------------------------------
   # Prescribed oxidant concentrations for the HAM chemistry scheme 
   #----------------------------------------------------------------
   
   ln -sf ${input_basepath}/hammoz/${hres}/ham_oxidants_monthly_${hres}${vres}_macc.nc ham_oxidants_monthly.nc
   
   #--------------------------------------
   # Ion production rate from cosmic rays 
   #--------------------------------------
   
   ln -sf ${input_basepath}/hammoz/solmin.txt gcr_ipr_solmin.txt
   ln -sf ${input_basepath}/hammoz/solmax.txt gcr_ipr_solmax.txt
   
   #--------------------------------------------
   # PARNUC neutral and charge nucleation scheme
   #--------------------------------------------
   
   ln -sf ${input_basepath}/hammoz/parnuc.15H2SO4.A0.total.nc parnuc.15H2SO4.nc
   
   #--------------------------------------------------
   # Aerosol water uptake (using Kappa-Koehler theory)
   #--------------------------------------------------
   
   ln -sf ${input_basepath}/hammoz/lut_kappa.nc lut_kappa.nc
   
   #---------------------------
   # Aerosol optical properties
   #---------------------------
   
   ln -sf ${input_basepath}/hammoz/lut_optical_properties_new.nc lut_optical_properties.nc
   ln -sf ${input_basepath}/hammoz/lut_optical_properties_lw.nc  lut_optical_properties_lw.nc
   
fi # end echam6-hammoz specific

#---------
# Nudging
#---------

if $flag_nudg ; then

   imo=10#$exp_start_month
   iyear=$exp_start_year
   idate=$exp_start_yyyymm
   previous_prefix="" # cosmetics. Just for nice output!
   if $flag_nudg_netcdf ; then
      declare -a exts=( "nc" )
      dir_ext="_netcdf"
      format="netcdf"
   else
      declare -a exts=( "div" "sst" "stp" "vor" )
      dir_ext=""
      format="binary"
   fi

   #-- Initialization of the default preferred order for the nudging prefixes, if not already set by user
   if [ -z $nudg_prefix_order ] ; then 
      declare -a nudg_prefix_order=( "eraia" "era40"  "ana" )
   fi

   #-- Loop over YYYYMM:
   while ((idate<=$stop_yyyymm)) ; do

       #-- Loop through all potential nudging data prefixes to find the first valid one
       flag_not_found=true
       for prefix in ${nudg_prefix_order[*]} ; do
           if [ -d ${nudg_basepath}/${prefix}/${prefix}${hres}${vres}_${idate}${dir_ext} ] ; then
              flag_not_found=false
              break
           fi
       done

       if $flag_not_found ; then
          #-- Try any pattern (*) and pick up the first found by alphabetical order:
          nudg_subdir=`find ${nudg_basepath} -maxdepth 2 -type d \
                       -name "*${hres}${vres}_${idate}${dir_ext}" 2> /dev/null | sort | head -1`

          #-- Raise an error if nothing found:
          if [[ "$nudg_subdir" == "" ]] ; then
             echo "ERROR! Nudging data for ${hres}${vres} at $idate in $format format does not seem to be available in ${nudg_basepath}." | tee -a $log_file
             echo "You may check if alternate format exists for this date and change the NDGCTL namelist parameters accordingly." | tee -a $log_file
             echo "Exiting" | tee -a $log_file
             exit 1
          fi

          #-- Get prefix
          prefix=`basename $nudg_subdir`
          prefix=${prefix%%${hres}${vres}_${idate}${dir_ext}}
       fi

       #-- Prints out the prefix, but only when it changes to avoid cluttering the log:
       if [[ "$prefix" != "$previous_prefix" ]]  ; then
          echo "Nudging dataset from $idate on: $prefix" | tee -a $log_file
          previous_prefix=$prefix
       fi

       nudg_name="${prefix}${hres}${vres}_${idate}"

       #-- make the links:
       for ext in ${exts[*]} ; do
           ln -sf ${nudg_basepath}/${prefix}/${nudg_name}${dir_ext}/${nudg_name}.${ext} ndg${idate}.${ext}
       done

       #-- additional linking for the edges 
       #   (fake nudging files for exp_start_yyyymm_m1 and stop_yyyymm_p1)
       #   Note: this is possible due to the fact that any nudging file contains
       #         the necessary timsteps BEFORE and AFTER the current month
       #         for echam to perform the correct interpolation

       if [[ "$idate" -eq "$exp_start_yyyymm" ]] ; then

          for ext in ${exts[*]} ; do
              ln -sf ${nudg_basepath}/${prefix}/${nudg_name}${dir_ext}/${nudg_name}.${ext} ndg${exp_start_yyyymm_m1}.${ext}
          done

       elif [[ "$idate" -eq "$stop_yyyymm" ]] ; then

          for ext in ${exts[*]} ; do
              ln -sf ${nudg_basepath}/${prefix}/${nudg_name}${dir_ext}/${nudg_name}.${ext} ndg${stop_yyyymm_p1}.${ext}
          done

       fi

       #-- increment idate (YYYYMM):
       ((imo=$imo+1))
       if [[ "$imo" -eq "13" ]] ; then
          imo=1
          ((iyear=$iyear+1))
       fi
       idate=${iyear}`printf '%02d' $imo`

   done

fi # end nudging

#--------------------------------
# Get back to previous directory
#--------------------------------

cd $OLDPWD

echo  | tee -a $log_file
