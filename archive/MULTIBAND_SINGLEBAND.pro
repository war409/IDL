; ######################################################################
; NAME: MULTIBAND_SINGLEBAND.pro
; LANGUAGE: ENVI IDL
; AUTHOR: Garth Warren
; DATE: 04/01/2010
; DLM: 04/01/2010
; DESCRIPTION: This tool converts input multi-band image data to multiple 
;              single-band files, and vice-versa.
; INPUT: One or more single-band or multi-band image files. 
; OUTPUT: One new single-band image per multi-band image band OR one new
;         multi-band image per multiple single-band selection.
; SET PARAMETERS: Via widgets.
; NOTES:
; ######################################################################
; 
PRO MULTIBAND_SINGLEBAND
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: MULTIBAND_SINGLEBAND'
  ;---------------------------------------------------------------------
  ; SELECT CONVERSION TYPE: RADIO-BUTTON WIDGET
  VALUES1 = ['Multi-Band To Single-Band', 'Single-Band To Multi-Band']  
  BASE1 = WIDGET_BASE(TITLE='IDL', /ROW)  
  BGROUP1 = CW_BGROUP(BASE1, VALUES1, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', $
    LABEL_TOP='SELECT CONVERSION TYPE')
  WIDGET_CONTROL, BASE1, /REALIZE
  EV1 = WIDGET_EVENT(BASE1)
  CONTYPE = EV1.VALUE
  WIDGET_CONTROL, BASE1, /DESTROY
  ;---------------------------------------------------------------------
  IF CONTYPE EQ 0 THEN BEGIN
    ;-------------------------------------------------------------------
    ; SELECT INPUT TYPE: RADIO-BUTTON WIDGET
    VALUES2 = ['One File', 'More Than One File']
    BASE2 = WIDGET_BASE(TITLE='IDL', /ROW)  
    BGROUP2 = CW_BGROUP(BASE2, VALUES2, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', $
      LABEL_TOP='SELECT INPUT TYPE')
    WIDGET_CONTROL, BASE2, /REALIZE
    EV2 = WIDGET_EVENT(BASE2)
    INTYPE = EV2.VALUE
    WIDGET_CONTROL, BASE2, /DESTROY
    ;-------------------------------------------------------------------
    ; RETURNS PATH/S:
    ;-------------------------------------------------------------------
    IF INTYPE EQ 0 THEN BEGIN
      INPUT = DIALOG_PICKFILE(/MUST_EXIST, /OVERWRITE_PROMPT, PATH='C:\', $
        TITLE='SELECT INPUT FILE')
    ENDIF
    ;-------------------------------------------------------------------
    IF INTYPE EQ 1 THEN BEGIN
      INPUT = DIALOG_PICKFILE(/MULTIPLE_FILES, /MUST_EXIST, /OVERWRITE_PROMPT, $
        PATH='C:\Workspace\GoogleEarthEngine\extract\', TITLE='SELECT INPUT FILES')
    ENDIF
    ;-------------------------------------------------------------------
    ; INPUT FILE LOOP:
    ;-------------------------------------------------------------------
    ; GET FILE COUNT
    RCOUNT = N_ELEMENTS(INPUT)
    ;-------------------------------------------------------------------
    FOR i=0, RCOUNT-1 DO BEGIN ; START 'FOR i'
      ;-----------------------------------------------------------------
      ; GET START TIME: LOOP
      L_TIME = SYSTIME(1)
      ;-----------------------------------------------------------------
      ; GET INPUT FILENAME FULL
      INFILE = INPUT[i]
      ;-----------------------------------------------------------------
      ; GET FILENAME FROM FULL NAME & PATH
      START = STRPOS(INFILE, '\', /REVERSE_SEARCH)+1
      LENGTH = (STRLEN(INFILE)-START)-4
      FNAME = STRMID(INFILE, START, LENGTH)
      INPATH = STRMID(INFILE, 0, START)
      ;-----------------------------------------------------------------
      ; OPEN FILE
      ENVI_OPEN_FILE, INFILE, /NO_REALIZE, R_FID=FID 
      ;-----------------------------------------------------------------
      ; QUERY FILE
      ENVI_FILE_QUERY, FID, SNAME=SNAME, DIMS=INDIMS, BNAMES=BNAME, NS=NS, $
        NL=NL, DATA_TYPE=DATATYPE
      ; BAND COUNT
      BCOUNT = N_ELEMENTS(BNAME)
      ;-----------------------------------------------------------------
      ; INPUT FILE BAND LOOP:
      ;-----------------------------------------------------------------
      FOR j=0, BCOUNT-1 DO BEGIN ; START 'FOR j'
        ;--------------------------------------------------------------- 
        ; SAVE BAND TO OUTPUT:
        ;--------------------------------------------------------------- 
        ; GET BAND NAME
        BANDNAME = BNAME[j]
        ;--------------------------------------------------------------- 
        ; BUILD OUTNAME
        OUTNAME = INPATH + BANDNAME + '.img'
        ;---------------------------------------------------------------
        ; WRITE DATA
        ENVI_DOIT, 'CF_DOIT', FID=FID, DIMS=INDIMS, POS=[j], OUT_DT=DATATYPE, $
          OUT_NAME=OUTNAME, R_FID=RFID, OUT_BNAME=BANDNAME, /NO_REALIZE
        ;---------------------------------------------------------------
      ENDFOR ; END 'FOR j' 
      ;-----------------------------------------------------------------
      ; PRINT LOOP TIME
      SECONDS = (SYSTIME(1)-L_TIME)
      PRINT, ''
      PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2),'  SECONDS, FOR FILE: ', INFILE
      ;-----------------------------------------------------------------   
    ENDFOR ; END 'FOR i'
    ;-------------------------------------------------------------------
  ENDIF ELSE BEGIN
    ;-------------------------------------------------------------------
    ; SELECT INPUT FILES
    INPUT = DIALOG_PICKFILE(/MULTIPLE_FILES, /MUST_EXIST, /OVERWRITE_PROMPT, $
      PATH='C:\', TITLE='SELECT INPUT FILES')
    ;-------------------------------------------------------------------
    ; DEFINE OUTPUT FILE
    OUTPUT = DIALOG_PICKFILE(/OVERWRITE_PROMPT, PATH='C:\', TITLE='DEFINE OUTPUT FILE')
    ;-------------------------------------------------------------------
    ; INPUT FILE LOOP:
    ;-------------------------------------------------------------------
    ; GET FILE COUNT
    RCOUNT = N_ELEMENTS(INPUT)
    ;-------------------------------------------------------------------
    ; CREATE FID ARRAY
    FIDARR = LONARR(RCOUNT)
    ; CREATE BAND NAME ARRAY
    BNAMEARR = STRARR(RCOUNT)
    ; CREATE POS ARRAY
    POSARR = LONARR(RCOUNT)
    ;-------------------------------------------------------------------
    FOR i=0, RCOUNT-1 DO BEGIN ; START 'FOR i'
      ;-----------------------------------------------------------------
      ; GET INPUT FILENAME FULL
      INFILE = INPUT[i]
      ;-----------------------------------------------------------------
      ; OPEN FILE
      ENVI_OPEN_FILE, INFILE, /NO_REALIZE, R_FID=FID
      ;-----------------------------------------------------------------
      ENVI_FILE_QUERY, FID, SNAME=SNAME, DIMS=INDIMS, BNAMES=BNAME, NS=NS, $
        NL=NL, DATA_TYPE=DATATYPE
      ;----------------------------------------------------------------
      ; FILL ARRAYS
      FIDARR[i] = FID
      BNAMEARR[i] = BNAME
      POSARR[i] = 0
      ;-----------------------------------------------------------------
    ENDFOR ; END 'FOR i'
    ;-------------------------------------------------------------------
    ; WRITE DATA
    ENVI_DOIT, 'CF_DOIT', FID=FIDARR, DIMS=INDIMS, POS=POSARR, OUT_DT=DATATYPE, $
      OUT_NAME=OUTPUT, R_FID=RFID, OUT_BNAME=BNAMEARR, /NO_REALIZE
    ;-------------------------------------------------------------------
  ENDELSE
  ;---------------------------------------------------------------------
  PRINT,''
  ; PRINT THE TOTAL PROCESSING TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), '  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: MULTIBAND_SINGLEBAND'
  PRINT,'' 
END 