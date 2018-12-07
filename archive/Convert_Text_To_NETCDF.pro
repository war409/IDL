; ##########################################################################
; NAME: Convert_Irregularly_Gridded_Text_Based_Data.pro
; LANGUAGE: IDL + ENVI
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: For Hylke Beck
; DATE: 06/04/2010
; DLM: 07/04/2010
;
; DESCRIPTION: This tool converts three-part ascii text files to grid.
;
; INPUT:       One text (.txt) file containing latitude coordinates, one text 
;              (.txt) file containing longitude coordinates and one, or more 
;              text (.txt) files containing data of interest; that is, data
;              associated with the aformentioned coordinate pairs.  
;
; OUTPUT:      One floating point binary (bsq) file per input data file.
;               
; PARAMETERS:  Via IDL widgets:
; 
;              'SELECT THE INPUT LATITUDE FILE'
;              'SELECT THE INPUT LONGITUDE FILE'
;              'SELECT THE INPUT DATA'
;              'SELECT THE INPUT DATA TYPE'
;              'SET THE OUTPUT CELL SIZE'
;
; NOTES:       An interactive ENVI session is needed to run this tool.
;
; ##########################################################################
;
PRO Convert_Irregularly_Gridded_Text_Based_Data
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Convert_Irregularly_Gridded_Text_Based_Data'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT LATITUDE FILE
  IN_LAT = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\TerReS_team\Visitors\Beck\FASIR data\temp', $
    TITLE='SELECT THE INPUT LATITUDE FILE', FILTER='*.txt', /MUST_EXIST, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------  
  ; SELECT THE INPUT LONGITUDE FILE
  IN_LON = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\TerReS_team\Visitors\Beck\FASIR data\temp', $
    TITLE='SELECT THE INPUT LONGITUDE FILE', FILTER='*.txt', /MUST_EXIST, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------  
  ; SELECT THE INPUT DATA FILES
  IN_DATA = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\TerReS_team\Visitors\Beck\FASIR data\temp', $
    TITLE='SELECT THE INPUT DATA', FILTER='*.txt', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT DATATYPE
  VALUES = ['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', '2 : INT : Integer', $
    '3 : LONG : Longword integer', '4 : FLOAT : Floating point', '5 : DOUBLE : Double-precision floating', $
    '6 : COMPLEX : Complex floating', '7 : STRING : String', '8 : STRUCT : Structure', $
    '9 : DCOMPLEX : Double-precision complex', '10 : POINTER : Pointer', '11 : OBJREF : Object reference', $
    '12 : UINT : Unsigned Integer', '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT THE INPUT DATA TYPE', $
    /COLUMN, /EXCLUSIVE, /NO_RELEASE)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  DATATYPE = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY
  ;DIR_OUT = ENVI_PICKFILE(PATH='\\file-wron', $
  ;  TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY)
  ;---------------------------------------------------------------------   
  ; SELECT THE OUTPUT CELL SIZE
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=0.25000, TITLE='SET THE OUTPUT CELL SIZE', $
    /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  SIZE_OUT = FLOAT(RESULT.VALUE)
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------   
  ; SORT FILE LIST
  IN_DATA = IN_DATA[SORT(IN_DATA)]
  ; SET FILE COUNT
  COUNT_DF = N_ELEMENTS(IN_DATA)
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; BUILD LOCATION ARRAYS:
  ;*************************************************************************
  ;------------------------------------------------------------------------- 
  ; LATITUDE:
  ;------------------------------------------------------------------------- 
  ; OPEN THE LATITUDE FILE
  OPENR, LAT_LUN, IN_LAT, /GET_LUN
  ;-------------------------------------------------------------------------    
  ; GET LINE COUNT
  COUNT_LLAT = FILE_LINES(IN_LAT)  
  ;-------------------------------------------------------------------------
  ; SET COUNTER
  i = -1
  ;-------------------------------------------------------------------------
  ; READ INPUT (ONE LINE AT A TIME)
  WHILE NOT EOF(LAT_LUN) DO BEGIN  
    ;-----------------------------------------------------------------------
    ; UPDATE COUNTER    
    i = (i+1)
    ;-----------------------------------------------------------------------    
    ; RESET VARIABLE 'LINE'
    LINE = ''
    ;-----------------------------------------------------------------------
    ; READ THE iTH LINE OF THE INPUT FILE
    READF, LAT_LUN, LINE
    ;-----------------------------------------------------------------------    
    ; SPLIT THE LINE INTO COMPONENT ELEMENTS
    SPLIT_LAT = STRSPLIT(LINE(0), ' ', /EXTRACT)
    ;-----------------------------------------------------------------------    
    ; GET SAMPLE COUNT
    COUNT_SLAT = N_ELEMENTS(SPLIT_LAT)
    ;-----------------------------------------------------------------------    
    ; MAKE AN EMPTY ARRAY TO HOLD THE LATITUDE INFORMATION
    IF i EQ 0 THEN MATRIX_LAT = FLTARR(COUNT_SLAT,COUNT_LLAT)
    ;-----------------------------------------------------------------------    
    ; FILL THE LATITUDE ARRAY
    MATRIX_LAT[*,i] = FLOAT(SPLIT_LAT)
    ;-----------------------------------------------------------------------    
  ENDWHILE
  ;-------------------------------------------------------------------------
  ; LONGITUDE:
  ;------------------------------------------------------------------------- 
  ; OPEN THE LONGITUDE FILE
  OPENR, LON_LUN, IN_LON, /GET_LUN
  ;-------------------------------------------------------------------------    
  ; GET LINE COUNT
  COUNT_LLON = FILE_LINES(IN_LON)  
  ;-------------------------------------------------------------------------
  ; SET COUNTER
  i = -1
  ;-------------------------------------------------------------------------
  ; READ INPUT (ONE LINE AT A TIME)
  WHILE NOT EOF(LON_LUN) DO BEGIN  
    ;-----------------------------------------------------------------------
    ; UPDATE COUNTER    
    i = (i+1)
    ;-----------------------------------------------------------------------    
    ; RESET VARIABLE 'LINE'
    LINE = ''
    ;-----------------------------------------------------------------------
    ; READ THE iTH LINE OF THE INPUT FILE
    READF, LON_LUN, LINE
    ;-----------------------------------------------------------------------    
    ; SPLIT THE LINE INTO COMPONENT ELEMENTS
    SPLIT_LON = STRSPLIT(LINE(0), ' ', /EXTRACT)
    ;-----------------------------------------------------------------------    
    ; GET SAMPLE COUNT
    COUNT_SLON = N_ELEMENTS(SPLIT_LON)
    ;-----------------------------------------------------------------------    
    ; MAKE AN EMPTY ARRAY TO HOLD THE LONGITUDE INFORMATION
    IF i EQ 0 THEN MATRIX_LON = FLTARR(COUNT_SLON,COUNT_LLON)
    ;-----------------------------------------------------------------------    
    ; FILL THE LONGITUDE ARRAY
    MATRIX_LON[*,i] = FLOAT(SPLIT_LON)
    ;-----------------------------------------------------------------------    
  ENDWHILE
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SAMPLE AND LINE CHECK
  IF COUNT_SLAT NE COUNT_SLON THEN RETURN
  IF COUNT_LLAT NE COUNT_LLON THEN RETURN
  ; SET SAMPLE AND LINE COUNT
  COUNT_SAMPLE = COUNT_SLAT
  COUNT_LINE = COUNT_LLAT
  ; SET ELEMENT TOTAL
  COUNT_TOTAL = (COUNT_SAMPLE * COUNT_LINE)
  ;-------------------------------------------------------------------------
  FOR i=0, COUNT_DF-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; SET THE iTH INPUT FILE
    DATA_IN = IN_DATA[i]
    ;-----------------------------------------------------------------------
    ; SET THE OUTPUT FILE NAME
    START = STRPOS(DATA_IN, '\', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(DATA_IN)-START)-4
    FNAME = STRMID(DATA_IN, START, LENGTH)
    ; BUILD THE OUTPUT FILENAME
    ;FILE_OUT = DIR_OUT + '\' + FNAME + '.nc'
    ;-----------------------------------------------------------------------    
    ; MAKE AN EMPTY ARRAY TO HOLD THE INPUT DATA
    IF DATATYPE EQ 1 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /BYTE)
    IF DATATYPE EQ 2 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /INTEGER)
    IF DATATYPE EQ 3 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /LONG)
    IF DATATYPE EQ 4 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /FLOAT)
    IF DATATYPE EQ 5 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /DOUBLE)
    IF DATATYPE EQ 6 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /COMPLEX)
    IF DATATYPE EQ 7 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /STRING)
    IF DATATYPE EQ 8 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /STRUCT)
    IF DATATYPE EQ 9 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /DCOMPLEX)
    IF DATATYPE EQ 10 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /POINTER)
    IF DATATYPE EQ 11 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /OBJREF)    
    IF DATATYPE EQ 12 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /UINT)
    IF DATATYPE EQ 13 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /ULONG)
    IF DATATYPE EQ 14 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /LONG64)
    IF DATATYPE EQ 15 THEN MATRIX_DATA = MAKE_ARRAY(COUNT_SAMPLE,COUNT_LINE, /ULONG64)
    ;-----------------------------------------------------------------------
    ; OPEN THE CURRENT INPUT FILE AND GET DATA
    OPENR, IN_LUN, DATA_IN, /GET_LUN
    ; SET THE POINTER POSITION
    POINT_LUN, IN_LUN, 0
    ; FILL ARRAY
    READF, IN_LUN, MATRIX_DATA
    ; CLOSE THE INPUT FILE 
    CLOSE, IN_LUN
    ; FREE THE INPUT LUN
    FREE_LUN, IN_LUN
    ;-----------------------------------------------------------------------    
    ; CONVERT LATITUDE, LONGITUDE AND DATA ARRAYS TO 3D:
    ;-----------------------------------------------------------------------
    ; MAKE AN EMPTY ARRAY TO HOLD THE COORDINATE INFORMATION
    MATRIX_M = MAKE_ARRAY(3,COUNT_TOTAL, /FLOAT)
    SEGMENT_START = -1
    SEGMENT_LENGTH = COUNT_SAMPLE
    ;----------------------------------------------------------------------- 
    FOR j=0, COUNT_LINE-1 DO BEGIN
      ;---------------------------------------------------------------------
      ; UPDATE SEGMENT START & SEGMENT END
      IF j EQ 0 THEN SEGMENT_END = SEGMENT_START + SEGMENT_LENGTH
      IF j EQ 0 THEN SEGMENT_START = SEGMENT_START + 1
      IF j GT 0 THEN SEGMENT_START = SEGMENT_END + 1
      IF j GT 0 THEN SEGMENT_END = SEGMENT_END + SEGMENT_LENGTH
      ;---------------------------------------------------------------------
      ; (SEGMENT_START:SEGMENT_END)
      MATRIX_M[0,SEGMENT_START:SEGMENT_END] = MATRIX_LAT[*,j]
      MATRIX_M[1,SEGMENT_START:SEGMENT_END] = MATRIX_LON[*,j]
      MATRIX_M[2,SEGMENT_START:SEGMENT_END] = MATRIX_DATA[*,j]
      ;---------------------------------------------------------------------
    ENDFOR
    ;-----------------------------------------------------------------------    
    ; GET THE FIRST AND LAST COORDINATE PAIR:
    ;-----------------------------------------------------------------------
    ; GET THE FIRST LONGITUDE COORDINATE
    FIRST_MX = MAX(MATRIX_M[1,*])
    ; GET THE FIRST LATITUDE COORDINATE
    FIRST_MY = MAX(MATRIX_M[0,*])
    ; GET THE LAST LONGITUDE COORDINATE
    INDEX_X = WHERE((MATRIX_M[1,*]) NE -180.10000, COUNT)
    LAST_MX = MIN((MATRIX_M[1,*])[INDEX_X]) 
    ; GET THE LAST LATITUDE COORDINATE
    INDEX_Y = WHERE((MATRIX_M[0,*]) NE -90.10000, COUNT)
    LAST_MY = MIN((MATRIX_M[0,*])[INDEX_Y]) 
    ;-----------------------------------------------------------------------  
    ; GET THE TOTAL X AND Y SHIFT:
    ;-----------------------------------------------------------------------  
    ; GET X SHIFT
    XSHIFT = FIRST_MX - LAST_MX
    ; GET Y SHIFT
    YSHIFT = FIRST_MY - LAST_MY
    ;-----------------------------------------------------------------------  
    ; GET THE UNIQUE LONGITUDE COORDINATES
    UNIQUE_X = ((MATRIX_M[1,*])[INDEX_X])[UNIQ(((MATRIX_M[1,*])[INDEX_X]), SORT(((MATRIX_M[1,*])[INDEX_X])))]
    ; GET THE UNIQUE LATITUDE COORDINATES
    UNIQUE_Y = ((MATRIX_M[0,*])[INDEX_Y])[UNIQ(((MATRIX_M[0,*])[INDEX_Y]), SORT(((MATRIX_M[0,*])[INDEX_Y])))]
    ; GET THE MEAN LONGITUDE STEP
    MEAN_XSTEP = XSHIFT / N_ELEMENTS(UNIQUE_X)
    ; GET THE MEAN LATITUDE STEP
    MEAN_YSTEP = YSHIFT / N_ELEMENTS(UNIQUE_Y)
    ;-----------------------------------------------------------------------
    ; ESTIMATE THE NUMBER OF SAMPLES
    OUT_SAMPLES = XSHIFT / MEAN_XSTEP
    ; ESTIMATE THE NUMBER OF LINES
    OUT_LINES = YSHIFT / MEAN_YSTEP
    ;-----------------------------------------------------------------------    
    PRINT,''

    OUT_PROJ = ENVI_PROJ_CREATE(/GEOGRAPHIC, DATUM='WGS-84', NAME='GEOGRAPHIC Lat/Lon', UNITS=Degrees)

    ENVI_DOIT, 'ENVI_GRID_DOIT', /EXTRAP, /IN_MEMORY, R_FID=R_FID, INTERP=1, OUT_DT=4, $
      X_PTS=((MATRIX_M[1,*])[INDEX_X]), Y_PTS=((MATRIX_M[0,*])[INDEX_X]), Z_PTS=((MATRIX_M[2,*])[INDEX_X]), $
      PIXEL_SIZE=[0.25,0.25], O_PROJ=OUT_PROJ
      
    
    
    ;-----------------------------------------------------------------------
    ; GET END TIME: LOOP
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'    PROCESSING TIME: ', STRTRIM(SECONDS, 2),$
      ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_DF, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR i'
  ;-------------------------------------------------------------------------
  
  
  
  
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Convert_Irregularly_Gridded_Text_Based_Data'
  PRINT,''
  ;-------------------------------------------------------------------------
END   