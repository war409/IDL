; ######################################################################
; NAME: RADIOSONDE_ET_TIMESERIES_EXTRACT_INTERSECT.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren
; DATE: 02/10/2009
; DLM: 02/11/2009
; DESCRIPTION: THIS TOOL EXTRACTS RASTER TIME-SERIES DATA AT 31 RADIOSONDE
;              LAUNCH SITES. THE INTERSECT VALUE IS RETURNED.
; INPUT: 31 RADIOSONDE SITES (AS [1X1] ROIs). SINGLE OR MULTI-BAND IMAGE.
; OUTPUT: ONE CSV FILE.
; SET PARAMETERS: SEE **DEFINE** IN THE CODE.
; NOTES: MAKE SURE THAT THE COLUMN HEAD IS SORTED LIKE THE ENVI ROI LIST.
; ######################################################################
; 
PRO RADIOSONDE_ET_TIMESERIES_EXTRACT_INTERSECT
  ; GET START TIME FOR WHOLE
  F_DATE = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: RADIOSONDE_ET_TIMESERIES_EXTRACT_INTERSECT'
  ;---------------------------------------------------------------------
  ; CREATE THE [EMPTY] OUTPUT CSV FILE TO CONTAIN TIME-SERIES DATA
  ; DEFINE OUTPUT CSV FILE WIDGET
  OUTFILE=DIALOG_PICKFILE(TITLE='ENTER OUTPUT FILE NAME')
  ; CHECK WHETHER THE OUTPUT FILE NAME AND PATH IS VALID
  IF OUTFILE EQ '' THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED OUTPUT FILE NAME IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ; CREATE THE FILE 
  OPENW, OUTLUN_CSV, OUTFILE, /GET_LUN
  ;---------------------------------------------------------------------
  ; WRITE THE COLUMN HEADER                                    **DEFINE**
  FHEAD=["DATEID","DATE","BANDNAME","SITEID_94120","SITEID_94150","SITEID_94170","SITEID_94203", $
    "SITEID_94294","SITEID_94299","SITEID_94302","SITEID_94312","SITEID_94326", $
    "SITEID_94332","SITEID_94374","SITEID_94403","SITEID_94430","SITEID_94461", $
    "SITEID_94510","SITEID_94578","SITEID_94610","SITEID_94637","SITEID_94638", $
    "SITEID_94647","SITEID_94659","SITEID_94672","SITEID_94711","SITEID_94767", $
    "SITEID_94776","SITEID_94802","SITEID_94821","SITEID_94866","SITEID_94910", $
    "SITEID_94975","SITEID_95527"]
  PRINTF, FORMAT='(10000(A,:,","))', OUTLUN_CSV, '"' + FHEAD + '"'
  ; CLOSE THE FILE
  FREE_LUN, OUTLUN_CSV
  ;-----------------------------------------------------------------
  ; DEFINE THE INPUT IMAGE DATA (SINGLE BAND OR MULTIBAND IMAGE)
  ENVI_SELECT, TITLE='SELECT INPUT IMAGE DATA', FID=FID, POS=POS
  ; CHECK WHETHER THE INPUT IMAGE DATA NAME AND PATH IS VALID
  IF (FID EQ -1) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED IMAGE DATA IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ENVI_FILE_QUERY, FID, BNAME=BNAME, SNAME=SNAME, NB=NB, DATA_TYPE=DATA_TYPE
  ; COUNT THE NUMBER OF BANDS IN THE INPUT FILE
  BCOUNT = WHERE(BNAME, COUNT)
  ;
  ;CHECK IF THERE IS 1 OR MORE ROI ASSOCIATED WITH THE INPUT IMAGE DATA
  ROI_IDS = ENVI_GET_ROI_IDS(FID=FID, ROI_NAME=ROI_NAME, /SHORT_NAME)
  IF (ROI_IDS[0] EQ -1) THEN BEGIN
    PRINT,''
    PRINT, 'THERE IS NO ROI ASSOCIATED WITH THE SELECTED INPUT IMAGE'
    PRINT,''
    RETURN
  ENDIF
  ;-----------------------------------------------------------------
  ; SELECT ONE OR MORE ROI
  BASE = WIDGET_AUTO_BASE(TITLE='SELECT ONE OR MORE ROI')
  WM   = WIDGET_MULTI(BASE, LIST=ROI_NAME, UVALUE='LIST', /AUTO)
  RESULT = AUTO_WID_MNG(BASE)
  ;
  ; ERROR CHECK - AT LEAST ONE VALID ROI IS NEEDED TO PROCEED
  IF (RESULT.ACCEPT EQ 0) THEN RETURN
  ; COUNT THE NUMBER OF BANDS ASSOCIATED WITH THE ROI LIST
  PTR = WHERE(RESULT.LIST EQ 1, COUNT)
  ROIBAND_MATCH_COUNT = COUNT
  ;-----------------------------------------------------------------
  ; MAKE ARRAY 'MATRIX_F' [31,112]
  MATRIX_F = MAKE_ARRAY(ROIBAND_MATCH_COUNT, N_ELEMENTS(POS), /FLOAT)
  ;-----------------------------------------------------------------
  ; LOOP THROUGH EACH ROI
  FOR i=0, ROIBAND_MATCH_COUNT-1 DO BEGIN ; START 'FOR i'
    ;---------------------------------------------------------------
    ;INITIALISE THE VARIABLE TEMP_DATA TO HOLD THE ROI-BASED DATA
    DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, POS=[0])
    ; WHERE POS IN THE NUMBER OF BANDS AND DATA IS THE NUMBER OF ROI ELEMENTS IN THE ROI
    TEMP_DATA = DBLARR(N_ELEMENTS(POS),N_ELEMENTS(DATA))
    ;---------------------------------------------------------------
    ; MAKE ARRAY TO HOLD THE ROI VALUE DATA - PRINT ARRAY (ROW) AFTER EACH BAND LOOP
    MATRIX = MAKE_ARRAY(1, N_ELEMENTS(POS), /FLOAT)
    ; MAKE ARRAY TO HOLD BANDNAME AND DATE
    MATRIX_BAND = MAKE_ARRAY(2, N_ELEMENTS(POS), /STRING)
    ; MAKE ARRAY DATEID
    DATEID = MAKE_ARRAY(1, N_ELEMENTS(POS), /INTEGER)
    ; LOOP THROUGH EACH BAND
    FOR j=0, N_ELEMENTS(POS)-1 DO BEGIN ; START 'FOR j'
      BANDCOUNT = N_ELEMENTS(POS)
      DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, POS=POS[j])
      TEMP_DATA[j,*] = DATA
      ;-------------------------------------------------------------
      ; GET ROI NAME
      RESULT = ENVI_GET_ROI(ROI_IDS[PTR[i]], ROI_NAME=ROI_NAME)
      ; EXTRACT ROI_NAME_SHORT FROM ROI_NAME               **DEFINE**
      ROI_NAMESHORT = STRMID(ROI_NAME, 12, 12)
      ;-------------------------------------------------------------
      ; CALCULATE & WRITE   
      ; CHECK IF THE DATA TYPE IS FLOAT
      IF DATA_TYPE LT 4 OR DATA_TYPE GT 5 THEN BEGIN
        ; CONVERT TEMP_DATA ARRAY TO FLOAT
        TEMP_DATA = FLOAT(TEMP_DATA)
      ENDIF
      PRINT, '  CALCULATE THE MEAN VALUE AT THE ROI LOCATION'
      ; SET NODATA VALUES TO NaN IN TEMP_DATA ARRAY        **DEFINE**
      k = WHERE(TEMP_DATA EQ -999.000, COUNT)
      IF (COUNT GT 0) THEN TEMP_DATA[k] = !VALUES.F_NAN
      ; GET MEAN VALUE (SEE VERSION 1)******************************
      ; OUTMEAN = MEAN(TEMP_DATA[j,*], /NAN)
      ; GET THE INTERSECT VALUE
      VALUE = TEMP_DATA[j,*]
      ;-------------------------------------------------------------
      ; GET DATE AND BAND NAME
      BAND_NAME = BNAME[j]
      ; MANIPULATE BAND NAME TO GET DATE                   **DEFINE**
      IF (j LE 8) THEN BEGIN
        YYY = STRMID(BAND_NAME, 23, 4)
        MMM = STRMID(BAND_NAME, 28, 2)
        DDD = 01
        DM = JULDAY(MMM, DDD, YYY)
      ENDIF 
      IF ((j GT 8) AND (j LE 98)) THEN BEGIN
        YYY = STRMID(BAND_NAME, 24, 4)
        MMM = STRMID(BAND_NAME, 29, 2)
        DDD = 01
        DM = JULDAY(MMM, DDD, YYY)
      ENDIF
      IF (j GT 98) THEN BEGIN
        YYY = STRMID(BAND_NAME, 25, 4)
        MMM = STRMID(BAND_NAME, 30, 2)
        DDD = 01
        DM = JULDAY(MMM, DDD, YYY)
      ENDIF 
      ; AS CALANDER DATE                                   **DEFINE**
      DATE = STRTRIM(DM, 2)
      CALDAT, DATE, Month, Day, Year
      IF Month EQ 1 THEN Month1 = 'jan'
      IF Month EQ 2 THEN Month1 = 'feb'
      IF Month EQ 3 THEN Month1 = 'mar
      IF Month EQ 4 THEN Month1 = 'apr
      IF Month EQ 5 THEN Month1 = 'may'
      IF Month EQ 6 THEN Month1 = 'jun'
      IF Month EQ 7 THEN Month1 = 'jul'
      IF Month EQ 8 THEN Month1 = 'aug'
      IF Month EQ 9 THEN Month1 = 'sep'
      IF Month EQ 10 THEN Month1 = 'oct'
      IF Month EQ 11 THEN Month1 = 'nov'
      IF Month EQ 12 THEN Month1 = 'dec' 
      OUTDATE = Month1 + ' ' + STRING(STRTRIM(Year, 2))
      ; EXTRACT BAND_NAME_SHORT FROM BAND_NAME             **DEFINE** 
      IF (j LE 8) THEN BEGIN
        BAND_NAMESHORT = STRMID(BAND_NAME, 15, 24)
      ENDIF
      IF ((j GT 8) AND (j LE 98)) THEN BEGIN
        BAND_NAMESHORT = STRMID(BAND_NAME, 16, 24)
      ENDIF
      IF (j GT 98) THEN BEGIN
        BAND_NAMESHORT = STRMID(BAND_NAME, 17, 24)
      ENDIF
      PRINT, ''
      PRINT, '  DATE: ', OUTDATE, '  ROI: ', ROI_NAMESHORT
      ;-------------------------------------------------------------
      ; FILL ARRAY 'MATRIX', 'MATRIX_BAND' AND 'DATEID'
      MATRIX[0,j] = VALUE
      MATRIX_BAND[0,j] = OUTDATE
      MATRIX_BAND[1,j] = BAND_NAMESHORT
      DATEID[0,j] = j+1
      ;-------------------------------------------------------------
    ENDFOR ; END 'FOR j' BAND
    ;---------------------------------------------------------------
    ; SET OUTMEDIAN NaN TO -9999.00                        **DEFINE**
    l= WHERE(FINITE(MATRIX, /NAN), COUNT)
    IF (COUNT GT 0) THEN MATRIX[l] = -9999.00
    ;---------------------------------------------------------------
    ; FILL ARRAY 'MATRIX_F'
    MATRIX_F[i,*] = MATRIX
    ;---------------------------------------------------------------
  ENDFOR ; END 'FOR i' ROI
  ;-----------------------------------------------------------------
  ; WRITE THE DATA TO THE OUTPUT CSV FILE
  ; OPEN OUTPUT FILE
  OPENU, OUTLUN_CSV, OUTFILE, /APPEND, /GET_LUN
  FOR m=0, BANDCOUNT-1 DO BEGIN ; START 'FOR m'
    ; WRITE                                                **DEFINE**
    PRINTF, FORMAT='(10000(A,:,","))', OUTLUN_CSV, DATEID[m], '"' + MATRIX_BAND[0,m] + '"', $
      '"' + MATRIX_BAND[1,m] + '"', MATRIX_F[0,m], MATRIX_F[1,m], MATRIX_F[2,m], MATRIX_F[3,m], $
      MATRIX_F[4,m], MATRIX_F[5,m], MATRIX_F[6,m], MATRIX_F[7,m], MATRIX_F[8,m], MATRIX_F[9,m], $
      MATRIX_F[10,m], MATRIX_F[11,m], MATRIX_F[12,m], MATRIX_F[13,m], MATRIX_F[14,m], MATRIX_F[15,m], $      
      MATRIX_F[16,m], MATRIX_F[17,m], MATRIX_F[18,m], MATRIX_F[19,m], MATRIX_F[20,m], MATRIX_F[21,m], $    
      MATRIX_F[22,m], MATRIX_F[23,m], MATRIX_F[24,m], MATRIX_F[25,m], MATRIX_F[26,m], MATRIX_F[27,m], $
      MATRIX_F[28,m], MATRIX_F[29,m], MATRIX_F[30,m]
  ENDFOR ; END 'FOR m' ROI  
  ; CLOSE OUTPUT FILE
  FREE_LUN, OUTLUN_CSV
  ;-----------------------------------------------------------------
  PRINT,''
  ; PRINT THE PROCESSING TIME
  MINUTES = (SYSTIME(1)-F_DATE)/60
  PRINT, MINUTES,'  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: RADIOSONDE_ET_TIMESERIES_EXTRACT_INTERSECT'
  PRINT,'' 
END  