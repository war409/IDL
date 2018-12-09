; ##############################################################################################
; NAME: BATCH_DOIT_ENVI_Header.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 18/02/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool create an ENVI header information file for each input.
; 
;              The first input file (listed alphabetically) may have an associated ENVI header if
;              so this file is used as a template for the remaining input data. 
;              
;              If the first input file (listed alphabetically) does not have an associated ENVI 
;              header file an ENVI widget will request the header information. The user may point 
;              to an existing file or enter the header information manually.
;              
;              In order for flat binary files (including ENVI standard format .img) to be used in 
;              ENVI, they need to have an associated header file. The header fields DATA_TYPE, 
;              INTERLEAVE, NB, NL, NS, OFFSET & DATA_IGNORE_VALUE define the basic set of  
;              information needed to open and work with the data. These keywords represent the data
;              -type (i.e. byte, integer etc.), the file interleave (BSQ, BIL, BIP), band count, line
;              count (i.e. number of rows), sample count (i.e. number of columns) and the no-data 
;              value respectively.
;
; INPUT:       Multiple single-band rasters.
;
; OUTPUT:      One ENVI header information file (.hdr) for each input.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.  SELECT THE INPUT DATA: see INPUT
;
; NOTES:       The input data must have identical dimensions and data type. 
; 
;              An interactive ENVI session is needed to run this tool.
;              
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_ENVI_Header
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_ENVI_Header'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA
  
  PATH = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\floodplain\nagler\'
  
  FILTER=['*.img','*.flt','*.bin','*.bsq','*.dat']
  TITLE='SELECT THE INPUT DATA'
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)  
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
  ;--------------------------------------------------------------------------------------------- 
  ; QUERY THE FIRST FILE:
  ;--------------
  ; OPEN FILE
  ENVI_OPEN_FILE, IN_FILES[0], /NO_REALIZE, R_FID=FID_FIRST
  ;--------------
  ; QUERY FILE
  ENVI_FILE_QUERY, FID_FIRST, DIMS=DIMS_IN, NS=NS_IN, NL=NL_IN, NB=NB_IN, INTERLEAVE=INTERLEAVE_IN, $
    DATA_TYPE=DATATYPE_IN, XSTART=XSTART_IN, FILE_TYPE=FILE_TYPE_IN,YSTART=YSTART_IN, OFFSET=OFFSET_IN, $
    DATA_OFFSETS=DATA_OFFSETS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN
  ;--------------
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
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=1, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME:
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET THE i-TH INPUT FILE
    FILE_IN = IN_FILES[i]
    ;-------------------------------------------------------------------------------------------
    ; SET ENVI HEADER:
    ;-------------------------------------------------------------------------------------------
    ; BUILD ENVI HEADER FILE  
    ENVI_SETUP_HEAD, FNAME=FILE_IN, NB=NB_IN, NL=NL_IN, NS=NS_IN, DATA_TYPE=DATATYPE_IN, $
      PIXEL_SIZE=[SIZEX_IN, SIZEY_IN], MAP_INFO=MAPINFO_IN, INTERLEAVE=INTERLEAVE_IN, $
      XSTART=XSTART_IN, YSTART=YSTART_IN, FILE_TYPE=FILE_TYPE_IN, OFFSET=OFFSET_IN, $
      DATA_OFFSETS=DATA_OFFSETS_IN, UNITS=UNITS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN, /WRITE
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', $
      STRTRIM(N_ELEMENTS(IN_FILES), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Temporal_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END