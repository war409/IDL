; ##############################################################################################
; NAME: MODIS_Time_Series_DOIT_State_Flag_Cloud_Information.pro
; LANGUAGE: IDL + 7zip
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 17/06/2010
; DLM: 21/06/2010
;
; DESCRIPTION: This tool queries the input MODIS state flag data. For each input the percentage of
;              clear pixels; cloud pixels; pixels with cloud shadow; and pixels with a mixture of
;              clear and cloud cover is returned.
;
; INPUT:       Compressed (.hdf.gz) MODIS data. This tool searches for MODIS state flag grids within
;              the user selected MODIS product folder. The user should select a MODIS product
;              directory @ - \\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust - the tool will
;              automatically search for valid data within the product folder sub-directories. The
;              tool will loop until all valid data under the initial parent directory has been
;              queried.
;
; OUTPUT:      One user defined comma-delimited text file (See description).
;
; PARAMETERS:  Via IDL widgets, set:
;
;              'SELECT THE INPUT DIRECTORY'
;              'DEFINE THE OUTPUT FILE'
;
; NOTES:
;
;              BITWISE OPERATORS...
;
;              In bitwise operators the 'AND operator' takes two binary 'objects' of equal length
;              and performs the following 'logical operation'. At each bit-location
;              (i.e. 0000000000000001 has 16-bits) each input is compared. If both objects have a
;              value of '1' at the same bit-location the result is 1. If the objects have any other
;              combination the result is 0.
;
;              For example:
;
;              1033 AND 1 = 0000010000001001 AND 0000000000000001
;                         = 0000000000000001
;                         = BINARY(1)
;
;              The result above (0000000000000001) occurs because the only bit that has a value of 1
;              in both 0000010000001001 and 0000000000000001 at the same bit-location is the last or
;              16th bit.
;
;              Another example:
;
;              8205 AND 8025 = 0010000000001101 AND 0001111101011001
;                            = 0000000000001001
;                            = BINARY(9)
;
; ##############################################################################################




;************************************************************************************************
; FUNCTIONS: START
;************************************************************************************************


; ##############################################################################################
FUNCTION BITWISE_OPERATOR, DATA, BIN, EQV, WV
  ;---------------------------------------------------------------------------------------------
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BIN) EQ EQV)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WV, COUNT)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [COUNT]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################

; ##############################################################################################
FUNCTION BITWISE_OPERATOR_AND, DATA, BIN1, EQV1, BIN2, EQV2, WV
  ;---------------------------------------------------------------------------------------------
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BIN1) EQ EQV1) AND ((DATA AND BIN2) EQ EQV2)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WV, COUNT)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [COUNT]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


;************************************************************************************************
; FUNCTIONS: END
;************************************************************************************************




PRO MODIS_Time_Series_DOIT_State_Flag_Cloud_Information
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: MODIS_Time_Series_DOIT_State_Flag_Cloud_Information'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DIRECTORY:
  TITLE='SELECT THE INPUT DIRECTORY'
  PATH = '\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust'
  INPUT_PARENT = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF INPUT_PARENT EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  TITLE='DEFINE THE OUTPUT FILE'
  PATH = '\\File-wron\Working\work\war409\Other\Temp\IDL\MODIS'
  ; DEFINE THE OUTPUT FILE:
  OUTPUT_FILE = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF OUTPUT_FILE EQ '' THEN RETURN
  ;--------------------------------------
  ; GET OUTPUT PATH
  PATH_END = STRPOS(OUTPUT_FILE, '\', /REVERSE_SEARCH)
  OUTPUT_PATH = STRMID(OUTPUT_FILE, 0, PATH_END)
  ;---------------------------------------------------------------------------------------------
  ; GET SUB-DIRECTORY LIST:
  ;--------------------------------------
  ; CHANGE CWD TO THE INPUT DIRECTORY
  CD, INPUT_PARENT, CURRENT=OWD
  ;--------------------------------------
  ; GET SUB-DIRECTORY LIST IN THE NEW CWD
  CHILD_LIST = FILE_SEARCH(/TEST_DIRECTORY)
  ;-----------------------------------
  ; RESET THE ORIGINAL WORKING DIRECTORY
  CD, OWD
  ;--------------------------------------
  ; SORT THE SUB-DIRECTORY LIST
  CHILD_LIST = CHILD_LIST[SORT(CHILD_LIST)]
  ;--------------------------------------
  ; SET THE SUB-DIRECTORY COUNT
  COUNT_CHILD = N_ELEMENTS(CHILD_LIST)
  ;--------------------------------------
  ; COUNT CHECK
  IF COUNT_CHILD EQ 0 THEN BEGIN
    PRINT,''
    PRINT, 'NO SUB-DIRECTORYS IN THE PARENT DIRECTORY'
    RETURN
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; CREATE THE OUTPUT FILE
  OPENW, LUN_OUTPUT, OUTPUT_FILE, /GET_LUN
  ;--------------------------------------
  ; SET THE OUTPUT FILE HEAD
  FHEAD=["FID","File","Clear","Mixed","Cloud","Cloud_Shadow","Path"]
  ;--------------------------------------
  ; WRITE THE OUTPUT FILE HEAD
  PRINTF, FORMAT='(10000(A,:,","))', LUN_OUTPUT, '"' + FHEAD + '"'
  ;--------------------------------------
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, LUN_OUTPUT
  ;---------------------------------------------------------------------------------------------
  ; SUB-DIRECTORY LOOP:
  ;---------------------------------------------------------------------------------------------
  FOR i=0, COUNT_CHILD-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; SET THE iTH SUB-DIRECTORY
    CHILD_IN = INPUT_PARENT + CHILD_LIST[i]
    ;--------
    PRINT, '  Searching: ', CHILD_IN, '\ ... ...'
    ;--------------------------------------
    ; CHANGE THE WORKING DIRECTORY
    CD, CHILD_IN, CURRENT=OWD
    ;--------------------------------------
    ; GET THE LIST OF FILES IN CURRENT SUB-DIRECTORY
    FILE_LIST = FILE_SEARCH('*state_flags.hdf.gz')
    ;--------------------------------------
    ; RESET THE ORIGINAL WORKING DIRECTORY
    CD, OWD
    ;--------------------------------------
    ; SORT THE SUB-DIRECTORY LIST
    FILE_LIST = FILE_LIST[SORT(FILE_LIST)]
    ;--------------------------------------
    ; SET THE SUB-DIRECTORY COUNT
    COUNT_FILE = N_ELEMENTS(FILE_LIST)
    ;--------------------------------------
    ; COUNT CHECK
    IF COUNT_FILE EQ 0 THEN CONTINUE
    IF FILE_LIST EQ '' THEN CONTINUE
    ;-------------------------------------------------------------------------------------------
    ; FILE LOOP:
    ;-------------------------------------------------------------------------------------------
    FOR j=0, COUNT_FILE-1 DO BEGIN ; START 'FOR j'
      ;-----------------------------------------------------------------------------------------
      ; SET THE iTH FILE
      FILE = FILE_LIST[j]
      ; GET FILENAME SHORT
      FNAME_LENGTH = (STRLEN(FILE)-0)-7
      FNAME_SHORT = STRMID(FILE, 0, FNAME_LENGTH[0])
      FNAME_STRIP = STRMID(FNAME_SHORT, 0, 21)
      ;--------------------------------------
      ; BUILD THE FULL INPUT FILENAME
      FNAME = CHILD_IN + '\' + FILE
      ;--------------------------------------
      ; EXTRACT THE CURRENT INPUT FILE (UNZIP WITH 7-ZIP VIA MS DOS)
      SPAWN, '7z x ' + FNAME + ' -o' + OUTPUT_PATH, /NOSHELL
      ;--------------------------------------
      ; SET THE UNCOMPRESSED HDF FILENAME
      HDF = OUTPUT_PATH + '\' + FNAME_SHORT + '.hdf'
      ;-----------------------------------------------------------------------------------------
      ; GET THE HDF DATA:
      ;--------------------------------------
      ; OPEN THE HDF FILE
      FID_SD = HDF_SD_START(HDF, /READ)
      ;--------------------------------------
      ; SET THE SD DATASET ID
      ID_SDS = HDF_SD_SELECT(FID_SD, 0)
      ;--------------------------------------
      ; GET FILE INFORMATION
      HDF_SD_FILEINFO, FID_SD, DATASETS, ATTRIBUTES
      HDF_SD_GETINFO, ID_SDS, NAME=SDSNAME
      ;--------------------------------------
      ; GET FILE DATA
      HDF_SD_GETDATA, ID_SDS, DATA
      ;--------------------------------------
      ; CLOSE THE SD FILE
      HDF_SD_END, FID_SD
      ;--------------------------------------
      ; DELETE THE UNCOMPRESSED HDF FILE
      FILE_DELETE, HDF
      ;--------------------------------------
      ; GET THE SIZE (NUMBER OF ELEMENTS) IN DATA
      ELEMENTS = N_ELEMENTS(DATA)
      ;--------
      ; GET THE NODATA (FILL = 65535) COUNT
      INDEX_NAN = WHERE(DATA EQ FLOAT(65535), COUNT_NAN)
      IF (COUNT_NAN GT 0) THEN DATA[INDEX_NAN] = !VALUES.F_NAN
      ;--------
      ; UPDATE ELEMENT COUNT
      ELEMENTS_DATA = ELEMENTS - COUNT_NAN
      ;-----------------------------------------------------------------------------------------
      ; GET STATE INFORMATION:
      ;-----------------------------------------------------------------------------------------
      ; USE BITWISE OPERATORS TO IDENTIFY CLOUD PIXELS
      ; -  SEE 'NOTES' IN THE HEADER FOR MORE INFORMATION
      ; -  WHERE THE CELL (ELEMENT) IS CLEAR (STATUS_STATE = 1)THEN CELL = NO CLOUD
      ; -  WHERE THE CELL (ELEMENT) IS NOT CLEAR (STATUS_STATE = 0) THEN CELL = CLOUD
      ;-----------------------------------------------------------------------------------------
      ; GET PERCENTAGE OF CLOUD PIXELS ["Cloud"= 1 (0000000000000001)]
      COUNT_CLOUD = BITWISE_OPERATOR_AND(DATA, 1, 1, 2, 0, 1)
      ;--------
      CLOUD_P = (FLOAT(COUNT_CLOUD[0]) / FLOAT(ELEMENTS_DATA)) * 100.00
      ;--------------------------------------
      ; GET PERCENTAGE OF CLOUD SHADOW PIXELS ["Cloud_Shadow"=4 (0000000000000100)]
      COUNT_SHADOW = BITWISE_OPERATOR(DATA, 4, 0, 0)
      ;--------
      SHADOW_P = (FLOAT(COUNT_SHADOW[0]) / FLOAT(ELEMENTS_DATA)) * 100.00
      ;--------------------------------------
      ; GET PERCENTAGE OF MIXED PIXELS ["MIXED"= 2 (0000000000000010)]
      COUNT_MIXED = BITWISE_OPERATOR(DATA, 3, 2, 1)
      ;--------
      MIXED_P = (FLOAT(COUNT_MIXED[0]) / FLOAT(ELEMENTS_DATA)) * 100.00
      ;--------------------------------------
      ; GET PERCENTAGE OF NOT SET PIXELS [= 3 (0000000000000011)]
      COUNT_NOTSET = BITWISE_OPERATOR(DATA, 3, 3, 1)
      ;--------
      NOTSET_P = (FLOAT(COUNT_NOTSET[0]) / FLOAT(ELEMENTS_DATA)) * 100.00
      ;--------------------------------------
      ; GET CLEAR VALUE
      CLEAR_P = 100.00 - MIXED_P - CLOUD_P - NOTSET_P
      ;-----------------------------------------------------------------------------------------
      ; WRITE INFORMATION TO FILE:
      ;-----------------------------------------------------------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, LUN_OUTPUT, OUTPUT_FILE, /APPEND, /GET_LUN
      ;--------------------------------------
      ; WRITE DATA
      PRINTF, FORMAT='(10000(A,:,","))', LUN_OUTPUT, STRTRIM(i+j+1, 2),'"' + FNAME_STRIP + '"', $
        STRTRIM(CLEAR_P, 2), STRTRIM(MIXED_P, 2), STRTRIM(CLOUD_P, 2), STRTRIM(SHADOW_P, 2),  $
        '"' + CHILD_IN + '\' + '"'
      ;--------------------------------------
      ; CLOSE THE OUTPUT FILE
      FREE_LUN, LUN_OUTPUT
      ;-----------------------------------------------------------------------------------------
    ENDFOR ; END 'FOR i'
    ;-------------------------------------------------------------------------------------------
  ENDFOR ; END 'FOR i'
  ;---------------------------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2), ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: MODIS_Time_Series_DOIT_State_Flag_Cloud_Information'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END