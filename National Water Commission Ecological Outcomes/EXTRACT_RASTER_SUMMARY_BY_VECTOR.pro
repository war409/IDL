; ######################################################################
; NAME: EXTRACT_RASTER_SUMMARY_BY_VECTOR.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren 
; DATE: 30/09/2009
; DLM: 08/10/2009
; DESCRIPTION: This tool extracts a summary (mean, median, stddev, min 
;              & max) of the input cell data where the user-selected 
;              vector (ROI) intersect the input raster image.
; INPUT: Single or multi-band raster; polygon or point feature class
; OUTPUT: Text or CSV file (inc. file extension in output file name)
; SET PARAMETERS: WIDGET Based input; DEFINE OUTPUT CSV FILE, DEFINE 
;                 INPUT IMAGE DATA; DEFINE ROI. OTHER input; SET NODATA  
;                 VALUES TO NaN (set NoData Value)
; NOTES: A polygon or point vector must be opened in ENVI and associated
;        with the input raster data as a ROI. When extracting data at 
;        multiple polygon ROI please open each polygon as individual 
;        ROIs.
; ######################################################################
;
PRO EXTRACT_RASTER_SUMMARY_BY_VECTOR
  PRINT,''
  PRINT,'BEGIN PROCESSING: EXTRACT_RASTER_SUMMARY_BY_VECTOR'
  PRINT,'' 
  ;
  PRINT, '  DEFINE OUTPUT CSV FILE'
  ; DEFINE OUTPUT CSV FILE
  OUTFILE=DIALOG_PICKFILE(TITLE='Enter Output File Name')
  ; CHECK WHETHER THE OUTPUT FILE NAME AND PATH IS VALID
  IF OUTFILE EQ '' THEN BEGIN
  PRINT,''
  PRINT, 'The Selected Output File Name Is Not Valid'
  PRINT,''
  RETURN
  ENDIF
  ; CREATE THE EMPTY OUTPUT FILE
  OPENW, OUTLUN, OUTFILE, /GET_LUN
  ;
  PRINT, '  DEFINE INPUT IMAGE DATA'
  ; DEFINE INPUT IMAGE DATA (SINGLE OR MULTIBAND)
  ENVI_SELECT, TITLE='Select Input Image Data', FID=FID, POS=POS
  ; CHECK WHETHER THE INPUT IMAGE DATA NAME AND PATH IS VALID
  IF (FID EQ -1) THEN BEGIN
  PRINT,''
  PRINT, 'The Selected Image File Is Not Valid'
  PRINT,''
  RETURN
  ENDIF
  ENVI_FILE_QUERY, FID, BNAME=BNAME, SNAME=SNAME, NB=NB, DATA_TYPE=DATA_TYPE
  ; SET FILE COLUMN HEADER
  FNAME=["RASTERID","FILE&BAND","ROI","MEAN","STDDEV","MEDIAN","MIN","MAX"]
  PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, '"' + FNAME + '"'
  ; COUNT THE NUMBER OF BANDS IN THE INPUT FILE
  BCOUNT = WHERE(BNAME, COUNT)
  ;
  ;CHECK IF THE INPUT ROIs ARE ASSOCIATED WITH THE INPUT IMAGE DATA
  ROI_IDS = ENVI_GET_ROI_IDS(FID=FID, ROI_NAME=ROI_NAME, /SHORT_NAME)
  ; IF INPUT ROI IS NOT VALID PRINT... 
  IF (ROI_IDS[0] EQ -1) THEN BEGIN
  PRINT,''
  PRINT, 'There Is No ROI Associated With The Selected Input Image'
  PRINT,''
  RETURN
  ENDIF
  ;
  ; WIDGET FOR THE ROI SELECTION
  BASE = WIDGET_AUTO_BASE(TITLE='Select ROI')
  WM   = WIDGET_MULTI(BASE, LIST=ROI_NAME, UVALUE='LIST', /AUTO)
  RESULT = AUTO_WID_MNG(BASE)
  ;
  ; ERROR CHECK
  IF (RESULT.ACCEPT EQ 0) THEN RETURN
  PTR = WHERE(RESULT.LIST EQ 1, COUNT)
  ;
  ; ROI DATA EXTRACTION: BAND LOOP
  FOR i=0, COUNT-1 DO BEGIN
    ;
    ;INITIALISE VARIABLE TEMP_DATA TO HOLD ROI-BASED DATA
    DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, $
      POS=[0])
    TEMP_DATA = DBLARR(N_ELEMENTS(POS),N_ELEMENTS(DATA))
    ;
    ; ROI DATA EXTRACTION: ROI LOOP
    ; EXTRACT THE DATA AT EACH CELL IN THE ROI
    FOR j=0, N_ELEMENTS(POS)-1 DO BEGIN
      DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, $
        POS=POS[j])
      TEMP_DATA[j,*] = DATA
      ; GET ROI NAME
      RESULT = ENVI_GET_ROI(ROI_IDS[PTR[i]], ROI_NAME=ROI_NAME)         
      ;
      ; CALCULATE & WRITE
      ; CHECK DATA TYPE IS FLOAT
      IF DATA_TYPE LT 4 OR DATA_TYPE GT 5 THEN BEGIN
      ; CONVERT TEMP_DATA ARRAY TO FLOAT
      TEMP_DATA = FLOAT(TEMP_DATA)
      ENDIF
      PRINT, '  CALCULATE ROI MEAN, STDDEV, MEDIAN & WRITE'
      ; SET NODATA VALUES TO NaN IN TEMP_DATA ARRAY
      k = WHERE(TEMP_DATA EQ -1000.000, COUNT)
      IF (COUNT GT 0) THEN TEMP_DATA[k] = !VALUES.F_NAN
      ; GET MIN MAX
      OUTMIN = MIN(TEMP_DATA[j,*], DIMENSION=0, MAX=OUTMAX, /NAN)
      ; GET MEAN
      OUTMEAN = MEAN(TEMP_DATA[j,*], /NAN)
      ; GET STDDEV
      ; WHEN THERE ARE LESS THAN TWO 'REAL' NUMBERS IN THE ARRAY PRINT 'NaN'
      IF (N_ELEMENTS(WHERE(FINITE(TEMP_DATA[j,*]))) LT 2) THEN BEGIN
        OUTSTDDEV = 'NaN' 
      ENDIF ELSE BEGIN
        OUTSTDDEV = STDDEV(TEMP_DATA[j,*], /NAN)
      ENDELSE
      ;
      ; GET MEDIAN
      OUTMEDIAN = MEDIAN(TEMP_DATA[j,*], DIMENSION=0, /EVEN)
      ;
      ; WRITE THE ROI SUMMARY DATA TO THE OUTPUT CSV FILE
      ; GET BAND NAME
      NEWBNAME = BNAME[j]
      ; GET BAND & FILE NAME
      IRNAME = SNAME + ':' + BNAME[j]
      PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, j, '"' + NEWBNAME + '"', '"' + ROI_NAME + '"', $
        OUTMIN, OUTMAX, OUTMEAN, OUTSTDDEV, OUTMEDIAN
      ;
      ; LOOP BACK TO THE NEXT ROI IN THE LIST
    ENDFOR
    ;
    ; LOOP BACK TO THE NEXT BAND IN THE LIST
  ENDFOR
  ;
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUTLUN
  ;
  PRINT,''
  PRINT,'FINISHED PROCESSING: EXTRACT_RASTER_SUMMARY_BY_VECTOR'
  PRINT,''
END