; ######################################################################
; NAME: EXTRACT_PLUVIOGRAPH.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren @ CLW
; DATE: 11/01/2010
; DLM: 12/01/2010
; 
; DESCRIPTION: This tool reads-in raw Pluviograph data and extracts
;              the 10 minute rainfall values for each date (00:00 to 24:00),   
;              and converts the records to daily rainfall (09:00 to 09:00), 
;              the output is written to a new comma delimeted csv file.
;              
; INPUT: One or more pluviograph files (10 minute rainfal from BoM). One
;        text file containing the pluviograph station coordinates.
; 
; OUTPUT: One csv file.
; 
; PARAMETERS: Via widgets.
;                          
; NOTES: 
; 
; ######################################################################
; 
PRO EXTRACT_PLUVIOGRAPH
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: EXTRACT_PLUVIOGRAPH'
  ;---------------------------------------------------------------------
  ; SET INPUT OUTPUT: START
  ;---------------------------------------------------------------------  
  ; SET INPUT DIRECTORY
  INDIR = DIALOG_PICKFILE(/DIRECTORY, TITLE='SELECT INPUT DIRECTORY', $
    PATH='C:\Documents and Settings\war409\My Documents\data\Temp\Pluviograph Testing\')
  ;---------------------------------------------------------------------
  ; GET INPUT DIRECTORY FILE LIST                                
  ALLFILELIST = FILE_SEARCH(INDIR, "*.txt", COUNT=FCOUNT)
  ;---------------------------------------------------------------------
  ; SET INPUT COORDINATE FILE  
  INCO = DIALOG_PICKFILE(TITLE='SELECT INPUT COORDINATE FILE', $
    PATH='C:\Documents and Settings\war409\My Documents\data\Temp\Pluviograph Testing\')
  ;---------------------------------------------------------------------
  ; GET NUMBER OF LINES IN THE INPUT COORDINATE FILE
  INCOROWS = FILE_LINES(INCO)
  ; OPEN INPUT COORDINATE FILE
  OPENR, INCOLUN, INCO, /GET_LUN
  ; CREATE ARRAY TO HOLD THE INPUT COORDINATE FILE DATA
  INCOARR = STRARR(INCOROWS)
  ; READ DATA INTO THE ABOVE ARRAY
  READF, INCOLUN, INCOARR  
  ;---------------------------------------------------------------------
  ; SET OUTPUT FILE  
  OUTPUT = DIALOG_PICKFILE(TITLE='DEFINE OUTPUT FILE', DEFAULT_EXTENSION='csv', /OVERWRITE_PROMPT, $
   PATH='C:\Documents and Settings\war409\My Documents\data\Temp\Pluviograph Testing\')
  ;---------------------------------------------------------------------    
  ; CREATE THE OUTPUT FILE 
  OPENW, OUTLUN, OUTPUT, /GET_LUN
  ; WRITE THE OUTPUT FILE HEADER                               
  FHEAD=["PID","ID","PNAME","CX","CY","DATE","MMSUM","MM/DAY","NaN","STATUS"]
  PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, '"' + FHEAD + '"'
  ;---------------------------------------------------------------------
  ; SET INPUT OUTPUT: END
  ;---------------------------------------------------------------------
  ; INPUT FILE LOOP: START
  ;---------------------------------------------------------------------
  FOR i=0, FCOUNT-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------
    ; GET START TIME
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------
    ; GET INPUT FILE
    INFILE = ALLFILELIST[i]
    ;-------------------------------------------------------------------
    ; OPEN INPUT FILE
    OPENR, INLUN, INFILE, /GET_LUN
    ;-------------------------------------------------------------------    
    ; GET INPUT DATA: START
    ;-------------------------------------------------------------------
    ; READ CURRENT INPUT FILE BY LINE
    ; INITIALISE INDEX
    q = 0
    WHILE NOT EOF(INLUN) DO BEGIN ; START 'WHILE 1
      ;-----------------------------------------------------------------
      ; PROGRESS INDEX
      q = q + 1
      ;-----------------------------------------------------------------       
      ; CREATE VARIABLE 'LINE'
      LINE = ''   
      ;-----------------------------------------------------------------   
      ; READ DATA
      READF, INLUN, LINE
      ;-----------------------------------------------------------------    
      ; REPLACE NODATA VALUE LONG (-9999.0) WITH NODATA VALUE SHORT (255.0)
      WHILE (((j = STRPOS(LINE, '-9999.0'))) NE -1) DO STRPUT, LINE, ' 255.0 ', j
      ;-----------------------------------------------------------------
      ; SPLIT STRING (LINE)
      SPLITLINE = STRSPLIT(LINE, ' ', /EXTRACT)
      ;-----------------------------------------------------------------
      ; GET PLUVIOGRAPH ID AND NAME
      IF q EQ 2 THEN BEGIN
        ; GET LENGTH OF ARRAY
        LENGTH1 = N_ELEMENTS(SPLITLINE)
        ; EXTRACT NAME
        PNAMEA = SPLITLINE(2:LENGTH1-1)
        PNAME = STRJOIN(PNAMEA,' ')
        ; EXTRACT PID
        PID = SPLITLINE(0)
      ENDIF
      ;-----------------------------------------------------------------      
      ; STORE PREVIOUS LINES 
      ; RAINFALL SUM (09:00 TO 24:00) 
      IF q GE 4 THEN pRAIN9TO24TOTAL = RAIN9TO24TOTAL
      ; NO DATA COUNT
      IF q GE 4 THEN pNAN9TO24 = NAN9TO24
      ; MONTH
      IF q GE 4 THEN pMM = MM
      ; DAY
      IF q GE 4 THEN pDD = DD 
      ; YEAR
      IF q GE 4 THEN pYY = YY
      ;----------------------------------------------------------------- 
      ; GET RAINFALL
      IF q GT 2 THEN BEGIN ; GET RAINFALL: START
        ;---------------------------------------------------------------      
        ; GET LENGTH OF ARRAY
        LENGTH2 = N_ELEMENTS(SPLITLINE)
        ; REMOVE ID FROM ARRAY
        RAINLINE = SPLITLINE(1:LENGTH2-1)
        ;---------------------------------------------------------------
        ; CONVERT STRING ARRAY TO DOUBLE ARRAY
        RAINLINED = DOUBLE(RAINLINE)  
        ;---------------------------------------------------------------    
        IF (RAINLINED[0] GT 10000000) THEN BEGIN ; DATE CHECK 1: START
          ;-------------------------------------------------------------      
          ; GET DATE
          DATEIN = RAINLINE(0)
          ;-------------------------------------------------------------
          ; GET RAINFALL ARRAY:
          ;-------------------------------------------------------------
          ; GET LENGTH OF ARRAY
          LENGTH3 = N_ELEMENTS(RAINLINED)
          ; REMOVE DATE FROM ARRAY
          RAINARRAY = RAINLINED(1:LENGTH3-1)
          ;-------------------------------------------------------------
        ENDIF ; DATE CHECK 1: END
        ;---------------------------------------------------------------      
        IF (RAINLINED[0] LT 10000000) AND (RAINLINED[0] GT 1000) THEN BEGIN ; DATE CHECK 2: START
          ;-------------------------------------------------------------  
          ; GET DATE
          DATEINA = RAINLINE(0)
          DATEINB = RAINLINE(1)
          ; BUILD DATEIN
          DATEIN = DATEINA + '0' + DATEINB
          ;-------------------------------------------------------------
          ; GET RAINFALL ARRAY:
          ;-------------------------------------------------------------
          ; GET LENGTH OF ARRAY
          LENGTH3 = N_ELEMENTS(RAINLINED)
          ; REMOVE DATE FROM ARRAY
          RAINARRAY = RAINLINED(2:LENGTH3-1)
          ;-------------------------------------------------------------
        ENDIF ; DATE CHECK 2: END
        ;---------------------------------------------------------------           
        IF (RAINLINED[0] LT 10000) AND (RAINLINED[0] GT 100) THEN BEGIN ; DATE CHECK 3: START
          ;-------------------------------------------------------------     
          IF RAINLINED[1] GT 100 THEN BEGIN ; DATE CHECK 3A: START
            ;-----------------------------------------------------------       
            ; GET DATE
            DATEINA = RAINLINE(0)
            DATEINB = RAINLINE(1)
            ; BUILD DATEIN
            DATEIN = DATEINA + '0' + DATEINB
            ;-----------------------------------------------------------
            ; GET RAINFALL ARRAY:
            ;-----------------------------------------------------------
            ; GET LENGTH OF ARRAY
            LENGTH3 = N_ELEMENTS(RAINLINED)
            ; REMOVE DATE FROM ARRAY
            RAINARRAY = RAINLINED(2:LENGTH3-1)
            ;-----------------------------------------------------------            
          ENDIF ; DATE CHECK 3A: END
          ;-------------------------------------------------------------           
          IF RAINLINED[1] LT 100 THEN BEGIN ; DATE CHECK 3B: START
            ;----------------------------------------------------------- 
            ; GET DATE
            DATEINA = RAINLINE(0)
            DATEINB = RAINLINE(1)
            DATEINC = RAINLINE(2)            
            ; BUILD DATEIN
            DATEIN = DATEINA + '0' + DATEINB + '0' + DATEINC
            ;-----------------------------------------------------------
            ; GET RAINFALL ARRAY:
            ;-----------------------------------------------------------            
            ; GET LENGTH OF ARRAY
            LENGTH3 = N_ELEMENTS(RAINLINED)
            ; REMOVE DATE FROM ARRAY
            RAINARRAY = RAINLINED(3:LENGTH3-1) 
            ;-----------------------------------------------------------            
          ENDIF ; DATE CHECK 3B: END          
          ;-------------------------------------------------------------            
        ENDIF ; DATE CHECK 3: END
        ;---------------------------------------------------------------            
        ; EXTRACT DATE ELEMENTS FROM DATEIN
        YY = STRMID(STRTRIM(DATEIN, 2), 0, 4)
        MM = STRMID(STRTRIM(DATEIN, 2), 4, 2)
        DD = STRMID(STRTRIM(DATEIN, 2), 6, 2)
        ; APPLY CALDAT
        CALDAT, JULDAY(MM, DD, YY), MONTH, DAY, YEAR
        ; ADD LEADING ZEROS
        IF DAY LE 9 THEN DAY = '0' + STRING(STRTRIM(DAY,2)) ELSE DAY = STRING(STRTRIM(DAY,2))
        IF MONTH LE 9 THEN MONTH = '0' + STRING(STRTRIM(MONTH,2)) ELSE MONTH = STRING(STRTRIM(MONTH,2))
        ; BUILD OUTDATE
        OUTDATE = DAY + '/' + MONTH + '/' + STRING(STRTRIM(YEAR,2)) 
        ;---------------------------------------------------------------           
        IF q EQ 3 THEN BEGIN ; FIRST RAINFALL LINE: START
          ;-------------------------------------------------------------
          ; GET LENGTH OF ARRAY
          LENGTH4 = N_ELEMENTS(RAINARRAY)
          ;-------------------------------------------------------------          
          ; GET RAINFALL (09:00 TO 24:00)
          RAIN9TO24 = RAINARRAY(54:LENGTH4-1)
          ;-------------------------------------------------------------
          ; REMOVE NODATA (09:00 TO 24:00)
          NAN = WHERE(RAIN9TO24 EQ 255.00, COUNT)
          IF (COUNT GT 0) THEN RAIN9TO24[NAN] = !VALUES.F_NAN
          NAN9TO24 = COUNT
          ;-------------------------------------------------------------
          ; GET RAINFALL (09:00 TO 24:00) SUM 
          RAIN9TO24TOTAL = TOTAL(RAIN9TO24)
          ;-------------------------------------------------------------
        ENDIF ; FIRST RAINFALL LINE: END
        ;---------------------------------------------------------------        
        IF q GE 4 THEN BEGIN ; POST FIRST RAINFALL LINE: START
          ;-------------------------------------------------------------
          ; GET LENGTH OF ARRAY
          LENGTH4 = N_ELEMENTS(RAINARRAY)        
          ;-------------------------------------------------------------
          ; GET RAINFALL (00:00 TO 09:00)
          RAIN00TO9 = RAINARRAY(0:53)
          ; GET RAINFALL (09:00 TO 24:00)
          RAIN9TO24 = RAINARRAY(54:LENGTH4-1)
          ;-------------------------------------------------------------        
          ; REMOVE NODATA (00:00 TO 09:00)
          NAN = WHERE(RAIN00TO9 EQ 255.00, COUNT)
          IF (COUNT GT 0) THEN RAIN00TO9[NAN] = !VALUES.F_NAN
          NAN00TO9 = COUNT   
          ; REMOVE NODATA (09:00 TO 24:00)
          NAN = WHERE(RAIN9TO24 EQ 255.00, COUNT)
          IF (COUNT GT 0) THEN RAIN9TO24[NAN] = !VALUES.F_NAN
          NAN9TO24 = COUNT
          ;-------------------------------------------------------------
          ; GET NO DATA COUNT
          NANCOUNT = pNAN9TO24 + NAN00TO9   
          ;-------------------------------------------------------------
          ; GET RAINFALL (00:00 TO 09:00) SUM 
          RAIN00TO9TOTAL = TOTAL(RAIN00TO9)
          ; GET RAINFALL (09:00 TO 24:00) SUM 
          RAIN9TO24TOTAL = TOTAL(RAIN9TO24)  
          ;-------------------------------------------------------------
          ; GET 24HR RAINFALL SUM:
          ;-------------------------------------------------------------
          ; DATE CHECK
          IF (JULDAY(MM,DD,YY))-1 EQ (JULDAY(pMM,pDD,pYY)) THEN BEGIN
            MMSUM = pRAIN9TO24TOTAL + RAIN00TO9TOTAL
            STATUS24 = 'YES'
          ENDIF ELSE BEGIN
            MMSUM = 'NaN'
            STATUS24 = 'NO'            
          ENDELSE
          ;-------------------------------------------------------------
          ; GET RAINFALL PER DAY:
          ;-------------------------------------------------------------
          ; DATE CHECK
          IF (JULDAY(MM,DD,YY))-1 EQ (JULDAY(pMM,pDD,pYY)) THEN BEGIN
            MMPD = MMSUM*.1
          ENDIF ELSE BEGIN
            MMPD = 'NaN'
          ENDELSE
          ;-------------------------------------------------------------
          ; GET COORDINATES AND ID
          FOR k=0, INCOROWS-1 DO BEGIN ; START 'FOR k'
            ;-----------------------------------------------------------
            ; SPLIT LINE
            INCOARRL = STRSPLIT(INCOARR(k), ' ,', /EXTRACT)
            ;-----------------------------------------------------------
            IF INCOARRL(0) EQ PID THEN BEGIN
              ;--------------------------------------------------------- 
              CY = INCOARRL(2)
              CX = INCOARRL(3)
              ID = INCOARRL(4) 
              ;---------------------------------------------------------
            ENDIF
            ;-----------------------------------------------------------
          ENDFOR ; END 'FOR k'
          ;-------------------------------------------------------------  
          ; WRITE DATA
          PRINTF, FORMAT='(10000(A,:,","))', OUTLUN, PID, ID, '"' + PNAME + '"', CX, CY, $
            OUTDATE, STRTRIM(MMSUM, 2), STRTRIM(MMPD, 2), STRTRIM(NANCOUNT, 2), $
            '"' + STATUS24 + '"'
          ;-------------------------------------------------------------
        ENDIF ; POST FIRST RAINFALL LINE: START
        ;---------------------------------------------------------------
       ENDIF ; GET RAINFALL: END
      ;-----------------------------------------------------------------
    ENDWHILE ; END 'WHILE 1'
    ;-------------------------------------------------------------------
    ; GET INPUT DATA: END
    ;-------------------------------------------------------------------
    ; CLOSE THE INPUT FILE
    FREE_LUN, INLUN
    ;-------------------------------------------------------------------
    ; PRINT LOOP TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    PRINT, ''
    PRINT, '  ', STRTRIM(SECONDS, 2), ' SECONDS. FILE NO. ', STRTRIM(i+1, 2), $
      ' OF ', STRTRIM(FCOUNT, 2)
    ;-------------------------------------------------------------------   
  ENDFOR ; END 'FOR i'
  ;---------------------------------------------------------------------
  ; INPUT FILE LOOP: END
  ;---------------------------------------------------------------------
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUTLUN
  ;---------------------------------------------------------------------
  ; CLOSE THE INPUT COORDINATE FILE
  FREE_LUN, INCOLUN
  ;---------------------------------------------------------------------
  PRINT,''
  MINUTES = (SYSTIME(1)-T_TIME)/60
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), '  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: EXTRACT_PLUVIOGRAPH'
  PRINT,'' 
END 