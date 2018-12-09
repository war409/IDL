; ##############################################################################################
; NAME: MODIS_DOIT_Create_False_Colour_PNG.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 15/06/2010
; DLM: 23/06/2010
;
; DESCRIPTION: This tool creates one PNG file for each unique input date. For each unique date a 
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
;              1.  SELECT THE INPUT DIRECTORY
;              2.  SELECT THE OUTPUT DIRECTORY
;              3.  SELECT THE FALSE COLOUR TYPE
;              
; NOTES:       An interactive ENVI session is needed to run this tool.
; 
;              Lines 192-197 control how the script extracts the MODIS product prefix from the input 
;              file name for use in the output file name. The default extracts the first 7 characters
;              from the file name, for example:
;              
;              Filename = MCD43A4_A2004305.aust.005.b01.500m_0620_0670nm_nbar.img
;              Prefix = MCD43A4
;              
;              Similarly, lines 130-142 extract the file date from the file name. For example,
;              to get the year (YYY) and day-of-year (DOY) from the filename above:
;
;              YYY = STRMID(Filename, 9, 4) ; Extract 4 characters starting at the 9th character
;              DOY = STRMID(Filename, 13, 3) ; Extract 3 characters starting at the 13th character
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


FUNCTION EXTRACT_MODIS_NIR_RED_GREEN, X_ALL
  ; EXTRACT FILES (SURFACE REFLECTANCE) 
  NIR = X_ALL[WHERE(STRMATCH(X_ALL, '*b02*') EQ 1)]
  RED = X_ALL[WHERE(STRMATCH(X_ALL, '*b01*') EQ 1)]
  GREEN = X_ALL[WHERE(STRMATCH(X_ALL, '*b04*') EQ 1)]
  ; RETURN VALUES:
  RETURN, [NIR, RED, GREEN]
END

FUNCTION EXTRACT_MODIS_SWIR3_NIR_RED, X_ALL

  ; EXTRACT FILES (SURFACE REFLECTANCE) 
  SWIR3 = X_ALL[WHERE(STRMATCH(X_ALL, '*b05*') EQ 1)]
  NIR = X_ALL[WHERE(STRMATCH(X_ALL, '*b02*') EQ 1)]
  RED = X_ALL[WHERE(STRMATCH(X_ALL, '*b01*') EQ 1)]
  ; RETURN VALUES:
  RETURN, [SWIR3, NIR, RED]
END

PRO MODIS_DOIT_Create_False_Colour_PNG
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: MODIS_DOIT_Create_False_Colour_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA:
  TITLE='SELECT THE INPUT DATA'
  PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  ;-----------------------------------
  IN_X = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-----------------------------------
  ; ERROR CHECK:
  IF IN_X[0] EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  PATH = '\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\'  
  ;-----------------------------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE FALSE COLOUR TYPE
  TITLE = 'SELECT THE FALSE COLOUR TYPE'
  VALUES = ['NIR=Red, RED=Green, GREEN=Blue', 'SWIR3=Red, NIR=Green, RED=Blue']
  FALSECOLOUR_TYPE = FUNCTION_WIDGET_Radio_Button(TITLE, VALUES)
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
  ; EXTRACT YEAR FROM FILE NAME ARRAY ; 21 18 9
  YYY = STRMID(FN, 9, 4)
  ; EXTRACT DAY OF YEAR FROM FILE NAME ARRAY ; 25 22 13
  DOY = STRMID(FN, 13, 3)
  ; GET 'DAY' AND 'MONTH' FROM 'DAY OF YEAR' 
  CALDAT, JULDAY(1, DOY, YYY), MONTH, DAY
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY = JULDAY(MONTH, DAY, YYY)
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
    IF FALSECOLOUR_TYPE EQ 0 THEN X_BANDS = EXTRACT_MODIS_NIR_RED_GREEN(X_ALL) ELSE X_BANDS = EXTRACT_MODIS_SWIR3_NIR_RED(X_ALL)
    ;--------------------------------------
    ; SET FUNCTION OUTPUT
    X_R = X_BANDS[0]
    X_G = X_BANDS[1]
    X_B = X_BANDS[2]
    ;--------------------------------------
    ; LOAD DATA
    ENVI_OPEN_FILE, X_R, R_FID=FID_R, /NO_REALIZE
    ENVI_OPEN_FILE, X_G, R_FID=FID_G, /NO_REALIZE
    ENVI_OPEN_FILE, X_B, R_FID=FID_B, /NO_REALIZE
    ;--------------------------------------
    ; QUERY DATA
    ENVI_FILE_QUERY, FID_R, DIMS=DIMS, NS=NS_R, NL=NL_R, DATA_TYPE=DATATYPE_R
    ;--------------------------------------
    ; GET DATA
    R_IN = ENVI_GET_DATA(FID=FID_R, DIMS=DIMS, POS=0)
    G_IN = ENVI_GET_DATA(FID=FID_G, DIMS=DIMS, POS=0)
    B_IN = ENVI_GET_DATA(FID=FID_B, DIMS=DIMS, POS=0)
    ;--------------------------------------
    ; SET REDUCTION FACTOR
    REDUCTION_FACTOR = 1
    ; SET INPUT FILE DIMENSIONS
    DIMS_IN = [NS_R, NL_R]
    ; SET OUTPUT FILE DIMENSIONS
    DIMS_OUT = DIMS_IN / REDUCTION_FACTOR
    ;-------------------------------------------------------------------------------------------
    ; TRIM FILENAME
    FNAME_START = STRPOS(X_R, '\', /REVERSE_SEARCH)+1
    FNAME_SHORT = STRMID(X_R, FNAME_START, 7)
    ; BUILD OUTNAME:
    ; SUFFIX
    IF FALSECOLOUR_TYPE EQ 0 THEN SUFFIX = '.NIRRG.False.Colour.png' ELSE SUFFIX = '.SWIR3NIRR.False.Colour.png'   
    OUTNAME = OUT_DIRECTORY + FNAME_SHORT + '.' + STRTRIM(OUT_YEAR, 2)  + STRTRIM(DOY, 2) + SUFFIX
    ;-------------------------------------------------------------------------------------------
    ; DATA TYPE CHECK: CONVERT CONTINUOUS DATA TO INTEGER
    IF (DATATYPE_R GE 4) OR (DATATYPE_R LE 9) THEN BEGIN
      R_IN = FIX(R_IN)
      G_IN = FIX(G_IN)
      B_IN = FIX(B_IN)
    ENDIF
    ;--------------------------------------
    ;Decides enhancement
    max_enhancement = 5000
    division_factor = 255. / max_enhancement
    noDataColor = 200
    ; Rescale data to 0-max_enhancement
    where_nodata = Where(G_IN le -10000 or R_IN le -10000 or B_IN le -10000, count)
    G_IN >= 0
    G_IN <= max_enhancement
    G_IN = byte (temporary(G_IN) * division_factor)
    if count ge 1 then G_IN[where_nodata] = noDataColor
    R_IN >= 0
    R_IN <= max_enhancement
    R_IN = byte (temporary(R_IN) * division_factor)
    if count ge 1 then R_IN[where_nodata] = noDataColor
    B_IN >= 0
    B_IN <= max_enhancement
    B_IN = byte (temporary(B_IN) * division_factor)
    if count ge 1 then B_IN[where_nodata] = noDataColor
    ;--------------------------------------
    ; FORCE DATA INTO 3D ARRAY
    MATRIX_PNG = BYTARR(3, NS_R, NL_R)
    MATRIX_PNG[0,*,*] = TEMPORARY(R_IN)
    MATRIX_PNG[1,*,*] = TEMPORARY(G_IN)
    MATRIX_PNG[2,*,*] = TEMPORARY(B_IN)    
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
  PRINT,'FINISHED PROCESSING: MODIS_DOIT_Create_False_Colour_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END