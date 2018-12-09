; ######################################################################
; NAME: OWL_TIME_SERIES_SUMMARY_BY_VECTOR_SLIM_VERSION.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren
; DATE: 18/11/2009
; DLM: 25/03/2010
; 
; DESCRIPTION: This tool extracts a summary (mean, median, stddev, min 
;              & max) of the input cell data where the user-selected 
;              vector (ROI) intersect the input raster image.
;              The OWL version contains additional output fields;
;              the proportion of pixels that meet set OWL thresholds.
;              For example, 'PRCNT_GT_10' is the percentage of pixels
;              within the ROI that have an OWL value of greater than 10.
;              Note that NoData (cloud) pixels are excluded from the 
;              calculation.
;              
; INPUT: ENVI meta file; polygon or point feature class.
; 
; OUTPUT: Comma-seperated text or CSV file.
; 
; SET PARAMETERS: Set via widgets.
; 
; NOTES: TA polygon or point vector must be opened in ENVI and associated
;        with the input raster data as a ROI. When extracting data at 
;        multiple polygon ROI please open each polygon as individual 
;        ROIs. * FIX TO REMOVE '% OF ALL' BUG
;        
; ######################################################################
;
PRO OWL_TIME_SERIES_SUMMARY_BY_VECTOR_SLIM_VERSION
  ; GET START TIME FOR WHOLE
  F_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: OWL_TIME_SERIES_SUMMARY_BY_VECTORS_SLIM_VERSION'
  PRINT,''
  ;---------------------------------------------------------------------
  ; SELECT OUTPUT SUMMARY FILE
  OUTFILE=DIALOG_PICKFILE(TITLE='ENTER OUTPUT FILE NAME AND EXTENSION')
  ; ERROR CHECK
  IF OUTFILE EQ '' THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED OUTPUT IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ; WRITE THE EMPTY OUTPUT FILE
  OPENW, OUTLUN, OUTFILE, /GET_LUN
  ; WRITE FILE HEADER
  FNAME=["RASTERID","BAND","DATE","YEAR","DOY","ROI","MEAN","STDDEV","MEDIAN","MIN","MAX","NO_PIXELS","NO_255","NO_NOT_255", $
    "PROP_GE_50","PROP_255"]
  ; WRITE
  PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, '"' + FNAME + '"'
  ;---------------------------------------------------------------------
  ; SELECT INPUT IMAGE DATA (SINGLE OR MULTIBAND)
  ENVI_SELECT, TITLE='SELECT INPUT IMAGE DATA', FID=FID, POS=POS
  ; ERROR CHECK
  IF (FID EQ -1) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED IMAGE FILE IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ; QUERY FILE
  ENVI_FILE_QUERY, FID, BNAME=BNAME, SNAME=SNAME, NB=NB, DATA_TYPE=DATA_TYPE
  ; COUNT THE NUMBER OF BANDS IN THE INPUT FILE
  BCOUNT = WHERE(BNAME, COUNT)
  ;---------------------------------------------------------------------
  ; GET ROI ASSOCIATED WITH THE INPUT IMAGE
  ROI_IDS = ENVI_GET_ROI_IDS(FID=FID, ROI_NAME=ROI_NAME, /SHORT_NAME)
  ; ERROR CHECK
  IF (ROI_IDS[0] EQ -1) THEN BEGIN
    PRINT,''
    PRINT, 'NO ROI ASSOCIATED WITH THE INPUT IMAGE'
    PRINT,''
    RETURN
  ENDIF
  ;---------------------------------------------------------------------
  ; SELECT ROI
  ; ROI SELECTION WIDGET
  BASE = WIDGET_AUTO_BASE(TITLE='SELECT ONE OR MORE ROI')
  WM   = WIDGET_MULTI(BASE, LIST=ROI_NAME, UVALUE='LIST', /AUTO)
  RESULT = AUTO_WID_MNG(BASE)
  ; ERROR CHECK
  IF (RESULT.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED ROI IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ; ASSIGN RESULTS TO POINTER
  PTR = WHERE(RESULT.LIST EQ 1, COUNT)
  RCOUNT = COUNT
  ;---------------------------------------------------------------------
  ; ROI LOOP
  FOR i=0, RCOUNT-1 DO BEGIN ; FOR 'i' START
    ; GET DATA AT ROI[i]
    DATA1 = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, POS=[0])
    ; CREATE VARIABLE 'TEMP_DATA'
    TEMP_DATA = DBLARR(N_ELEMENTS(POS),N_ELEMENTS(DATA1))
    ; GET ROI NAME
    RESULT2 = ENVI_GET_ROI(ROI_IDS[PTR[i]], ROI_NAME=ROI_NAME)
    ;-------------------------------------------------------------------
    ; BAND LOOP
    FOR j=0, N_ELEMENTS(POS)-1 DO BEGIN ; FOR 'j' START
      PRINT, 'ROI: ', STRTRIM((i+1), 2), ' OF ', STRTRIM(RCOUNT, 2), ' BAND: ', STRTRIM((j+1), 2), $
        ' OF ', STRTRIM(N_ELEMENTS(POS), 2)
      ; GET DATA AT ROI[i] FOR BAND[j]
      DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, POS=POS[j])
      ; FILL ARRAY WITH DATA
      TEMP_DATA[j,*] = DATA
      ;-----------------------------------------------------------------
      ; GET CURRENT BAND NAME
      BNAME2 = BNAME[j]
      ; GET ROI NAME START POS
      RNAME_START = STRPOS(ROI_NAME, '=', /REVERSE_SEARCH)+1
      ; GET ROI NAME LENGTH
      RNAME_LENGTH = (STRLEN(ROI_NAME)-RNAME_START)-1  
      ROINAME = STRMID(ROI_NAME, RNAME_START, RNAME_LENGTH)
      
      IF (j+1) LT 10 THEN BANDNAME = STRMID(BNAME2, 15, 32)
      IF (((j+1) GE 10) AND ((j+1) LT 100)) THEN BANDNAME = STRMID(BNAME2, 16, 32)
      IF (j+1) GE 100 THEN BANDNAME = STRMID(BNAME2, 17, 32)
      ;-----------------------------------------------------------------
      ; MANIPULATE BANDNAME TO GET DATE                       **DEFINE**
      YYY = STRMID(BANDNAME, 8, 4)
      DOY = STRMID(BANDNAME, 13, 3)
      ; AS CALANDER DATE
      CALDAT, JULDAY(1, DOY, YYY), MONTH, DAY, YEAR
      IF DAY LE 9 THEN DAY = '0' + STRING(STRTRIM(DAY,2)) ELSE DAY = STRING(STRTRIM(DAY,2))
      IF MONTH LE 9 THEN MONTH = '0' + STRING(STRTRIM(MONTH,2)) ELSE MONTH = STRING(STRTRIM(MONTH,2))
      OUTDATE = DAY + '/' + MONTH + '/' + STRING(STRTRIM(YEAR,2))
      ; GET YEAR AND DOY
      YEARP = YYY
      DOYP = DOY
      ;-----------------------------------------------------------------
      ; DATA TYPE CHECK
      IF DATA_TYPE LT 4 OR DATA_TYPE GT 5 THEN BEGIN
        ; CONVERT TEMP_DATA TO FLOAT
        TEMP_DATA[j,*] = FLOAT(TEMP_DATA[j,*])
      ENDIF
      ;-----------------------------------------------------------------
      ; GET PIXEL COUNTS
      ; CLEAR OLD
      GE_50 = 0.00
      EQ_255 = 0.00
      COUNT_TOTAL = 0.00
      COUNT_255 = 0.00
      COUNT_VALID = 0.00
      NEWDATA = 0.00
      k = 0.00
      ; COUNT THE NUMBER OF ELEMENTS (PIXELS) IN ROI[i] BAND[j]
      COUNT_TOTAL = N_ELEMENTS(TEMP_DATA[j,*])*1.0
      ; COUNT THE NUMBER OF NODATA PIXELS IN ROI[i] BAND[j]
      COUNT_255 = TOTAL(TEMP_DATA[j,*] EQ 255.00)*1.0
      ; COUNT THE NUMBER OF VALID (NOT NODATA) PIXELS IN ROI[i] BAND[j]
      COUNT_VALID = TOTAL(TEMP_DATA[j,*] NE 255.00)*1.0
	    ; GET PROPORTIONS:
      EQ_255 = COUNT_255 / COUNT_TOTAL
      ;-----------------------------------------------------------------
      ; RENAME
      NEWDATA = TEMP_DATA[j,*]
      ; GET PROPORTIONS:
      GE_50 = TOTAL((NEWDATA GE 50.00) AND (NEWDATA NE 255.00)) / COUNT_TOTAL
      IF COUNT_VALID EQ 0.00 THEN GE_50 = 'NAN'
      ;-----------------------------------------------------------------
      ; SET NODATA PIXELS TO NaN IN TEMP_DATA ARRAY
      k = WHERE(NEWDATA EQ 255.000, COUNT)
      IF (COUNT GT 0) THEN NEWDATA[k] = !VALUES.F_NAN
      ; GET SUMMARY STATISTICS
      ; GET MIN AND MAX
      OUTMIN = MIN(NEWDATA, DIMENSION=0, MAX=OUTMAX, /NAN)
      ; RECLASSIFY RESULT RANGE: MODIS NDVI & mNDWI
      OUTMIN = DOUBLE(OUTMIN)
      OUTMAX = DOUBLE(OUTMAX)
      ; GET MEAN
      OUTMEAN = MEAN(NEWDATA, /NAN)
      ; RECLASSIFY RESULT RANGE: MODIS NDVI & mNDWI
      OUTMEAN = DOUBLE(OUTMEAN)
      ; GET STDDEV: WHEN THERE ARE LESS THAN TWO 'REAL' NUMBERS IN THE ARRAY PRINT 'NaN'
      IF (N_ELEMENTS(WHERE(FINITE(NEWDATA))) LT 2) THEN BEGIN
        OUTSTDDEV = 'NaN'
      ENDIF ELSE BEGIN
        OUTSTDDEV = STDDEV(NEWDATA, /NAN)
        ; RECLASSIFY RESULT RANGE: MODIS NDVI & mNDWI
        OUTSTDDEV = DOUBLE(OUTSTDDEV)
      ENDELSE
      ; GET MEDIAN
      OUTMEDIAN = MEDIAN(NEWDATA, DIMENSION=0, /EVEN)
      ; RECLASSIFY RESULT RANGE: MODIS NDVI & mNDWI
      OUTMEDIAN = DOUBLE(OUTMEDIAN)
      ;-----------------------------------------------------------------
      ; WRITE RESULTS TO OUTPUT
      PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, j, '"'+ BANDNAME +'"', OUTDATE, YEARP, DOYP, '"'+ ROINAME +'"', $
        OUTMEAN, OUTSTDDEV, OUTMEDIAN, OUTMIN, OUTMAX, COUNT_TOTAL, COUNT_255, COUNT_VALID, GE_50, EQ_255
      ;-----------------------------------------------------------------
    ENDFOR ; FOR 'j' END
  ENDFOR ; FOR 'i' END
  ;---------------------------------------------------------------------
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUTLUN
  PRINT,''
  ; PRINT THE PROCESSING TIME
  MINUTES = (SYSTIME(1)-F_TIME)/60
  PRINT, MINUTES,'  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: OWL_TIME_SERIES_SUMMARY_BY_VECTOR_SLIM_VERSION'
  PRINT,''
END