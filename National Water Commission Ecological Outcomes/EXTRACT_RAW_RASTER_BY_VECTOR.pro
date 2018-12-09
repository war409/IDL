; ######################################################################
; NAME: EXTRACT_RAW_RASTER_BY_VECTOR.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren 
; DATE: 30/09/2009
; DLM: 02/10/2009
; DESCRIPTION: This tool extracts raster cell data where the user-
;              selected polygon or point vector intersect the 
;              input raster image.
; INPUT: Single or multi-band raster; polygon or point feature class
; OUTPUT: Text or CSV file (inc. file extension in output file name)
; SET PARAMETERS: WIDGET Based input; DEFINE OUTPUT CSV FILE, DEFINE 
;                 INPUT IMAGE DATA; DEFINE ROI
; NOTES: A polygon or point vector must be opened in ENVI and associated
;        with the input raster data as a ROI. When extracting data at 
;        multiple polygon ROI please open each polygon as individual 
;        ROIs.
; ######################################################################
;
PRO EXTRACT_RAW_RASTER_BY_VECTOR
  PRINT,''
  PRINT,'BEGIN PROCESSING: EXTRACT_RAW_RASTER_BY_VECTOR'
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
  ENVI_FILE_QUERY, FID, BNAME=BNAME, SNAME=SNAME, NB=NB, DATA_TYPE=DATA_TYPE, NS=NS
  ; SET FILE COLUMN HEADER
  BNAME2 = "CELLVALUE:" + BNAME
  FNAME=["ID","CELLX","CELLY","ROI",BNAME2]
  PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, '"' + FNAME + '"'
  ; COUNT THE NUMBER OF BANDS IN THE INPUT FILE
  BCOUNT = WHERE(BNAME, COUNT)
  ;
  ; CHECK IF THE INPUT ROIs ARE ASSOCIATED WITH THE INPUT IMAGE DATA
  ROI_IDS = ENVI_GET_ROI_IDS(FID=FID, ROI_NAME=ROI_NAME, /SHORT_NAME)
  ; IF INPUT ROI IS NOT VALID PRINT... 
  IF (ROI_IDS[0] EQ -1) THEN BEGIN
  PRINT,''
  PRINT, 'There Is No Vector (ROI) Associated With The Selected Input Image'
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
  ; ROI DATA EXTRACTION: ROI LOOP
  FOR i=0, COUNT-1 DO BEGIN
    ;
    ; CREATE VARIABLE TEMP_DATA TO HOLD ROI-BASED DATA
    DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, $
      POS=[0])
    TEMP_DATA = DBLARR(N_ELEMENTS(POS),N_ELEMENTS(DATA))
    ;
    ; EXTRACT THE DATA AT EACH CELL IN THE ROI
    FOR j=0, N_ELEMENTS(POS)-1 DO BEGIN
      DATA = ENVI_GET_ROI_DATA(ROI_IDS[PTR[i]], FID=FID, ADDR=ADDR, $
        POS=POS[j])
      TEMP_DATA[j,*] = DATA
      ; GET ROI NAME
      RESULT = ENVI_GET_ROI(ROI_IDS[PTR[i]], ROI_NAME=ROI_NAME)
      ; GET MAP COORDINATES FOR ROI POSITION
      XF = (ADDR MOD NS) + 1
      XY  = (ADDR/NS) + 1
      ENVI_CONVERT_FILE_COORDINATES, FID, XF, XY, XMAP, YMAP, /TO_MAP
      ;
    ENDFOR
    ;
    ; PRINT THE ROI DATA TO THE OUTPUT CSV FILE
    PRINT, '  WRITE ROI CELL DATA'
    ; WRITE DATA TO OUTPUT
    FOR  k=0, N_ELEMENTS(TEMP_DATA[0,*])-1 DO BEGIN
      PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, k+1, XMAP[k],YMAP[k], '"' + ROI_NAME + '"', TEMP_DATA[*,k]
    ENDFOR
    ;
    ; LOOP BACK TO THE NEXT ROI IN THE LIST
  ENDFOR
  ;
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUTLUN
  PRINT,''
  PRINT,'FINISHED PROCESSING: EXTRACT_RAW_RASTER_BY_VECTOR'
  PRINT,''
END