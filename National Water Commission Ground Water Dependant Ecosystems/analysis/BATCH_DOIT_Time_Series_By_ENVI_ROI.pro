; ##############################################################################################
; NAME: BATCH_DOIT_Time_Series_By_ENVI_ROI.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 05/12/2010
; DLM: 08/12/2010
;
; DESCRIPTION:  This tool extracts cell value/s where the input grid and point region of interest 
;               (ROI) intersect. Regions are defined by an ENVI ROI (.roi) file. The user may 
;               select one or more regions.
;               
;               This tool will function with any valid region type, i.e. point, polygon, or line. 
;               However, the point ROI type is recommended as it is more efficient. For polygon-
;               type regions I recommend using a point-cloud.
;               
;               The identified grid values are written to a user defined comma-delimited text file. 
;               The ROI ID and name, the input grid date, and name are also included.
;
; INPUT:        One or more ENVI compatible rasters. One or more regions of interest (ROI)  
;               defined in an ENVI .roi file.
;
; OUTPUT:       One comma-delimited text file. The output file (inc. hearder information) is 
;               formatted dynamically depending on the selected regions, and the number of regions.
;               
; PARAMETERS:   Via pop-up dialog widgets:
;               
; NOTES:        An interactive ENVI session needed to run this tool. You can convert ENVI vector files 
;               (.evf) or ESRI shapefiles to a ROI file in ENVI.
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
;
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_Time_Series_By_ENVI_ROI
  ;---------------------------------------------------------------------------------------------
  T_TIME = SYSTIME(1) ; Get the program start time
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Time_Series_By_ENVI_ROI'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; Input/Output:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  PATH='C:\WorkSpace\Time_Series_By_ENVI_ROI'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input Data', FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES)
  IF IN_FILES[0] EQ '' THEN RETURN ; Error check
  IN_FILES = IN_FILES[SORT(IN_FILES)] ; Sort the input file list
  ;--------------
  ; Remove the file path from the input file names:
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path)
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4 ; Get the length of each path-less file name
  FNS = MAKE_ARRAY(N_ELEMENTS(IN_FILES), /STRING) ; Create an array to store the input file names
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a]) ; Get the a-the file name (trim away the file path)
  ENDFOR
  ;--------------
  IN_DATES = FUNCTION_WIDGET_Date(IN_FILES=FNS, /JULIAN) ; Get the input file name dates
  IF IN_DATES[0] NE -1 THEN BEGIN ; Check for valid dates
    IN_FILES = IN_FILES[SORT(IN_DATES)] ; Sort file name by date
    FNS = FNS[SORT(IN_DATES)] ; Sort file name by date
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Select the input ROI:
  PATH='C:\WorkSpace\Time_Series_By_ENVI_ROI'
  IN_ROI = DIALOG_PICKFILE(PATH=PATH, TITLE='Select The Input ROI', FILTER='*.roi', /MUST_EXIST)
  IF IN_ROI EQ '' THEN RETURN ; Error check
  ;-------------- 
  ENVI_RESTORE_ROIS, IN_ROI ; Open ROI
  ROI_ID = ENVI_GET_ROI_IDS(ROI_NAMES=ROI, /SHORT_NAME) ; Get ROI ID
  ;--------------
  ; Select one or more ROI: ENVI widget
  BASE = WIDGET_AUTO_BASE(TITLE='Select One Or More ROI')
  WM = WIDGET_MULTI(BASE, LIST=ROI, UVALUE='LIST', /AUTO)
  SELECT_ROI = AUTO_WID_MNG(BASE)
  IF (SELECT_ROI.ACCEPT EQ 0) THEN RETURN  ; Error check
  INDEX = WHERE(SELECT_ROI.LIST EQ 1) ; Get ROI index 
  ROI = ROI[INDEX] ; Get the selected ROI names
  ;--------------
  ; Trim the excess information from the ROI names:
  ROI_START = STRPOS(ROI, '=', /REVERSE_SEARCH)+1 ; Get ROI name start position
  ROI_LENGTH = (STRLEN(ROI)-ROI_START)-1 ; Get ROI name length
  RNS = MAKE_ARRAY(1, N_ELEMENTS(ROI), /STRING) ; Create an array to store the selected input ROI names
  FOR a=0, N_ELEMENTS(ROI)-1 DO BEGIN ; Fill the ROI name array:
    RNS[*,a] += STRMID(ROI[a], ROI_START[a], ROI_LENGTH[a]) ; ; Get the a-the ROI name (trim away the excess information)
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; Set the output file: 
  PATH='C:\WorkSpace\Time_Series_By_ENVI_ROI'
  OUT_FILE = DIALOG_PICKFILE(PATH=PATH, TITLE='Define The Output File', DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  IF OUT_FILE EQ '' THEN RETURN ; Error check
  ;---------------------------------------------------------------------------------------------
  ; Create the output file:
  FHEAD = MAKE_ARRAY(N_ELEMENTS(ROI)+3, /STRING) ; Create an array to store the output file header
  FHEAD[0] = 'ID' ; Set the first element in the array (A unique ID for each row in the output file)
  FHEAD[1] = 'Filename' ; Set the second element in the array (The file name of the i-th grid)
  FHEAD[2] = 'DD/MM/YYYY' ; Set the third element in the array (The date of the i-th grid)  
  FOR a=0, N_ELEMENTS(ROI)-1 DO BEGIN ; Fill the output header array:
    IF a EQ 0 THEN b=3 ELSE b=b+1 ; Update the array position status
    FHEAD[b] += RNS[a] ; Add the a-th ROI name to the array
  ENDFOR
  ;--------------
  OPENW, OUT_LUN, OUT_FILE, /GET_LUN ; Create the output file
  PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, '"' + FHEAD + '"' ; Write the output file header
  FREE_LUN, OUT_LUN ; Close the output file
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; File Loop:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------  
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------  
    L_TIME = SYSTIME(1) ; Get the file loop start time
    ;------------------------------------------------------------------------------------------- 
    FILE_IN = IN_FILES[i] ; Set the i-th file
    FNS_IN = FNS[i] ; Set the i-th filename
    ENVI_OPEN_FILE, FILE_IN, /NO_REALIZE, R_FID=FID ; Open the i-th file 
    ENVI_FILE_QUERY, FID, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DT ; Get file information
    ;--------------
    IF IN_DATES[0] NE -1 THEN BEGIN ; Set the i-th date
      CALDAT, IN_DATES[i], MONTH, DAY, YEAR ; Convert the Julian day number to day, month and year
      IF (MONTH LE 9) THEN MONTH = ('0' + STRTRIM(MONTH, 2)) ELSE MONTH = STRTRIM(MONTH, 2); Add leading zero to month string
      IF (DAY LE 9) THEN DAY = ('0' + STRTRIM(DAY, 2)) ELSE DAY = STRTRIM(DAY, 2) ; Add leading zero to day string
      DATE_IN = DAY + '/' + MONTH + '/' + STRTRIM(YEAR, 2) ; Build the output date string
    ENDIF ELSE DATE_IN = 'NA' 
    ;-------------------------------------------------------------------------------------------
    ; Create an array to hold the cell values where the grid and ROI intersect:
    IF DT EQ 1 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /BYTE) ; Byte (8 bits)
    IF DT EQ 2 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /INTEGER) ; Integer (16 bits)
    IF DT EQ 3 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /LONG) ; Long integer (32 bits)
    IF DT EQ 4 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /FLOAT) ; Floating-point (32 bits)
    IF DT EQ 5 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /DOUBLE) ; Double-precision floating-point (64 bits)
    IF DT EQ 6 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /COMPLEX) ; Complex (2x32 bits)     
    IF DT EQ 9 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /DCOMPLEX) ; Double-precision complex (2x64 bits)
    IF DT EQ 12 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /UINT) ; Unsigned integer (16 bits)
    IF DT EQ 13 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /ULONG) ; Unsigned long integer (32 bits)
    IF DT EQ 14 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /L64) ; Long 64-bit integer
    IF DT EQ 15 THEN MATRIX_X = MAKE_ARRAY(N_ELEMENTS(ROI), /UL64) ; Unsigned long 64-bit integer 
    ;-------------------------------------------------------------------------------------------    
    ;*******************************************************************************************  
    ; ROI LOOP:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------  
    FOR j=0, N_ELEMENTS(ROI)-1 DO BEGIN ; FOR j
      ;-----------------------------------------------------------------------------------------    
      DATA_ROI = ENVI_GET_ROI_DATA(ROI_ID[INDEX[j]], FID=FID, POS=[0]) ; Get data for the i-th file and j-th ROI
      MATRIX_X[j] = DATA_ROI ; Fill the data array
      ;-----------------------------------------------------------------------------------------
      PRINT, '  FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2), '; ROI ', $
        STRTRIM(j+1, 2), ' OF ', STRTRIM(N_ELEMENTS(ROI), 2)
      ;----------------------------------------------------------------------------------------- 
    ENDFOR
    ;-------------------------------------------------------------------------------------------    
    OPENU, OUT_LUN, OUT_FILE, /APPEND, /GET_LUN ; Open the output file
    ; Write data to the output file:
    IF DT EQ 1 THEN BEGIN
      PRINTF, FORMAT='(10000(A,:,","))',OUT_LUN,STRTRIM(i, 2),'"'+FNS_IN+'"','"'+DATE_IN+'"', STRTRIM(FIX(MATRIX_X), 2) 
    ENDIF ELSE PRINTF, FORMAT='(10000(A,:,","))',OUT_LUN,STRTRIM(i, 2),'"'+FNS_IN+'"','"'+DATE_IN+'"', STRTRIM(MATRIX_X, 2)  
    FREE_LUN, OUT_LUN ; Close the output file
    ;-------------------------------------------------------------------------------------------
    SECONDS = (SYSTIME(1)-L_TIME) ; Get the file loop end time
    ;--------------
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  MINUTES = (SYSTIME(1)-T_TIME)/60 ; Get the program end time
  HOURS = MINUTES/60 ; Convert minutes to hours
  ;--------------
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Time_Series_By_ENVI_ROI'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END  