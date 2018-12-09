; ##############################################################################################
; NAME: Time_Series_DOIT_Statistics_By_ENVI_ROI.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 07/10/2010
; DLM: 11/10/2010
;
; DESCRIPTION:  This tool calculates raster statistics by region. Regions are defined by an ENVI 
;               ROI (.roi) file. The user may select one or more regions. The user may select one 
;               or more statistics from the following: Mean; Median; Minimum; Maximum; Standard 
;               Deviation; Variance. The selected statistics are calculated for each input region 
;               and input file. The combined regional mean per input raster is also calculated.
;               
;               The count (total number of cells) per region and file, and the number of no-data 
;               cells per region and file are identified and returned.
;               
;               The statistics are written to a user defined comma-delimited text file.
;
; INPUT:        One or more ENVI compatible rasters. One or more regions of interest (ROI)  
;               defined in an ENVI .roi file.
;
; OUTPUT:       One comma-delimited text file. The output file (inc. hearder information) is 
;               formatted dynamically depending on the selected regions, number of regions, and 
;               the selected statistics.
;               
; PARAMETERS:   Via IDL and ENVI widgets, set:  
;           
;               1.  SELECT THE INPUT DATA: see INPUT
;               
;               2.  Select the date format: Select whether the input filenames include the year, day,
;               and month as YYYY MM DD (e.g. 2010 13 10), or year and day-of-year (e.g. 2010 049). 
;               The date elements can be in any order. See NOTES for more information.
;               
;               3.  Define an input nodata value: If your input data contains a 'fill' or 'nodata' 
;               value that you want to exclude from the processing select YES.
;               
;               3.1 Define the input nodata value (optional; if YES in 3.): The input nodata value.
;               
;               4.  SELECT ONE OR MORE STATISTICS: Select one or more statistics to calculate.
;               
;               5.  SELECT THE INPUT ROI: Select the .roi file.
;               
;               6.  SELECT ONE OR MORE ROI: Select one or more regions from 5. The selected satistics
;                   will be calculated for each selected region.
;               
;               7.  DEFINE THE OUTPUT FILE: Define the output text file. 
;               
;                
; NOTES:        An interactive ENVI session needed to run this tool. You can convert ENVI vector files 
;               (.evf) or ESRI shapefiles to a ROI file in ENVI.
; 
;               FILE DATES:
; 
;               The input data are sorted by date (in ascending order). Lines 125 and 128
;               control how the date is extracted from the input raster file name. For example,
;               in the filename: MOD09A1.005.OWL.5VariableModel.2004329.hdr
;               
;               The year '2004', and day-of-year (DOY) '329', is extracted by the line:
;               
;               DMY = FUNCTION_GET_Julian_Day_Number_YYYYDOY(FNS, 31, 35)
;               
;               Where, '31' is the character position of the first number in 2004. Similarly,
;               '35' is the character position of the first number in 326.
;               
;               The code could be modified to print the filename date as a column in the output.
;               
;               FUNCTIONS:
;               
;               This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool. To open a different workspace, select Switch  
;               Workspace from the File menu.
;               
;               Functions used in this program include:
;               
;               FUNCTION_WIDGET_Radio_Button
;               FUNCTION_GET_Julian_Day_Number_YYYYDOY
;               FUNCTION_GET_Julian_Day_Number_DDMMYYYY
;               FUNCTION_WIDGET_Enter_Value
;
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO Time_Series_DOIT_Statistics_By_ENVI_ROI
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_DOIT_Statistics_By_ENVI_ROI'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA:
  PATH='C:\'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; GET FILENAME SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  FNS = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  ; FILL ARRAY
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; GET THE a-TH FILE NAME 
    FNS[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;-----------------------------------  
  ; SET DATE TYPE:
  TYPE_DATE = FUNCTION_WIDGET_Radio_Button('Select the date format:  ', ['YYYY/DOY', 'DD/MM/YYYY'])
  ;--------------
  IF TYPE_DATE EQ 0 THEN BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY = FUNCTION_GET_Julian_Day_Number_YYYYDOY(FNS, 31, 35)
  ENDIF ELSE BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY = FUNCTION_GET_Julian_Day_Number_DDMMYYYY(FNS, 15, 13, 11)
  ENDELSE
  ;--------------
  ; SORT BY DATE
  IN_FILES = IN_FILES[SORT(DMY)]
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  NT = FUNCTION_WIDGET_Radio_Button('Define an input nodata value?  ', ['YES', 'NO'])
  ;--------------
  ; SET THE NODATA VALUE
  IF NT EQ 0 THEN NAN_VALUE = FUNCTION_WIDGET_Enter_Value('Define the input nodata value:  ', 255.00)
  ;---------------------------------------------------------------------------------------------
  ; SELECT ONE OR MORE STATISTIC
  VALUES = ['MEAN', 'MEDIAN', 'MIN', 'MAX', 'STDDEV','VARIANCE']
  BASE = WIDGET_AUTO_BASE(TITLE='SELECT ONE OR MORE STATISTICS')
  WM = WIDGET_MULTI(BASE, LIST=VALUES, UVALUE='LIST', /AUTO)
  SELECT_STATISTIC = AUTO_WID_MNG(BASE)
  ;--------------
  ; ERROR CHECK
  IF (SELECT_STATISTIC.ACCEPT EQ 0) THEN RETURN
  ;--------------
  ; GET STATISTIC INDEX
  INDEX = WHERE(SELECT_STATISTIC.LIST EQ 1)
  ; GET SELECTED STATISTIC STRINGS
  ST_STRING = VALUES[INDEX]
  ;---------------------------------------------------------------------------------------------
  ; SET THE INPUT ROI
  PATH='C:\'
  IN_ROI = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT ROI', FILTER='*.roi', /MUST_EXIST)
  ;-------------- 
  ; ERROR CHECK
  IF IN_ROI EQ '' THEN RETURN
  ;-------------- 
  ; OPEN ROI
  ENVI_RESTORE_ROIS, IN_ROI
  ;--------------  
  ; GET ROI IDS
  ROI_ID = ENVI_GET_ROI_IDS(ROI_NAMES=RNAMES, /SHORT_NAME)
  ;-----------------------------------
  ; SELECT ONE OR MORE ROI
  BASE = WIDGET_AUTO_BASE(TITLE='SELECT ONE OR MORE ROI')
  WM = WIDGET_MULTI(BASE, LIST=RNAMES, UVALUE='LIST', /AUTO)
  SELECT_ROI = AUTO_WID_MNG(BASE)
  ;--------------
  ; ERROR CHECK
  IF (SELECT_ROI.ACCEPT EQ 0) THEN RETURN
  ;--------------
  ; GET ROI INDEX
  INDEX = WHERE(SELECT_ROI.LIST EQ 1)
  ; GET SELECTED ROI NAMES
  RNAMES = RNAMES[INDEX]
  ; GET ROI NAME START POS
  RNAME_START = STRPOS(RNAMES, '=', /REVERSE_SEARCH)+1
  ; GET ROI NAME LENGTH
  RNAME_LENGTH = (STRLEN(RNAMES)-RNAME_START)-1  
  ;--------------
  ; CREATE ROI NAME ARRAY
  RNS = MAKE_ARRAY(1, N_ELEMENTS(RNAMES), /STRING)
  ; FILL ARRAY
  FOR a=0, N_ELEMENTS(RNAMES)-1 DO BEGIN
    ; GET THE a-TH ROI NAME 
    RNS[*,a] += STRMID(RNAMES[a], RNAME_START[a], RNAME_LENGTH[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SET THE OUTPUT FILE
  PATH='C:\'
  OUT_FILE = DIALOG_PICKFILE(PATH=PATH, TITLE='DEFINE THE OUTPUT FILE', DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_FILE EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; CREATE THE OUTPUT FILE HEADER:
  ;-----------------------------------
  ; CREATE FILE HEADER ARRAY
  FHEAD = MAKE_ARRAY((N_ELEMENTS(RNAMES)*(2+N_ELEMENTS(ST_STRING)))+5, /STRING)
  FHEAD[0] = 'ID'
  FHEAD[1] = 'FILENAME'
  FHEAD[2] = 'COMBINED_COUNT'
  FHEAD[3] = 'COMBINED_NaNCOUNT'
  FHEAD[4] = 'COMBINED_MEAN'
  ;--------------
  ; FILL ARRAY
  FOR a=0, N_ELEMENTS(RNAMES)-1 DO BEGIN
    ; UPDATE COUNTER
    IF a EQ 0 THEN b=5 ELSE b=b+2+N_ELEMENTS(ST_STRING)
    ; FILL
    FHEAD[b] += RNS[a] + '_COUNT'
    FHEAD[b+1] += RNS[a] + '_NaNCOUNT'
    FOR c=0, N_ELEMENTS(ST_STRING)-1 DO BEGIN
      FHEAD[b+c+2] += RNS[a] + '_' + ST_STRING[c]
    ENDFOR
  ENDFOR
  ;--------------
  ; CREATE THE OUTPUT FILE 
  OPENW, OUT_LUN, OUT_FILE, /GET_LUN
  ; WRITE THE FILE HEAD
  PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, '"' + FHEAD + '"'
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUT_LUN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: FILE LOOP
    L_TIME = SYSTIME(1)
    ;------------------------------------------------------------------------------------------- 
    ; GET DATA:
    ;-----------------------------------
    FILE_IN = IN_FILES[i] ; SET THE i-TH FILE 
    FN_IN = FNS[i] ; SET THE i-TH FILENAME
    ;--------------
    ; OPEN FILE
    ENVI_OPEN_FILE, FILE_IN, /NO_REALIZE, R_FID=FID
    ;-------------------------------------------------------------------------------------------    
    ; MAKE ROI LOOP ARRAYS:
    ;-----------------------------------
    ; MAKE ARRAY TO HOLD ROI STATISTICS
    ARRAY_STATISTIC = MAKE_ARRAY(N_ELEMENTS(RNAMES), N_ELEMENTS(ST_STRING), /FLOAT)
    ; MAKE ARRAY TO HOLD THE COUNT OF CELLS IN EACH ROI
    ARRAY_TCOUNT = MAKE_ARRAY(N_ELEMENTS(RNAMES), /FLOAT)
    ; MAKE ARRAY TO HOLD OF NON NaN CELLS IN EACH ROI
    ARRAY_VCOUNT = MAKE_ARRAY(N_ELEMENTS(RNAMES), /FLOAT)
    ; MAKE ARRAY TO HOLD OF NaN CELLS IN EACH ROI
    ARRAY_NCOUNT = MAKE_ARRAY( N_ELEMENTS(RNAMES), /FLOAT)
    ;-------------------------------------------------------------------------------------------  
    ;*******************************************************************************************  
    ; ROI LOOP:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    FOR j=0, N_ELEMENTS(RNAMES)-1 DO BEGIN ; FOR j
      ;-----------------------------------------------------------------------------------------    
      ; GET ROI DATA:
      ;-----------------------------------
      ; GET DATA FOR THE iTH FILE AND jTH ROI
      DATA_ROI = ENVI_GET_ROI_DATA(ROI_ID[INDEX[j]], FID=FID, POS=[0])
      ;-----------------------------------------------------------------------------------------
      ; MAKE ARRAYS TO HOLD THE COMBINED ROI STATISTICS
      IF j EQ 0 THEN DATA_COMBINED = MAKE_ARRAY(N_ELEMENTS(RNAMES), 2, /FLOAT)
      ;-----------------------------------------------------------------------------------------
      ; SET NAN
      IF NT EQ 0 THEN BEGIN
        n = WHERE(DATA_ROI EQ FLOAT(NAN_VALUE), COUNT)
        IF (COUNT GT 0) THEN DATA_ROI[n] = !VALUES.F_NAN
      ENDIF
      ;-----------------------------------------------------------------------------------------      
      ; GET:
      DATA_SUM = TOTAL(DATA_ROI, 1, /NAN) ; THE SUM OF ELEMENTS IN DATA_ROI     
      DATA_TCOUNT = N_ELEMENTS(DATA_ROI) ; COUNT OF CELLS IN DATA_ROI
      DATA_VCOUNT = TOTAL(FINITE(DATA_ROI), 1) ; COUNT OF NON-NaN CELLS IN DATA_ROI
      DATA_NCOUNT = DATA_TCOUNT - DATA_VCOUNT ; COUNT OF NaN CELLS IN DATA_ROI
      ;-----------------------------------------------------------------------------------------
      ; FILL DATA_COMBINED:
      DATA_COMBINED[j,0] = DATA_SUM
      DATA_COMBINED[j,1] = DATA_VCOUNT
      ;-----------------------------------------------------------------------------------------
      ; FILL ROI ARRAYS:
      ;-----------------------------------
      ARRAY_TCOUNT[j] = DATA_TCOUNT
      ARRAY_VCOUNT[j] = DATA_VCOUNT
      ARRAY_NCOUNT[j] = DATA_NCOUNT
      ;--------------
      FOR s=0, N_ELEMENTS(ST_STRING)-1 DO BEGIN
        ;--------------
        ; GET ROI STATISTICS:
        IF ST_STRING[s] EQ 'MEAN' THEN ARRAY_STATISTIC[j,s] = MEAN(DATA_ROI, /NAN) 
        IF ST_STRING[s] EQ 'MEDIAN' THEN ARRAY_STATISTIC[j,s] = MEDIAN(DATA_ROI, /EVEN)
        IF ST_STRING[s] EQ 'MIN' THEN ARRAY_STATISTIC[j,s] = MIN(DATA_ROI, /NAN)
        IF ST_STRING[s] EQ 'MAX' THEN ARRAY_STATISTIC[j,s] = MAX(DATA_ROI, /NAN)
        IF ST_STRING[s] EQ 'STDDEV' THEN BEGIN
          IF DATA_VCOUNT LT 2 THEN ARRAY_STATISTIC[j,s] = !VALUES.F_NAN ELSE ARRAY_STATISTIC[j,s] =  STDDEV(DATA_ROI, /NAN)
        ENDIF
        IF ST_STRING[s] EQ 'VARIANCE' THEN BEGIN
          IF DATA_VCOUNT LT 2 THEN ARRAY_STATISTIC[j,s] = !VALUES.F_NAN ELSE ARRAY_STATISTIC[j,s] = VARIANCE(DATA_ROI, /NAN)
        ENDIF 
        ;--------------
      ENDFOR
      ;-----------------------------------------------------------------------------------------
      ; PRINT LOOP INFORMATION
      PRINT, '  FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2), '; ROI ', $
        STRTRIM(j+1, 2), ' OF ', STRTRIM(N_ELEMENTS(RNAMES), 2)
      ;----------------------------------------------------------------------------------------- 
    ENDFOR ; FOR j
    ;-------------------------------------------------------------------------------------------
    ; GET COMBINED STATISTIC:
    ;-----------------------------------
    COMBINED_SUM = TOTAL(DATA_COMBINED[*,0], 1, /NAN) ; COMBINED SUM
    COMBINED_COUNT = TOTAL(DATA_COMBINED[*,1], 1, /NAN) ; COMBINED COUNT
    COMBINED_NCOUNT = TOTAL(ARRAY_NCOUNT, 1, /NAN) ; COMBINED NaN COUNT
    ;--------------   
    ; FILL ARRAY_COMBINED 
    COMBINED_MEAN = (COMBINED_SUM / COMBINED_COUNT) ; COMBINED MEAN
    ;-------------------------------------------------------------------------------------------
    ; WRITE TO OUTPUT:
    ;-----------------------------------
    ; OPEN THE OUTPUT FILE
    OPENU, OUT_LUN, OUT_FILE, /APPEND, /GET_LUN
    ;-----------------------------------
    ; MAKE ARRAY TO HOLD ROI OUTPUTS
    ARRAY_ROI = MAKE_ARRAY(N_ELEMENTS(RNAMES)*(N_ELEMENTS(ST_STRING)+2), /FLOAT)
    ;--------------
    ; FILL ARRAY
    FOR a=0, N_ELEMENTS(RNAMES)-1 DO BEGIN
      ; UPDATE COUNTER
      IF a EQ 0 THEN b=0 ELSE b=b+2+N_ELEMENTS(ST_STRING)
      ; FILL
      ARRAY_ROI[b] += ARRAY_TCOUNT[a]
      ARRAY_ROI[b+1] += ARRAY_NCOUNT[a]
      FOR c=0, N_ELEMENTS(ST_STRING)-1 DO BEGIN
        ARRAY_ROI[b+c+2] += ARRAY_STATISTIC[a,c]
      ENDFOR
    ENDFOR   
    ;-----------------------------------
    ; WRITE DATA TO FILE
    PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, i, '"'+ FN_IN +'"', $
      STRTRIM(COMBINED_COUNT, 2), STRTRIM(COMBINED_NCOUNT, 2), STRTRIM(COMBINED_MEAN, 2), STRTRIM(ARRAY_ROI, 2)
    ;-----------------------------------
    ; CLOSE THE OUTPUT FILE
    FREE_LUN, OUT_LUN
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------  
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR  ; FOR i
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
  PRINT,'FINISHED PROCESSING: Time_Series_DOIT_Statistics_By_ENVI_ROI'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END