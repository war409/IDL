; ##############################################################################################
; NAME: BATCH_DOIT_Subset_Extents.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 09/03/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool subsets the spatial extents of the input data. The user may manually 
;              enter new dimension parameters or choose to use the dimensions of an existing 
;              image file.
;
; INPUT:       One or more single band raster datasets.
;
; OUTPUT:      One subsetted dataset per input. The output filename is the same name as the 
;              input with the added suffix '.SUBSET' (see line 151).
;
; PARAMETERS:  Via ENVI and IDL widgets, set:
;
;              1.  SELECT THE INPUT DATA: see INPUT
;              
;              2.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;              
;              3.  DEFINE THE SUBSET: define the subset using the ENVI subset widget (see the
;                  ENVI help for more information).
;
; NOTES:       The input data must have identical dimensions. An interactive ENVI session is 
;              needed to run this tool. The input data must have an associated ENVI header file.
;
;              Note that when you select subset by file in the ENVI subset widget the subset is 
;              one cell too many in the X and Y direction. To correct this manually subtract one 
;              (cell) from the ‘Samples’ ‘To’ text box and from the ‘Lines’ ‘To’ text box.
;              
;              For more information contact Garth.Warren@csiro.au
;              
; ##############################################################################################


PRO BATCH_DOIT_Subset_Extents
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Subset_Extents'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE INPUT:
  PATH='C:\'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_X = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=FILTER, /MUST_EXIST, $
    /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_X[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_X = IN_X[SORT(IN_X)]
  ;--------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT:
  ;--------------
  ; GET FNAME_SHORT
  FNAME_START_X = STRPOS(IN_X, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH_X = (STRLEN(IN_X)-FNAME_START_X)-4
  ;--------------
  ; GET FILENAME ARRAY
  FN_X = MAKE_ARRAY(1, N_ELEMENTS(IN_X), /STRING)
  FOR a=0, N_ELEMENTS(IN_X)-1 DO BEGIN
    ; ADD THE a-TH FILENAME TO THE FILENAME ARRAY
    FN_X[*,a] += STRMID(IN_X[a], FNAME_START_X[a], FNAME_LENGTH_X[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY
  PATH='C:\' 
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; DEFINE SUBSET:
  ;--------------------------------------------------------------------------------------------- 
  ; GET THE FIRST FILE IN THE LIST
  IN_FIRST = IN_X[0]
  ;--------------------------------------
  ; OPEN FILE
  ENVI_OPEN_FILE, IN_FIRST, /NO_REALIZE, R_FID=FID_FIRST
  ;--------------
  ; QUERY FILE
  ENVI_FILE_QUERY, FID_FIRST, DIMS=DIMS_X, NS=NS_X, NL=NL_X, NB=NB_X, INTERLEAVE=INTERLEAVE_X, $
    DATA_TYPE=DT_X, FILE_TYPE=FILE_TYPE_X, OFFSET=OFFSET_X, DATA_OFFSETS=DATA_OFFSETS_X, $
    DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_X
  ;--------------
  ; GET MAP INFORMATION
  MAPINFO_X = ENVI_GET_MAP_INFO(FID=FID_FIRST)
  PROJFULL_X = MAPINFO_X.PROJ
  DATUM_X = MAPINFO_X.PROJ.DATUM
  PROJ_X = MAPINFO_X.PROJ.NAME
  UNITS_X = MAPINFO_X.PROJ.UNITS
  XSIZE_X = DOUBLE(MAPINFO_X.PS[0])
  YSIZE_X = DOUBLE(MAPINFO_X.PS[1])
  CXUL_X = DOUBLE(MAPINFO_X.MC[2])
  CYUL_X = DOUBLE(MAPINFO_X.MC[3])
  LOCX_X = DOUBLE(MAPINFO_X.MC[0])
  LOCY_X = DOUBLE(MAPINFO_X.MC[1])
  ;--------------------------------------
  ; SET SUBSET:
  ;--------------------------------------
  ; CALL SUBSET WIDGET
  BASE = WIDGET_AUTO_BASE(TITLE='DEFINE THE SUBSET')
  WS = WIDGET_SUBSET(BASE, UVALUE='SUBSET', FID=FID_FIRST, DIMS=DIMS_X, /AUTO)
  RESULT = AUTO_WID_MNG(BASE)
  ;--------------
  IF (RESULT.ACCEPT EQ 0) THEN BEGIN
    PRINT, ''
    PRINT, 'THE SELECTED SUBSET IS NOT VALID'
    PRINT, ''
    RETURN
  ENDIF
  ;--------------
  ; SET SUBSET DIMENSIONS
  DIMS_OUT = RESULT.SUBSET
  ;--------------
  ; SET OUTPUT NUMBER OF SAMPLES AND LINES
  IF DIMS_OUT[1] EQ 0 THEN NS_OUT = (DIMS_OUT[2] + 1) ELSE NS_OUT = (DIMS_OUT[2] - DIMS_OUT[1]) + 1
  IF DIMS_OUT[3] EQ 0 THEN NL_OUT = (DIMS_OUT[4] + 1) ELSE NL_OUT = (DIMS_OUT[4] - DIMS_OUT[3]) + 1
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_X)-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;------------------------------------------------------------------------------------------- 
    ; GET DATA:
    ;-------------------------------------------------------------------------------------------
    ; GET THE i-TH INPUT FILENAME
    FILE_IN = IN_X[i]
    ;--------------
    ; GET THE i-TH INPUT FILENAME SHORT    
    FSHORT_IN = FN_X[i]
    ;--------------
    ; BUILD THE OUTPUT FILENAME
    FILE_OUT = OUT_DIRECTORY + FSHORT_IN + '.SUBSET.img'
    ;--------------------------------------
    ; OPEN THE i-TH INPUT FILE
    ENVI_OPEN_FILE, FILE_IN, R_FID=FID_IN, /NO_REALIZE
    ;--------------
    ; QUERY THE i-TH INPUT FILE
    ENVI_FILE_QUERY, FID_IN, DATA_TYPE=DT_OUT   
    ;------------------------------------------------------------------------------------------- 
    ; SUBSET DATA AND WRITE:
    ;-------------------------------------------------------------------------------------------  
    ; GET DATA FOR THE SELECTED SUBSET
    DATA_IN = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS_OUT, POS=0)
    ;--------------------------------------
    ; CREATE THE OUTPUT MAPINFO STRUCTURE 
    MAPINFO_OUT = ENVI_MAP_INFO_CREATE(DATUM=DATUM_X, NAME=PROJ_X, PROJ=PROJFULL_X, PS=[XSIZE_X, YSIZE_X], $
      MC=[LOCX_X, LOCY_X, CXUL_X + (DCOMPLEX(DIMS_OUT[1]) * DCOMPLEX(XSIZE_X)), $
      CYUL_X - (DCOMPLEX(DIMS_OUT[3]) * DCOMPLEX(YSIZE_X))], UNITS=UNITS_X)
    ;--------------------------------------    
    ; WRITE DATA
    ENVI_WRITE_ENVI_FILE, DATA_IN, OUT_NAME=FILE_OUT, MAP_INFO=MAPINFO_OUT, $
      PIXEL_SIZE=[XSIZE_X, YSIZE_X], OUT_DT=DT_OUT, NS=NS_OUT, NL=NL_OUT, $
      NB=NB_X, FILE_TYPE=FILE_TYPE_X, UNITS=UNITS_X, /NO_OPEN
    ;-------------------------------------------------------------------------------------------    
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), $
      ' OF ', STRTRIM(N_ELEMENTS(IN_X), 2)
    ;-------------------------------------------------------------------------------------------    
  ENDFOR ; FOR i
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Subset_Extents'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END  