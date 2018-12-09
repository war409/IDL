; ######################################################################
; NAME: PLUVIOGRAPH_PRECIPITATION_EXTRACT.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren @ CLW
; DATE: 08/01/2010
; DLM: 11/01/2010
; 
; DESCRIPTION: This tool reads-in the raw Pluviograph text files extracts
;              raw hourly rainfall values per date converts to daily rain-
;              fall and writes to an output csv file.
;              
; INPUT:       
; 
; OUTPUT:     
; 
; PARAMETERS:     
;                          
; NOTES:      
; 
; ######################################################################
; 
PRO PLUVIOGRAPH_PRECIPITATION_EXTRACT
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: PLUVIOGRAPH_PRECIPITATION_EXTRACT'
  ;---------------------------------------------------------------------
  ; SET INPUT DIRECTORY
  INDIR = DIALOG_PICKFILE(/DIRECTORY, PATH='C:\', TITLE='SELECT INPUT DIRECTORY')
  ;---------------------------------------------------------------------
  ; SET INPUT COORDINATE FILE  
  INCO = DIALOG_PICKFILE(PATH='C:\', TITLE='SELECT INPUT COORDINATE FILE')
  ;---------------------------------------------------------------------
  ; GET NUMBER OF LINES IN INCO
  INCOROWS = FILE_LINES(INCO)
  ; OPEN INPUT COORDINATE FILE
  OPENR, INCOLUN, INCO, /GET_LUN
  ; CREATE INCO ARRAY
  INCOARR = STRARR(INCOROWS)
  ; READ DATA
  READF, INCOLUN, INCOARR  
  ;---------------------------------------------------------------------
  ; SET OUTPUT FILE  
  OUTPUT = DIALOG_PICKFILE(DEFAULT_EXTENSION='csv', /OVERWRITE_PROMPT, $
   PATH='C:\', TITLE='DEFINE OUTPUT FILE')
  ;---------------------------------------------------------------------  
  ; GET FILE LIST                                   
  ALLFILELIST = FILE_SEARCH(INDIR, "*.txt", COUNT=FCOUNT)
  ;---------------------------------------------------------------------
  ; CREATE THE [EMPTY] OUTPUT FILE:
  ;---------------------------------------------------------------------
  ; GET OUTPUT ROOT     
  ROOTE = STRPOS(OUTPUT, '\')+1  
  ROOT = STRMID(OUTPUT, 0, ROOTE)  
  ; GET OUTPUT PATH
  PATHE1 = STRPOS(OUTPUT, '\', /REVERSE_SEARCH)-ROOTE
  PATH = STRMID(OUTPUT, ROOTE, PATHE1)                              
  ; GET OUTPUT NAME
  PATHE2 = STRPOS(OUTPUT, '\', /REVERSE_SEARCH)
  NAMEL = (STRLEN(OUTPUT)-PATHE2)                             
  OUTNAME = STRMID(OUTPUT, PATHE2+1, NAMEL)
  ; FUNCTION 'FILEPATH'
  OUTFILE = FILEPATH(OUTNAME, ROOT_DIR=ROOT, SUBDIRECTORY=PATH)
  ; CREATE THE FILE 
  OPENW, OUTLUN, OUTFILE, /GET_LUN
  ; WRITE THE HEAD                               
  FHEAD=["PID","ID","PNAME","CX","CY","DATE","MMPHSUM","MMPD","MMPDADJ"]
  PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, '"' + FHEAD + '"'
  ;---------------------------------------------------------------------
  ; INPUT FILE LOOP:
  ;---------------------------------------------------------------------
  FOR i=0, FCOUNT-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------
    ; GET START TIME
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------
    ; GET INPUT FILE
    INFILEFULL = ALLFILELIST[i]
    ; GET FILE NAME SHORT AND PATH
    INS = STRPOS(INFILEFULL, '\', /REVERSE_SEARCH)+1
    INL = (STRLEN(INFILEFULL)-INS)
    INFILE = STRMID(INFILEFULL, INS, INL)
    INPATH = STRMID(INFILEFULL, 0, INS)
    ;-------------------------------------------------------------------
    ; OPEN INFILE
    OPENR, INLUN, INFILEFULL, /GET_LUN
    ;-------------------------------------------------------------------
    ; GET DATA:
    ;-------------------------------------------------------------------
    ; READ DATA FILE ONE LINE AT A TIME
    WHILE NOT EOF(INLUN) DO BEGIN ; START 'WHILE 1'
      LINE = ''
      ; READ-IN DATA
      READF, INLUN, LINE
      ; GET INFILE ROW
      LINEF = STRSPLIT(LINE(0), '=', /EXTRACT)
      ; SET INFILE ROW AS ARRAY
      LINEA = STRSPLIT(LINEF(0), ' ,', /EXTRACT)
      ; GET PLUVIOGRAPH ID 
      PID = LINEA[0]
      ; GET ROW LENGTH
      ROWL = N_ELEMENTS(LINEA)
      ;-----------------------------------------------------------------     
      ; GET PRECIPITATION DATA:
      ;-----------------------------------------------------------------
      ; CONVERT LINE TO DOUBLE
      LINED = DOUBLE(LINEA)
      ;-----------------------------------------------------------------
      ; DATE TYPE CHECK     
      IF (LINED[1] LT 9999) AND (LINED[1] GT 999) THEN BEGIN
        ; DATE TYPE CHECK
        ;---------------------------------------------------------------
        IF LINED[2] GT 99 THEN BEGIN
          ;-------------------------------------------------------------
          ; GET ROW TOTAL
          ROWSUM = TOTAL(LINED)
          ; REMOVE ID AND DATE
          MMPHSUM = ((ROWSUM-LINED[1])-LINED[0])-LINED[2]
          ;-------------------------------------------------------------          
          ; GET MM PER DAY ; (MMPD=MMPHSUM*24) OR (MMPD = (LINED(START:END)*0.1)*COUNT)
          ;   (A = PER DAY), (B = PER DAY ADJUSTED)
          INLENGTH = N_ELEMENTS(LINED)
          LINED2 = LINED(3:INLENGTH-1)
          RC = N_ELEMENTS(LINED2)
          MMTMP = (LINED2*0.1)
          MMPD_ADJ = TOTAL(MMTMP)*RC
          MMPD = MMPHSUM*24 
          ;-------------------------------------------------------------
          ; GET DATE
          DATE1 = (LINEA[1])
          DATE2 = (LINEA[2])
          ; BUILD DATE
          SDATE = STRING(DATE1) + STRING(DATE2)
          YY = STRMID(STRTRIM(SDATE, 2), 0, 4)
          MM = STRMID(STRTRIM(SDATE, 2), 4, 2)
          DD = STRMID(STRTRIM(SDATE, 2), 6, 2)
          CALDAT, JULDAY(MM, DD, YY), MONTH, DAY, YEAR
          IF DAY LE 9 THEN DAY = '0' + STRING(STRTRIM(DAY,2)) ELSE DAY = STRING(STRTRIM(DAY,2))
          IF MONTH LE 9 THEN MONTH = '0' + STRING(STRTRIM(MONTH,2)) ELSE MONTH = STRING(STRTRIM(MONTH,2))
          OUTDATE = DAY + '/' + MONTH + '/' + STRING(STRTRIM(YEAR,2))
          ;-------------------------------------------------------------       
        ENDIF ELSE BEGIN
          ;-------------------------------------------------------------
          ; GET ROW TOTAL
          ROWSUM = TOTAL(LINED)
          ; REMOVE ID AND DATE
          MMPHSUM = (((ROWSUM-LINED[1])-LINED[0])-LINED[2])-LINED[3]
          ;-------------------------------------------------------------
          ; GET MM PER DAY ; (MMPD=MMPHSUM*24) OR (MMPD = (LINED(START:END)*0.1)*COUNT)
          ;   (A = PER DAY), (B = PER DAY ADJUSTED)
          INLENGTH = N_ELEMENTS(LINED)
          LINED2 = LINED(4:INLENGTH-1)
          RC = N_ELEMENTS(LINED2)
          MMTMP = (LINED2*0.1)
          MMPD_ADJ = TOTAL(MMTMP)*RC
          MMPD = MMPHSUM*24 
          ;-------------------------------------------------------------
          ; GET DATE
          DATE1 = (LINEA[1])
          DATE2 = (LINEA[2])
          DATE3 = (LINEA[3])
          ; BUILD DATE      
          SDATE = STRING(DATE1) + STRING(DATE2)
          YY = STRMID(STRTRIM(SDATE, 2), 0, 4)
          MM = STRMID(STRTRIM(SDATE, 2), 4, 2)
          DD = STRMID(STRTRIM(SDATE, 2), 6, 2)
          CALDAT, JULDAY(MM, DD, YY), MONTH, DAY, YEAR
          IF DAY LE 9 THEN DAY = '0' + STRING(STRTRIM(DAY,2)) ELSE DAY = STRING(STRTRIM(DAY,2))
          IF MONTH LE 9 THEN MONTH = '0' + STRING(STRTRIM(MONTH,2)) ELSE MONTH = STRING(STRTRIM(MONTH,2))
          OUTDATE = DAY + '/' + MONTH + '/' + STRING(STRTRIM(YEAR,2))
          ;-------------------------------------------------------------
        ENDELSE  
        ;---------------------------------------------------------------
      ENDIF 
      ;-----------------------------------------------------------------
      ; DATE TYPE CHECK 
      IF (LINED[1] LT 999999) AND (LINED[1] GT 9999) THEN BEGIN
        ;---------------------------------------------------------------
        ; GET ROW TOTAL
        ROWSUM = TOTAL(LINED)
        ; REMOVE ID AND DATE
        MMPHSUM = ((ROWSUM-LINED[1])-LINED[0])-LINED[2]
        ;---------------------------------------------------------------
        ; GET MM PER DAY ; (MMPD=MMPHSUM*24) OR (MMPD = (LINED(START:END)*0.1)*COUNT)
        ;   (A = PER DAY), (B = PER DAY ADJUSTED)
        INLENGTH = N_ELEMENTS(LINED)
        LINED2 = LINED(3:INLENGTH-1)
        RC = N_ELEMENTS(LINED2)
        MMTMP = (LINED2*0.1)
        MMPD_ADJ = TOTAL(MMTMP)*RC
        MMPD = MMPHSUM*24 
        ;---------------------------------------------------------------
        ; GET DATE
        DATE1 = (LINEA[1])
        DATE2 = (LINEA[2])
        ; BUILD DATE
        SDATE = STRING(DATE1) + STRING(DATE2)
        YY = STRMID(STRTRIM(SDATE, 2), 0, 4)
        MM = STRMID(STRTRIM(SDATE, 2), 4, 2)
        DD = STRMID(STRTRIM(SDATE, 2), 6, 2)
        CALDAT, JULDAY(MM, DD, YY), MONTH, DAY, YEAR
        IF DAY LE 9 THEN DAY = '0' + STRING(STRTRIM(DAY,2)) ELSE DAY = STRING(STRTRIM(DAY,2))
        IF MONTH LE 9 THEN MONTH = '0' + STRING(STRTRIM(MONTH,2)) ELSE MONTH = STRING(STRTRIM(MONTH,2))
        OUTDATE = DAY + '/' + MONTH + '/' + STRING(STRTRIM(YEAR,2))
        ;--------------------------------------------------------------- 
      ENDIF
      ;-----------------------------------------------------------------      
      ; DATE TYPE CHECK
      IF (LINED[1] GT 10000000) THEN BEGIN
        ;---------------------------------------------------------------
        ; GET ROW TOTAL 
        ROWSUM = TOTAL(LINED)
        ; REMOVE ID AND DATE
        MMPHSUM = (ROWSUM-LINED[1])-LINED[0]
        ;---------------------------------------------------------------
        ; GET MM PER DAY ; (MMPD=MMPHSUM*24) OR (MMPD = (LINED(START:END)*0.1)*COUNT)
        ;   (A = PER DAY), (B = PER DAY ADJUSTED)
        INLENGTH = N_ELEMENTS(LINED)
        LINED2 = LINED(2:INLENGTH-1)
        RC = N_ELEMENTS(LINED2)
        MMTMP = (LINED2*0.1)
        MMPD_ADJ = TOTAL(MMTMP)*RC
        MMPD = MMPHSUM*24 
        ;---------------------------------------------------------------
        ; GET DATE
        DATE = (LINEA[1])
        ; GET DATE ELEMENTS
        SDATE = STRING(DATE)
        YY = STRMID(STRTRIM(SDATE, 2), 0, 4)
        MM = STRMID(STRTRIM(SDATE, 2), 4, 2)
        DD = STRMID(STRTRIM(SDATE, 2), 6, 2)
        CALDAT, JULDAY(MM, DD, YY), MONTH, DAY, YEAR
        IF DAY LE 9 THEN DAY = '0' + STRING(STRTRIM(DAY,2)) ELSE DAY = STRING(STRTRIM(DAY,2))
        IF MONTH LE 9 THEN MONTH = '0' + STRING(STRTRIM(MONTH,2)) ELSE MONTH = STRING(STRTRIM(MONTH,2))
        OUTDATE = DAY + '/' + MONTH + '/' + STRING(STRTRIM(YEAR,2))
        ;---------------------------------------------------------------        
      ENDIF
      ;-----------------------------------------------------------------
      ; GET PLUVIOGRAPH NAME, COORDINATES AND ID
      FOR k=0, INCOROWS-1 DO BEGIN ; START 'FOR k'
        ; SPLIT LINE
        INCOARRL = STRSPLIT(INCOARR(k), ' ,', /EXTRACT)
        IF INCOARRL(0) EQ PID THEN BEGIN
          PNAME = INCOARRL(1)
          CY = INCOARRL(2)
          CX = INCOARRL(3)
          ID = INCOARRL(4) 
        ENDIF
      ENDFOR ; END 'FOR k'
      ;-----------------------------------------------------------------
      IF LINED[1] GT 999 THEN BEGIN
        ;---------------------------------------------------------------     
        ; WRITE DATA TO OUTPUT
        PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, PID, ID, PNAME, CX, CY, OUTDATE, MMPHSUM, MMPD, MMPD_ADJ
        ;---------------------------------------------------------------      
      ENDIF
      ;-----------------------------------------------------------------
    ENDWHILE ; END 'WHILE 1'
    ;-------------------------------------------------------------------
    ; CLOSE THE INPUT FILE
    FREE_LUN, INLUN
    ;-------------------------------------------------------------------
    ; PRINT LOOP TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    PRINT, ''
    PRINT, '  ', STRTRIM(SECONDS, 2), ' SECONDS FOR: ', INFILE, ' FILE NO. ', $ 
      STRTRIM(i+1, 2), ' OF ', STRTRIM(FCOUNT, 2)
    ;-------------------------------------------------------------------   
  ENDFOR ; END 'FOR i'
  ;---------------------------------------------------------------------
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUTLUN
  ; CLOSE THE INPUT COORDINATE FILE
  FREE_LUN, INCOLUN
  ;---------------------------------------------------------------------
  PRINT,''
  ; PLUVIOGRAPH_PRECIPITATION_EXTRACT
  MINUTES = (SYSTIME(1)-T_TIME)/60
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), '  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: PLUVIOGRAPH_PRECIPITATION_EXTRACT'
  PRINT,'' 
END 