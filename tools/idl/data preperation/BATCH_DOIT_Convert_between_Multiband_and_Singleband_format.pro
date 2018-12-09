; ##############################################################################################
; NAME: BATCH_DOIT_Convert_between_Multiband_and_Singleband_format.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 04/01/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool converts the selected input multiband raster file to multiple single-band
;              files.
;
;              The user may also select multiple single band grids and create a single multiband
;              output.
;
; INPUT:       One or more multiband image files.
;
;              OR
;
;              Two or more single band rasters.
;
; OUTPUT:      One new single band image per input multiband band.
;
;              OR
;
;              One new multiband image per multiple input single band rasters.
;
; PARAMETERS:  Via IDL widgets, set:
;
;              1.  SELECT THE CONVERSION TYPE: Select whether to convert multiband files to single
;                  band files, or single band files to a multiband file.
;
;              2.  SELECT THE INPUT DATA: see INPUT
;
;              3.  SELECT THE OUTPUT DIRECTORY (multiband band to single only): The output data
;                  is saved to this location.
;
;              OR
;
;              3.  DEFINE THE OUTPUT FILE (single band to multiband only): The output multiband
;                  file
;
; NOTES:       An interactive ENVI session is needed to run this tool.
;
;              When converting single band to multiband, the input data should have identical
;              dimensions, the same data-type, and use same coordinate system.
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
;
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_Convert_between_Multiband_and_Singleband_format
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Convert_between_Multiband_and_Singleband_format'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT CONVERSION TYPE
  VALUES = ['Convert Multi-Band To Single-Band', 'Convert Single-Band To Multi-Band']
  ;CT = FUNCTION_WIDGET_Radio_Button('SELECT THE CONVERSION TYPE  ', VALUES)
CT=1
  ;---------------------------------------------------------------------------------------------
  IF CT EQ 0 THEN BEGIN ; MULTIBAND TO SINGLEBAND
    ;-----------------------------------
    ; SELECT THE INPUT DATA:
    PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled_Open_Water\MOD09A1\New'
    IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=['*.tif','*.img','*.flt','*.bin'], $
      /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
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
    ;-------------------------------------------------------------------------------------------
    ; SELECT THE OUTPUT DIRECTORY
    OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
    ;--------------
    ; ERROR CHECK
    IF OUT_DIRECTORY EQ '' THEN RETURN
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; FILE LOOP:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
      ;-----------------------------------------------------------------------------------------
      ; GET START TIME: FILE LOOP
      L_TIME = SYSTIME(1)
      ;-----------------------------------------------------------------------------------------
      ; GET DATA:
      ;-----------------------------------------------------------------------------------------
      ; SET THE i-TH FILE
      FILE_IN = IN_FILES[i]
      ;--------------
      ; SET THE i-TH FILENAME
      FN_IN = FNS[i]
      ;-----------------------------------------------------------------------------------------
      ; OPEN FILE
      ENVI_OPEN_FILE, FILE_IN, /NO_REALIZE, R_FID=FID
      ;-----------------------------------------------------------------------------------------
      ; QUERY FILE
      ENVI_FILE_QUERY, FID, SNAME=SNAME, DIMS=INDIMS, BNAMES=BNAME, NS=NS, NL=NL, DATA_TYPE=DT
      ;-----------------------------------------------------------------------------------------
      ;*****************************************************************************************
      ; BAND LOOP:
      ;*****************************************************************************************
      ;-----------------------------------------------------------------------------------------
      FOR j=0, N_ELEMENTS(BNAME)-1 DO BEGIN ; FOR j
        ;---------------------------------------------------------------------------------------
        ; GET BAND NAME
        BANDNAME = BNAME[j]
        ;--------------
        ; SET THE OUTPUT FILENAME
        FNAME_OUT = OUT_DIRECTORY + BANDNAME + '.img'
        ;---------------------------------------------------------------------------------------
        ; WRITE DATA
        ENVI_DOIT, 'CF_DOIT', FID=FID, DIMS=INDIMS, POS=[j], OUT_DT=DT, OUT_NAME=FNAME_OUT, R_FID=RFID, OUT_BNAME=BANDNAME, /NO_REALIZE
        ;---------------------------------------------------------------------------------------
      ENDFOR ; FOR j
      ;-----------------------------------------------------------------------------------------
      ; PRINT LOOP INFORMATION:
      ;-----------------------------------
      ; GET END TIME
      SECONDS = (SYSTIME(1)-L_TIME)
      ;--------------
      ; PRINT
      PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), $
        ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
      ;-----------------------------------------------------------------------------------------
    ENDFOR ; FOR i
    ;-------------------------------------------------------------------------------------------
  ENDIF ELSE BEGIN ; SINGLEBAND TO MULTIBAND
    ;-----------------------------------
    ; SELECT THE INPUT DATA:
    PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled_Open_Water\MOD09A1\New'
    IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=['*.tif','*.img','*.flt','*.bin','*.dat'], /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
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
    ;-------------------------------------------------------------------------------------------
    ; SET THE OUTPUT FILE
    FNAME_OUT = DIALOG_PICKFILE(PATH=PATH, TITLE='DEFINE THE OUTPUT FILE', /OVERWRITE_PROMPT)
    ;--------------
    ; ERROR CHECK
    IF FNAME_OUT EQ '' THEN RETURN
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; FILE LOOP:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    ; MAKE ARRAYS TO HOLD LOOP DATA:
    ;--------------
    ARRAY_FID = MAKE_ARRAY(N_ELEMENTS(IN_FILES), /INTEGER)
    ARRAY_BNAME = MAKE_ARRAY(N_ELEMENTS(IN_FILES), /STRING)
    ARRAY_POS = MAKE_ARRAY(N_ELEMENTS(IN_FILES), /INTEGER)
    ;-------------------------------------------------------------------------------------------
    FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
      ;-----------------------------------------------------------------------------------------
      ; GET DATA:
      ;-----------------------------------------------------------------------------------------
      ; SET THE i-TH FILE
      FILE_IN = IN_FILES[i]
      ;--------------
      ; SET THE i-TH FILENAME
      FN_IN = FNS[i]
      ;-----------------------------------------------------------------------------------------
      ; OPEN FILE
      ENVI_OPEN_FILE, FILE_IN, /NO_REALIZE, R_FID=FID
      ;-----------------------------------------------------------------------------------------
      ; QUERY FILE
      ENVI_FILE_QUERY, FID, SNAME=SNAME, DIMS=INDIMS, BNAMES=BNAME, NS=NS, NL=NL, DATA_TYPE=DT
      ;-----------------------------------------------------------------------------------------
      ; ADD DATA TO ARRAYS:
      ;--------------
      ARRAY_FID[i] = FID
      ARRAY_BNAME[i] = SNAME
      ARRAY_POS[i] = 0
      ;-----------------------------------------------------------------------------------------
    ENDFOR ; END 'FOR i'
    ;-------------------------------------------------------------------------------------------
    ; WRITE DATA
    ENVI_DOIT, 'CF_DOIT', FID=ARRAY_FID, DIMS=INDIMS, POS=ARRAY_POS, OUT_DT=DT, OUT_NAME=FNAME_OUT, OUT_BNAME=ARRAY_BNAME, R_FID=RFID, /NO_REALIZE
    ;-------------------------------------------------------------------------------------------
  ENDELSE
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Convert_between_Multiband_and_Singleband_format'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END