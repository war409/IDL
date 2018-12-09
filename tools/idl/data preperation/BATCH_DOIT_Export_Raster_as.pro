; ##############################################################################################
; NAME: BATCH_DOIT_Export_Raster_as.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 29/09/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool exports input raster data to a different raster dataset format.
; 
;              The available output raster formats include: ArcView Raster, ASCII, ENVI Standard,
;              ESRI GRID, JPEG2000, and TIFF.  
;
; INPUT:       One or more ENVI compatible single band raster datasets.       
;
; OUTPUT:      One output raster dataset of the user-selected format per input. The output file name 
;              is identical to the input file name, with the exception of output ESRI GRID. 
;              
;              The ESRI GRID raster format has some specific naming restrictions: The maximum 
;              number of characters in an ESRI GRID filename is 13; Cannot start with a number; 
;              Cannot have spaces; Cannot use special characters.
;               
;              The user may select input data that conflicts with the above restrictions. The 
;              program will automatically remove invalid special characters and will only use the 
;              first 13 characters of the input filename.
;               
; PARAMETERS:  Via ENVI and IDL widgets, set:
; 
;              1.  SELECT THE INPUT DATA: see INPUT
;              
;              2.  SELECT THE OUTPUT RASTER FORMAT: see DESCRIPTION
;              
;              2.1   SET THE ASCII CHARACTER FIELD WIDTH (ASCII only)
;              
;              2.2   SET THE ASCII CHARACTER FIELD PRECISION (ASCII only)
;              
;              3.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;              
; NOTES:       An interactive ENVI session is needed to run this tool.
; 
;              FUNCTIONS:
;               
;              This program calls one or more external functions. You will need to compile the  
;              necessary functions in IDL, or save the functions to the current IDL workspace  
;              prior to running this tool. To open a different workspace, select Switch  
;              Workspace from the File menu.
;               
;              Functions used in this program include:
;               
;              FUNCTION_WIDGET_Radio_Button
;              FUNCTION_WIDGET_Enter_Value
; 
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_Export_Raster_as
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Export_Raster_as'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA
  IN_FILES = ENVI_PICKFILE(TITLE='SELECT THE INPUT DATA', /MULTIPLE_FILES)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;--------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT:
  ;--------------
  ; GET FNAME_SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  IN_FSHORT = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; ADD THE a-TH FILENAME TO THE FILENAME ARRAY
    IN_FSHORT[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT RASTER FORMAT
  VALUES = ['ARCVIEW Raster', 'ASCII', 'ENVI Standard (.img)', 'ESRI Grid', 'JPEG2000', 'TIFF']
  TYPE_FORMAT = FUNCTION_WIDGET_Radio_Button('SELECT THE OUTPUT RASTER FORMAT ', VALUES)
  ;---------------------------------------------------------------------------------------------
  ; SET ASCII FIELD KEYWORD
  IF TYPE_FORMAT EQ 1 THEN BEGIN
    ;--------------    
    FIELD_WIDTH = FUNCTION_WIDGET_Enter_Value('SET THE ASCII CHARACTER FIELD WIDTH ', 10)
    FIELD_PRECISION = FUNCTION_WIDGET_Enter_Value('SET THE ASCII CHARACTER FIELD PRECISION ', 2)
    FIELD_ARRAY = MAKE_ARRAY(2, 1, /LONG)
    FIELD_ARRAY[0,0] = FIELD_WIDTH
    FIELD_ARRAY[1,0] = FIELD_PRECISION
    ;--------------  
  ENDIF
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE OUTPUT DIRECTORY:
  PATH='C:\'
  ;--------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;------------------------------------------------------------------------------------------- 
    ;*******************************************************************************************
    ; GET DATA:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    ; GET THE i-TH INPUT FILENAME
    FILE_IN = IN_FILES[i]
    ;--------------
    ; GET THE i-TH INPUT FILENAME SHORT    
    FSHORT_IN = IN_FSHORT[i]
    ;--------------------------------------
    ; OPEN THE i-TH INPUT FILE
    ENVI_OPEN_FILE, FILE_IN, R_FID=FID_IN, /NO_REALIZE
    ;--------------
    ; GET MAP INFORMATION
    MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_IN)
    PROJ_IN = MAPINFO_IN.PROJ
    DATUM_IN = MAPINFO_IN.PROJ.DATUM
    PROJNAME_IN = MAPINFO_IN.PROJ.NAME
    UNITS_IN = MAPINFO_IN.PROJ.UNITS
    XSIZE_IN = DOUBLE(MAPINFO_IN.PS[0])
    YSIZE_IN = DOUBLE(MAPINFO_IN.PS[1])
    XUL_IN = DOUBLE(MAPINFO_IN.MC[2])
    YUL_IN = DOUBLE(MAPINFO_IN.MC[3])
    XO_IN = DOUBLE(MAPINFO_IN.MC[0])
    YO_IN = DOUBLE(MAPINFO_IN.MC[1])
    ;--------------
    ; QUERY THE i-TH INPUT FILE
    ENVI_FILE_QUERY, FID_IN, DIMS=DIMS_IN, DATA_TYPE=DATATYPE_IN, NS=NS_IN, NL=NL_IN
    ;-------------------------------------------------------------------------------------------    
    ;*******************************************************************************************
    ; WRITE OUTPUT:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    IF TYPE_FORMAT EQ 0 THEN BEGIN
      ;--------------
      ; BUILD THE OUTPUT FILENAME
      FILE_OUT = OUT_DIRECTORY + FSHORT_IN + '.bil'
      ;--------------
      ; SAVE AS ARCVIEW RASTER
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_IN, DIMS=DIMS_IN, OUT_NAME=FILE_OUT, POS=0, /ARCVIEW
      ;--------------
    ENDIF
    ;--------------------------------------
    IF TYPE_FORMAT EQ 1 THEN BEGIN
      ;--------------
      ; BUILD THE OUTPUT FILENAME
      FILE_OUT = OUT_DIRECTORY + FSHORT_IN + '.asc'
      ;--------------     
      ; SAVE AS ASCII
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_IN, DIMS=DIMS_IN, OUT_NAME=FILE_OUT, POS=0, FIELD=FIELD_ARRAY, /ASCII
      ;--------------
    ENDIF
    ;--------------------------------------
    IF TYPE_FORMAT EQ 2 THEN BEGIN
      ;--------------
      ; BUILD THE OUTPUT FILENAME
      FILE_OUT = OUT_DIRECTORY + FSHORT_IN + '.img' 
      ;--------------      
      ; SAVE AS ENVI STANDARD
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_IN, DIMS=DIMS_IN, OUT_NAME=FILE_OUT, POS=0, /ENVI
      ;--------------
    ENDIF
    ;--------------------------------------
    IF TYPE_FORMAT EQ 3 THEN BEGIN
      ;--------------
      ; CHECK FILE NAME LENGTH 
      IF STRLEN(FSHORT_IN) GT 12 THEN FSHORT_IN = STRMID(FSHORT_IN, 0, 12)
      ;--------------
      ; CHECK INVALID CHARACTERS
      INVALID_ARRAY = ['.','(',')','{','}','[',']','\','~','"',"'",',','%','$','@','!','^','&','*',';',':','<','>','?']
      FOR j=0, N_ELEMENTS(INVALID_ARRAY)-1 DO BEGIN
        INVALID = INVALID_ARRAY[j]
        CPOS = 0
        WHILE (CPOS GE 0) DO BEGIN
          CPOS = STRPOS(FSHORT_IN, INVALID)
          IF CPOS GE 0 THEN STRPUT, FSHORT_IN, ' ', CPOS
        ENDWHILE
      ENDFOR
      ;--------------
      ; REMOVE ANY SPACES
      FSHORT_IN = STRCOMPRESS(FSHORT_IN, /REMOVE_ALL) 
      ;--------------
      ; BUILD THE OUTPUT FILENAME
      FILE_OUT = OUT_DIRECTORY + FSHORT_IN
      PRINT, FILE_OUT
      ;--------------   
      ; SAVE AS ESRI GRID
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_IN, DIMS=DIMS_IN, OUT_NAME=FILE_OUT, POS=0, /ESRI_GRID
      ;--------------
    ENDIF
    ;--------------------------------------
    IF TYPE_FORMAT EQ 4 THEN BEGIN
      ;-------------- 
      ; BUILD THE OUTPUT FILENAME
      FILE_OUT = OUT_DIRECTORY + FSHORT_IN 
      ;--------------   
      ; SAVE AS JPEG2000
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_IN, DIMS=DIMS_IN, OUT_NAME=FILE_OUT, POS=0, /JP2
      ;--------------
    ENDIF
    ;--------------------------------------
    IF TYPE_FORMAT EQ 5 THEN BEGIN
      ;--------------
      ; BUILD THE OUTPUT FILENAME
      FILE_OUT = OUT_DIRECTORY + FSHORT_IN + '.tif'
      ;--------------   
      ; SAVE AS TIFF
      ENVI_OUTPUT_TO_EXTERNAL_FORMAT, FID=FID_IN, DIMS=DIMS_IN, OUT_NAME=FILE_OUT, POS=0, /TIFF
      ;--------------
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Export_Raster_as'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END
