; ##############################################################################################
; NAME: BATCH_DOIT_Priestley_Taylor_PET.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/01/2011
; DLM: 13/01/2011
;
; DESCRIPTION:  This tool calculates Priestley-Taylor potential evapotranspiration (PET).
;
; INPUT:       
;
; OUTPUT:      
;               
; PARAMETERS:  
;            
; NOTES:       
;               
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_Priestley_Taylor_PET
  ;---------------------------------------------------------------------------------------------
  ; Get start time
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Priestley_Taylor_PET'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; Input/Output:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; Set parameters:
  Albedo = 0.15 ; Ratio of the radiation reflected from a target to the radiation falling on the target (reflected/incident)
  RMair = 0.02897 ; Molecular weight of dry air [kg/mol]
  RMh2o = 0.018016 ; Molecular weight of water [kg/mol]
  RMC = 0.012000 ; Atomic weight of carbon-12 [kg/mol]
  Rgas = 8.3143 ; Universal gas constant [J/mol/K]
  Rlat = 2.45e6 ; Evaporative latent heat of water (latent heat of vaporization) [J/kg]
  RhoW = 1000.0 ; Liquid water density [kg/m3]
  cPA = 1004.0 ; Isobaric specific heat of air (specific heat of dry air at constant pressure) [J/kg] 
  Ga = 0.05 ; Aerodynamic conductance for heat and water vapour transfer 
  PMB = 1000.0 ; Air [Atmospheric] pressure [Pa]
  fDay = 0.5 ; The fraction of daylight hours
  sDay = 86400.0 ; Seconds per day  
  PT_Coefficient = 1.26 ; Priestley-Taylor coefficient
  SB_Constant = 5.67e-8 ; Stefan-Boltzmann constant [W/m2/K4]  
  gamma = 0.665e-3 ; Psychrometric constant [kPa] (or 66 Pa) - gamma = (cPA*PMB) / (Rlat*(RMh2o/RMair))
  ;---------------------------------------------------------------------------------------------
  ; Set variables:
  FILTER = ['*.tif','*.img','*.flt','*.bin'] ; File-type filter
  ;--------------
  ; Minimum air temperature [degC]
  ;Path = '\\File-wron\TimeSeries\Climate\usilo\tmin'  
  Path = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\Temp'
  IN_TMin = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input Minimum Air Temperature Data', FILTER=FILTER, /MULTIPLE_FILES)
  IN_TMin = IN_TMin[SORT(IN_TMin)] ; Sort the input file list
  ; Remove the file path from the input file names:
  FNA_START = STRPOS(IN_TMin, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path)
  FNA_LENGTH = (STRLEN(IN_TMin)-FNA_START)-4 ; Get the length of each path-less file name
  FNA_TMin = MAKE_ARRAY(N_ELEMENTS(IN_TMin), /STRING) ; Create an array to store the input file names
  FOR a=0, N_ELEMENTS(IN_TMin)-1 DO BEGIN ; Fill the file name array:
    FNA_TMin[a] += STRMID(IN_TMin[a], FNA_START[a], FNA_LENGTH[a]) ; Get the a-the file name (trim away the file path)
  ENDFOR
  ;--------------
  ; Maximum air temperature [degC]
  ;Path = '\\File-wron\TimeSeries\Climate\usilo\tmax'
  IN_TMax = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input Maximum Air Temperature Data', FILTER=FILTER, /MULTIPLE_FILES) 
  IN_TMax = IN_TMax[SORT(IN_TMax)] ; Sort the input file list
  ; Remove the file path from the input file names:
  FNA_START = STRPOS(IN_TMax, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path)
  FNA_LENGTH = (STRLEN(IN_TMax)-FNA_START)-4 ; Get the length of each path-less file name
  FNA_TMax = MAKE_ARRAY(N_ELEMENTS(IN_TMax), /STRING) ; Create an array to store the input file names
  FOR a=0, N_ELEMENTS(IN_TMax)-1 DO BEGIN ; Fill the file name array:
    FNA_TMax[a] += STRMID(IN_TMax[a], FNA_START[a], FNA_LENGTH[a]) ; Get the a-the file name (trim away the file path)
  ENDFOR
  ;--------------
  ; Solar radiation [MJ m-2]
  ;Path = '\\File-wron\TimeSeries\Climate\usilo\rad'
  IN_Solar = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input Solar Radiation Data', FILTER=FILTER, /MULTIPLE_FILES) 
  IN_Solar = IN_Solar[SORT(IN_Solar)] ; Sort the input file list
  ; Remove the file path from the input file names:
  FNA_START = STRPOS(IN_Solar, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path)
  FNA_LENGTH = (STRLEN(IN_Solar)-FNA_START)-4 ; Get the length of each path-less file name
  FNA_Solar = MAKE_ARRAY(N_ELEMENTS(IN_Solar), /STRING) ; Create an array to store the input file names
  FOR a=0, N_ELEMENTS(IN_Solar)-1 DO BEGIN ; Fill the file name array:
    FNA_Solar[a] += STRMID(IN_Solar[a], FNA_START[a], FNA_LENGTH[a]) ; Get the a-the file name (trim away the file path)
  ENDFOR
  ;--------------
  ; Albedo: Ratio of the radiation reflected from a target to the radiation falling on the target (reflected/incident
  ;Path = '\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MCD43B3.005'
  ;IN_Albedo = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input Albedo Data', FILTER=FILTER, /MULTIPLE_FILES)
  ;IN_Albedo = IN_Albedo[SORT(IN_Albedo)] ; Sort the input file list
  ;; Remove the file path from the input file names:
  ;FNA_START = STRPOS(IN_Albedo, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path)
  ;FNA_LENGTH = (STRLEN(IN_Albedo)-FNA_START)-4 ; Get the length of each path-less file name
  ;FNA_TMin = MAKE_ARRAY(N_ELEMENTS(IN_Albedo), /STRING) ; Create an array to store the input file names
  ;FOR a=0, N_ELEMENTS(IN_Albedo)-1 DO BEGIN ; Fill the file name array:
  ;  FNA_TMin[a] += STRMID(IN_Albedo[a], FNA_START[a], FNA_LENGTH[a]) ; Get the a-the file name (trim away the file path)
  ;ENDFOR  
  ;--------------
  ; Atmospheric vapour pressure [Pa]
  ;Path = '\\File-wron\TimeSeries\Climate\usilo\vp'
  ;IN_pe = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input Atmospheric Vapour Pressure Data', FILTER=FILTER, /MULTIPLE_FILES)
  ;IN_pe = IN_pe[SORT(IN_pe)] ; Sort the input file list
  ;; Remove the file path from the input file names:
  ;FNA_START = STRPOS(IN_pe, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path)
  ;FNA_LENGTH = (STRLEN(IN_pe)-FNA_START)-4 ; Get the length of each path-less file name
  ;FNA_TMin = MAKE_ARRAY(N_ELEMENTS(IN_pe), /STRING) ; Create an array to store the input file names
  ;FOR a=0, N_ELEMENTS(IN_pe)-1 DO BEGIN ; Fill the file name array:
  ;  FNA_TMin[a] += STRMID(IN_pe[a], FNA_START[a], FNA_LENGTH[a]) ; Get the a-the file name (trim away the file path)
  ;ENDFOR  
  ;---------------------------------------------------------------------------------------------
  ; Set Date:
  ;--------------
  ; Minimum air temperature [degC]
  DAY_TMin = STRMID(FNA_TMin, 6, 2) ; Manipulate the filename array to get the DAY
  MONTH_TMin = STRMID(FNA_TMin, 4, 2) ; Manipulate the filename array to get the MONTH                   
  YEAR_TMin = STRMID(FNA_TMin, 0, 4) ; Manipulate the filename array to get the YEAR 
  DATES_TMin = JULDAY(MONTH_TMin, DAY_TMin, YEAR_TMin) ; Convert file dates to 'JULDAY' format
  IN_TMin = IN_TMin[SORT(DATES_TMin)] ; Sort file names by date
  FNA_TMin = FNA_TMin[SORT(DATES_TMin)] ; Sort file name array by date
  DATES_TMinU = DATES_TMin[UNIQ(DATES_TMin)] ; Get unique input dates
  DATES_TMinU = DATES_TMinU[SORT(DATES_TMinU)] ; Sort the unique dates    
  DATES_TMinU = DATES_TMinU[UNIQ(DATES_TMinU)] ; Get unique input dates
  ;--------------
  ; Maximum air temperature [degC]
  DAY_TMax = STRMID(FNA_TMax, 6, 2) ; Manipulate the filename array to get the DAY
  MONTH_TMax = STRMID(FNA_TMax, 4, 2) ; Manipulate the filename array to get the MONTH                   
  YEAR_TMax = STRMID(FNA_TMax, 0, 4) ; Manipulate the filename array to get the YEAR 
  DATES_TMax = JULDAY(MONTH_TMax, DAY_TMax, YEAR_TMax) ; Convert file dates to 'JULDAY' format
  IN_TMax = IN_TMax[SORT(DATES_TMax)] ; Sort file names by date
  FNA_TMax = FNA_TMax[SORT(DATES_TMax)] ; Sort file name array by date
  DATES_TMaxU = DATES_TMax[UNIQ(DATES_TMax)] ; Get unique input dates
  DATES_TMaxU = DATES_TMaxU[SORT(DATES_TMaxU)] ; Sort the unique dates    
  DATES_TMaxU = DATES_TMaxU[UNIQ(DATES_TMaxU)] ; Get unique input dates
  ;--------------
  ; Solar radiation [MJ m-2]
  DAY_Solar = STRMID(FNA_Solar, 6, 2) ; Manipulate the filename array to get the DAY
  MONTH_Solar = STRMID(FNA_Solar, 4, 2) ; Manipulate the filename array to get the MONTH                   
  YEAR_Solar = STRMID(FNA_Solar, 0, 4) ; Manipulate the filename array to get the YEAR 
  DATES_Solar = JULDAY(MONTH_Solar, DAY_Solar, YEAR_Solar) ; Convert file dates to 'JULDAY' format
  IN_Solar = IN_Solar[SORT(DATES_Solar)] ; Sort file names by date
  FNA_Solar = FNA_Solar[SORT(DATES_Solar)] ; Sort file name array by date
  DATES_SolarU = DATES_Solar[UNIQ(DATES_Solar)] ; Get unique input dates
  DATES_SolarU = DATES_SolarU[SORT(DATES_SolarU)] ; Sort the unique dates    
  DATES_SolarU = DATES_SolarU[UNIQ(DATES_SolarU)] ; Get unique input dates
  ;--------------
  ; Albedo: Ratio of the radiation reflected from a target to the radiation falling on the target (reflected/incident)
  ;DAY_Albedo = STRMID(IN_Albedo, 6, 2) ; Manipulate the filename array to get the DAY
  ;MONTH_Albedo = STRMID(IN_Albedo, 4, 2) ; Manipulate the filename array to get the MONTH                   
  ;YEAR_Albedo = STRMID(IN_Albedo, 0, 4) ; Manipulate the filename array to get the YEAR 
  ;DATES_Albedo = JULDAY(MONTH_Albedo, DAY_Albedo, YEAR_Albedo) ; Convert file dates to 'JULDAY' format
  ;IN_Albedo = IN_Albedo[SORT(DATES_Albedo)] ; Sort file names by date
  ;FNA_Albedo = FNA_Albedo[SORT(DATES_Albedo)] ; Sort file name array by date
  ;DATES_AlbedoU = DATES_Albedo[UNIQ(DATES_Albedo)] ; Get unique input dates
  ;DATES_AlbedoU = DATES_AlbedoU[SORT(DATES_AlbedoU)] ; Sort the unique dates    
  ;DATES_AlbedoU = DATES_AlbedoU[UNIQ(DATES_AlbedoU)] ; Get unique input dates
  ;--------------
  ; Atmospheric vapour pressure [Pa]
  ;DAY_pe = STRMID(IN_pe, 6, 2) ; Manipulate the filename array to get the DAY
  ;MONTH_pe = STRMID(IN_pe, 4, 2) ; Manipulate the filename array to get the MONTH                   
  ;YEAR_pe = STRMID(IN_pe, 0, 4) ; Manipulate the filename array to get the YEAR 
  ;DATES_pe = JULDAY(MONTH_pe, DAY_pe, YEAR_pe) ; Convert file dates to 'JULDAY' format
  ;IN_pe = IN_pe[SORT(DATES_pe)] ; Sort file names by date
  ;FNA_pe = FNA_pe[SORT(DATES_pe)] ; Sort file name array by date
  ;DATES_peU = DATES_pe[UNIQ(DATES_pe)] ; Get unique input dates
  ;DATES_peU = DATES_peU[SORT(DATES_peU)] ; Sort the unique dates    
  ;DATES_peU = DATES_peU[UNIQ(DATES_peU)] ; Get unique input dates
  ;---------------------------------------------------------------------------------------------
  ; Select the input data type:
  DT_TMin = 4 ; Minimum air temperature [degC]
  DT_TMax = 4 ; Maximum air temperature [degC]
  DT_Solar = 4 ; Solar radiation [MJ m-2]
  ;DT_Albedo = 1 ; Albedo
  ;DT_pe = 4 ; Actual atmospheric vapour pressure [Pa]
  ; Reference:
    ; ['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    ; '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    ; '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    ; '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    ; '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    ; '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    ; '15 : ULONG64 : Unsigned 64-bit Integer'])
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  PATH='\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\Temp\'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF OUT_DIRECTORY EQ '' THEN RETURN ; Error check
  ;---------------------------------------------------------------------------------------------
  ; Set land mask:
  Land_IN = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO.Land.Mask.aust.5000m.img'
  IN_Land =  READ_BINARY(Land_IN, DATA_TYPE=4) ; Open land mask
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; Date loop:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(DATES_TMinU)-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    L_TIME = SYSTIME(1) ; Get the file loop start time
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; Get data:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    CALDAT, DATES_TMinU[i], iM, iD, iY ; Convert the i-th julday to calday
    DOY = JULDAY(iM, iD, iY) - JULDAY(1, 0, iY) ; Get day of year
    IF (iD LE 9) THEN iD = '0' + STRING(STRTRIM(iD,2)) ELSE iD = STRTRIM(iD,2) ; Add leading zero    
    IF (iM LE 9) THEN iM = '0' + STRING(STRTRIM(iM,2)) ELSE iM = STRTRIM(iM,2) ; Add leading zero
    IF (DOY LE 9) THEN DOY = '00' + STRING(STRTRIM(DOY,2)) ; Add leading zero
    IF (DOY LE 99) AND (DOY GT 9) THEN DOY = '0' + STRING(STRTRIM(DOY,2)) ; Add leading zero
    ;-------------- ; Get input files for the current date:
    ; Minimum air temperature [degC]    
    INDEX_TMin = WHERE(DATES_TMin EQ DATES_TMinU[i], COUNT) ; TMin file index
    IF COUNT GT 0 THEN TMin_IN = IN_TMin[INDEX_TMin] ; Get TMin files
    ;--------------
    ; Maximum air temperature [degC]
    INDEX_TMax = WHERE(DATES_TMax EQ DATES_TMinU[i], COUNT) ; TMax file index
    IF COUNT GT 0 THEN TMax_IN = IN_TMax[INDEX_TMax] ELSE TMax_IN = '-1' ; Get TMax files
    ;--------------
    ; Solar radiation [MJ m-2]
    INDEX_Solar = WHERE(DATES_Solar EQ DATES_TMinU[i], COUNT) ; Solar file index
    IF COUNT GT 0 THEN Solar_IN = IN_Solar[INDEX_Solar] ELSE Solar_IN = '-1' ; Get Solar files
    ;--------------
    ; Albedo: Ratio of the radiation reflected from a target to the radiation falling on the target (reflected/incident
    ;INDEX_Albedo = WHERE(DATES_Albedo EQ DATES_TMinU[i], COUNT) ; Albedo file index
    ;IF COUNT GT 0 THEN Albedo_IN = IN_Albedo[INDEX_Albedo] ELSE  Albedo_IN = -1 ; Get Albedo files
    ;--------------
    ; Atmospheric vapour pressure [Pa]
    ;INDEX_pe = WHERE(DATES_pe EQ DATES_TMinU[i], COUNT) ; pe file index
    ;IF COUNT GT 0 THEN pe_IN = IN_pe[INDEX_pe] ELSE pe_IN = -1 ; Get pe files
    ;-------------- ; Check for missing files
    TMin = READ_BINARY(TMin_IN, DATA_TYPE=DT_TMin) ; Open TMin_IN
    SIZE = N_ELEMENTS(TMin) ; Set the input raster size
    IF (TMax_IN EQ '-1') OR (Solar_IN EQ '-1') THEN BEGIN
      ; Create empty output arrays:
      PET_Out = MAKE_ARRAY(SIZE, VALUE=-999.00, /FLOAT)
    ENDIF ELSE BEGIN ; Get data:
      TMax = READ_BINARY(TMax_IN, DATA_TYPE=DT_TMax) ; Open TMax_IN
      Solar = READ_BINARY(Solar_IN, DATA_TYPE=DT_Solar) ; Open TMin_Solar
      ;Albedo = READ_BINARY(Albedo_IN, DATA_TYPE=DT_Albedo) ; Open Albedo_IN
      ;pe = READ_BINARY(TMin_pe, DATA_TYPE=DT_pe) ; Open TMin_pe
      ;-----------------------------------------------------------------------------------------
      ;*****************************************************************************************
      ; Calculate Priestley Taylor Potential Evapotranspiration (PET)
      ;*****************************************************************************************
      ;-----------------------------------------------------------------------------------------
      ; Ratio of the molecular weight of water vapour to the molecular weight of dry air
      rMwaterMair = (RMh2o/RMair)
      ; Average (effective) daytime air temperature
      Ta = TMin + 0.75*(TMax - TMin) 
      ; Average (effective) daytime air temperature in kelvin
      Tk = Ta + 273.16 
      ; Incoming shortwave radiation [W/m2]
      PhiS = (10.0^6.0 / (fDay * sDay)) * Solar
      ;--------------
      ; The following is not used in the WaterDyn26M Potential Evaporation Code (Raupach et al. 2009):
      ;  pes = 610.80*exp((17.27*Ta)/(237.30+Ta)) ; Atmospheric vapour pressure at saturation point (a.k.a es) [Pa]
      ;  pe = pes * TMin ; Estimated actual atmospheric vapour pressure [Pa] (SILO also provides gridded pe) 
      ;  fRH = pe / pes ; Relative humidity
      ;  Emissivity = 0.65*(pe/(Ta+273.16))^0.14 ; Atmospheric emissivity
      ;  PhiL = Emissivity*SB_Constant*(Tk)^4 ; Incoming longwave radiation [W/m2] Brutsaert method
      ;  Gr = (4.0 * Emissivity * SB_Constant * Tk^3) / (RhoA*cPA) ; Radiative conductance
      ;  PhiA = (1.0-Albedo)*PhiS + Emissivity*(PhiL-(SB_Constant*Tk^4)) ; Isothermal available energy flux
      ;--------------
      ; Incoming longwave radiation [W/m2] Swinbank method
      PhiL  = 335.97 * ((Tk / 293.0)^6.0)
      ; Air density [kg/m3] 
      RhoA = (RMair*100.0*PMB)/(Rgas*Tk) 
      ; Radiative conductance with Emissivity = 1
      Gr = (4.0 * SB_Constant * Tk^3.0) / (RhoA*cPA) 
      ; Radiative coupling (PP = Ga/(Ga+Gr))
      PP = Ga / (Ga + Gr)
      ; Isothermeral available energy flux with Emissivity = 1
      PhiA = (1.0-Albedo)*PhiS + (PhiL-(SB_Constant*Tk^4.0)) 
      ;--------------      
      ; Constrain air temperature to between -40.0 and 100.0 degC
      l = WHERE(Ta GT 100.0, COUNT_UP)
      IF (COUNT_UP GT 0) THEN Ta[l] = 100.0
      m = WHERE(Ta LT -40.0, COUNT_DOWN)
      IF (COUNT_DOWN GT 0) THEN Ta[m] = -40.0
      ;--------------
      ; Slope of saturation vapour pressure (the slope of the vapour pressure-temperature curve) [mb/K]
      delta = (4098.0 * (6.106*exp((17.27*Ta)/(237.3+Ta)))) / ((237.3+Ta)^2.0) ; Equivilant to: delta = 6.106*EXP(17.27*Ta/(237.3+Ta))*17.27*237.3/((237.3+Ta)^2)
      ; Ratio of latent to sensible heat content of saturated air (2.2 at 20degC, ~double every 13 degC)
      Epsilon = (Rlat/cPA) * ((rMwaterMair*delta)/PMB)
      ; Equilibrium latent heat flux
      PhiE = (PP*Epsilon*PhiA) / ((PP*Epsilon) + 1)
      ; Negative value check
      k = WHERE(PhiE LT 1.00, COUNT) ; Find where PhiE is less than 1.00
      IF (COUNT GT 0) THEN PhiE[k] = 1.00 ; Set PhiE values that are less than 1.00, to 1.00
      ; PT evapotranspiration [m/day]
      PET = PT_Coefficient*PhiE*((fDay*sDay)/(RhoW*Rlat))
      ; PT evapotranspiration [mm/day]
      PET = PET*1000.0
      ;--------------
      ; Apply land mask:
      Land = WHERE(IN_Land EQ 1, COUNT) ; Get land only
      ;PET_Out = MAKE_ARRAY(SIZE, VALUE=-999.00, /FLOAT) TMin_IN = IN_TMin[INDEX_TMin]
      PET_Out = FLTARR(SIZE) & PET_Out[*] =  -999.00
      PET_Out[Land] = PET[Land] ; For land elements set PET. Non-land elememts remain as -999.00 (default PET_Out value)
    ENDELSE 
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; Write data:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    FILE_PET = OUT_DIRECTORY + STRTRIM(iY, 2) + iM + iD + '_PET.img' ; Set the output file name
    OPENW, UNIT, FILE_PET, /GET_LUN ; Create the output file
    FREE_LUN, UNIT ; Close the output file
    OPENU, UNIT, FILE_PET, /GET_LUN, /APPEND ; Open the output file for editing
    WRITEU, UNIT, PET_OUT ; Write data
    FREE_LUN, UNIT ; Close the output file
    ;-------------------------------------------------------------------------------------------
    SECONDS = (SYSTIME(1)-L_TIME) ; Get the file loop end time
    ;--------------
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR DATE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(DATES_TMinU), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; PRINT SCRIPT INFORMATION:
  ;-----------------------------------
  ; GET END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  ;--------------
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Priestley_Taylor_PET'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

