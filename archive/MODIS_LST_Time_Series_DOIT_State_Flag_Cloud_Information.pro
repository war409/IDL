; ##############################################################################################
; NAME: MODIS_LST_Time_Series_DOIT_State_Flag_Cloud_Information.pro
; LANGUAGE: IDL + 7zip
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 24/06/2010
; DLM: 24/06/2010
;
; DESCRIPTION: This tool queries the input MODIS LST quality data. For each input the percentage of
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




PRO MODIS_LST_Time_Series_DOIT_State_Flag_Cloud_Information
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: MODIS_LST_Time_Series_DOIT_State_Flag_Cloud_Information'
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
  FHEAD=["FID","File","LST_Produced_Good","LST_Produced_Unreliable","LST_Not_Produced_Cloud","LST_Not_Produced_Other","Path"]
  ;--------------------------------------
  ; WRITE THE OUTPUT FILE HEAD
  PRINTF, FORMAT='(10000(A,:,","))', LUN_OUTPUT, '"' + FHEAD + '"'
  ;--------------------------------------
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, LUN_OUTPUT
  ;---------------------------------------------------------------------------------------------
  ; SUB-DIRECTORY LOOP:
  ;---------------------------------------------------------------------------------------------
  FOR i=1774, COUNT_CHILD-1 DO BEGIN ; START 'FOR i'
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
    FILE_LIST_DAY = FILE_SEARCH('*day_quality.hdf.gz')
    FILE_LIST_NIGHT = FILE_SEARCH('*night_quality.hdf.gz')
    ;--------------------------------------
    ; RESET THE ORIGINAL WORKING DIRECTORY
    CD, OWD
    ;--------------------------------------
    ; SORT THE SUB-DIRECTORY LISTS
    FILE_LIST_DAY = FILE_LIST_DAY[SORT(FILE_LIST_DAY)]
    FILE_LIST_NIGHT = FILE_LIST_NIGHT[SORT(FILE_LIST_NIGHT)]
    ;--------------------------------------
    ; SET THE SUB-DIRECTORY COUNT
    COUNT_FILE = N_ELEMENTS(FILE_LIST_DAY)
    ;--------------------------------------
    ; COUNT CHECK
    IF COUNT_FILE EQ 0 THEN CONTINUE
    IF FILE_LIST_DAY EQ '' THEN CONTINUE
    IF FILE_LIST_NIGHT EQ '' THEN CONTINUE
    ;-------------------------------------------------------------------------------------------
    ; FILE LOOP:
    ;-------------------------------------------------------------------------------------------
    FOR j=0, COUNT_FILE-1 DO BEGIN ; START 'FOR j'
      ;-----------------------------------------------------------------------------------------
      ; SET THE iTH FILE
      FILE_DAY = FILE_LIST_DAY[j]
      FILE_NIGHT = FILE_LIST_NIGHT[j]
      ;--------------------------------------
      ; GET FILENAME SHORT
      FNAME_LENGTH_DAY = (STRLEN(FILE_DAY)-0)-7
      FNAME_SHORT_DAY = STRMID(FILE_DAY, 0, FNAME_LENGTH_DAY[0])
      FNAME_STRIP_DAY = STRMID(FNAME_SHORT_DAY, 0, 21)
      ;--------
      ; GET FILENAME SHORT
      FNAME_LENGTH_NIGHT = (STRLEN(FILE_NIGHT)-0)-7
      FNAME_SHORT_NIGHT = STRMID(FILE_NIGHT, 0, FNAME_LENGTH_NIGHT[0])
      FNAME_STRIP_NIGHT = STRMID(FNAME_SHORT_NIGHT, 0, 21)
      ;--------------------------------------
      ; BUILD THE FULL INPUT FILENAME
      FNAME_DAY = CHILD_IN + '\' + FILE_DAY
      FNAME_NIGHT = CHILD_IN + '\' + FILE_NIGHT
      ;--------------------------------------
      ; EXTRACT THE CURRENT INPUT FILE (UNZIP WITH 7-ZIP VIA MS DOS)
      SPAWN, '7z x ' + FNAME_DAY + ' -o' + OUTPUT_PATH, /NOSHELL
      SPAWN, '7z x ' + FNAME_NIGHT + ' -o' + OUTPUT_PATH, /NOSHELL      
      ;--------------------------------------
      ; SET THE UNCOMPRESSED HDF FILENAME
      HDF_DAY = OUTPUT_PATH + '\' + FNAME_SHORT_DAY + '.hdf'
      HDF_NIGHT = OUTPUT_PATH + '\' + FNAME_SHORT_NIGHT + '.hdf'
      ;-----------------------------------------------------------------------------------------
      ; GET THE HDF DATA:
      ;--------------------------------------
      ; OPEN THE HDF FILE
      FID_SD_DAY = HDF_SD_START(HDF_DAY, /READ)
      ;--------      
      FID_SD_NIGHT = HDF_SD_START(HDF_NIGHT, /READ)
      ;--------------------------------------
      ; SET THE SD DATASET ID
      ID_SDS_DAY = HDF_SD_SELECT(FID_SD_DAY, 0)
      ;--------
      ID_SDS_NIGHT = HDF_SD_SELECT(FID_SD_NIGHT, 0)      
      ;--------------------------------------
      ; GET FILE INFORMATION
      HDF_SD_FILEINFO, FID_SD_DAY, DATASETS, ATTRIBUTES
      HDF_SD_GETINFO, ID_SDS_DAY, NAME=SDSNAME
      ;--------
      HDF_SD_FILEINFO, FID_SD_NIGHT, DATASETS, ATTRIBUTES
      HDF_SD_GETINFO, ID_SDS_NIGHT, NAME=SDSNAME
      ;--------------------------------------
      ; GET FILE DATA
      HDF_SD_GETDATA, ID_SDS_DAY, DATA_DAY
      ;--------
      HDF_SD_GETDATA, ID_SDS_NIGHT, DATA_NIGHT
      ;--------------------------------------
      ; CLOSE THE SD FILE
      HDF_SD_END, FID_SD_DAY
      ;--------
      HDF_SD_END, FID_SD_NIGHT
      ;--------------------------------------
      ; DELETE THE UNCOMPRESSED HDF FILE
      FILE_DELETE, HDF_DAY
      ;--------
      FILE_DELETE, HDF_NIGHT
      ;--------------------------------------
      ; GET THE SIZE (NUMBER OF ELEMENTS) IN DATA
      ELEMENTS_DAY = N_ELEMENTS(DATA_DAY)
      ELEMENTS_NIGHT = N_ELEMENTS(DATA_NIGHT) 
      ;-----------------------------------------------------------------------------------------
      ; GET STATE INFORMATION:
      ;-----------------------------------------------------------------------------------------
      ; USE BITWISE OPERATORS TO IDENTIFY CLOUD PIXELS
      ; -  SEE 'NOTES' IN THE HEADER FOR MORE INFORMATION
      ; -  WHERE THE CELL (ELEMENT) IS CLEAR (STATUS_STATE = 1)THEN CELL = NO CLOUD
      ; -  WHERE THE CELL (ELEMENT) IS NOT CLEAR (STATUS_STATE = 0) THEN CELL = CLOUD
      ;-----------------------------------------------------------------------------------------     
      ; LST PRODUCED BUT UNRELIABLE - 1 (0000000000000001)
      COUNT_PROD_BAD = BITWISE_OPERATOR_AND(DATA_DAY, 1, 1, 2, 0, 1)
      ;--------
      PROD_BAD_P = (FLOAT(COUNT_PROD_BAD[0]) / FLOAT(ELEMENTS_DAY)) * 100.00
      ;--------------------------------------
      ; LST NOT PRODUCED DUE TO CLOUD - 2 (0000000000000010)
      COUNT_NOTPROD_CLOUD = BITWISE_OPERATOR(DATA_DAY, 3, 2, 1)
      ;--------
      NOTPROD_CLOUD_P = (FLOAT(COUNT_NOTPROD_CLOUD[0]) / FLOAT(ELEMENTS_DAY)) * 100.00
      ;--------------------------------------
      ; LST NOT PRODUCED DUE TO OTHER - 3 (0000000000000011)
      COUNT_NOTPROD_OTHER = BITWISE_OPERATOR(DATA_DAY, 3, 3, 1)
      ;--------
      NOTPROD_OTHER_P = (FLOAT(COUNT_NOTPROD_OTHER[0]) / FLOAT(ELEMENTS_DAY)) * 100.00
      ;--------------------------------------
      ; GET CLEAR VALUE
      ;PROD_GOOD_P = 100.00 - NOTPROD_CLOUD_P - PROD_BAD_P - NOTPROD_OTHER_P
      COUNT_PROD_GOOD = BITWISE_OPERATOR_AND(DATA_DAY, 1, 0, 2, 0, 1)
      PROD_GOOD_P = (FLOAT(COUNT_PROD_GOOD[0]) / FLOAT(ELEMENTS_DAY)) * 100.00
      ;-----------------------------------------------------------------------------------------
      ; WRITE INFORMATION TO FILE:
      ;-----------------------------------------------------------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, LUN_OUTPUT, OUTPUT_FILE, /APPEND, /GET_LUN
      ;--------------------------------------
      ; WRITE DATA
      PRINTF, FORMAT='(10000(A,:,","))', LUN_OUTPUT, STRTRIM(i+j+1, 2),'"' + FNAME_STRIP_DAY + '.Day' + '"', $
        STRTRIM(PROD_GOOD_P, 2), STRTRIM(PROD_BAD_P, 2), STRTRIM(NOTPROD_CLOUD_P, 2), STRTRIM(NOTPROD_OTHER_P, 2),  $
        '"' + CHILD_IN + '\' + '"'
      ;--------------------------------------
      ; CLOSE THE OUTPUT FILE
      FREE_LUN, LUN_OUTPUT
      ;-----------------------------------------------------------------------------------------      
      ; LST PRODUCED BUT UNRELIABLE
      COUNT_PROD_BAD = BITWISE_OPERATOR_AND(DATA_NIGHT, 1, 1, 2, 0, 1)
      ;--------
      PROD_BAD_P = (FLOAT(COUNT_PROD_BAD[0]) / FLOAT(ELEMENTS_NIGHT)) * 100.00
      ;--------------------------------------
      ; LST NOT PRODUCED DUE TO CLOUD
      COUNT_NOTPROD_CLOUD = BITWISE_OPERATOR(DATA_NIGHT, 3, 2, 1)
      ;--------
      NOTPROD_CLOUD_P = (FLOAT(COUNT_NOTPROD_CLOUD[0]) / FLOAT(ELEMENTS_NIGHT)) * 100.00
      ;--------------------------------------
      ; LST NOT PRODUCED DUE TO OTHER
      COUNT_NOTPROD_OTHER = BITWISE_OPERATOR(DATA_NIGHT, 3, 3, 1)
      ;--------
      NOTPROD_OTHER_P = (FLOAT(COUNT_NOTPROD_OTHER[0]) / FLOAT(ELEMENTS_NIGHT)) * 100.00
      ;--------------------------------------
      ; GET CLEAR VALUE
      ;PROD_GOOD_P = 100.00 - NOTPROD_CLOUD_P - PROD_BAD_P - NOTPROD_OTHER_P
      COUNT_PROD_GOOD = BITWISE_OPERATOR_AND(DATA_NIGHT, 1, 0, 2, 0, 1)
      PROD_GOOD_P = (FLOAT(COUNT_PROD_GOOD[0]) / FLOAT(ELEMENTS_NIGHT)) * 100.00
      ;-----------------------------------------------------------------------------------------
      ; WRITE INFORMATION TO FILE:
      ;-----------------------------------------------------------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, LUN_OUTPUT, OUTPUT_FILE, /APPEND, /GET_LUN
      ;--------------------------------------
      ; WRITE DATA
      PRINTF, FORMAT='(10000(A,:,","))', LUN_OUTPUT, STRTRIM(i+j+1, 2),'"' + FNAME_STRIP_NIGHT + '.Night' + '"', $
        STRTRIM(PROD_GOOD_P, 2), STRTRIM(PROD_BAD_P, 2), STRTRIM(NOTPROD_CLOUD_P, 2), STRTRIM(NOTPROD_OTHER_P, 2),  $
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
  PRINT,'FINISHED PROCESSING: MODIS_LST_Time_Series_DOIT_State_Flag_Cloud_Information'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END