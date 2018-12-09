; ######################################################################
; NAME: NETCDF_TIMESERIES_EXTRACT.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren 
; DATE: 28/10/2009
; DLM: 29/10/2009
; DESCRIPTION: Extract time-series data from netCDF files at one or more
;              locations (via user selected coordinates). The output is in
;              the form of a CSV file with one row for each file (date), 
;              variable and location 'set'.
; INPUT: One or more netCDF files (date must be included in the file name).
; OUTPUT: One CSV file for each 'date range'.
; SET PARAMETERS: See **DEFINE** in code. Define input file path details,
;                 input file variables, the number of variables, location
;                 coordinates and input file name details i.e. position of
;                 'date' element in the file name.
; NOTES: IDL is not case-sensitive.
; ######################################################################
; 
PRO NETCDF_TIMESERIES_EXTRACT
  ; GET START TIME FOR WHOLE
  F_DATE = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: NETCDF_TIMESERIES_EXTRACT'
  ;---------------------------------------------------------------------
  PRINT,'GET FULL FILE NAME LIST'
  ; GET FILE NAMES                                             **DEFINE**
  ALLFILENAME = FILE_SEARCH("R:/ASAR_GM/", "*.nc", COUNT=COUNT)
  ; MANIPULATE FILE NAMES TO GET DATE                          **DEFINE**
  YYY = STRMID(ALLFILENAME, 76, 4)
  MMM = STRMID(ALLFILENAME, 80, 2)
  DDD = STRMID(ALLFILENAME, 82, 2)
  DMY = JULDAY(MMM, DDD, YYY)
  ;---------------------------------------------------------------------
  ; SETUP DATE RANGE                                           **DEFINE**
  SA = JULDAY(1, 1, 2000) ; (M,D,YYYY)
  EA = JULDAY(12, 31, 2000) ; (M,D,YYYY)
  ; GET FILES FROM ALLFILENAME THAT FALL WITHIN THE DATE RANGE
  FILE_INDEX = WHERE(((DMY LE EA) AND (DMY GE SA)), COUNT)
  ; SET COUNT VARIABLE
  FILE_COUNT = COUNT
  ; GET AND PRINT DATES
  ; START DATE
  STARTDATE = STRTRIM(SA, 2)
  CALDAT, STARTDATE, MONTH, DAY, YEAR
  ; ADD THE PREFIX '0' TO 'DAY' AND OR 'MONTH' IF VALUE IS LESS THAN OR EQUAL TO 9
  IF DAY LE 9 THEN DAY = (STRING(0) + STRING(STRTRIM(DAY, 2))) ELSE DAY = DAY
  IF MONTH LE 9 THEN MONTH = (STRING(0) + STRING(STRTRIM(MONTH, 2))) ELSE MONTH = MONTH
  ; BUILD DATE
  STARTDATE_CAL = STRTRIM(DAY, 2) + STRTRIM(MONTH, 2) + STRTRIM(YEAR, 2)
  PRINT,''
  PRINT, '  START DATE: ', STARTDATE_CAL
  ; END DATE    
  ENDDATE = STRTRIM((EA), 2)
  CALDAT, ENDDATE, MONTH, DAY, YEAR
  ; ADD THE PREFIX '0' TO 'DAY' AND OR 'MONTH' IF VALUE IS LESS THAN OR EQUAL TO 9
  IF DAY LE 9 THEN DAY = (STRING(0) + STRING(STRTRIM(DAY, 2))) ELSE DAY = DAY
  IF MONTH LE 9 THEN MONTH = (STRING(0) + STRING(STRTRIM(MONTH, 2))) ELSE MONTH = MONTH  
  ; BUILD DATE
  ENDDATE_CAL = STRTRIM(DAY, 2) + STRTRIM(MONTH, 2) + STRTRIM(YEAR, 2)
  PRINT, '  END DATE: ', ENDDATE_CAL
  ; ERROR CHECK
  IF (FILE_COUNT EQ 0) THEN BEGIN
    PRINT,'' 
    PRINT, '  NO FILES IN DATE RANGE ...GO TO NEXT DATE RANGE'
  ENDIF ELSE BEGIN ; START ELSE_1
  ; GET FILES IN DATE RANGE
  FILENAME = ALLFILENAME[FILE_INDEX]
  PRINT,''
  PRINT, FILENAME
  PRINT,'' 
  PRINT, '  NO. OF FILES: ', FILE_COUNT
  ;-----------------------------------------------------------------
  ; CREATE THE [EMPTY] OUTPUT CSV FILE TO CONTAIN TIME-SERIES DATA
  ; SET THE OUTPUT FILE PATH AND NAME 
  ; OUTPUT ROOT                                            **DEFINE**
  ROOT = 'R:\'
  ; OUTPUT PATH                                            **DEFINE**
  OUT_PATH = 'ASAR_GM\ENVI_daily\Australia_BINARY_8DAY\2006'
  ; OUTPUT NAME [PART 1]                                   **DEFINE**
  OUT_NAME1 = 'TUW_ASAGW_SSM_002_8DAY_'
  ; OUTPUT NAME [PART 2] WITH DATE RANGE                   **DEFINE**
  OUTNAME = OUT_NAME1 + STARTDATE_CAL + '_TO_' + ENDDATE_CAL + '.csv'
  ; SET FUNCTION 'FILEPATH'
  OUTFILE = FILEPATH(OUTNAME, ROOT_DIR=ROOT, SUBDIRECTORY=OUT_PATH)
  ; CREATE THE FILE 
  OPENW, OUTLUN_CSV, OUTFILE, /GET_LUN
  ; WRITE THE COLUMN HEADER                                **DEFINE**
  FHEAD=["FILENAME","VARIABLE","LATTITUDE","LONGITUDE","VALUE"]
  PRINTF, FORMAT='(10000(A,:,","))', OUTLUN_CSV, '"' + FHEAD + '"'
  ; CLOSE THE FILE
  FREE_LUN, OUTLUN_CSV
  ;-----------------------------------------------------------------
  ; OPEN EACH NETCDF FILE IN THE LIST 'FILENAME'
  FOR i=0, FILE_COUNT-1 DO BEGIN ; START FOR_1
    PRINT,''
    PRINT,'    NETCDF LOOP: FILE', i+1, 'OF ', FILE_COUNT
    ;---------------------------------------------------------------
    NETCDF_ROOT = ROOT
    ; EXTRACT FILE NAME AND PATH FROM 'FILENAME' LIST      **DEFINE**
    NETCDF_NAME = STRMID(FILENAME[i], 58, 44)
    NETCDF_PATH = STRMID(FILENAME[i], 3, 55)
    PRINT,''
    PRINT,'    OPEN FILE: ', NETCDF_NAME
    FILEOPEN = FILEPATH(NETCDF_NAME, ROOT_DIR=NETCDF_ROOT, SUBDIRECTORY=NETCDF_PATH)
    ;---------------------------------------------------------------
    ; DEFINE NETCDF FILE
    ; CREATE THE 'IN' IDL VARIABLE TO CONTAIN THE INPUT NETCDF FILE ID
    IN = NCDF_OPEN(FILEOPEN ,/NOWRITE)
    ; MAKE VARIABLE LIST ARRAY                             **DEFINE**
    VAR_LIST = MAKE_ARRAY(9, 1, /STRING)
    ; FILL VARIABLE LIST ARRAY                             **DEFINE**
    VAR_LIST[0] = 'albedo_visible'
    VAR_LIST[1] = 'brightness_temperature_10.8um'
    VAR_LIST[2] = 'brightness_temperature_12.0um'
    VAR_LIST[3] = 'brightness_temperature_6.75um'
    VAR_LIST[4] = 'brightness_temperature_3.75um'
    VAR_LIST[5] = 'rejection_flag'
    VAR_LIST[6] = 'satellite_zenith_angle'
    VAR_LIST[7] = 'solar_zenith_angle'
    VAR_LIST[8] = 'solar_azimuth_angle'
    ;---------------------------------------------------------------
    VAR_COUNT = N_ELEMENTS(VAR_LIST)
    ; LOOP THROUGH EACH VARIABLE IN THE NETCDF FILE
    FOR j=0, VAR_COUNT-1 DO BEGIN ; START FOR_2
      ; CREATE THE 'VARID' IDL VARIABLE TO, $
      ;   CONTAIN THE INPUT NETCDF VARIABLE
      VAR_NAME = VAR_LIST[j]
      VARID = NCDF_VARID(IN, VAR_NAME)
      ;-------------------------------------------------------------
      ; GET THE OFFSET LOCATIONS FOR THE COORDINATES OF INTEREST
      ; GET COORDINATE (OFFSET)                            **DEFINE**
      VARID_LAT = NCDF_VARID(IN, "latitude")
      VARID_LON = NCDF_VARID(IN, "longitude")
      ; SET COORDINATE ARRAY [LON,LAT]                     **DEFINE**
      CXCY_ARRAY = [[103.96, -7.98],[104.04, -8.06]]
      ; GET THE NUMBER OF COORDINATE PAIRS
      COORD_COUNT = (N_ELEMENTS(CXCY_ARRAY))/2
      ; LOOP THROUGH EACH COORDINATE PAIR
      FOR k=0, COORD_COUNT-1 DO BEGIN ; START FOR_3
        ; GET LONGITUDE; STRIDES IN STEPS OF 0.04 DEGREES
        LON = CXCY_ARRAY[0,k] ; E.G. 100.04
        ; GET LONGITUDE LOWER (LL) AND UPPER (UU) LIMITS
        LON_UU = LON + 0.04 ; E.G. 100.08
        LON_LL = LON - 0.04 ; E.G. 100.00
        ; GET LATTITUDE; STRIDES IN STEPS OF 0.04 DEGREES
        LAT = CXCY_ARRAY[1,k] ; E.G. -99.98
        ; GET LATTITUDE LOWER (LL) AND UPPER (UU) LIMITS
        LAT_UU = LAT + 0.04 ; E.G. -99.94
        LAT_LL = LAT - 0.04 ; E.G. -100.02   
        ; FIND THE NETCDF VALUE POSITION FOR THE COORDINATE PAIR
        NCDF_VARGET, IN, VARID_LON, VALUE
        LON_POS = WHERE(((VALUE GT LON_LL) AND (VALUE LT LON_UU)), COUNT) 
        PRINT, LON_POS
        NCDF_VARGET, IN, VARID_LAT, VALUE
        LAT_POS = WHERE(((VALUE GT LAT_LL) AND (VALUE LT LAT_UU)), COUNT) 
        PRINT, LAT_POS
        ;-----------------------------------------------------------            
        ; GET THE NETCDF VARIABLE VALUE AT THE COORDINATE PAIR LOCATION
        OFFSET = [LON_POS,LAT_POS,0] ; [LON,LAT,z] WHERE z HAS 1 DIMENSION i.e. 0
        COUNT = [1,1,1] ; HOW MANY VALUES TO GET STARTING AT THE OFFSET POSITION
        NCDF_VARGET, IN, VARID, VALUE, OFFSET=OFFSET, COUNT=COUNT
        PRINT, VALUE ; NETCDF VARIABLE VALUE
        ;-----------------------------------------------------------
        ; WRITE THE DATA TO THE OUTPUT CSV FILE
        ; GET FILE NAME
        FILENAME_PRINT = NETCDF_NAME
        ; GET VARIABLE NAME
        VARIABLENAME_PRINT = VAR_NAME
        ; GET COORDINATE
        LAT_PRINT = LAT
        LON_PRINT = LON
        ; PRINT DATA
        PRINTF, FORMAT='(10000(A,:,","))', OUTLUN_CSV, '"' + FILENAME_PRINT + '"', '"' + VARIABLENAME_PRINT + '"', $
          LAT, LON, VALUE
        ;-----------------------------------------------------------
        ENDFOR ; END FOR_3 ; LOOP TO THE NEXT COORDINATE PAIR
      ENDFOR ; END FOR_2 ; LOOP TO THE NEXT VARIABLE
    ENDFOR ; END FOR_1 ; LOOP TO THE NEXT NETCDF FILE
  ENDELSE ; END ELSE_1
  ;---------------------------------------------------------------------
  PRINT,''
  ; PRINT THE PROCESSING TIME
  MINUTES = (SYSTIME(1)-F_TIME)/60
  PRINT, MINUTES,'  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: NETCDF_TIMESERIES_EXTRACT'
  PRINT,'' 
END  