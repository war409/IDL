; ##############################################################################################
; NAME: Time_Series_DOIT_Create_Tiled_PNG_Files.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 15/06/2010
; DLM: 23/06/2010
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
;              'SELECT THE FALSE COLOUR TYPE'
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




;************************************************************************************************
; FUNCTIONS: START
;************************************************************************************************


; ##############################################################################################
FUNCTION RADIO_BUTTON_WIDGET, TITLE, VALUES
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;-----------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP=TITLE, /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT_TMP = WIDGET_EVENT(BASE)
  RESULT = RESULT_TMP.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-----------------------------------
  ; ERROR CHECK:
  IF N_ELEMENTS(RESULT) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF
  ;-----------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, RESULT
END
; ##############################################################################################


;************************************************************************************************
; FUNCTIONS: END
;************************************************************************************************




PRO Time_Series_DOIT_Create_Tiled_PNG_Files
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_DOIT_Create_Tiled_PNG_Files'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; INPUT/OUTPUT:
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT FALSE COLOUR PNG FILES:
  TITLE='SELECT THE INPUT FALSE COLOUR PNG FILES'
  PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\PNG'
  FILTER=['*.png']
  ;-----------------------------------
  IN_FC = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-----------------------------------
  ; ERROR CHECK:
  IF IN_FC[0] EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT 3 VARIABLE MODEL PNG FILES:
  TITLE='SELECT THE INPUT 3 VARIABLE MODEL PNG FILES'
  PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\PNG'
  FILTER=['*.png']
  ;-----------------------------------
  IN_M3 = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-----------------------------------
  ; ERROR CHECK:
  IF IN_M3[0] EQ '' THEN RETURN
  ;-----------------------------------  
  ; REMOVE THRESHOLD GRIDS
  IN_M3 = IN_M3[WHERE(STRMATCH(IN_M3, '*Inundation*') EQ 0)]
  ;-----------------------------------  
  ; SORT FILE LIST
  IN_M3 = IN_M3[SORT(IN_M3)]
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT 5 VARIABLE MODEL PNG FILES:
  TITLE='SELECT THE INPUT 5 VARIABLE MODEL PNG FILES'
  PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\PNG'
  FILTER=['*.png']
  ;-----------------------------------
  IN_M5 = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-----------------------------------
  ; ERROR CHECK:
  IF IN_M5[0] EQ '' THEN RETURN
  ;-----------------------------------  
  ; REMOVE THRESHOLD GRIDS
  IN_M5 = IN_M5[WHERE(STRMATCH(IN_M5, '*Inundation*') EQ 0)]
  ;----------------------------------- 
  ; SORT FILE LIST
  IN_M5 = IN_M5[SORT(IN_M5)]
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\PNG'
  ;-----------------------------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ;----------------------------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ; GET THE FILE NAME FROM THE FULL PATH:
  ;---------------------------------------------------------------------------------------------
  ; GET THE STARTING POSITION OF EACH FALSE COLOUR FILE NAME FROM THE FULL FILE PATH
  FNAME_START_FC = STRPOS(IN_FC, '\', /REVERSE_SEARCH)+1
  ; GET THE LENGTH OF EACH FILE NAME
  FNAME_LENGTH_FC = (STRLEN(IN_FC)-FNAME_START_FC)-4
  ;--------------------------------------
  ; GET THE STARTING POSITION OF EACH 3 VARIABLE MODEL FILE NAME FROM THE FULL FILE PATH
  FNAME_START_M3 = STRPOS(IN_M3, '\', /REVERSE_SEARCH)+1
  ; GET THE LENGTH OF EACH FILE NAME
  FNAME_LENGTH_M3 = (STRLEN(IN_M3)-FNAME_START_M3)-4
  ;-------------------------------------- 
  ; GET THE STARTING POSITION OF EACH 5 VARIABLE MODEL FILE NAME FROM THE FULL FILE PATH
  FNAME_START_M5 = STRPOS(IN_M5, '\', /REVERSE_SEARCH)+1
  ; GET THE LENGTH OF EACH FILE NAME
  FNAME_LENGTH_M5 = (STRLEN(IN_M5)-FNAME_START_M5)-4
  ;---------------------------------------------------------------------------------------------
  ; EXTRACT FILE NAMES FROM THE FULL PATHS
  ; MAKE ARRAY TO HOLD THE FILE NAMES
  FN_FC = MAKE_ARRAY(1, N_ELEMENTS(IN_FC), /STRING)
  ; FILL ARRAY
  FOR a=0, N_ELEMENTS(IN_FC)-1 DO BEGIN ; START 'FOR a'
    ; GET THE a-TH FILE NAME 
    FN_FC[*,a] += STRMID(IN_FC[a], FNAME_START_FC[a], FNAME_LENGTH_FC[a])
  ENDFOR ; END 'FOR a'
  ;--------------------------------------
  ; EXTRACT FILE NAMES FROM THE FULL PATHS
  ; MAKE ARRAY TO HOLD THE FILE NAMES
  FN_M3 = MAKE_ARRAY(1, N_ELEMENTS(IN_M3), /STRING)
  ; FILL ARRAY
  FOR a=0, N_ELEMENTS(IN_M3)-1 DO BEGIN ; START 'FOR a'
    ; GET THE a-TH FILE NAME 
    FN_M3[*,a] += STRMID(IN_M3[a], FNAME_START_M3[a], FNAME_LENGTH_M3[a])
  ENDFOR ; END 'FOR a'
  ;--------------------------------------
  ; EXTRACT FILE NAMES FROM THE FULL PATHS
  ; MAKE ARRAY TO HOLD THE FILE NAMES
  FN_M5 = MAKE_ARRAY(1, N_ELEMENTS(IN_M5), /STRING)
  ; FILL ARRAY
  FOR a=0, N_ELEMENTS(IN_M5)-1 DO BEGIN ; START 'FOR a'
    ; GET THE a-TH FILE NAME 
    FN_M5[*,a] += STRMID(IN_M5[a], FNAME_START_M5[a], FNAME_LENGTH_M5[a])
  ENDFOR ; END 'FOR a'
  ;---------------------------------------------------------------------------------------------
  ; GET UNIQUE FILE DATES:
  ;---------------------------------------------------------------------------------------------
  ; EXTRACT YEAR FROM FILE NAME ARRAY ; 21 18 9
  YYY_FC = STRMID(FN_FC, 8, 4)
  ; EXTRACT DAY OF YEAR FROM FILE NAME ARRAY ; 25 22 13
  DOY_FC = STRMID(FN_FC, 12, 3)
  ; GET 'DAY' AND 'MONTH' FROM 'DAY OF YEAR' 
  CALDAT, JULDAY(1, DOY_FC, YYY_FC), MONTH_FC, DAY_FC
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY_FC = JULDAY(MONTH_FC, DAY_FC, YYY_FC)
  ; GET UNIQUE DATES I
  UNIQ_DATE_FC = DMY_FC[UNIQ(DMY_FC)]
  ; SORT DATES (ASCENDING)
  UNIQ_DATE_FC = UNIQ_DATE_FC[SORT(UNIQ_DATE_FC)]
  ; GET UNIQUE DATES II
  UNIQ_DATE_FC = UNIQ_DATE_FC[UNIQ(UNIQ_DATE_FC)]
  ;--------------------------------------
  ; EXTRACT YEAR FROM FILE NAME ARRAY
  YYY_M3 = STRMID(FN_M3, 33, 4)
  ;YYY_M3 = STRMID(FN_M3, 46, 4)
  ; EXTRACT DAY FROM FILE NAME ARRAY
  DDD_M3 = STRMID(FN_M3, 39, 2)
  ;DOY_M3 = STRMID(FN_M3, 50, 3)
  ;CALDAT, JULDAY(1, DOY_M3, YYY_M3), MONTH_M3, DAY_M3
  ; EXTRACT MONTH FROM FILE NAME ARRAY
  MMM_M3 = STRMID(FN_M3, 37, 2)
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY_M3 = JULDAY(MMM_M3, DDD_M3, YYY_M3)
  ;DMY_M3 = JULDAY(MONTH_M3, DAY_M3, YYY_M3)
  ; GET UNIQUE DATES I
  UNIQ_DATE_M3 = DMY_M3[UNIQ(DMY_M3)]
  ; SORT DATES (ASCENDING)
  UNIQ_DATE_M3 = UNIQ_DATE_M3[SORT(UNIQ_DATE_M3)]
  ; GET UNIQUE DATES II
  UNIQ_DATE_M3 = UNIQ_DATE_M3[UNIQ(UNIQ_DATE_M3)]
  ;--------------------------------------
  ; EXTRACT YEAR FROM FILE NAME ARRAY
  YYY_M5 = STRMID(FN_M5, 33, 4)
  ;YYY_M5 = STRMID(FN_M5, 46, 4)
  ; EXTRACT DAY FROM FILE NAME ARRAY
  DDD_M5 = STRMID(FN_M5, 39, 2)
  ;DOY_M5 = STRMID(FN_M5, 50, 3)
  ;CALDAT, JULDAY(1, DOY_M5, YYY_M5), MONTH_M5, DAY_M5
  ; EXTRACT MONTH FROM FILE NAME ARRAY
  MMM_M5 = STRMID(FN_M5, 37, 2)
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY_M5 = JULDAY(MMM_M5, DDD_M5, YYY_M5)
  ;DMY_M5 = JULDAY(MONTH_M5, DAY_M5, YYY_M5)
  ; GET UNIQUE DATES I
  UNIQ_DATE_M5 = DMY_M5[UNIQ(DMY_M5)]
  ; SORT DATES (ASCENDING)
  UNIQ_DATE_M5 = UNIQ_DATE_M5[SORT(UNIQ_DATE_M5)]
  ; GET UNIQUE DATES II
  UNIQ_DATE_M5 = UNIQ_DATE_M5[UNIQ(UNIQ_DATE_M5)]
  ;---------------------------------------------------------------------------------------------  
  ; DATE LOOP:
  ;---------------------------------------------------------------------------------------------
  FOR d=0, N_ELEMENTS(UNIQ_DATE_FC)-1 DO BEGIN ; START 'FOR d'
    ;-------------------------------------------------------------------------------------------
    ; GET INPUT FILES FOR THE d-TH DATE:
    ;--------------------------------------
    ; GET THE d-TH DATE FOR FOR THE OUTPUT FILE NAME
    CALDAT, UNIQ_DATE_FC[d], OUT_MONTH_FC, OUT_DAY_FC, OUT_YEAR_FC
    ; GET DAY OF YEAR
    DOY_FC = JULDAY(OUT_MONTH_FC, OUT_DAY_FC, OUT_YEAR_FC) - JULDAY(1, 0, OUT_YEAR_FC)
    ; ADD THE PREFIX '0'
    IF (DOY_FC LE 9) THEN DOY_FC = ('00' + STRING(STRTRIM(DOY_FC, 2)))
    IF (DOY_FC GT 9) AND (DOY_FC LE 99) THEN DOY_FC = ('0' + STRING(STRTRIM(DOY_FC, 2)))
    ;-------------------------------------------------------------------------------------------
    ; SEARCH THE FOR FILE WITH THE d-TH DATE WITHIN THE FULL FILE LIST 
    INDEX_FC = WHERE(DMY_FC EQ UNIQ_DATE_FC[d], COUNT)
    INDEX_M3 = WHERE(DMY_M3 EQ UNIQ_DATE_FC[d], COUNT)
    INDEX_M5 = WHERE(DMY_M5 EQ UNIQ_DATE_FC[d], COUNT)   
    ;--------------------------------------
    ; EXTRACT THE FALSE COLOUR FILE WITH THE d-TH DATE FROM THE FULL FILE LIST
    X_FC = IN_FC[INDEX_FC]
    ; EXTRACT THE 3 VARIABLE MODEL FILE WITH THE d-TH DATE FROM THE FULL FILE LIST
    X_M3 = IN_M3[INDEX_M3]
    ; EXTRACT THE 5 VARIABLE MODEL FILE WITH THE d-TH DATE FROM THE FULL FILE LIST
    X_M5 = IN_M5[INDEX_M5]
    ;--------------------------------------
    ; ERROR CHECK
    IF N_ELEMENTS(X_FC) EQ '' THEN CONTINUE
    IF N_ELEMENTS(X_M3) EQ '' THEN CONTINUE
    IF N_ELEMENTS(X_M5) EQ '' THEN CONTINUE
    ; ERROR CHECK
    IF N_ELEMENTS(X_FC) GT 1 THEN CONTINUE
    IF N_ELEMENTS(X_M3) GT 1 THEN CONTINUE
    IF N_ELEMENTS(X_M5) GT 1 THEN CONTINUE
    ;-------------------------------------------------------------------------------------------
    ; GET DATA:
    ;-------------------------------------------------------------------------------------------  
    ; OPEN THE FALSE COLOUR FILE 
    FC =  READ_PNG(X_FC, /ORDER)
    ;--------------------------------------
    ; OPEN THE 3 VARIABLE MODEL
    ENVI_OPEN_FILE, X_M3, R_FID=FID_M3, /NO_REALIZE
    ENVI_FILE_QUERY, FID_M3, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DATATYPE
    ; GET DATA
    DATA1_M3 = ENVI_GET_DATA(FID=FID_M3, DIMS=DIMS, POS=0)
    DATA2_M3 = ENVI_GET_DATA(FID=FID_M3, DIMS=DIMS, POS=1)
    DATA3_M3 = ENVI_GET_DATA(FID=FID_M3, DIMS=DIMS, POS=2)
    ; ADD DATA TO 3D ARRAY
    M3 = BYTARR(3, NS, NL)
    M3[0,*,*] = DATA1_M3
    M3[1,*,*] = DATA2_M3
    M3[2,*,*] = DATA3_M3
    ;--------------------------------------
    ; OPEN THE 5 VARIABLE MODEL
    ENVI_OPEN_FILE, X_M5, R_FID=FID_M5, /NO_REALIZE
    ENVI_FILE_QUERY, FID_M5, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DATATYPE
    ; GET DATA
    DATA1_M5 = ENVI_GET_DATA(FID=FID_M5, DIMS=DIMS, POS=0)
    DATA2_M5 = ENVI_GET_DATA(FID=FID_M5, DIMS=DIMS, POS=1)
    DATA3_M5 = ENVI_GET_DATA(FID=FID_M5, DIMS=DIMS, POS=2)
    ; ADD DATA TO 3D ARRAY
    M5 = BYTARR(3, NS, NL)
    M5[0,*,*] = DATA1_M5
    M5[1,*,*] = DATA2_M5
    M5[2,*,*] = DATA3_M5
    ;-------------------------------------------------------------------------------------------
    ; WRITE PNG:
    ;--------------------------------------
    ; MAKE OUPUT ARRAY
    IMG_OUT = [[M3],[FC],[M5]]
    ;--------------------------------------    
    ; BUILD THE OUTPUT NAME:
    ;--------------------------------------       
    ; TRIM FILENAME
    FNAME_START = STRPOS(X_FC, '\', /REVERSE_SEARCH)+1
    FNAME_SHORT = STRMID(X_FC, FNAME_START, 7)    
    ;--------------------------------------   
    ; SET OUTNAME
    OUTNAME = OUT_DIRECTORY + FNAME_SHORT + '.' + STRTRIM(OUT_YEAR_FC, 2)  + STRTRIM(DOY_FC, 2) + '.SWIR3NIRR.FC.3AND5.Model.png'
    ;--------------------------------------       
    ; SAVE PNG
    PRINT, '  WRITE PNG: ', FNAME_SHORT + '.' + STRTRIM(OUT_YEAR_FC, 2)  + STRTRIM(DOY_FC, 2) + '.SWIR3NIRR.FC.3AND5.Model.png'
    WRITE_PNG, OUTNAME, IMG_OUT, /ORDER
    ;-------------------------------------------------------------------------------------------
  ENDFOR 
  ;---------------------------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2), ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_DOIT_Create_Tiled_PNG_Files'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END