; ##############################################################################################
; NAME: MODIS_DOIT_Normalised_Ratio.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/10/2010
; DLM: 13/10/2010
;
; DESCRIPTION:  This tool calculates 'normalised ratios' of the form:
; 
;               (BAND - BAND) / (BAND + BAND)
;               
;               The user must define the band combination to be used in the above statement.
;               
;               The tool creates one output raster per input 'date-set', that is, a set of files
;               with a unique date (the date must be included in the filename; see NOTES).
; 
; INPUT:        One or more MODIS optical surface reflectance date-sets. The MODIS state flags 
;               layer must be included in each input 'date set'. The state flag layers are used
;               to 'mask-out' ocean cells and cloud affected cells.
;               
;               For example, to calculate NDVI using MOD09A1 data for 2000 057 you must select the
;               following files:
;               
;               MOD09A1.2000.057.aust.005.b01.500m_0620_0670nm_refl.img
;               MOD09A1.2000.057.aust.005.b02.500m_0841_0876nm_refl.img
;               MOD09A1.2000.057.aust.005.b12.500m_state_flags.img
;               
;               You may select multiple date-sets, the tool will batch process each set independently.
;               Also, you can select all of the available bands per date. The tool will automatically
;               discard unused files; this makes selecting multiple dates much easier as you can simply 
;               select all of the files in a folder. 
;               
;               This tool was written to process MODIS surface reflectance data extracted using the 
;               tool 'MODIS_DOIT_HDF_gzip_to_img.pro'. The tool could be modified to process other
;               data. For more information contact Garth.Warren@csiro.au
;
; OUTPUT:       One raster per input 'date set'.
;               
; PARAMETERS:   Via IDL widgets, set: 
;           
;               1.  SELECT THE INPUT DATA: see INPUT
;               
;               2.  Select the date format: see NOTES
;               
;               3.  Define the output nodata value: The value that will be used to signify nodata in 
;                   the output.
;                    
;               4.  DEFINE THE NORMALISED RATIO INDEX: see DESCRIPTION
;               
;               5.  Define the output filename prefix: A string that will be added to the start of 
;                   the output filename/s. The year and DOY is added to the output filename after the 
;                   prefix. 
;               
;               6.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;                
; NOTES:        FILE DATES:
; 
;               The input data are sorted by date (in ascending order). Lines  and 
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
;               FUNCTION_WIDGET_Enter_String
;               
;               BITWISE MASK:
;              
;               In bitwise operators the 'AND operator' takes two binary 'objects' of equal length
;               and performs the following 'logical operation'. At each bit-location
;               (i.e. 0000000000000001 has 16-bits) each input is compared. If both objects have a
;               value of '1' at the same bit- location the result is 1. If the objects have any
;               other combination the result is 0.
;
;               For example:
;
;               1033 AND 1 = 0000010000001001 AND 0000000000000001
;                          = 0000000000000001
;                          = BINARY(1)
;
;               The result above (0000000000000001) occurs because the only bit that has a value of 1
;               in both 0000010000001001 and 0000000000000001 at the same bit-location is the last or
;               16th bit.
;
;               Another example:
;
;               8205 AND 8025 = 0010000000001101 AND 0001111101011001
;                             = 0000000000001001
;                             = BINARY(9)             
;
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################

FUNCTION BITWISE_OPERATOR, DATA, BINARY1, MATCH1, WHERE_VALUE
  ;-----------------------------------
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BINARY1) EQ MATCH1)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WHERE_VALUE, COUNT)
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, [INDEX]
  ;----------------------------------- 
END

FUNCTION BITWISE_OPERATOR_AND, DATA, BINARY1, MATCH1, BINARY2, MATCH2, WHERE_VALUE
  ;----------------------------------- 
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BINARY1) EQ MATCH1) AND ((DATA AND BINARY2) EQ MATCH2)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WHERE_VALUE, COUNT)
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, [INDEX]
  ;----------------------------------- 
END

PRO MODIS_DOIT_Normalised_Ratio
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: MODIS_DOIT_Normalised_Ratio'
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
    DMY = FUNCTION_GET_Julian_Day_Number_YYYYDOY(FNS, 8, 13)
  ENDIF ELSE BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY = FUNCTION_GET_Julian_Day_Number_DDMMYYYY(FNS, 15, 13, 11)
  ENDELSE
  ;--------------
  ; SORT BY DATE
  IN_FILES = IN_FILES[SORT(DMY)]
  ;--------------  
  ; GET UNIQUE INPUT DATES
  UNIQ_DATES = DMY[UNIQ(DMY)]
  ; SORT DATES (ASCENDING)
  UNIQ_DATES = UNIQ_DATES[SORT(UNIQ_DATES)]
  ; GET UNIQUE DATES
  UNIQ_DATES = UNIQ_DATES[UNIQ(UNIQ_DATES)]
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE OUTPUT NODATA VALUE
  NAN_VALUE = FUNCTION_WIDGET_Enter_Value('Define the output nodata value:  ', 255.00)
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE NORMALISED RATIO:
  ;-----------------------------------
  ; SET CUSTOM WIDGET:
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT:
  REPEAT BEGIN ; START 'REPEAT'
  CHECK_P = 1
  ;-----------------------------------
  PARENT = WIDGET_BASE(TITLE='DEFINE THE NORMALISED RATIO INDEX:', TAB_MODE=2, XSIZE=370, /ROW, /GRID_LAYOUT)
    WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400
    ;--------------
    CHILD = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=1, /ROW)
    ;--------------
    VALUES=['','b01','b02','b03','b04','b05','b06','b07']
    DROP1 = WIDGET_DROPLIST(CHILD, SCR_XSIZE=75, YSIZE=25, TITLE='   ( ', VALUE=VALUES, YOFFSET=0)
    DROP2 = WIDGET_DROPLIST(CHILD, SCR_XSIZE=75, YSIZE=25, TITLE='  -  ', VALUE=VALUES, YOFFSET=0)
    DROP3 = WIDGET_DROPLIST(CHILD, SCR_XSIZE=75, YSIZE=25, TITLE=') / (', VALUE=VALUES, YOFFSET=0)
    DROP4 = WIDGET_DROPLIST(CHILD, SCR_XSIZE=75, YSIZE=25, TITLE='  +  ', VALUE=VALUES, YOFFSET=0)
    ;--------------
    BUTTON_BASE = WIDGET_BASE(CHILD, XPAD=0, YPAD=0, /ROW, /ALIGN_TOP)
    OK = CW_BGROUP(BUTTON_BASE, ['OK'], LABEL_LEFT=')  ', /RETURN_NAME)
    ;--------------
    WIDGET_CONTROL, DROP1, /REALIZE
      RESULT1 = WIDGET_EVENT(DROP1)
      VALUE1 = RESULT1.INDEX
      NUMERATOR_1 = VALUE1[0]
    WIDGET_CONTROL, DROP2, /REALIZE
      RESULT2 = WIDGET_EVENT(DROP2)
      VALUE2 = RESULT2.INDEX
      NUMERATOR_2 = VALUE2[0]
    WIDGET_CONTROL, DROP3, /REALIZE
      RESULT3 = WIDGET_EVENT(DROP3)
      VALUE3 = RESULT3.INDEX
      DENOMINATOR_1 = VALUE3[0]
    WIDGET_CONTROL, DROP4, /REALIZE
      RESULT4 = WIDGET_EVENT(DROP4)
      VALUE4 = RESULT4.INDEX
      DENOMINATOR_2 = VALUE4[0]
    ;--------------------------------------
    BUTTON_RESULT = WIDGET_EVENT(BUTTON_BASE)
    BUTTON_VALUE = BUTTON_RESULT.VALUE
  IF BUTTON_VALUE EQ 'OK' THEN WIDGET_CONTROL, PARENT, /DESTROY  
  ;--------------------------------------
  ; CHECK FOR INVALID SELECTIONS
  IF (NUMERATOR_1 EQ 0) OR (NUMERATOR_2 EQ 0) OR (DENOMINATOR_1 EQ 0) OR (DENOMINATOR_2 EQ 0) THEN GOTO, JUMP
  ;--------------
  PRINT, '( ', VALUES[NUMERATOR_1], ' - ', VALUES[NUMERATOR_2], ' ) / ( ', $
    VALUES[DENOMINATOR_1], ' + ', VALUES[DENOMINATOR_2], ' )'       
  TITLE ='Is this correct?     '
  CHECK_P = FUNCTION_WIDGET_Radio_Button(TITLE, ['YES', 'NO'])
  ;--------------
  JUMP:
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;--------------------------------------
  ; SET FILE TYPE SELECTION STRING
  BANDS = [NUMERATOR_1, NUMERATOR_2, DENOMINATOR_1, DENOMINATOR_2]
  BAND_STRING = STRJOIN(VALUES[BANDS], /SINGLE)
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE OUTPUT FILENAME PREFIX
  PREFIX = FUNCTION_WIDGET_Enter_String('Define the output filename prefix:  ', 'MOD09A1.aust.005.INDEX')
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  PATH='C:\'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY)
  ;--------------
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; DATE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(UNIQ_DATES)-1 DO BEGIN
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET FILES:
    ;-------------------------------------------------------------------------------------------
    ; GET THE i-TH DATE
    CALDAT, UNIQ_DATES[i], iM, iD, iY ; CONVERT JULDAY TO CALDAY
    DOY = JULDAY(iM, iD, iY) - JULDAY(1, 0, iY) ; GET DAY OF YEAR
    ;--------------
    ; DOY ZERO CHECK
    IF (DOY LE 9) THEN DOY = '00' + STRING(STRTRIM(DOY,2))
    IF (DOY LE 99) AND (DOY GT 9) THEN DOY = '0' + STRING(STRTRIM(DOY,2))
    ;--------------
    INDEX = WHERE(DMY EQ UNIQ_DATES[i], COUNT) ; GET FILE INDEX
    FILES_IN = IN_FILES[INDEX] ; GET FILES
    FNS_IN = FNS[INDEX] ; GET FILES SHORT
    ;-------------------------------------------------------------------------------------------
    ; GET DATA:
    ;-------------------------------------------------------------------------------------------
    ; EXTRACT FILENAMES AND LOAD DATA:
    ;--------------------------------------
    IF STRMATCH(BAND_STRING ,'*b01*') EQ 1 THEN BEGIN
      b01_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*b01*') EQ 1)]
      b01 = READ_BINARY(b01_IN, DATA_TYPE=2)
    ENDIF
    ;--------------
    IF STRMATCH(BAND_STRING ,'*b02*') EQ 1 THEN BEGIN
      b02_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*b02*') EQ 1)]    
      b02 = READ_BINARY(b02_IN, DATA_TYPE=2)
    ENDIF
    ;--------------
    IF STRMATCH(BAND_STRING ,'*b03*') EQ 1 THEN BEGIN
      b03_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*b03*') EQ 1)]
      b03 = READ_BINARY(b03_IN, DATA_TYPE=2)    
    ENDIF
    ;-------------- 
    IF STRMATCH(BAND_STRING ,'*b04*') EQ 1 THEN BEGIN
      b04_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*b04*') EQ 1)]
      b04 = READ_BINARY(b04_IN, DATA_TYPE=2)    
    ENDIF
    ;--------------     
    IF STRMATCH(BAND_STRING ,'*b05*') EQ 1 THEN BEGIN
      b05_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*b05*') EQ 1)]            
      b05 = READ_BINARY(b05_IN, DATA_TYPE=2)
    ENDIF
    ;--------------     
    IF STRMATCH(BAND_STRING ,'*b06*') EQ 1 THEN BEGIN
      b06_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*b06*') EQ 1)]
      b06 = READ_BINARY(b06_IN, DATA_TYPE=2)   
    ENDIF
    ;--------------     
    IF STRMATCH(BAND_STRING ,'*b07*') EQ 1 THEN BEGIN
      b07_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*b07*') EQ 1)]
      b07 = READ_BINARY(b07_IN, DATA_TYPE=2)
    ENDIF
    ;--------------      
    STATE_IN = FILES_IN[WHERE(STRMATCH(FILES_IN, '*state*') EQ 1)]
    STATE = READ_BINARY(STATE_IN, DATA_TYPE=2)
    ;--------------------------------------
    ; SET INDEX VARIABLES:
    ;--------------------------------------
    IF VALUES[NUMERATOR_1] EQ 'b01' THEN  NUMERATOR_A =  b01
    IF VALUES[NUMERATOR_1] EQ 'b02' THEN  NUMERATOR_A =  b02
    IF VALUES[NUMERATOR_1] EQ 'b03' THEN  NUMERATOR_A =  b03
    IF VALUES[NUMERATOR_1] EQ 'b04' THEN  NUMERATOR_A =  b04
    IF VALUES[NUMERATOR_1] EQ 'b05' THEN  NUMERATOR_A =  b05
    IF VALUES[NUMERATOR_1] EQ 'b06' THEN  NUMERATOR_A =  b06
    IF VALUES[NUMERATOR_1] EQ 'b07' THEN  NUMERATOR_A =  b07
    IF VALUES[NUMERATOR_2] EQ 'b01' THEN  NUMERATOR_B =  b01
    IF VALUES[NUMERATOR_2] EQ 'b02' THEN  NUMERATOR_B =  b02
    IF VALUES[NUMERATOR_2] EQ 'b03' THEN  NUMERATOR_B =  b03
    IF VALUES[NUMERATOR_2] EQ 'b04' THEN  NUMERATOR_B =  b04
    IF VALUES[NUMERATOR_2] EQ 'b05' THEN  NUMERATOR_B =  b05
    IF VALUES[NUMERATOR_2] EQ 'b06' THEN  NUMERATOR_B =  b06
    IF VALUES[NUMERATOR_2] EQ 'b07' THEN  NUMERATOR_B =  b07
    IF VALUES[DENOMINATOR_1] EQ 'b01' THEN  DENOMINATOR_A =  b01
    IF VALUES[DENOMINATOR_1] EQ 'b02' THEN  DENOMINATOR_A =  b02
    IF VALUES[DENOMINATOR_1] EQ 'b03' THEN  DENOMINATOR_A =  b03
    IF VALUES[DENOMINATOR_1] EQ 'b04' THEN  DENOMINATOR_A =  b04
    IF VALUES[DENOMINATOR_1] EQ 'b05' THEN  DENOMINATOR_A =  b05
    IF VALUES[DENOMINATOR_1] EQ 'b06' THEN  DENOMINATOR_A =  b06
    IF VALUES[DENOMINATOR_1] EQ 'b07' THEN  DENOMINATOR_A =  b07
    IF VALUES[DENOMINATOR_2] EQ 'b01' THEN  DENOMINATOR_B =  b01
    IF VALUES[DENOMINATOR_2] EQ 'b02' THEN  DENOMINATOR_B =  b02
    IF VALUES[DENOMINATOR_2] EQ 'b03' THEN  DENOMINATOR_B =  b03
    IF VALUES[DENOMINATOR_2] EQ 'b04' THEN  DENOMINATOR_B =  b04
    IF VALUES[DENOMINATOR_2] EQ 'b05' THEN  DENOMINATOR_B =  b05
    IF VALUES[DENOMINATOR_2] EQ 'b06' THEN  DENOMINATOR_B =  b06
    IF VALUES[DENOMINATOR_2] EQ 'b07' THEN  DENOMINATOR_B =  b07
    ;-------------------------------------------------------------------------------------------
    ; GET VALID DATA:
    ;--------------------------------------
    ; SET THE INPUT RASTER SIZE
    SIZE = n_elements(NUMERATOR_A)
    ;--------------
    ; BUILD INDEX OF VALID (NON FILL) DATA
    BANDS_OK = WHERE(NUMERATOR_A ne -32768 AND NUMERATOR_B ne -32768 AND $
     DENOMINATOR_A ne -32768 AND DENOMINATOR_B ne -32768, COUNT)
    ;--------------
    ; DATA CHECK
    IF COUNT GT 0 THEN BEGIN ; IF COUNT EQ 0 THEN THERE IS NO VALID DATA, IF SO MAKE 'FAKE ARRAY'
      ;-------------------------------------- 
      ; GET VALID DATA ONLY
      NUMERATOR_A = TEMPORARY(NUMERATOR_A[BANDS_OK])
      NUMERATOR_B = TEMPORARY(NUMERATOR_B[BANDS_OK])
      DENOMINATOR_A = TEMPORARY(DENOMINATOR_A[BANDS_OK])
      DENOMINATOR_B = TEMPORARY(DENOMINATOR_B[BANDS_OK])
      STATE= TEMPORARY(STATE[BANDS_OK])
      ;-----------------------------------------------------------------------------------------
      ; CALCULATE RATIO
      RATIO = (NUMERATOR_A - NUMERATOR_B) / (DENOMINATOR_A + DENOMINATOR_B * 1.0)
      ;-----------------------------------------------------------------------------------------    
      ; APPLY MODIS CLOUD MASK:
      ;--------------------------------------
      ; REPLACE FILL CELLS
      INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
      IF (COUNT_FILL GT 0) THEN RATIO[INDEX_FILL] = NAN_VALUE
      ;--------------
      ; REPLACE CLOUD CELLS ["Cloud"= 0000000000000001]
      INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1) ; STATE = ((1033 AND 1) EQ 1) AND ((1033 AND 2) EQ 0)
      IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN RATIO[INDEX_CLOUD] = NAN_VALUE
      ;--------------
      ; REPLACE MIXED CLOUD CELLS ["MIXED"= 0000000000000010] ; STATE = ((DATA AND BIN) EQ EQV)
      INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
      IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN RATIO[INDEX_MIXED] = NAN_VALUE
      ;--------------
      ; REPLACE CLOUD SHADOW CELLS ["Cloud_Shadow"= 0000000000000100]
      INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
      IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN RATIO[INDEX_SHADOW] = NAN_VALUE
      ;--------------------------------------    
      ; APPLY MODIS OCEAN MASK:
      ;--------------------------------------
      ; REPLACE SHALLOW OCEAN CELLS ["shallow ocean"= 0000000000000000]
      INDEX_SHALLOW = BITWISE_OPERATOR_AND(STATE, 0, 0, 56, 0, 1) ; ((8196 AND 0) EQ 0) AND ((8196 AND 56) EQ 0)
      IF (N_ELEMENTS(INDEX_SHALLOW) GT 1) THEN RATIO[INDEX_SHALLOW] = NAN_VALUE
      ;--------------
      ; REPLACE CONTINENTAL OCEAN CELLS ["continental ocean"= 0000000000110000]
      INDEX_CONTINENTAL = BITWISE_OPERATOR_AND(STATE, 48, 48, 8, 0, 1) ; ((1073 AND 48) EQ 48) AND ((1073 AND 8) EQ 0)
      IF (N_ELEMENTS(INDEX_CONTINENTAL) GT 1) THEN RATIO[INDEX_CONTINENTAL] = NAN_VALUE
      ;--------------  
      ; REPLACE DEEP OCEAN CELLS ["deep ocean"= 0000000000111000]
      INDEX_DEEP = BITWISE_OPERATOR(STATE, 56, 56, 1) ; ((123 AND 56) EQ 56)
      IF (N_ELEMENTS(INDEX_DEEP) GT 1) THEN RATIO[INDEX_DEEP] = NAN_VALUE
      ;-----------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN
      ;--------------------------------------    
      ; MAKE 'FAKE ARRAY':
      ;--------------------------------------
      RATIO = NAN_VALUE
      BANDS_OK[0] = 0
      ;--------------------------------------
    ENDELSE
    ;-------------------------------------------------------------------------------------------
    ; RECONSTRUCT DATA TO ORIGINAL DIMENSIONS (FILL MISSING LOCATIONS)
    RATIO_OUTPUT =  FLTARR(SIZE) & RATIO_OUTPUT[*] =  NAN_VALUE
    RATIO_OUTPUT[BANDS_OK] = RATIO
    ;-------------------------------------------------------------------------------------------
    ; WRITE DATA:
    ;--------------------------------------
    ; SET THE OUTPUT FILE NAME
    FILE_OUT = OUT_DIRECTORY + PREFIX + '.' + STRTRIM(iY, 2) + '.' + STRTRIM(DOY, 2) +  '.img'
    ;--------------
    OPENW, UNIT_OWL, FILE_OUT, /GET_LUN ; CREATE THE OUTPUT FILE
    FREE_LUN, UNIT_OWL ; CLOSE THE NEW FILES
    OPENU, UNIT_OWL, FILE_OUT, /GET_LUN, /APPEND ; OPEN THE OUTPUT FILE
    WRITEU, UNIT_OWL, RATIO_OUTPUT ; WRITE DATA
    FREE_LUN, UNIT_OWL ; CLOSE THE OUTPUT FILE
    ;-------------------------------------------------------------------------------------------    
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------
    ; GET END TIME
    MINUTES = (SYSTIME(1)-L_TIME)/60
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES, FOR DATE ', STRTRIM(i+1, 2), $
      ' OF ', STRTRIM(N_ELEMENTS(UNIQ_DATES), 2)
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
  PRINT,'FINISHED PROCESSING: MODIS_DOIT_Normalised_Ratio'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END