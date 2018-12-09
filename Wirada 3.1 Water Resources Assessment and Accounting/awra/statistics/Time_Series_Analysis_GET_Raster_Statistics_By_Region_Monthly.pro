; ##########################################################################
; NAME: Time_Series_Analysis_GET_Raster_Statistics_By_Region_Monthly.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Reconstructing the Murray-Darling drought (Activity 6, WRAA, WIRADA)
; DATE: 19/02/2010
; DLM: 03/05/2010
;
; DESCRIPTION: This tool extracts the mean, median, minimum, maximum, standard 
;              deviation and variance of the cell values where the user-selected 
;              polygon or point vector region of interest intersect the input 
;              time-series.
;
; INPUT:       Multiple single-band rasters. One or more ENVI region of interest.
;
; OUTPUT:      One comma delimeted text base file. One file enrty is recorded for 
;              each input region of interest and input file pair.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              'SELECT THE INPUT DATA'
;              'SELECT THE OUTPUT FILE'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE' (Optional)
;              'SELECT ONE OR MORE ROI'
;
; NOTES:       The input data must have identical dimensions. An interactive 
;              ENVI session is needed to run this tool. One or more ROI
;              must be associated with the input data.
;
; ##########################################################################
;
PRO Time_Series_Analysis_GET_Raster_Statistics_By_Region_Monthly
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_GET_Raster_Statistics_By_Region_Monthly'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; SET THE DATASET PREFIX
  IN_PREFIX = 'MCD43A4.aet.monthly.composite'
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT DATA
  IN_X = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample', $
    TITLE='SELECT THE INPUT DATA', FILTER='*.img', /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------  
  ; SELECT THE OUTPUT FILE:
  OUT_FILE = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Statistics\Univariate', $
    TITLE='SELECT THE OUTPUT FILE', /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  VALUES = ['ENTER A NODATA VALUE', 'DO NOT ENTER A NODATA VALUE']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT NODATA STATUS', $
    /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  STATUS = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  IF STATUS EQ 0 THEN BEGIN
    BASE = WIDGET_BASE(TITLE='IDL WIDGET')
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=-999, TITLE='SET THE NODATA VALUE  ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA1 = RESULT.VALUE
    NODATA = NODATA1[0]
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
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
  ; GET ROI:
  ;-------------------------------------------------------------------------
  ; ERROR CHECK
  ROI_IDS = ENVI_GET_ROI_IDS(FID=FID_FIRST, ROI_NAME=ROI_NAME, /SHORT_NAME)
  IF (ROI_IDS[0] EQ -1) THEN BEGIN
    PRINT, 'THERE IS NO ROI ASSOCIATED WITH THE SELECTED INPUT IMAGE'
    RETURN
  ENDIF
  ;-------------------------------------------------------------------------
  ; SELECT ONE OR MORE ROI
  BASE = WIDGET_AUTO_BASE(TITLE='SELECT ONE OR MORE ROI')
  WM   = WIDGET_MULTI(BASE, LIST=ROI_NAME, UVALUE='LIST', /AUTO)
  RESULT = AUTO_WID_MNG(BASE)
  ; ERROR CHECK
  IF (RESULT.ACCEPT EQ 0) THEN BEGIN
    PRINT, 'SELECT ONE OR MORE ROI'
    RETURN
  ENDIF
  ;-------------------------------------------------------------------------
  ; SET ROI POSITION AND NAME:
  ;-------------------------------------------------------------------------  
  ; GET ROI NAMES
  RN = STRARR(N_ELEMENTS(ROI_NAME))
  FOR h=0, N_ELEMENTS(ROI_NAME)-1 DO BEGIN
    RNAME_START = STRPOS(ROI_NAME[h], '(', /REVERSE_SEARCH)+6 ; Where: '+6' equals '(NAME='
    RNAME_LENGTH = (STRLEN(ROI_NAME[h])-RNAME_START)-1 ; Where: '-1' removes ')'
    RN[h] = STRMID(ROI_NAME[h], RNAME_START[0], RNAME_LENGTH[0])
  ENDFOR
  ;-------------------------------------------------------------------------
  ; SET SHORT ROI NAMES
  IF N_ELEMENTS(RN) GT 0 THEN R0 = RN[0] ELSE R0 = 'NA' 
  IF N_ELEMENTS(RN) GT 1 THEN R1 = RN[1] ELSE R1 = 'NA' 
  IF N_ELEMENTS(RN) GT 2 THEN R2 = RN[2] ELSE R2 = 'NA' 
  IF N_ELEMENTS(RN) GT 3 THEN R3 = RN[3] ELSE R3 = 'NA' 
  IF N_ELEMENTS(RN) GT 4 THEN R4 = RN[4] ELSE R4 = 'NA' 
  IF N_ELEMENTS(RN) GT 5 THEN R5 = RN[5] ELSE R5 = 'NA' 
  IF N_ELEMENTS(RN) GT 6 THEN R6 = RN[6] ELSE R6 = 'NA' 
  IF N_ELEMENTS(RN) GT 7 THEN R7 = RN[7] ELSE R7 = 'NA' 
  IF N_ELEMENTS(RN) GT 8 THEN R8 = RN[8] ELSE R8 = 'NA' 
  IF N_ELEMENTS(RN) GT 9 THEN R9 = RN[9] ELSE R9 = 'NA' 
  IF N_ELEMENTS(RN) GT 10 THEN R10 = RN[10] ELSE R10 = 'NA' 
  IF N_ELEMENTS(RN) GT 11 THEN R11 = RN[11] ELSE R11 = 'NA' 
  IF N_ELEMENTS(RN) GT 12 THEN R12 = RN[12] ELSE R12 = 'NA' 
  IF N_ELEMENTS(RN) GT 13 THEN R13 = RN[13] ELSE R13 = 'NA' 
  IF N_ELEMENTS(RN) GT 14 THEN R14 = RN[14] ELSE R14 = 'NA' 
  IF N_ELEMENTS(RN) GT 15 THEN R15 = RN[15] ELSE R15 = 'NA' 
  IF N_ELEMENTS(RN) GT 16 THEN R16 = RN[16] ELSE R16 = 'NA' 
  IF N_ELEMENTS(RN) GT 17 THEN R17 = RN[17] ELSE R17 = 'NA' 
  IF N_ELEMENTS(RN) GT 18 THEN R18 = RN[18] ELSE R18 = 'NA' 
  ;-------------------------------------------------------------------------  
  ; GET LANDUSE
  LNAME_START = STRPOS(ROI_NAME, 'Layer: ', /REVERSE_SEARCH)+7 ; Where: '+7' equals 'EVF: Layer: '
  ; Where: '14' removes '_intercept.shp', 'RNAME_LENGTH' removes the RR name, and 7 removes ' (NAME='
  LNAME_LENGTH = (STRLEN(ROI_NAME)-LNAME_START)-(14+RNAME_LENGTH+7)  
  LN = STRMID(ROI_NAME, LNAME_START[0], LNAME_LENGTH[0])
  ;-------------------------------------------------------------------------   
  ;*************************************************************************
  ; GET DATES:
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT 
  FNAME_START = STRPOS(IN_X, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_X)-FNAME_START)-4
  FNAME_SHORT = STRMID(IN_X, FNAME_START[0], FNAME_LENGTH[0])
  ;-------------------------------------------------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE (8-Day or 16-Day)         ** DEFINE **
  ;YYYYDOY = STRMID(FNAME_SHORT, 0, 7)
  ;YYYY = STRMID(FNAME_SHORT, 0, 4)
  ;DOY = STRMID(FNAME_SHORT, 4, 7)
  ; MANIPULATE FILE NAMES TO GET DATE (Monthly)                 ** DEFINE **
  YYYYMM = STRMID(FNAME_SHORT, 8, 7)
  YYYY = STRMID(FNAME_SHORT, 8, 4)
  MM = STRMID(FNAME_SHORT, 13, 2)
  ;-------------------------------------------------------------------------  
  ; SET ROI COUNT
  PTR = WHERE(RESULT.LIST EQ 1, COUNT_ROI)
  COUNT_R = COUNT_ROI
  ;-------------------------------------------------------------------------    
  ; CREATE THE OUTPUT FILE 
  OPENW, OUT_LUN, OUT_FILE, /GET_LUN
  ;-------------------------------------------------------------------------
  ; WRITE THE FILE HEAD:                       
  ;-------------------------------------------------------------------------
  ; SET THE FILE HEAD
  FHEAD=["FID","Year","Month","Variable","Landuse", $
    "MDB_Mean","MDB_Pixel_Count","MDB_Valid_Count","MDB_NaN_Count", $
    R0+'_Mean',R0+'_Median',R0+'_StdDev',R0+'_Var',R0+'_Min',R0+'_Max',R0+'_'+"Pixel_Count",R0+'_'+"Valid_Count",R0+'_'+"NaN_Count", $
    R1+'_Mean',R1+'_Median',R1+'_StdDev',R1+'_Var',R1+'_Min',R1+'_Max',R1+'_'+"Pixel_Count",R1+'_'+"Valid_Count",R1+'_'+"NaN_Count", $
    R2+'_Mean',R2+'_Median',R2+'_StdDev',R2+'_Var',R2+'_Min',R2+'_Max',R2+'_'+"Pixel_Count",R2+'_'+"Valid_Count",R2+'_'+"NaN_Count", $
    R3+'_Mean',R3+'_Median',R3+'_StdDev',R3+'_Var',R3+'_Min',R3+'_Max',R3+'_'+"Pixel_Count",R3+'_'+"Valid_Count",R3+'_'+"NaN_Count", $
    R4+'_Mean',R4+'_Median',R4+'_StdDev',R4+'_Var',R4+'_Min',R4+'_Max',R4+'_'+"Pixel_Count",R4+'_'+"Valid_Count",R4+'_'+"NaN_Count", $
    R5+'_Mean',R5+'_Median',R5+'_StdDev',R5+'_Var',R5+'_Min',R5+'_Max',R5+'_'+"Pixel_Count",R5+'_'+"Valid_Count",R5+'_'+"NaN_Count", $
    R6+'_Mean',R6+'_Median',R6+'_StdDev',R6+'_Var',R6+'_Min',R6+'_Max',R6+'_'+"Pixel_Count",R6+'_'+"Valid_Count",R6+'_'+"NaN_Count", $
    R7+'_Mean',R7+'_Median',R7+'_StdDev',R7+'_Var',R7+'_Min',R7+'_Max',R7+'_'+"Pixel_Count",R7+'_'+"Valid_Count",R7+'_'+"NaN_Count", $
    R8+'_Mean',R8+'_Median',R8+'_StdDev',R8+'_Var',R8+'_Min',R8+'_Max',R8+'_'+"Pixel_Count",R8+'_'+"Valid_Count",R8+'_'+"NaN_Count", $
    R9+'_Mean',R9+'_Median',R9+'_StdDev',R9+'_Var',R9+'_Min',R9+'_Max',R9+'_'+"Pixel_Count",R9+'_'+"Valid_Count",R9+'_'+"NaN_Count", $
    R10+'_Mean',R10+'_Median',R10+'_StdDev',R10+'_Var',R10+'_Min',R10+'_Max',R10+'_'+"Pixel_Count",R10+'_'+"Valid_Count",R10+'_'+"NaN_Count", $
    R11+'_Mean',R11+'_Median',R11+'_StdDev',R11+'_Var',R11+'_Min',R11+'_Max',R11+'_'+"Pixel_Count",R11+'_'+"Valid_Count",R11+'_'+"NaN_Count", $
    R12+'_Mean',R12+'_Median',R12+'_StdDev',R12+'_Var',R12+'_Min',R12+'_Max',R12+'_'+"Pixel_Count",R12+'_'+"Valid_Count",R12+'_'+"NaN_Count", $
    R13+'_Mean',R13+'_Median',R13+'_StdDev',R13+'_Var',R13+'_Min',R13+'_Max',R13+'_'+"Pixel_Count",R13+'_'+"Valid_Count",R13+'_'+"NaN_Count", $
    R14+'_Mean',R14+'_Median',R14+'_StdDev',R14+'_Var',R14+'_Min',R14+'_Max',R14+'_'+"Pixel_Count",R14+'_'+"Valid_Count",R14+'_'+"NaN_Count", $
    R15+'_Mean',R15+'_Median',R15+'_StdDev',R15+'_Var',R15+'_Min',R15+'_Max',R15+'_'+"Pixel_Count",R15+'_'+"Valid_Count",R15+'_'+"NaN_Count", $
    R16+'_Mean',R16+'_Median',R16+'_StdDev',R16+'_Var',R16+'_Min',R16+'_Max',R16+'_'+"Pixel_Count",R16+'_'+"Valid_Count",R16+'_'+"NaN_Count", $
    R17+'_Mean',R17+'_Median',R17+'_StdDev',R17+'_Var',R17+'_Min',R17+'_Max',R17+'_'+"Pixel_Count",R17+'_'+"Valid_Count",R17+'_'+"NaN_Count", $
    R18+'_Mean',R18+'_Median',R18+'_StdDev',R18+'_Var',R18+'_Min',R18+'_Max',R18+'_'+"Pixel_Count",R18+'_'+"Valid_Count",R18+'_'+"NaN_Count"]
  ;-------------------------------------------------------------------------
  ; WRITE THE FILE HEAD
  PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, '"' + FHEAD + '"'
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUT_LUN    
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; PART 1 (COMBINED ROI STATISTICS):
  PRINT, '  PART 1: GET COMBINED ROI STATISTIC...'
  PRINT,''
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; MAKE MASTER COMBINED STATISTIC ARRAY
  ;   TO HOLD THE COMBINED ROI STATISTIC FROM EACH INPUT FILE (DATE)
  MATRIX_MC = MAKE_ARRAY(COUNT_F, 1, /FLOAT)
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  FOR i=0, COUNT_F-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIMEC = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET THE jTH INPUT FILE
    INFILE = IN_X[i] 
    ; GET THE jTH INPUT FILE DATE (8-Day or 16-Day)
    INDATE = YYYYMM[i]
    INYYYY = YYYY[i]
    INM = MM[i]
    ;-----------------------------------------------------------------------
    ; OPEN THE FILE
    ENVI_OPEN_FILE, INFILE, R_FID=FID_IN, /NO_REALIZE
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; ROI LOOP:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    FOR j=0, COUNT_R-1 DO BEGIN ; START 'FOR j'
      ;---------------------------------------------------------------------
      ; GET THE ROI INTERCEPTED DATA FOR THE iTH FILE
      DATA_XC = ENVI_GET_ROI_DATA(ROI_IDS[PTR[j]], FID=FID_IN, POS=[0])
      ;---------------------------------------------------------------------
      IF j EQ 0 THEN BEGIN
        ; CREATE TEMP_DATA 
        ;   TO HOLD THE COUNT OF VALID ELEMENTS AND THE SUM VALUE
        TEMP_DATAC = MAKE_ARRAY(COUNT_R, 2, /FLOAT)
      ENDIF
      ;---------------------------------------------------------------------
      ; SET NAN
      IF STATUS EQ 0 THEN BEGIN
        k = WHERE(DATA_XC EQ FLOAT(NODATA), COUNT_k)
        IF (COUNT_k GT 0) THEN DATA_XC[k] = !VALUES.F_NAN
      ENDIF
      ;---------------------------------------------------------------------      
      ; GET SUM
      SUM_XC = TOTAL(DATA_XC, 1, /NAN)
      ;---------------------------------------------------------------------      
      ; GET COUNT
      COUNT_XC = TOTAL(FINITE(DATA_XC), 1)
      ;---------------------------------------------------------------------
      ; FILL THE ARRAY TEMP_DATA
      TEMP_DATAC[j,0] = SUM_XC
      TEMP_DATAC[j,1] = COUNT_XC
      ;---------------------------------------------------------------------
    ENDFOR ; END 'FOR j'
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; GET STATISTIC FOR THE COMBINED ROIS:
    ;***********************************************************************
    ;-----------------------------------------------------------------------
    ; GET MEAN:
    ;-----------------------------------------------------------------------
    ; GET THE COMBINED SUM
    SUM_XC_C = TOTAL(TEMP_DATAC[*,0], 1, /NAN)
    ; GET THE COMBINED COUNT
    COUNT_XC_C = TOTAL(TEMP_DATAC[*,1], 1, /NAN)
    ;-----------------------------------------------------------------------    
    ; FILL DATA ARRAYS
    MATRIX_MC[i,0] = (SUM_XC_C / COUNT_XC_C)
    ;-----------------------------------------------------------------------  
    ; CLOSE THE CURRENT INPUT FILE
    IF i GT 0 THEN ENVI_FILE_MNG, ID=FID_IN, /REMOVE
    ;-----------------------------------------------------------------------
    ; GET END TIME: LOOP
    SECONDSC = (SYSTIME(1)-L_TIMEC)
    ; PRINT LOOP INFORMATION
    PRINT,'    PROCESSING TIME: ', STRTRIM(SECONDSC, 2),$
      ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_F, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR i'
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; PART 2 (INDIVIDUAL ROI STATISTICS):
  PRINT,''
  PRINT, '  PART 2: GET INDIVIDUAL ROI STATISTICS...'
  PRINT,''
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; MAKE THE MASTER STATISTIC ARRAYS
  ;   MATRIX M HOLDS THE STATISTIC VALUES DIRIVED FROM THE INDIVIDUAL REGIONS  
  ;   BY-INPUT FILE (DATE). THE SAMPLE VALUE IS HARD-CODED TO ALLOW FOR NULL  
  ;   VALUES IN THE OUTPUT IF THERE ARE 0 ROI ELEMENTS IN ANY REPORTING REGION
  MATRIX_M = MAKE_ARRAY(19, COUNT_F, /FLOAT)
  MATRIX_M1 = MAKE_ARRAY(19, COUNT_F, /FLOAT)  
  MATRIX_M2 = MAKE_ARRAY(19, COUNT_F, /FLOAT)
  MATRIX_M3 = MAKE_ARRAY(19, COUNT_F, /FLOAT)  
  MATRIX_M4 = MAKE_ARRAY(19, COUNT_F, /FLOAT)  
  MATRIX_M5 = MAKE_ARRAY(19, COUNT_F, /FLOAT)  
  ;   MATRIX C HOLDS THE PIXEL COUNT DIRIVED FOR THE INDIVIDUAL REGIONS
  MATRIX_C = MAKE_ARRAY(19, COUNT_F, /FLOAT)
  ;   MATRIX C HOLDS THE VALID PIXEL COUNT DIRIVED FOR THE INDIVIDUAL REGIONS
  MATRIX_V = MAKE_ARRAY(19, COUNT_F, /FLOAT)
  ;   MATRIX N HOLDS THE NAN PIXEL COUNT DIRIVED FOR THE INDIVIDUAL REGIONS
  MATRIX_N = MAKE_ARRAY(19, COUNT_F, /FLOAT)
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; ROI LOOP:
  ;*************************************************************************
  FOR i=0, COUNT_R-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; CREATE THE DUMMY ARRAY TEMP_DATA TO HOLD THE ROI-BASED DATA:
    ;-----------------------------------------------------------------------    
    ; GET ROI INTERCEPTED DATA FOR FID_FIRST
    DATA_FIRST = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID_FIRST, POS=[0])
    ; GET ELEMENT COUNT; FID_FIRST WITHIN THE iTH ROI
    COUNT_D = N_ELEMENTS(DATA_FIRST)
    ; CREATE TEMP_DATA
    TEMP_DATA = MAKE_ARRAY(COUNT_F, COUNT_D, /FLOAT)
    ;-----------------------------------------------------------------------
    ; CREATE EMPTY ARRAY TO HOLD THE ROI INTERCEPTED STATISTICS
    MATRIX_DATA = MAKE_ARRAY(1, COUNT_F, /FLOAT)
    MATRIX_DATA1 = MAKE_ARRAY(1, COUNT_F, /FLOAT)
    MATRIX_DATA2 = MAKE_ARRAY(1, COUNT_F, /FLOAT)
    MATRIX_DATA3 = MAKE_ARRAY(1, COUNT_F, /FLOAT)
    MATRIX_DATA4 = MAKE_ARRAY(1, COUNT_F, /FLOAT)
    MATRIX_DATA5 = MAKE_ARRAY(1, COUNT_F, /FLOAT)
    ; CREATE EMPTY ARRAY TO HOLD BAND NAME, DATE  PIXEL INFORMATION 
    MATRIX_BAND = MAKE_ARRAY(4, COUNT_F, /STRING)
    ; CREATE EMPTY ARRAY TO HOLD PIXEL INFORMATION (PIXEL COUNT)
    MATRIX_BAND_S1 = MAKE_ARRAY(1, COUNT_F, /STRING)
    ; CREATE EMPTY ARRAY TO HOLD PIXEL INFORMATION (VALID PIXEL COUNT)
    MATRIX_BAND_S2 = MAKE_ARRAY(1, COUNT_F, /STRING)
    ; CREATE EMPTY ARRAY TO HOLD PIXEL INFORMATION (NAN PIXEL COUNT)
    MATRIX_BAND_S3 = MAKE_ARRAY(1, COUNT_F, /STRING)
    ; CREATE EMPTY ARRAY TO HOLD DATEID
    DATEID = MAKE_ARRAY(1, COUNT_F, /INTEGER)
    ;-----------------------------------------------------------------------  
    ;***********************************************************************
    ; FILE LOOP:
    ;***********************************************************************
    FOR j=0, COUNT_F-1 DO BEGIN ; START 'FOR j'
      ;---------------------------------------------------------------------
      ; GET THE jTH INPUT FILE
      INFILE = IN_X[j] 
      ; GET THE jTH INPUT FILE DATE (Monthly)
      INDATE = YYYYMM[j]
      INYYYY = YYYY[j]
      INM = MM[j]
      ;---------------------------------------------------------------------  
      ; OPEN THE FILE
      ENVI_OPEN_FILE, INFILE, R_FID=FID_IN, /NO_REALIZE
      ;---------------------------------------------------------------------  
      ; GET THE ROI INTERCEPTED DATA FOR THE jTH FILE
      DATA_X = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID_IN, POS=[0])
      ;---------------------------------------------------------------------       
      ; FILL THE ARRAY TEMP_DATA
      TEMP_DATA[j,*] = DATA_X
      ;---------------------------------------------------------------------       
      ; GET THE ROI NAME
      RESULT_ROI = ENVI_GET_ROI(ROI_IDS[PTR[i]], ROI_NAME=ROI_NAME)
      ROI_LENGTH = STRLEN(ROI_NAME)
      ; EXTRACT THE ROI SHORT NAME                              ** DEFINE **
      ROI_SHORT = STRMID(ROI_NAME, 12, 12)                      
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; FORMAT DATA:
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; SET NAN
      IF STATUS EQ 0 THEN BEGIN
        k = WHERE(TEMP_DATA EQ FLOAT(NODATA), COUNT_k)
        IF (COUNT_k GT 0) THEN TEMP_DATA[k] = !VALUES.F_NAN
      ENDIF
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; GET THE IMAGE STATISTIC:
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; GET MEAN
      OUT_MEAN = MEAN(TEMP_DATA[j,*], /NAN)
      ; GET MEDIAN
      OUT_MEDIAN = MEDIAN(TEMP_DATA[j,*], /EVEN)
      ; GET MINIMUM
      OUT_MIN = MIN(TEMP_DATA[j,*], /NAN)
      ; GET MAXIMUM
      OUT_MAX = MAX(TEMP_DATA[j,*], /NAN)
      ; GET STDDEV: WHEN THERE ARE LESS THAN TWO 'REAL' NUMBERS IN THE ARRAY PRINT 'NaN'
      IF (N_ELEMENTS(WHERE(FINITE(TEMP_DATA[j,*]))) LT 2) THEN BEGIN
        OUT_STDDEV = 'NaN'
      ENDIF ELSE BEGIN
        OUT_STDDEV = STDDEV(TEMP_DATA[j,*], /NAN)
      ENDELSE 
      ; GET VARIANCE: WHEN THERE ARE LESS THAN TWO 'REAL' NUMBERS IN THE ARRAY PRINT 'NaN'
      IF (N_ELEMENTS(WHERE(FINITE(TEMP_DATA[j,*]))) LT 2) THEN BEGIN
        OUT_VAR = 'NaN'
      ENDIF ELSE BEGIN
        OUT_VAR = VARIANCE(TEMP_DATA[j,*], /NAN)
      ENDELSE
      ;---------------------------------------------------------------------   
      ; GET PIXEL COUNT FOR ROI[i] FILE[j]
      COUNT_PIXEL = N_ELEMENTS(TEMP_DATA[j,*])
      ; GET VALID PIXEL COUNT FOR ROI[i] FILE[j]
      COUNT_VALID = ROUND(TOTAL(FINITE(TEMP_DATA[j,*])))
      ; GET NAN PIXEL COUNT FOR ROI[i] FILE[j]
      COUNT_NAN = COUNT_PIXEL-COUNT_VALID
      ;---------------------------------------------------------------------    
      ; FILL DATA ARRAYS
      DATEID[0,j] = j+1 ; ID
      MATRIX_DATA[0,j] = OUT_MEAN
      MATRIX_DATA1[0,j] = OUT_MEDIAN
      MATRIX_DATA2[0,j] = OUT_STDDEV
      MATRIX_DATA3[0,j] = OUT_VAR
      MATRIX_DATA4[0,j] = OUT_MIN
      MATRIX_DATA5[0,j] = OUT_MAX
      MATRIX_BAND[0,j] = INYYYY ; DATE YYYY
      MATRIX_BAND[1,j] = INM ; DATE MM
      MATRIX_BAND[2,j] = IN_PREFIX ; DATASET PREFIX
      MATRIX_BAND[3,j] = LN[0] ; BRS ALUM LANDUSE
      MATRIX_BAND_S1[0,j] = COUNT_PIXEL ; PIXEL COUNT FOR ROI[i] FILE[j]
      MATRIX_BAND_S2[0,j] = COUNT_VALID ; VALID PIXEL COUNT FOR ROI[i] FILE[j]
      MATRIX_BAND_S3[0,j] = COUNT_NAN ; NAN PIXEL COUNT FOR ROI[i] FILE[j]
      ;---------------------------------------------------------------------
      ; CLOSE THE CURRENT INPUT FILE
      IF j GT 0 THEN ENVI_FILE_MNG, ID=FID_IN, /REMOVE
      ;---------------------------------------------------------------------
    ENDFOR ; END 'FOR j'
    ;-----------------------------------------------------------------------
    ; FILL MASTER M
    MATRIX_M[i,*] = MATRIX_DATA
    MATRIX_M1[i,*] = MATRIX_DATA1
    MATRIX_M2[i,*] = MATRIX_DATA2
    MATRIX_M3[i,*] = MATRIX_DATA3
    MATRIX_M4[i,*] = MATRIX_DATA4
    MATRIX_M5[i,*] = MATRIX_DATA5
    ; FILL MASTER COUNT
    MATRIX_C[i,*] = MATRIX_BAND_S1
    ; FILL MASTER VALID
    MATRIX_V[i,*] = MATRIX_BAND_S2
    ; FILL MASTER NAN
    MATRIX_N[i,*] = MATRIX_BAND_S3
    ;-----------------------------------------------------------------------
    ; GET END TIME: LOOP
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'    PROCESSING TIME: ', STRTRIM(SECONDS, 2), $
      ' SECONDS, FOR ROI ', STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_R, 2)
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR i'
  ;------------------------------------------------------------------------- 
  ;*************************************************************************
  ; WRITE DATA:
  PRINT,''
  PRINT, '  PART 3: WRITING OUTPUT...'
  ;*************************************************************************
  ;-------------------------------------------------------------------------
  ; OPEN THE OUTPUT FILE
  OPENU, OUT_LUN, OUT_FILE, /APPEND, /GET_LUN
  ;-------------------------------------------------------------------------  
  ; FILE LOOP:
  ;-------------------------------------------------------------------------
  FOR l=0, COUNT_F-1 DO BEGIN ; START 'FOR l'
    ;-----------------------------------------------------------------------
    ; CALCULATE COMBINED PIXEL INFORMATION
    MATRIX_CC = TOTAL(MATRIX_C[*,l], 1, /NAN)
    MATRIX_VC = TOTAL(MATRIX_V[*,l], 1, /NAN)
    MATRIX_NC = TOTAL(MATRIX_N[*,l], 1, /NAN)
    ;-----------------------------------------------------------------------
    ; WRITE DATA WHERE MATRIX_M[0,l] TO MATRIX_M[18,l] CONTAIN THE MEAN FOR EACH ROI BY-FILE
    PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, DATEID[l],'"' + MATRIX_BAND[0,l] + '"', $
      '"' + MATRIX_BAND[1,l] + '"','"' + MATRIX_BAND[2,l] + '"','"' + MATRIX_BAND[3,l] + '"', $ 
      MATRIX_MC[l,0],MATRIX_CC,MATRIX_VC,MATRIX_NC, $
      MATRIX_M[0,l],MATRIX_M1[0,l],MATRIX_M2[0,l],MATRIX_M3[0,l],MATRIX_M4[0,l],MATRIX_M5[0,l],MATRIX_C[0,l],MATRIX_V[0,l],MATRIX_N[0,l], $    
      MATRIX_M[1,l],MATRIX_M1[1,l],MATRIX_M2[1,l],MATRIX_M3[1,l],MATRIX_M4[1,l],MATRIX_M5[1,l],MATRIX_C[1,l],MATRIX_V[1,l],MATRIX_N[1,l], $
      MATRIX_M[2,l],MATRIX_M1[2,l],MATRIX_M2[2,l],MATRIX_M3[2,l],MATRIX_M4[2,l],MATRIX_M5[2,l],MATRIX_C[2,l],MATRIX_V[2,l],MATRIX_N[2,l], $   
      MATRIX_M[3,l],MATRIX_M1[3,l],MATRIX_M2[3,l],MATRIX_M3[3,l],MATRIX_M4[3,l],MATRIX_M5[3,l],MATRIX_C[3,l],MATRIX_V[3,l],MATRIX_N[3,l], $
      MATRIX_M[4,l],MATRIX_M1[4,l],MATRIX_M2[4,l],MATRIX_M3[4,l],MATRIX_M4[4,l],MATRIX_M5[4,l],MATRIX_C[4,l],MATRIX_V[4,l],MATRIX_N[4,l], $   
      MATRIX_M[5,l],MATRIX_M1[5,l],MATRIX_M2[5,l],MATRIX_M3[5,l],MATRIX_M4[5,l],MATRIX_M5[5,l],MATRIX_C[5,l],MATRIX_V[5,l],MATRIX_N[5,l], $ 
      MATRIX_M[6,l],MATRIX_M1[6,l],MATRIX_M2[6,l],MATRIX_M3[6,l],MATRIX_M4[6,l],MATRIX_M5[6,l],MATRIX_C[6,l],MATRIX_V[6,l],MATRIX_N[6,l], $   
      MATRIX_M[7,l],MATRIX_M1[7,l],MATRIX_M2[7,l],MATRIX_M3[7,l],MATRIX_M4[7,l],MATRIX_M5[7,l],MATRIX_C[7,l],MATRIX_V[7,l],MATRIX_N[7,l], $ 
      MATRIX_M[8,l],MATRIX_M1[8,l],MATRIX_M2[8,l],MATRIX_M3[8,l],MATRIX_M4[8,l],MATRIX_M5[8,l],MATRIX_C[8,l],MATRIX_V[8,l],MATRIX_N[8,l], $   
      MATRIX_M[9,l],MATRIX_M1[9,l],MATRIX_M2[9,l],MATRIX_M3[9,l],MATRIX_M4[9,l],MATRIX_M5[9,l],MATRIX_C[9,l],MATRIX_V[9,l],MATRIX_N[9,l], $
      MATRIX_M[10,l],MATRIX_M1[10,l],MATRIX_M2[10,l],MATRIX_M3[10,l],MATRIX_M4[10,l],MATRIX_M5[10,l],MATRIX_C[10,l],MATRIX_V[10,l],MATRIX_N[10,l], $   
      MATRIX_M[11,l],MATRIX_M1[11,l],MATRIX_M2[11,l],MATRIX_M3[11,l],MATRIX_M4[11,l],MATRIX_M5[11,l],MATRIX_C[11,l],MATRIX_V[11,l],MATRIX_N[11,l], $ 
      MATRIX_M[12,l],MATRIX_M1[12,l],MATRIX_M2[12,l],MATRIX_M3[12,l],MATRIX_M4[12,l],MATRIX_M5[12,l],MATRIX_C[12,l],MATRIX_V[12,l],MATRIX_N[12,l], $   
      MATRIX_M[13,l],MATRIX_M1[13,l],MATRIX_M2[13,l],MATRIX_M3[13,l],MATRIX_M4[13,l],MATRIX_M5[13,l],MATRIX_C[13,l],MATRIX_V[13,l],MATRIX_N[13,l], $ 
      MATRIX_M[14,l],MATRIX_M1[14,l],MATRIX_M2[14,l],MATRIX_M3[14,l],MATRIX_M4[14,l],MATRIX_M5[14,l],MATRIX_C[14,l],MATRIX_V[14,l],MATRIX_N[14,l], $   
      MATRIX_M[15,l],MATRIX_M1[15,l],MATRIX_M2[15,l],MATRIX_M3[15,l],MATRIX_M4[15,l],MATRIX_M5[15,l],MATRIX_C[15,l],MATRIX_V[15,l],MATRIX_N[15,l], $       
      MATRIX_M[16,l],MATRIX_M1[16,l],MATRIX_M2[16,l],MATRIX_M3[16,l],MATRIX_M4[16,l],MATRIX_M5[16,l],MATRIX_C[16,l],MATRIX_V[16,l],MATRIX_N[16,l], $   
      MATRIX_M[17,l],MATRIX_M1[17,l],MATRIX_M2[17,l],MATRIX_M3[17,l],MATRIX_M4[17,l],MATRIX_M5[17,l],MATRIX_C[17,l],MATRIX_V[17,l],MATRIX_N[17,l], $ 
      MATRIX_M[18,l],MATRIX_M1[18,l],MATRIX_M2[18,l],MATRIX_M3[18,l],MATRIX_M4[18,l],MATRIX_M5[18,l],MATRIX_C[18,l],MATRIX_V[18,l],MATRIX_N[18,l]
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR m' ROI  
  ;-------------------------------------------------------------------------
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUT_LUN
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_GET_Raster_Statistics_By_Region_Monthly'
  PRINT,''
  ;-------------------------------------------------------------------------
END  