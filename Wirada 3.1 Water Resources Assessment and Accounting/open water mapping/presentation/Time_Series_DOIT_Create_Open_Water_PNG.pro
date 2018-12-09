; ##############################################################################################
; NAME: Time_Series_DOIT_Create_Open_Water_PNG.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 08/06/2010
; DLM: 10/06/2010
;
; DESCRIPTION: This tool create a PNG file for each input file. The tool processes all the image files
;              in the selected INPUT DIRECTORY. The output png files are saved to the selecetd OUTPUT 
;              DIRECTORY.
;
; INPUT:       One or more single-band OR multi-band grids.
;
; OUTPUT:      One PNG file (.png) for each input.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              'SELECT THE INPUT DIRECTORY'
;              'SELECT THE OUTPUT DIRECTORY'
;              
; NOTES:       The output colour table has been set to display low grid values as white, very low
;              values as transparent, high values as blue with increasing intensity, and cloud or 
;              missing data values as yellow.
;
; ##############################################################################################


PRO Time_Series_DOIT_Create_Open_Water_PNG
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_DOIT_Create_Open_Water_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DIRECTORY:
  TITLE='SELECT THE INPUT DIRECTORY'
  PATH = 'C:\workspace\avhrr\anomalies\total'
  ;-----------------------------------  
  PARENT = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF PARENT EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  PATH = 'C:\Users\war409\Documents\data\projects\AVHRR_Presentation'
  ;-----------------------------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; PROCESS IMAGE FILES IN THE PARENT DIRECTORY:
  ;---------------------------------------------------------------------------------------------
  ; SEACH FOR IMAGE FILES:
  ;-----------------------------------
  ; CHANGE CWD TO THE INPUT DIRECTORY
  CD, PARENT, CURRENT=OWD
  ;-----------------------------------  
  FILTER=['*.tif','*.img','*.flt','*.bin','*.rst']
  ; GET LIST OF FILES IN THE NEW CWD
  LIST_FILES = FILE_SEARCH(FILTER, COUNT=COUNT_FILES)
  ;-----------------------------------  
  ; RESET THE WORKING DIRECTORY
  CD, OWD
  ;---------------------------------------------------------------------------------------------
  ; FILE LOOP:
  ;---------------------------------------------------------------------------------------------
  ; STATUS CHECK: IF THERE ARE NO FILES IN THE CURRENT DIRECTORY JUMP TO THE END OF THE SCRIPT
  IF COUNT_FILES EQ 0 THEN GOTO, JUMP
  ;-----------------------------------
  FOR f=0, COUNT_FILES-1 DO BEGIN ; start parent directory file loop
    ;-------------------------------------------------------------------------------------------
    ; BUILD FILENAME
    FILE_IN = PARENT + LIST_FILES[f]
    ; FILE TYPE CHECK
    PATTERN_1 = ['*OWL*']
    PATTERN_2 = ['*Proportion*']
    MATCH_STATUS_1 = STRMATCH(LIST_FILES[f], PATTERN_1)
    MATCH_STATUS_2 = STRMATCH(LIST_FILES[f], PATTERN_2)
    ;-------------------------------------------------------------------------------------------
    ; SET COLOUR SCALE
    IF f EQ 0 THEN BEGIN
      ;----------------------------------- 
      ; SET RED COLOR RAMP
      RED = INTARR(256)
      RED[0:63] = [255,255,251,247,243,239,235,231,227,223,219,215,211,207,203,199,195,191,187,183,179,175,170,166,162, $
      158,154,150,146,142,138,134,130,126,122,118,114,110,106,102,98,94,90,85,81,77,73,69,65,61,57,53,49, $
      45,41,37,33,29,25,21,17,13,9,5]
      ; SET GREEN COLOR RAMP
      GREEN = INTARR(256)
      GREEN[0:159] = [255,255,254,252,251,249,247,246,244,243,241,239,238,236,235,233,231,230,228,227,225,223,222,220,219,217,215,214, $
      212,211,209,207,206,204,203,201,199,198,196,195,193,191,190,188,187,185,183,182,180,179,177,175,174,172,170,169, $
      167,166,164,162,161,159,158,156,154,153,151,150,148,146,145,143,142,140,138,137,135,134,132,130,129,127,126,124, $
      122,121,119,118,116,114,113,111,110,108,106,105,103,102,100,98,97,95,94,92,90,89,87,85,84,82,81,79,77,76,74,73, $
      71,69,68,66,65,63,61,60,58,57,55,53,52,50,49,47,45,44,42,41,39,37,36,34,33,31,29,28,26,25,23,21,20,18,17,15,13, $
      12,10,9,7,5,4,2]
      ; SET BLUE COLOR RAMP
      BLUE = INTARR(256)
      BLUE[0:68] = 255 
      BLUE[69:255] = [253,252,250,249,248,246,245,244,242,241,240,238,237,236,234,233,231,230,229,227,226,225,223,222, $
      221,219,218,217,215,214,212,211,210,208,207,206,204,203,202,200,199,198,196,195,193,192,191,189,188,187,185,184, $
      183,181,180,179,177,176,174,173,172,170,169,168,166,165,164,162,161,160,158,157,155,154,153,151,150,149,147,146, $
      145,143,142,141,139,138,136,135,134,132,131,130,128,127,126,124,123,122,120,119,118,116,115,113,112,111,109,108, $
      107,105,104,103,101,100,99,97,96,94,93,92,90,89,88,86,85,84,82,81,80,78,77,75,74,73,71,70,69,67,66,65,63,62,61, $
      59,58,56,55,54,52,51,50,48,47,46,44,43,42,40,39,37,36,35,33,32,31,29,28,27,25,24,23,21,20,18,17,16,14,13,12,10,9, $
      8,6,5,4,2,1]
      ; UPDATE RED & GREEN COLOR RAMP - SET HIGH VALUES (CLOUD 255) TO YELLOW
      IF MATCH_STATUS_1 EQ 1 THEN RED[155:255]=255 ELSE GREEN[155:255]=255
      ;-----------------------------------
      ; CREATE VECTOR TRANSPARENT
      TRANSPARENT = INTARR(256)
      ; UPDATE VECTOR TRANSPARENT
      ;IF MATCH_STATUS_2 EQ 0 THEN TRANSPARENT[5:254]=255 ELSE TRANSPARENT[1:254]=255
    ENDIF
    ;-----------------------------------
    ; GET FILE INFORMATION: 
    ;-----------------------------------
    ; OPEN FILE    
    ENVI_OPEN_FILE, FILE_IN, R_FID=FID_IN, /NO_REALIZE
    ENVI_FILE_QUERY, FID_IN, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DATATYPE
    ; SET REDUCTION FACTOR
    REDUCTION_FACTOR = 1
    ; SET INPUT FILE DIMENSIONS
    DIMS_IN = [NS, NL]
    ; SET OUTPUT FILE DIMENSIONS
    DIMS_OUT = DIMS_IN / REDUCTION_FACTOR
    ;-------------------------------------------------------------------------------------------
    IF NB GT 1 THEN BEGIN
      ;-----------------------------------------------------------------------------------------
      ; BAND LOOP:  
      ;-----------------------------------------------------------------------------------------
      FOR b=0, NB-1 DO BEGIN ; start parent directory file-band loop
        ;---------------------------------------------------------------------------------------
        ; GET DATA
        DATA = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS, POS=b)
        ;-----------------------------------
        ; DATA TYPE CHECK: CONVERT CONTINUOUS DATA TO INTEGER
        ;IF (DATATYPE GE 4) OR (DATATYPE LE 9) THEN DATA = FIX(DATA*100.00)
        ; CONVERT DATATYPE TO BYTE
        DATA_PNG = BYTE(TEMPORARY(DATA))
        ;-----------------------------------      
        ; SET BANDNAME
        BNAME = BNAMES[b]
        ; OUTNAME
        OUTNAME = OUT_DIRECTORY + BNAME + '.png'
        ;---------------------------------------------------------------------------------------
        ; SAVE PNG
        PRINT, '  SAVE PNG: ',  FNAME_SHORT + '.png'
        WRITE_PNG, OUTNAME, DATA_PNG, RED, GREEN, BLUE, TRANSPARENT=TRANSPARENT, /ORDER
        ;---------------------------------------------------------------------------------------
      ENDFOR ; end parent directory file-band loop
        ;---------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN
      ;----------------------------------------------------------------------------------------- 
      ; GET DATA
      DATA = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS, POS=0)
      ; TRIME FILENAME
      EXTENSION_LENGTH = 4 ; SET EXTENSION LENGTH (i.e. '.img' is 4 characters long) 
      FNAME_LENGTH = STRLEN(LIST_FILES[f])-EXTENSION_LENGTH
      FNAME_SHORT = STRMID(LIST_FILES[f], 0, FNAME_LENGTH)
      ; BUILD OUTNAME
      OUTNAME = OUT_DIRECTORY + FNAME_SHORT + '.png'
      ; DATA TYPE CHECK: CONVERT CONTINUOUS DATA TO INTEGER
      ;IF (DATATYPE GE 4) OR (DATATYPE LE 9) THEN DATA = FIX(DATA*100.00)
      ; CONVERT DATATYPE TO BYTE
      DATA_PNG = BYTE(TEMPORARY(DATA))
      ;----------------------------------------------------------------------------------------- 
      ; SAVE PNG
      PRINT, '  SAVE PNG: ',  FNAME_SHORT + '.png'
      WRITE_PNG, OUTNAME, DATA_PNG, RED, GREEN, BLUE, TRANSPARENT=TRANSPARENT, /ORDER
      ;-----------------------------------------------------------------------------------------     
    ENDELSE
    ;-------------------------------------------------------------------------------------------
  ENDFOR ; end parent directory file loop
  ;---------------------------------------------------------------------------------------------
  JUMP:
  ;---------------------------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2), ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_DOIT_Create_Open_Water_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END