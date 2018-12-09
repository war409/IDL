; ##############################################################################################
; NAME: LANDSAT_Time_Series_DOIT_Create_False_Colour_PNG.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 15/06/2010
; DLM: 15/06/2010
;
; DESCRIPTION: This tool create one PNG file for each unique input date. For each unique date a 
;              'standard' false colour composite PNG file is created using MODIS NIR (band 2), 
;              RED (band 1) and GREEN (band 4). The output png files are saved to the selected 
;              output directory.
;
; INPUT:       Single-band (i.e. file) MODIS data; each MODIS band must be saved as a single input 
;              file. The input data must have the file date included in the file name (see NOTES). 
;              The code will automatically detect the relevant surface reflectance data and ignore
;              any redundant data; this feature allows the user to 'group select' all of the files 
;              in the input directory without having to manually select individual files.
;              
;              For more information contact: Garth.Warren@csiro.au
;
; OUTPUT:      One PNG file (.png) for each unique input date.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              'SELECT THE INPUT DIRECTORY'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE'
;              
; NOTES:       Line 171 controls how the script extracts the MODIS product prefix from the input 
;              file name for use in the output file name. The default extracts the first 7 characters
;              from the file name, for example:
;              
;              Filename = MCD43A4_A2004305.aust.005.b01.500m_0620_0670nm_nbar.img
;              Prefix = MCD43A4
;              
;              Similarly, lines 111 and 113 extract the file date from the file name. For example,
;              to get the year (YYY) and day-of-year (DOY) from the filename above:
;
;              YYY = STRMID(Filename, 9, 4) ; Extract 4 characters starting at the 9th character
;              DOY = STRMID(Filename, 13, 3) ; Extract 3 characters starting at the 13th character
;
; ##############################################################################################




;***********************************************************************************************
FUNCTION EXTRACT_LANDSAT, X_ALL
  ;---------------------------------------------------------------------------------------------
  ; EXTRACT FILES (SURFACE REFLECTANCE) 
  NIR = X_ALL[WHERE(STRMATCH(X_ALL, '*b04*') EQ 1)]
  RED = X_ALL[WHERE(STRMATCH(X_ALL, '*b03*') EQ 1)]
  GREEN = X_ALL[WHERE(STRMATCH(X_ALL, '*b02*') EQ 1)]
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [NIR, RED, GREEN]  
  ;---------------------------------------------------------------------------------------------
END
;***********************************************************************************************



      
PRO LANDSAT_Time_Series_DOIT_Create_False_Colour_PNG
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: LANDSAT_Time_Series_DOIT_Create_False_Colour_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA:
  IN_X = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\', $
    TITLE='SELECT THE INPUT DATA', FILTER=['*.tif','*.img','*.flt','*.bin'], /MUST_EXIST, $
    /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ; ERROR CHECK:
  IF N_ELEMENTS(IN_X) EQ 0 THEN BEGIN
    PRINT, '*** THE INPUT IS NOT VALID (INPUT DATA) ***'
    RETURN
  ENDIF  
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  PATH = '\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\'  
  ;-----------------------------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  VALUES = ['ENTER A NODATA VALUE', 'DO NOT ENTER A NODATA VALUE']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT NODATA STATUS', $
    /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  STATUS_NAN = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  IF STATUS_NAN EQ 0 THEN BEGIN
    BASE = WIDGET_BASE(TITLE='IDL WIDGET')
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=-9999.00, TITLE='SET THE NODATA VALUE  ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA_TMP = RESULT.VALUE
    NODATA = FLOAT(NODATA_TMP[0])
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; GET THE FILE NAME FROM THE FULL PATH:
  ;---------------------------------------------------------------------------------------------
  ; GET THE STARTING POSITION OF EACH FILE NAME FROM THE FULL FILE PATH
  FNAME_START = STRPOS(IN_X, '\', /REVERSE_SEARCH)+1
  ; GET THE LENGTH OF EACH FILE NAME
  FNAME_LENGTH = (STRLEN(IN_X)-FNAME_START)-4
  ;--------------------------------------
  ; EXTRACT FILE NAMES FROM THE FULL PATHS
  ; MAKE ARRAY TO HOLD THE FILE NAMES
  FN = MAKE_ARRAY(1, N_ELEMENTS(IN_X), /STRING)
  ; FILL ARRAY
  FOR a=0, N_ELEMENTS(IN_X)-1 DO BEGIN ; START 'FOR a'
    ; GET THE a-TH FILE NAME 
    FN[*,a] += STRMID(IN_X[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR ; END 'FOR a'
  ;---------------------------------------------------------------------------------------------
  ; GET UNIQUE FILE DATES:
  ;--------------------------------------
  ; EXTRACT YEAR FROM FILE NAME ARRAY
  YYY = STRMID(FN, 10, 4)
  ; EXTRACT DAY FROM FILE NAME ARRAY
  DDD = STRMID(FN, 6, 2)
  ; EXTRACT MONTH FROM FILE NAME ARRAY
  MMM = STRMID(FN, 8, 2)
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY = JULDAY(MMM, DDD, YYY)
  ; GET UNIQUE DATES I
  UNIQ_DATE = DMY[UNIQ(DMY)]
  ; SORT DATES (ASCENDING)
  UNIQ_DATE = UNIQ_DATE[SORT(UNIQ_DATE)]
  ; GET UNIQUE DATES II
  UNIQ_DATE = UNIQ_DATE[UNIQ(UNIQ_DATE)]
  ;---------------------------------------------------------------------------------------------  
  ; DATE LOOP:
  ;---------------------------------------------------------------------------------------------
  FOR d=0, N_ELEMENTS(UNIQ_DATE)-1 DO BEGIN ; START 'FOR d'
    ;-------------------------------------------------------------------------------------------
    ; GET INPUT FILES FOR THE d-TH DATE:
    ;--------------------------------------
    ; GET THE d-TH DATE FOR FOR THE OUTPUT FILE NAME
    CALDAT, UNIQ_DATE[d], OUT_MONTH, OUT_DAY, OUT_YEAR
    ; GET DAY OF YEAR
    DOY = JULDAY(OUT_MONTH, OUT_DAY, OUT_YEAR) - JULDAY(1, 0, OUT_YEAR)
    ; ADD THE PREFIX '0'
    IF (DOY LE 9) THEN DOY = ('00' + STRING(STRTRIM(DOY, 2)))
    IF (DOY GT 9) AND (DOY LE 99) THEN DOY = ('0' + STRING(STRTRIM(DOY, 2)))
    ;-------------------------------------------------------------------------------------------
    ; SEARCH FOR FILES WITH THE d-TH DATE WITHIN THE FULL FILE LIST 
    INDEX = WHERE(DMY EQ UNIQ_DATE[d], COUNT)
    ; EXTRACT FILES WITH THE d-TH DATE FROM THE FULL FILE LIST
    X_ALL = IN_X[INDEX]
    ;-------------------------------------------------------------------------------------------
    ; EXTRACT FILES (SURFACE REFLECTANCE)
    X_BANDS = EXTRACT_LANDSAT(X_ALL)
    ;--------------------------------------
    ; SET FUNCTION OUTPUT
    X_NIR = X_BANDS[0]
    X_RED = X_BANDS[1]
    X_GREEN = X_BANDS[2]
    ;--------------------------------------
    ; LOAD DATA
    ENVI_OPEN_FILE, X_NIR, R_FID=FID_NIR, /NO_REALIZE
    ENVI_OPEN_FILE, X_RED, R_FID=FID_RED, /NO_REALIZE
    ENVI_OPEN_FILE, X_GREEN, R_FID=FID_GREEN, /NO_REALIZE
    ;--------------------------------------
    ; QUERY DATA
    ENVI_FILE_QUERY, FID_NIR, DIMS=DIMS, NS=NS_NIR, NL=NL_NIR, DATA_TYPE=DATATYPE_NIR
    ;--------------------------------------
    ; GET DATA
    NIR_IN = ENVI_GET_DATA(FID=FID_NIR, DIMS=DIMS, POS=0)
    RED_IN = ENVI_GET_DATA(FID=FID_RED, DIMS=DIMS, POS=0)
    GREEN_IN = ENVI_GET_DATA(FID=FID_GREEN, DIMS=DIMS, POS=0)
    ;-------------------------------------------------------------------------------------------
    ; SET NODATA
    IF STATUS_NAN EQ 0 THEN BEGIN
      ;--------------------------------------
      ; SET NIR NAN
      a = WHERE(NIR_IN EQ FLOAT(NODATA), COUNT_a)
      IF (COUNT_a GT 0) THEN NIR_IN[a] = !VALUES.F_NAN
      ; SET RED NAN
      b = WHERE(RED_IN EQ FLOAT(NODATA), COUNT_b)
      IF (COUNT_b GT 0) THEN RED_IN[b] = !VALUES.F_NAN
      ; SET GREEN NAN
      c = WHERE(GREEN_IN EQ FLOAT(NODATA), COUNT_c)
      IF (COUNT_c GT 0) THEN GREEN_IN[c] = !VALUES.F_NAN
      ;--------------------------------------
    ENDIF    
    ;-------------------------------------------------------------------------------------------
    ; SET REDUCTION FACTOR
    REDUCTION_FACTOR = 1
    ; SET INPUT FILE DIMENSIONS
    DIMS_IN = [NS_NIR, NL_NIR]
    ; SET OUTPUT FILE DIMENSIONS
    DIMS_OUT = DIMS_IN / REDUCTION_FACTOR
    ;-------------------------------------------------------------------------------------------
    ; TRIM FILENAME
    FNAME_START = STRPOS(X_NIR, '\', /REVERSE_SEARCH)+1
    FNAME_SHORT = STRMID(X_NIR, FNAME_START, 7)
    ; BUILD OUTNAME
    OUTNAME = OUT_DIRECTORY + FNAME_SHORT + '.' + STRTRIM(OUT_YEAR, 2)  + STRTRIM(DOY, 2) + '.NIRRG.False.Colour.png'
    ;-------------------------------------------------------------------------------------------
    ; DATA TYPE CHECK: CONVERT CONTINUOUS DATA TO INTEGER
    IF (DATATYPE_NIR GE 4) OR (DATATYPE_NIR LE 9) THEN BEGIN
      NIR_IN = FIX(NIR_IN)
      RED_IN = FIX(RED_IN)
      GREEN_IN = FIX(GREEN_IN)
    ENDIF
    ;--------------------------------------
    ;Decides enhancement
    max_enhancement = 5000
    division_factor = 255. / max_enhancement
    noDataColor = 200
    ; Rescale data to 0-max_enhancement
    where_nodata = Where(RED_IN le -10000 or NIR_IN le -10000 or GREEN_IN le -10000, count)
    RED_IN >= 0
    RED_IN <= max_enhancement
    RED_IN = byte (temporary(RED_IN) * division_factor)
    if count ge 1 then RED_IN[where_nodata] = noDataColor
    NIR_IN >= 0
    NIR_IN <= max_enhancement
    NIR_IN = byte (temporary(NIR_IN) * division_factor)
    if count ge 1 then NIR_IN[where_nodata] = noDataColor
    GREEN_IN >= 0
    GREEN_IN <= max_enhancement
    GREEN_IN = byte (temporary(GREEN_IN) * division_factor)
    if count ge 1 then GREEN_IN[where_nodata] = noDataColor
    ;--------------------------------------
    ; FORCE DATA INTO 3D ARRAY
    MATRIX_PNG = BYTARR(3, NS_NIR, NL_NIR)
    MATRIX_PNG[0,*,*] = TEMPORARY(NIR_IN)
    MATRIX_PNG[1,*,*] = TEMPORARY(RED_IN)
    MATRIX_PNG[2,*,*] = TEMPORARY(GREEN_IN)    
    ;--------------------------------------
    ; SAVE PNG
    PRINT, '  SAVE PNG: ', FNAME_SHORT + '.' + STRTRIM(OUT_YEAR, 2)  + STRTRIM(DOY, 2) + '.NIRRG.False.Colour.png'
    WRITE_PNG, OUTNAME, MATRIX_PNG, RED, GREEN, BLUE, /ORDER
    ;-------------------------------------------------------------------------------------------
  ENDFOR 
  ;---------------------------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2), ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: LANDSAT_Time_Series_DOIT_Create_False_Colour_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END