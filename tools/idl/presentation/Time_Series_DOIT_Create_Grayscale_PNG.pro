; ##############################################################################################
; NAME: Time_Series_DOIT_Create_Grayscale_PNG.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 08/06/2010
; DLM: 28/06/2010
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
;              1.  SELECT THE INPUT DIRECTORY
;              2.  SELECT THE OUTPUT DIRECTORY
;              
; NOTES:       The output colour table has been set to display low grid values as white, very low
;              values as transparent, high values as blue with increasing intensity, and cloud or 
;              missing data values as yellow.
;
; ##############################################################################################


PRO Time_Series_DOIT_Create_Grayscale_PNG
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_DOIT_Create_Grayscale_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DIRECTORY:
  PATH = '\\file-wron\Working\work\'
  ;-----------------------------------  
  PARENT = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF PARENT EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  PATH = '\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\PNG'
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
  FILTER=['*.tif','*.img','*.flt','*.bin']
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
      RED = REVERSE(INDGEN(256))
      ; SET GREEN COLOR RAMP
      GREEN = REVERSE(INDGEN(256))
      ; SET BLUE COLOR RAMP
      BLUE = REVERSE(INDGEN(256))
      ;-----------------------------------
      ; CREATE VECTOR TRANSPARENT
      TRANSPARENT = INTARR(256)
      ; UPDATE VECTOR TRANSPARENT
      IF MATCH_STATUS_2 EQ 1 THEN TRANSPARENT[1:254]=255 
      IF MATCH_STATUS_1 EQ 1 THEN TRANSPARENT[5:254]=255
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
        IF (DATATYPE GE 4) OR (DATATYPE LE 9) THEN DATA = FIX(DATA*100.00)
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
      ; NAN DATA
      x = WHERE(FINITE(DATA, /NAN), COUNT_X)
      IF (COUNT_X GT 0) THEN DATA[x] = 255.00
      ;IF (COUNT_X GT 0) THEN RED[0:1] = 255
      ;IF (COUNT_X GT 0) THEN GREEN[0:1] = 255
      ; DATA TYPE CHECK: CONVERT CONTINUOUS DATA TO INTEGER
      IF (DATATYPE GE 4) OR (DATATYPE LE 9) THEN DATA = FIX(DATA*100.00)
      ; CONVERT DATATYPE TO BYTE
      DATA_PNG = BYTE(TEMPORARY(DATA))
      ;----------------------------------------------------------------------------------------- 
      ; SAVE PNG
      PRINT, '  SAVE PNG: ',  FNAME_SHORT + '.png'
      ;WRITE_PNG, OUTNAME, DATA_PNG, RED, GREEN, BLUE, TRANSPARENT=TRANSPARENT, /ORDER
      WRITE_PNG, OUTNAME, DATA_PNG, RED, GREEN, BLUE, /ORDER
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
  PRINT,'FINISHED PROCESSING: Time_Series_DOIT_Create_Grayscale_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END