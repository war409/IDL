; ##############################################################################################
; NAME: BATCH_DOIT_Create_Custom_Landsat_PNG.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 01/11/2010
; DLM: 01/11/2010
;
; DESCRIPTION: This tool create one PNG file for each unique input date. For each unique date a 
;              'standard' RGB colour composite PNG file is created.
; 
; INPUT:
; 
; OUTPUT:
; 
; PARAMETERS:
; 
; NOTES: 
; 
; ##############################################################################################

;-----------------------------------------------------------------------------------------------
FUNCTION EXTRACT_LANDSAT, X_ALL
  ; EXTRACT FILES (SURFACE REFLECTANCE) 
  RED = X_ALL[WHERE(STRMATCH(X_ALL, '*B30*') EQ 1)]
  GREEN = X_ALL[WHERE(STRMATCH(X_ALL, '*B20*') EQ 1)]
  BLUE = X_ALL[WHERE(STRMATCH(X_ALL, '*B10*') EQ 1)]
  ; RETURN VALUES:
  RETURN, [RED, GREEN, BLUE]  
END
;-----------------------------------------------------------------------------------------------




PRO BATCH_DOIT_Create_Custom_Landsat_PNG
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Create_Custom_Landsat_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE INPUT DATA:
  PATH = 'C:\WorkSpace\NWC_GDE\'
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='Select the Input Data', FILTER=['*.tif','*.img','*.flt','*.bin'], $
    /MUST_EXIST, /MULTIPLE_FILES)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;--------------
  ; GET FILENAME SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  FNS = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    FNS[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY
  PATH = 'C:\WorkSpace\NWC_GDE\'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='Select the Output Directory', /DIRECTORY)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; GET UNIQUE FILE DATES:
  YYY = STRMID(FNS, 12, 4) ; EXTRACT YEAR FROM FILE NAME ARRAY
  DDD = STRMID(FNS, 18, 2) ; EXTRACT DAY FROM FILE NAME ARRAY
  MMM = STRMID(FNS, 16, 2) ; EXTRACT MONTH FROM FILE NAME ARRAY
  DMY = JULDAY(MMM, DDD, YYY) ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  IN_DATE = DMY[UNIQ(DMY)] ; GET UNIQUE DATES
  IN_DATE = IN_DATE[SORT(IN_DATE)] ; SORT DATES (ASCENDING)
  IN_DATE = IN_DATE[UNIQ(IN_DATE)] ; GET UNIQUE DATES
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; DATE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR d=0, N_ELEMENTS(IN_DATE)-1 DO BEGIN ; FOR d
    ;-------------------------------------------------------------------------------------------  
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    CALDAT, IN_DATE[d], OUT_MONTH, OUT_DAY, OUT_YEAR ; GET THE d-TH DATE FOR FOR THE OUTPUT FILE NAME
    DOY = JULDAY(OUT_MONTH, OUT_DAY, OUT_YEAR) - JULDAY(1, 0, OUT_YEAR) ; GET DAY OF YEAR
    ;-------------- 
    ; ADD THE PREFIX '0'
    IF (DOY LE 9) THEN DOY = ('00' + STRING(STRTRIM(DOY, 2)))
    IF (DOY GT 9) AND (DOY LE 99) THEN DOY = ('0' + STRING(STRTRIM(DOY, 2)))
    IF (OUT_DAY LE 9) THEN OUT_DAY = ('0' + STRING(STRTRIM(OUT_DAY, 2)))
    IF (OUT_MONTH LE 9) THEN OUT_MONTH = ('0' + STRING(STRTRIM(OUT_MONTH, 2)))  
    ;------------------------------------------------------------------------------------------
    INDEX = WHERE(DMY EQ IN_DATE[d], COUNT) ; SEARCH FOR FILES WITH THE d-TH DATE WITHIN THE FULL FILE LIST
    FILES_IN = IN_FILES[INDEX] ; EXTRACT FILES WITH THE d-TH DATE FROM THE FULL FILE LIST
    ;-------------- 
    ; EXTRACT FILES (SURFACE REFLECTANCE)
    BANDS_IN = EXTRACT_LANDSAT(FILES_IN)
    ;-------------- 
    ; SET FUNCTION OUTPUT
    RED_IN = BANDS_IN[0]
    GREEN_IN = BANDS_IN[1]
    BLUE_IN = BANDS_IN[2]
    ;-------------- 
    ; LOAD DATA:
    ENVI_OPEN_FILE, RED_IN, R_FID=FID_RED, /NO_REALIZE
    ENVI_OPEN_FILE, GREEN_IN, R_FID=FID_GREEN, /NO_REALIZE
    ENVI_OPEN_FILE, BLUE_IN, R_FID=FID_BLUE, /NO_REALIZE
    ;-------------- 
    ; GET MAP INFORMATION: 
    ENVI_FILE_QUERY, FID_RED, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DT
    DIMS_IN = [NS, NL] ; SET FILE DIMENSIONS
    MAPINFO = ENVI_GET_MAP_INFO(FID=FID_RED)
    PROJFULL = MAPINFO.PROJ
    DATUM = MAPINFO.PROJ.DATUM
    PROJ = MAPINFO.PROJ.NAME
    UNITS = MAPINFO.PROJ.UNITS
    CXSIZE = DOUBLE(MAPINFO.PS[0])
    CYSIZE = DOUBLE(MAPINFO.PS[1])
    LEFT = DOUBLE(MAPINFO.MC[2])
    TOP = DOUBLE(MAPINFO.MC[3])
    RIGHT = LEFT + (DOUBLE(DIMS_IN[0]) * DOUBLE(CXSIZE))
    BOTTOM = TOP - (DOUBLE(DIMS_IN[1]) * DOUBLE(CYSIZE))
    DIMS_IN = [NS, NL] ; SET INPUT FILE DIMENSIONS
    DIMS_OUT = DIMS_IN ; SET OUTPUT FILE DIMENSIONS
    ;-------------- 
    ; GET DATA
    DATA_R = ENVI_GET_DATA(FID=FID_RED, DIMS=DIMS, POS=0)
    DATA_G = ENVI_GET_DATA(FID=FID_GREEN, DIMS=DIMS, POS=0)
    DATA_B = ENVI_GET_DATA(FID=FID_BLUE, DIMS=DIMS, POS=0)
    ;-------------------------------------------------------------------------------------------
    ; TRIM FILENAME:
    FNAME_START = STRPOS(RED_IN, '\', /REVERSE_SEARCH)+1
    FNAME_SHORT = STRMID(RED_IN, FNAME_START, 8)
    ;--------------
    ; BUILD OUTNAME
    OUTNAME = OUT_DIRECTORY + FNAME_SHORT + '.' + STRTRIM(OUT_DAY, 2)  + STRTRIM(OUT_MONTH, 2) + STRTRIM(OUT_YEAR, 2) + '.' + STRTRIM(DOY, 2) + '.RGB.png' 
    ;-------------------------------------------------------------------------------------------  
    ; APPLY NEW LIMITS:
    l = WHERE(DATA_R LT 0, COUNT_l) ; GET POSITION OF VALUES LT LOW
    IF (COUNT_l GT 0) THEN DATA_R[l] = 0 ; SET VALUES LT LOW TO THE MINIMUM LIMIT VALUE
    h = WHERE(DATA_R GT 50, COUNT_h) ; GET POSITION OF VALUES GT HIGH
    IF (COUNT_h GT 0) THEN DATA_R[h] = 50 ; SET VALUES GT HIGH TO THE MAXIMUM LIMIT VALUE
    ;--------------      
    l = WHERE(DATA_G LT 0, COUNT_l) ; GET POSITION OF VALUES LT LOW
    IF (COUNT_l GT 0) THEN DATA_G[l] = 0 ; SET VALUES LT LOW TO THE MINIMUM LIMIT VALUE
    h = WHERE(DATA_G GT 50, COUNT_h) ; GET POSITION OF VALUES GT HIGH
    IF (COUNT_h GT 0) THEN DATA_G[h] = 50 ; SET VALUES GT HIGH TO THE MAXIMUM LIMIT VALUE
    ;--------------      
    l = WHERE(DATA_B LT 0, COUNT_l) ; GET POSITION OF VALUES LT LOW
    IF (COUNT_l GT 0) THEN DATA_B[l] = 0 ; SET VALUES LT LOW TO THE MINIMUM LIMIT VALUE
    h = WHERE(DATA_B GT 120, COUNT_h) ; GET POSITION OF VALUES GT HIGH
    IF (COUNT_h GT 0) THEN DATA_B[h] = 120 ; SET VALUES GT HIGH TO THE MAXIMUM LIMIT VALUE   
    ;--------------   
    ; APPLY BYTE STRETCH:
    ;--------------
    RANGE_X = 255 ; SET NEW HISTOGRAM RANGE 
    RANGE_DATA = (MAX(DATA_R, /NAN) - MIN(DATA_R, /NAN)) ; SET ORIGINAL HISTOGRAM RANGE (Maximum of DATA - Minimum of Data)
    SLOPE = (RANGE_X / RANGE_DATA) * 1.00 ; CALCULATE SLOPE
    INTERCEPT = (SLOPE * MIN(DATA_R, /NAN)) ; CALCULATE INTERCEPT
    DATA_R2 = FIX((SLOPE*DATA_R)-INTERCEPT) ; APPLY STRETCH
    DATA_R_PNG = BYTE(TEMPORARY(DATA_R2)) ; CONVERT DATATYPE TO BYTE
    ;-------------- 
    RANGE_DATA = (MAX(DATA_G, /NAN) - MIN(DATA_G, /NAN)) ; SET ORIGINAL HISTOGRAM RANGE (Maximum of DATA - Minimum of Data)
    SLOPE = (RANGE_X / RANGE_DATA) * 1.00 ; CALCULATE SLOPE
    INTERCEPT = (SLOPE * MIN(DATA_G, /NAN)) ; CALCULATE INTERCEPT
    DATA_G2 = FIX((SLOPE*DATA_G)-INTERCEPT) ; APPLY STRETCH
    DATA_G_PNG = BYTE(TEMPORARY(DATA_G2)) ; CONVERT DATATYPE TO BYTE
    ;--------------
    RANGE_DATA = (MAX(DATA_B, /NAN) - MIN(DATA_B, /NAN)) ; SET ORIGINAL HISTOGRAM RANGE (Maximum of DATA - Minimum of Data)
    SLOPE = (RANGE_X / RANGE_DATA) * 1.00 ; CALCULATE SLOPE
    INTERCEPT = (SLOPE * MIN(DATA_B, /NAN)) ; CALCULATE INTERCEPT
    DATA_B2 = FIX((SLOPE*DATA_B)-INTERCEPT) ; APPLY STRETCH
    DATA_B_PNG = BYTE(TEMPORARY(DATA_B2)) ; CONVERT DATATYPE TO BYTE      
    ;-------------------------------------------------------------------------------------------
    ; SET SHRINK SIZE:
    XRANGE = [MIN(LEFT), MAX(RIGHT)]
    YRANGE = [MIN(BOTTOM), MAX(TOP)]
    ASPECTRATIO = ABS(YRANGE[1] - YRANGE[0]) / ABS(XRANGE[1]-XRANGE[0])
    IF ASPECTRATIO LE 1 THEN BEGIN ; YRANGE IS GE XRANGE
      XSIZE=1000 
      YSIZE=1000*ASPECTRATIO
    ENDIF ELSE BEGIN ; YRANGE IS LT XRANGE
      XSIZE=1000*ASPECTRATIO
      YSIZE=1000
    ENDELSE
    ;--------------
    ; SHRINK GRIDS:
    R_PNG = CONGRID(DATA_R_PNG, XSIZE, YSIZE)
    G_PNG = CONGRID(DATA_G_PNG, XSIZE, YSIZE)
    B_PNG = CONGRID(DATA_B_PNG, XSIZE, YSIZE)
    ;--------------    
    ; BUILD OUTPUT PNG MATRIX:
    IMAGE_RGB = [[[R_PNG]], [[G_PNG]], [[B_PNG]]]
    IMAGE_RGB_TRANS = TRANSPOSE(IMAGE_RGB, [2,0,1])
    WRITE_PNG, OUTNAME, IMAGE_RGB_TRANS, /ORDER ; SAVE PNG
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(d+1, 2), ' OF ', $
      STRTRIM(N_ELEMENTS(IN_DATE), 2)
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Create_Custom_Landsat_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END  