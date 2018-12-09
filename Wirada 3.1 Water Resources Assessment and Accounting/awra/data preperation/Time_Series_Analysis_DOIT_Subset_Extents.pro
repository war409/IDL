; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Subset_Extents.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 09/03/2010
; DLM: 09/03/2010
;
; DESCRIPTION: This tool subsets the spatial extents of the input data. The
;              user may manually enter new dimension parameters or opt to use
;              the dimensions of an existing image file.
;
; INPUT:       Multiple single-band rasters.
;
; OUTPUT:      One subsetted dataset per input.
;
; PARAMETERS:  Via ENVI and IDL widgets, set:
;
;              'SELECT THE INPUT TIME-SERIES'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT SUBSET'
;
; NOTES:       The input data must have identical dimensions. An interactive
;              ENVI session is needed to run this tool. The input data must
;              have an associated ENVI header file.
;
; ##########################################################################
;
PRO Time_Series_Analysis_DOIT_Subset_Extents
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Subset_Extents'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE INPUT TIME-SERIES
  IN_X = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics', $
    TITLE='SELECT THE INPUT TIME-SERIES', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUT_DIR = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics', $
    TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SORT FILE LIST
  IN_X = IN_X[SORT(IN_X)]
  ;-------------------------------------------------------------------------
  ; SET FILE COUNT
  COUNT_F = N_ELEMENTS(IN_X)
  ;-------------------------------------------------------------------------
  ; GET THE FIRST FILE IN THE LIST
  IN_FIRST = IN_X[0]
  ;-------------------------------------------------------------------------
  ; OPEN FILE
  ENVI_OPEN_FILE, IN_FIRST, /NO_REALIZE, R_FID=FID_FIRST
  ;-------------------------------------------------------------------------
  ; QUERY FILE
  ENVI_FILE_QUERY, FID_FIRST, DIMS=DIMS_IN, NS=NS_IN, NL=NL_IN, NB=NB_IN, $
    INTERLEAVE=INTERLEAVE_IN, DATA_TYPE=DATATYPE_IN, XSTART=XSTART_IN, $
    FILE_TYPE=FILE_TYPE_IN,YSTART=YSTART_IN, OFFSET=OFFSET_IN, $
    DATA_OFFSETS=DATA_OFFSETS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN
  ;-------------------------------------------------------------------------
  ; GET MAP INFORMATION
  MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_FIRST)
  PROJ_FULL_IN = MAPINFO_IN.PROJ
  DATUM_IN = MAPINFO_IN.PROJ.DATUM
  PROJ_IN = MAPINFO_IN.PROJ.NAME
  UNITS_IN = MAPINFO_IN.PROJ.UNITS
  SIZEX_IN = FLOAT(MAPINFO_IN.PS[0])
  SIZEY_IN = FLOAT(MAPINFO_IN.PS[1])
  CXUL_IN = FLOAT(MAPINFO_IN.MC[2])
  CYUL_IN = FLOAT(MAPINFO_IN.MC[3])
  LOCX_IN = FLOAT(MAPINFO_IN.MC[0])
  LOCY_IN = FLOAT(MAPINFO_IN.MC[1])
  ;-------------------------------------------------------------------------
  ; SET SUBSET:
  ;-------------------------------------------------------------------------
  ; SUBSET WIDGET
  BASE = WIDGET_AUTO_BASE(TITLE='SELECT SUBSET')
  WS = WIDGET_SUBSET(BASE, UVALUE='SUBSET', FID=FID_FIRST, DIMS=DIMS_IN, /AUTO)
  RESULT = AUTO_WID_MNG(BASE)
  IF (RESULT.ACCEPT EQ 0) THEN BEGIN
    PRINT, ''
    PRINT, 'THE SELECTED SUBSET IS NOT VALID'
    PRINT, ''
    RETURN
  ENDIF
  ; SET SUBSET VARIABLE
  DIMS_NEW = RESULT.SUBSET
  ; FIX
  DIMS_NEW = LONG([DIMS_NEW[0], DIMS_NEW[1]+1, DIMS_NEW[2], DIMS_NEW[3], DIMS_NEW[4]])
  ; SET NEW NS AND NL
  IF DIMS_NEW[1] EQ 0 THEN NS_NEW = DIMS_NEW[2] + 1 ELSE NS_NEW = DIMS_NEW[2] - DIMS_NEW[1] + 1
  IF DIMS_NEW[3] EQ 0 THEN NL_NEW = DIMS_NEW[4] + 1 ELSE NL_NEW = DIMS_NEW[4] - DIMS_NEW[3]
  ; SET X_START AND Y_START
  X_START = DIMS_NEW[1] - 1
  Y_START = DIMS_NEW[3]
  ;-------------------------------------------------------------------------
  ; SET OUTPUT MAP INFO:
  ;-------------------------------------------------------------------------
  ; SELECT AN EXISTING FILE
  IN_EXAMPLE = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics', $
    TITLE='SELECT AN EXISTING FILE', /MUST_EXIST, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; OPEN FILE
  ENVI_OPEN_FILE, IN_EXAMPLE, R_FID=FID_EXAMPLE, /NO_REALIZE
  ;-------------------------------------------------------------------------
  ; QUERY FILE
  ENVI_FILE_QUERY, FID_EXAMPLE, DIMS=DIMS_EXAMPLE, NS=NS_EXAMPLE, NL=NL_EXAMPLE, NB=NB_EXAMPLE, $
    INTERLEAVE=INTERLEAVE_EXAMPLE, DATA_TYPE=DATATYPE_EXAMPLE, XSTART=XSTART_EXAMPLE, $
    FILE_TYPE=FILE_TYPE_EXAMPLE,YSTART=YSTART_EXAMPLE, OFFSET=OFFSET_EXAMPLE, DATA_OFFSETS=DATA_OFFSETS_EXAMPLE
  ;-------------------------------------------------------------------------
  ; GET MAP INFORMATION ; EXAMPLE RASTER
  MAPINFO_EXAMPLE = ENVI_GET_MAP_INFO(FID=FID_EXAMPLE)
  DATUM_EXAMPLE = MAPINFO_EXAMPLE.PROJ.DATUM
  PROJ_EXAMPLE = MAPINFO_EXAMPLE.PROJ.NAME
  UNITS_EXAMPLE = MAPINFO_EXAMPLE.PROJ.UNITS
  SIZEX_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.PS[0])
  SIZEY_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.PS[1])
  CXUL_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[2])
  CYUL_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[3])
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  FOR f=0, COUNT_F-1 DO BEGIN ; START 'FOR f'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET INPUT FILE
    INFILE = IN_X[f]
    ;-----------------------------------------------------------------------
    ; GET FILENAME AND PATH FROM FULL NAME & PATH
    START = STRPOS(INFILE, '\', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(INFILE)-START)-4
    FNAME = STRMID(INFILE, START, LENGTH)
    INPATH = STRMID(INFILE, 0, START)
    OUTPATH = OUT_DIR
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; SUBSET:
    ;***********************************************************************
    ; OPEN FILE
    ENVI_OPEN_FILE, INFILE, R_FID=FID_IN, /NO_REALIZE
    ;-----------------------------------------------------------------------
    ; QUERY FILE
    ENVI_FILE_QUERY, FID_IN, DATA_TYPE=DATATYPE_OUT
    ; GET DATA
    DATA_IN = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS_NEW, POS=0)
    ;-----------------------------------------------------------------------
    ; BUILD THE OUTPUT FILENAME
    OUT_FILE = OUTPATH + FNAME + '.SUBSET.img'
    ;-----------------------------------------------------------------------
    ; WRITE DATA
    ENVI_WRITE_ENVI_FILE, DATA_IN, OUT_NAME=OUT_FILE, MAP_INFO=MAPINFO_EXAMPLE, $
      PIXEL_SIZE=[SIZEX_IN, SIZEY_IN], OUT_DT=DATATYPE_OUT, NS=NS_NEW, NL=NL_NEW, $
      NB=NB_IN, FILE_TYPE=FILE_TYPE_IN, UNITS=UNITS_IN, XSTART=X_START, YSTART=Y_START, /NO_OPEN
    ;-----------------------------------------------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', $
      STRTRIM(f+1, 2), ' OF ', STRTRIM(COUNT_F, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR f'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Subset_Extents'
  PRINT,''
  ;-------------------------------------------------------------------------
END