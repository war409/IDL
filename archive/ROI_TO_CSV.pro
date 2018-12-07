; ######################################################################
; NAME: ROI_TO_CSV.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren 
; DATE: 18/08/2009
; DLM: 02/10/2009
; DESCRIPTION: Extract raster data at (or within) ROI.
; INPUT: Single or multi-band raster; ROI (point or polygon)
; OUTPUT: CSV Text file 
; SET PARAMETERS:
; NOTES: Load the raster file and ROI in ENVI prior to running the
;        tool. The input vector must be set as a single ROI; Add the
;        extension .csv to the output file; this tool is an early version
;        of EXTRACT_RAW_RASTER_BY_VECTOR (although this tool works I suggest 
;        using EXTRACT_RAW_RASTER_BY_VECTOR - Garth)
; ######################################################################
;
PRO ROI_To_CSV
  ;
  ; DEFINE OUTPUT CSV FILE
  FILENAME=DIALOG_PICKFILE(TITLE='Enter Output File Name')
  IF FILENAME EQ '' THEN RETURN
  OPENW, LUN, FILENAME, /GET_LUN
  ;
  ; DEFINE INPUT IMAGE DATA (SINGLE OR MULTIBAND)
  ;
  ENVI_SELECT, TITLE='Select Input Data', FID=FID, POS=POS
  IF (FID EQ -1) THEN RETURN
  ENVI_FILE_QUERY, FID, BNAME=BNAME, NB=NB
  NEWBNAME=["ID", BNAME]
  PRINTF,FORMAT='(10000(A,:,","))', LUN, NEWBNAME
  ;
  ; CHECK IF THE INPUT ROIs ARE ASSOCIATED WITH THE INPUT IMAGE DATA
  ROI_IDS = ENVI_GET_ROI_IDS(FID=FID, ROI_NAME=ROI_NAME, /SHORT_NAME)
  ; IF INPUT ROI IS NOT VALID PRINT... 
  IF (ROI_IDS[0] EQ -1) THEN BEGIN
  PRINT,''
  PRINT, 'There Is No Vector File Associated With The Selected Input Image'
  PRINT,''
  RETURN
  ENDIF
  ;
  ; COMPOUND WIDGET FOR THE ROI SELECTION
  BASE = WIDGET_AUTO_BASE(TITLE='Select ROI')
  WM   = WIDGET_MULTI(BASE, LIST=ROI_NAME, UVALUE='LIST', /AUTO)
  RESULT = AUTO_WID_MNG(BASE)
  ; ERROR CHECK
  IF (RESULT.ACCEPT EQ 0) THEN RETURN
  PTR = WHERE(RESULT.LIST EQ 1, COUNT)
  ;
  ; EXTRACT DATA AT ROI
  FOR i=0, COUNT-1 DO BEGIN
    ;
    ; CREATE VARIABLE TEMP_DATA TO HOLD ROI-BASED DATA
    DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, $
      POS=[0])
    TEMP_DATA = DBLARR(N_ELEMENTS(POS),N_ELEMENTS(DATA))
    ;
    ; EXTRACT THE DATA AT EACH CELL IN THE ROI
    FOR j=0, N_ELEMENTS(POS)-1 DO BEGIN
      DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, $
        POS=POS[j])
      TEMP_DATA[j,*] = DATA
    ENDFOR
    ;
    ; PRINT THE ROI DATA TO THE OUTPUT CSV FILE
    FOR  k=0, N_ELEMENTS(TEMP_DATA[0,*])-1 DO BEGIN
      PRINTF, FORMAT='(A,:,",",10000(D17.6,:,","))',LUN, k+1, TEMP_DATA[*,k]
    ENDFOR
    ;
    ; LOOP BACK TO THE NEXT ROI IN THE LIST
  ENDFOR
  ;
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUTLUN
  PRINT,''
  PRINT,'FINISHED PROCESSING'
  PRINT,''
END