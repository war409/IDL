; ##############################################################################################
; NAME: BATCH_DOIT_Confusion_Matrix.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 07/07/2010
; DLM: 30/07/2010
;
; DESCRIPTION: This tool generates ‘one class’ confusion matrix (a.k.a. contingency table) measures 
;              for each input pair. The results are written to a user-defined comma-delimited ‘txt’ 
;              (or ‘csv’) file. 
;          
;              The accuracy measures include:
;              
;              A: (a.k.a True Positive) The count (i.e. the number of cells) of correct predictions 
;              that the event is positive. 
;              
;              B: (a.k.a True Negative) The count (i.e. the number of cells) of incorrect predictions 
;              that the event is positive.
;              
;              C: (a.k.a False Positive) The count (i.e. the number of cells) of incorrect predictions 
;              that the event is negative.
;              
;              D: (a.k.a False Negative) The count (i.e. the number of cells) of correct predictions 
;              that the event is negative.
;              
;              N: The population size i.e. the number of elements in the input.
;              
;              A Proportion: The proportion (percentage) of A in N.
;              
;              B Proportion: The proportion (percentage) of B in N.
;              
;              C Proportion: The proportion (percentage) of C in N.
;              
;              D Proportion: The proportion (percentage) of D in N.
;              
;              Correct Classification Rate: (a.k.a Accuracy) The proportion of correct predictions. 
;              CCR = [(A+D) / (A+B+C+D)]
;              
;              Misclassification Rate: The proportion of incorrect predictions. MR = [(B+C) / (A+B+C+D)]
;              
;              True Positive Rate: (a.k.a Sensitivity) The proportion of positive cases correctly 
;              identified as positive. TPR = [A / (A+C)]
;              
;              False Positive rate: The proportion of negative cases incorrectly identified as 
;              positive. FPR = [B / (B+D)]
;              
;              True negative Rate: (a.k.a Specificity) The proportion of negative cases correctly 
;              identified as negative. TNR = [D / (D+B)]
;              
;              False negative Rate: The proportion of positive cases incorrectly identified as 
;              negative. FNR = [C / (C+A)]
;              
;              Positive predictive Power: (a.k.a precision) The proportion of correct positive 
;              predictions. PPP = [A / (A+B)]
;              
;              Negative predictive Power: The proportion of correct negative predictions. NPP = [D / (D+C)]
;              
;              Prevalence: The proportion of positive cases. P = [(A+C) / (A+B+C+D)]
;              
;              Overall diagnostic Power: The proportion of negative cases. ODP = [(B+D) / (A+B+C+D)]
;              
;              Odds ratio: ODDR = [(A*D) / (B*C)]
;              
;              Kappa: The proportion of specific agreement. 
;              Kappa = [(A+D)-(((A+C)*(A+B)+(B+D)*(C+D))/N)]/[N-(((A+C)*(A+B)+(B+D)*(C+D))/N)]
;              
;              Geometric g-means 1: GM1 = SQRT((A/(A+C))*(A/(A+B)))
;              
;              Geometric g-means 2: GM2 = SQRT((A/(A+C))*(D/(D+B)))  
;
; INPUT:       One or more classification pairs; for each date or instance - a single-band grid of the 
;              predicted (or modelled) event and a single-band grid of the actual (truth) event. 
;              
;              For example, the event may be 'open water' in which case the predicted data is modelled open
;              water, and the actual data is waster digitised using aerial photography.
;              
;              The input data (predicted and actual data) MUST depict the presence/absence of the event as
;              0's and 1's, where a value of 1 indicates the presence of the event and a value of 0 indicates
;              the absence of the event. In the example above, water pixels should have a value of 1 while 
;              non-water pixels should have a value of 0.  
;
; OUTPUT:      One user-selected comma-delimited text file (.txt or .csv). For each input instance (i.e. date) 
;              the measures described in DESCRIPTION are calculated and saved.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.    'SELECT THE PREDICTED DATA'
;              2.    'SELECT THE ACTUAL DATA'
;              3.    'SELECT THE DATATYPE: PREDICTED DATA'
;              4.    'SELECT THE DATATYPE: ACTUAL DATA'
;              5.    'SELECT THE DATE TYPE: PREDICTED DATA'
;              6.    'SELECT THE DATE TYPE: ACTUAL DATA'
;              7.    'SET A VALUE AS NODATA: PREDICTED DATA'
;              7.1   'ENTER THE NODATA VALUE: PREDICTED DATA'
;              8.    'SET A VALUE AS NODATA: ACTUAL DATA'
;              8.1   'ENTER THE NODATA VALUE: ACTUAL DATA'
;              9.    'SELECT THE OUTPUT FILE'
;              
; NOTES:       The input data must have identical dimensions.
;
; ##############################################################################################


;************************************************************************************************
; FUNCTIONS: START
;************************************************************************************************

; ##############################################################################################
FUNCTION RADIO_BUTTON_WIDGET, TITLE, VALUES
  ;-----------------------------------
  ; SET XSIZE
  VL = MAKE_ARRAY(1, N_ELEMENTS(VALUES)+1, /STRING)
  FOR v=0, N_ELEMENTS(VALUES) DO BEGIN
    IF v LT N_ELEMENTS(VALUES) THEN VL[*,v] += STRLEN(VALUES[v])
    IF v EQ N_ELEMENTS(VALUES) THEN VL[*,v] += STRLEN(TITLE[0])
  ENDFOR
  XSIZE = MAX(VL)*8
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT: 
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', XSIZE=XSIZE, /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP=TITLE, /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT_TMP = WIDGET_EVENT(BASE)
  RESULT = RESULT_TMP.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;--------------
  ; ERROR CHECK:
  IF N_ELEMENTS(RESULT) EQ 0 THEN BEGIN
    PRINT, ''
    PRINT, 'THE INPUT IS NOT VALID: ', TITLE
    CHECK_P = 1
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;----------------------------------- 
  ; RETURN VALUES:
  RETURN, RESULT
  ;-----------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION GET_FNAME_DMY_DOYYYYY, FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE                           
  YYY = STRMID(FILENAME, YEAR_STARTPOS, YEAR_LENGTH)
  DOY = STRMID(FILENAME, DOY_STARTPOS, DOY_LENGTH)
  ; GET 'DAY' AND 'MONTH' FROM 'DAY OF YEAR' 
  CALDAT, JULDAY(1, DOY, YYY), MONTH, DAY
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY = JULDAY(MONTH, DAY, YYY)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, DMY
  ;-----------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION GET_FNAME_DMY_DDMMYYYY, FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE FILE NAMES TO GET DATE                           
  YYY = STRMID(FILENAME, YEAR_STARTPOS, YEAR_LENGTH)
  MMM = STRMID(FILENAME, MONTH_STARTPOS, MONTH_LENGTH)
  DDD = STRMID(FILENAME, DAY_STARTPOS, DAY_LENGTH)
  DMY = JULDAY(MMM, DDD, YYY)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, DMY
  ;-----------------------------------
END
; ##############################################################################################


;************************************************************************************************
; FUNCTIONS: END
;************************************************************************************************


PRO BATCH_DOIT_Confusion_Matrix
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Confusion_Matrix'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SET INPUT DATA:
  ;--------------
  PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\Modelled_Open_Water'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  ;--------------
  ; SELECT THE PREDICTED DATA:
  TITLE='SELECT THE PREDICTED DATA'
  IN_P = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT) 
  ;--------------
  ; SELECT THE ACTUAL DATA:
  TITLE='SELECT THE ACTUAL DATA'
  IN_A = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, FILTER=FILTER, /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_P[0] EQ '' THEN RETURN
  IF IN_A[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_P = IN_P[SORT(IN_P)]
  IN_A = IN_A[SORT(IN_A)]
  ;---------------------------------------------------------------------------------------------
  ; SET DATATYPE:
  ;--------------
  VALUES = ['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', '2 : INT : Integer', $
    '3 : LONG : Longword integer', '4 : FLOAT : Floating point', '5 : DOUBLE : Double-precision floating', $
    '6 : COMPLEX : Complex floating', '7 : STRING : String', '8 : STRUCT : Structure', $
    '9 : DCOMPLEX : Double-precision complex', '10 : POINTER : Pointer', '11 : OBJREF : Object reference', $
    '12 : UINT : Unsigned Integer', '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer']
  ;--------------
  ; SELECT THE DATATYPE OF THE PREDICTED DATA
  TITLE='SELECT THE DATATYPE: PREDICTED DATA'
  DT_P = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;--------------
  ; SELECT THE DATATYPE OF THE ACTUAL DATA
  TITLE='SELECT THE DATATYPE: ACTUAL DATA'
  DT_A = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;---------------------------------------------------------------------------------------------
  ; DIMENSIONS CHECK:
  ;--------------
  ; OPEN INPUT IN_P[0] & IN_A[0]
  P_ONE = READ_BINARY(IN_P[0], DATA_TYPE=DT_P)
  A_ONE = READ_BINARY(IN_A[0], DATA_TYPE=DT_A)
  ;--------------
  ; GET THE NUMBER OF ELEMENTS
  ELEMENTS_P = N_ELEMENTS(P_ONE)
  ELEMENTS_A = N_ELEMENTS(A_ONE)
  ;--------------
  ; ERROR CHECK:
  IF ELEMENTS_P NE ELEMENTS_A THEN BEGIN
    PRINT,''
    PRINT,'INPUT DATA MUST HAVE IDENTICAL DIMENSIONS'
    RETURN
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SET DATE TYPE:
  ;--------------
  VALUES = ['DOY/YEAR', 'DD/MM/YYYY']
  ;--------------
  ; SET THE DATE-TYPE OF THE PREDICTED DATA
  TITLE_P ='SELECT THE DATE-TYPE: PREDICTED DATA'
  D_T_P = RADIO_BUTTON_WIDGET(TITLE_P, VALUES)
  ;--------------
  ; SET THE DATE-TYPE OF THE ACTUAL DATA
  TITLE_A ='SELECT THE DATE-TYPE: ACTUAL DATA'
  D_T_A = RADIO_BUTTON_WIDGET(TITLE_A, VALUES)
  ;---------------------------------------------------------------------------------------------
  ; SET NODATA:
  ;--------------
  ; SET THE NODATA STATUS
  TITLE_P ='SET A VALUE AS NODATA: PREDICTED DATA'
  VALUES = ['YES', 'NO']
  NAN_STATUS_P = RADIO_BUTTON_WIDGET(TITLE_P, VALUES)
  ; SET THE NODATA VALUE
  IF NAN_STATUS_P EQ 0 THEN BEGIN
    TITLE = 'ENTER THE NODATA VALUE: PREDICTED DATA'
    DEFAULT_VALUE = 255.00
    NAN_VALUE_P = ENTER_VALUE_WIDGET(TITLE, DEFAULT_VALUE)
  ENDIF
  ;--------------
  ; SET THE NODATA STATUS
  TITLE_A ='SET A VALUE AS NODATA: ACTUAL DATA'
  NAN_STATUS_A = RADIO_BUTTON_WIDGET(TITLE_A, VALUES)
  ; SET THE NODATA VALUE
  IF NAN_STATUS_A EQ 0 THEN BEGIN
    TITLE = 'ENTER THE NODATA VALUE: ACTUAL DATA'
    DEFAULT_VALUE = 255.00
    NAN_VALUE_A = ENTER_VALUE_WIDGET(TITLE, DEFAULT_VALUE)
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SET OUTPUT:
  ;--------------
  ; SELECT THE OUTPUT FILE:
  TITLE='SELECT THE OUTPUT FILE'  
  OUT_FILE = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, DEFAULT_EXTENSION='txt', /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_FILE EQ '' THEN RETURN
  ;-----------------------------------
  ; SET THE OUTPUT FILE HEAD
  FHEAD=["DATEID","PRED_FNAME","ACTU_FNAME","DAY","MONTH","YEAR","DOY","A","B","C","D","N", "CORRECT_CLASSIFICATION_RATE", $
    "MISCLASSIFICATION_RATE", "TRUE_POSITIVE_RATE", "FALSE_POSITIVE_RATE","TRUE_NEGATIVE_RATE", $
    "FALSE_NEGATIVE_RATE","POSITIVE_PREDICTIVE_POWER","NEGATIVE_PREDICTIVE_POWER", "PREVALENCE", $
    "OVERALL_DIAGNOSTIC_POWER","ODDS_RATIO","KAPPA","GEOMETRIC_GMEANS 1","GEOMETRIC_GMEANS_2"]
  ;--------------
  ; CREATE THE OUTPUT FILE 
  OPENW, OUT_LUN, OUT_FILE, /GET_LUN
  ; WRITE THE FILE HEAD
  PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, '"' + FHEAD + '"'
  ; CLOSE THE OUTPUT FILE
  FREE_LUN, OUT_LUN   
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; GET DATES:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT:
  ;--------------
  ; GET FNAME_SHORT
  FNAME_START_P = STRPOS(IN_P, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH_P = (STRLEN(IN_P)-FNAME_START_P)-4
  ;--------------
  ; GET FNAME_SHORT
  FNAME_START_A = STRPOS(IN_A, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH_A = (STRLEN(IN_A)-FNAME_START_A)-4
  ;----------------------------------- 
  ; GET FILENAME ARRAY
  FN_P = MAKE_ARRAY(1, N_ELEMENTS(IN_P), /STRING)
  FOR a=0, N_ELEMENTS(IN_P)-1 DO BEGIN
    ; GET THE a-TH FILENAME 
    FN_P[*,a] += STRMID(IN_P[a], FNAME_START_P[a], FNAME_LENGTH_P[a])
  ENDFOR
  ;--------------
  ; GET FILENAME ARRAY
  FN_A = MAKE_ARRAY(1, N_ELEMENTS(IN_A), /STRING)
  FOR a=0, N_ELEMENTS(IN_A)-1 DO BEGIN
    ; GET THE a-TH FILENAME 
    FN_A[*,a] += STRMID(IN_A[a], FNAME_START_A[a], FNAME_LENGTH_A[a])
  ENDFOR
  ;--------------------------------------
  ; GET UNIQUE DATES:
  ;--------------------------------------
  IF D_T_P EQ 0 THEN BEGIN
    ; GET FILENAME DAY/MONTH/YEAR: (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY_P = GET_FNAME_DMY_DOYYYYY(FN_P, 40, 4, 44, 3) 
  ENDIF ELSE BEGIN
    ; GET FILENAME DAY/MONTH/YEAR: (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY_P = GET_FNAME_DMY_DDMMYYYY(FN_P, 33, 4, 37, 2, 39, 2) 
  ENDELSE 
  ;--------------  
  IF D_T_A EQ 0 THEN BEGIN
    ; GET FILENAME DAY/MONTH/YEAR: (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY_A = GET_FNAME_DMY_DOYYYYY(FN_A, 31, 4, 35, 3)
  ENDIF ELSE BEGIN
    ; GET_FNAME_DMY_DDMMYYYY(FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH) 
    DMY_A = GET_FNAME_DMY_DDMMYYYY(FN_A, 17, 4, 21, 2, 23, 2)
  ENDELSE 
  ;--------------
  ; COMBINE STRING VECTORS
  DMY = [[DMY_P], [DMY_A]]
  ; GET UNIQUE DATES
  UNIQ_DATE = DMY[UNIQ(DMY)]  
  ; SORT DATES (ASCENDING)
  UNIQ_DATE = UNIQ_DATE[SORT(UNIQ_DATE)]
  ; GET UNIQUE DATES 2
  UNIQ_DATE = UNIQ_DATE[UNIQ(UNIQ_DATE)]
  ; SET DATE COUNT
  COUNT_D = N_ELEMENTS(UNIQ_DATE)
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; DATE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, COUNT_D-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;------------------------------------------------------------------------------------------- 
    ; GET LOOP DATA:
    ;-------------------------------------------------------------------------------------------
    ; GET THE i-TH DATE
    CALDAT, UNIQ_DATE[i], iM, iD, iY ; CONVERT JULDAY TO CALDAY
    DOY = JULDAY(iM, iD, iY) - JULDAY(1, 0, iY) ; GET DAY OF YEAR
    ;--------------
    ; DOY ZERO CHECK
    IF (DOY LE 9) THEN DOY = '00' + STRING(STRTRIM(DOY,2))
    IF (DOY LE 99) AND (DOY GT 9) THEN DOY = '0' + STRING(STRTRIM(DOY,2))
    ;--------------
    ; GET FILE INDEX
    INDEX_P = WHERE(DMY_P EQ UNIQ_DATE[i], COUNT_P)
    INDEX_A = WHERE(DMY_A EQ UNIQ_DATE[i], COUNT_A)
    ;--------------
    ; ERROR CHECK:
    IF COUNT_P EQ 0 THEN CONTINUE
    IF COUNT_A EQ 0 THEN CONTINUE
    ;--------------
    ; ERROR CHECK:
    IF COUNT_A GT 1 THEN RETURN
    ;--------------
    ;*******************************************************************************************
    ; MULTIPLE INPUT CHECK:    
    ;*******************************************************************************************
    ;--------------
    IF COUNT_P GT 1 THEN BEGIN
      ;-----------------------------------------------------------------------------------------
      ; GET FILENAME
      FILE_PL = IN_P[INDEX_P]
      FILE_A = IN_A[INDEX_A]
      ; GET FILENAME SHORT
      FNS_PL = FN_P[INDEX_P]
      FNS_A = FN_A[INDEX_A]
      ;--------------
      FOR j=0, COUNT_P-1 DO BEGIN ; FOR j
        ;---------------------------------------------------------------------------------------
        ; GET THE j-TH FILENAME
        FILE_P = FILE_PL[j]
        ; GET THE j-TH FILENAME SHORT
        FNS_P = FNS_PL[j]
        ;--------------
        ; GET DATA 
        DATA_P = READ_BINARY(FILE_P, DATA_TYPE=DT_P)
        DATA_A = READ_BINARY(FILE_A, DATA_TYPE=DT_A)
        ;-----------------------------------
        ; PREPARE DATA:
        ;-----------------------------------
        ; DATATYPE CHECK
        IF (DT_P LT 4) AND (DT_P GT 5) THEN DATA_P = FLOAT(DATA_P)
        IF (DT_A LT 4) AND (DT_A GT 5) THEN DATA_A = FLOAT(DATA_A)
        ;--------------
        ; SET NODATA:
        ;--------------
        IF NAN_STATUS_P EQ 0 THEN BEGIN
          n = WHERE(DATA_P EQ FLOAT(NAN_VALUE_P), COUNT)
          IF (COUNT GT 0) THEN DATA_P[n] = !VALUES.F_NAN
        ENDIF
        ;--------------  
        IF NAN_STATUS_A EQ 0 THEN BEGIN
          n = WHERE(DATA_A EQ FLOAT(NAN_VALUE_A), COUNT)
          IF (COUNT GT 0) THEN DATA_A[n] = !VALUES.F_NAN
        ENDIF
        ;---------------------------------------------------------------------------------------
        ; CALCULATE CONFUSION MATRIX:
        ;---------------------------------------------------------------------------------------
        ; APPLY ARRAY ARITHMETIC:
        ;-----------------------------------
        ; PREDICTION PLUS ACTUAL
        DATA_PpA = (DATA_P + DATA_A)
        ; PREDICTION MINUS ACTUAL
        DATA_PmA = (DATA_P - DATA_A)
        ;-----------------------------------
        ; GET CONFUSION MATRIX VARIABLES:
        ;-----------------------------------
        ; TRUE POSITIVE (TP a.k.a A)
        INDEX_TP = WHERE(DATA_PpA EQ 2.00, A_COUNT)
        A_PROP = (A_COUNT*1.0 / ELEMENTS_P*1.0)
        ;-------------- 
        ; TRUE NEGATIVE (TN a.k.a D)
        INDEX_TN = WHERE(DATA_PpA EQ 0.00, D_COUNT)
        D_PROP = (D_COUNT*1.0 / ELEMENTS_P*1.0)
        ;-------------- 
        ; FALSE POSITIVE (FP a.k.a B)
        INDEX_FP = WHERE(DATA_PmA EQ 1.00, B_COUNT)
        B_PROP = (B_COUNT*1.0 / ELEMENTS_P*1.0)
        ;-------------- 
        ; FALSE NEGATIVE (FN a.k.a C)
        INDEX_FN = WHERE(DATA_PmA EQ -1.00, C_COUNT)
        C_PROP = (C_COUNT*1.0 / ELEMENTS_P*1.0)
        ;---------------------------------------------------------------------------------------
        ; CALCULATE ACCURACY MEASURES:
        ;---------------------------------------------------------------------------------------
        ; SET COUNTS AS FLOAT
        A_COUNT = A_COUNT * 1.0
        B_COUNT = B_COUNT * 1.0
        C_COUNT = C_COUNT * 1.0
        D_COUNT = D_COUNT * 1.0
        ;--------------
        ; SAMPLE SIZE: N = (A+B+C+D)
        N = (A_COUNT + B_COUNT + C_COUNT + D_COUNT)
        ;--------------
        ; CORRECT CLASSIFICATION RATE (a.k.a ACCURACY): PROPORTION OF CORRECT PREDICTIONS. CCR = [(A+D) / (A+B+C+D)]
        CCR = ((A_COUNT + D_COUNT) / N)
        ;--------------
        ; MISCLASSIFICATION RATE: PROPORTION OF INCORRECT PREDICTIONS. MR = [(B+C) / (A+B+C+D)]
        MR = ((B_COUNT + C_COUNT) / N)
        ;--------------
        ; TRUE POSITIVE RATE (a.k.a SENSITIVITY): PROPORTION OF POSITIVE CASES CORRECTLY IDENTIFIED. TPR = [A / (A+C)]
        TPR = (A_COUNT / (A_COUNT + C_COUNT))
        ;--------------
        ; FALSE POSITIVE RATE: PROPORTION OF NEGATIVE CASES INCORRECTLY IDENTIFIED AS POSITIVE. FPR = [B / (B+D)]
        FPR = (B_COUNT / (B_COUNT + D_COUNT))
        ;--------------
        ; TRUE NEGATIVE RATE (a.k.a SPECIFICITY): PROPORTION OF NEGATIVE CASES CORRECTLY IDENTIFIED. TNR = [D / (D+B)]
        TNR = (D_COUNT / (D_COUNT + B_COUNT))
        ;--------------
        ; FALSE NEGATIVE RATE: PROPORTION OF POSITIVE CASES INCORRECTLY IDENTIFIED AS NEGATIVE. FNR = [C / (C+A)]
        FNR = (C_COUNT / (C_COUNT + A_COUNT))
        ;--------------
        ; POSITIVE PREDICTIVE POWER (a.k.a PRECISION): PROPORTION OF CORRECT POSITIVE PREDICTIONS. PPP = [A / (A+B)]
        PPP = (A_COUNT / (A_COUNT + B_COUNT))
        ;--------------
        ; NEGATIVE PREDICTIVE POWER: PROPORTION OF CORRECT NEGATIVE PREDICTIONS. NPP = [D / (D+C)]
        NPP = (D_COUNT / (D_COUNT + C_COUNT))
        ;--------------
        ; PREVALENCE: PROPORTION OF POSITIVE CASES. P = [(A+C) / (A+B+C+D)]
        P = ((A_COUNT + C_COUNT) / N)
        ;--------------
        ; OVERALL DIAGNOSTIC POWER: PROPORTION OF NEGATIVE CASES. ODP = [(B+D) / (A+B+C+D)] 
        ODP = ((B_COUNT + D_COUNT) / N)
        ;--------------
        ; ODDS RATIO: ODDR = [(A*D) / (B*C)]
        ODDR = ((A_COUNT * D_COUNT) / (B_COUNT * C_COUNT))
        ;--------------
        ; KAPPA: PROPORTION OF SPECIFIC AGREEMENT. KAPPA = [(A+D)-(((A+C)*(A+B)+(B+D)*(C+D))/N)]/[N-(((A+C)*(A+B)+(B+D)*(C+D))/N)]
        KAPPA = ((A_COUNT + D_COUNT) - (((A_COUNT + C_COUNT) * (A_COUNT + B_COUNT) + (B_COUNT + D_COUNT) * (C_COUNT + D_COUNT)) / N)) /(N - (((A_COUNT + C_COUNT) * (A_COUNT + B_COUNT) + (B_COUNT + D_COUNT) * (C_COUNT + D_COUNT)) /N))
        ;--------------
        ; GEOMETRIC G-MEANS 1: GM1 = SQRT((A/(A+C))*(A/(A+B)))
        GM1 = SQRT((A_COUNT / (A_COUNT + C_COUNT)) * (A_COUNT / (A_COUNT + B_COUNT)))
        ;--------------
        ; GEOMETRIC G-MEANS 2: GM2 = SQRT((A/(A+C))*(D/(D+B)))
        GM2 = SQRT((A_COUNT / (A_COUNT + C_COUNT)) * (D_COUNT / (D_COUNT + B_COUNT)))
        ;---------------------------------------------------------------------------------------
        ; WRITE OUTPUT:
        ;---------------------------------------------------------------------------------------
        ; ["DATEID","DAY","MONTH","YEAR","DOY","A","B","C","D","N", "CORRECT CLASSIFICATION RATE", $
        ; "MISCLASSIFICATION RATE", "TRUE POSITIVE RATE", "FALSE POSITIVE RATE","TRUE NEGATIVE RATE", $
        ; "FALSE NEGATIVE RATE","POSITIVE PREDICTIVE POWER","NEGATIVE PREDICTIVE POWER", "PREVALENCE", $
        ; "OVERALL DIAGNOSTIC POWER","ODDS RATIO","KAPPA","GEOMETRIC G-MEANS 1","GEOMETRIC G-MEANS 2"]
        ;---------------------------------------------------------------------------------------
        ; OPEN THE OUTPUT FILE
        OPENU, OUT_LUN, OUT_FILE, /APPEND, /GET_LUN
        ;--------------  
        ; WRITE DATA
        PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, i, '"' + FNS_P + '"', '"' + FNS_A + '"', STRTRIM(iD, 2), STRTRIM(iM, 2), STRTRIM(iY, 2), $ 
          STRTRIM(DOY, 2), STRTRIM(ROUND(A_COUNT), 2), STRTRIM(ROUND(B_COUNT), 2), STRTRIM(ROUND(C_COUNT), 2), $
          STRTRIM(ROUND(D_COUNT), 2), STRTRIM(ROUND(N), 2), STRTRIM(CCR, 2), STRTRIM(MR, 2), STRTRIM(TPR, 2), STRTRIM(FPR, 2), $
          STRTRIM(TNR, 2), STRTRIM(FNR, 2), STRTRIM(PPP, 2), STRTRIM(NPP, 2), STRTRIM(P, 2), STRTRIM(ODP, 2), $
          STRTRIM(ODDR, 2), STRTRIM(KAPPA, 2), STRTRIM(GM1, 2), STRTRIM(GM2, 2)
        ;--------------
        ; CLOSE THE OUTPUT FILE
        FREE_LUN, OUT_LUN
        ;---------------------------------------------------------------------------------------    
      ENDFOR ; FOR j
      ;-----------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN
      ;--------------
      ; GET FILENAME
      FILE_P = IN_P[INDEX_P]
      FILE_A = IN_A[INDEX_A]
      ; GET FILENAME SHORT
      FNS_P = FN_P[INDEX_P]
      FNS_A = FN_A[INDEX_A]
      ;--------------
      ; GET DATA 
      DATA_P = READ_BINARY(FILE_P, DATA_TYPE=DT_P)
      DATA_A = READ_BINARY(FILE_A, DATA_TYPE=DT_A)
      ;-----------------------------------
      ; PREPARE DATA:
      ;-----------------------------------
      ; DATATYPE CHECK
      IF (DT_P LT 4) AND (DT_P GT 5) THEN DATA_P = FLOAT(DATA_P)
      IF (DT_A LT 4) AND (DT_A GT 5) THEN DATA_A = FLOAT(DATA_A)
      ;--------------
      ; SET NODATA:
      ;--------------
      IF NAN_STATUS_P EQ 0 THEN BEGIN
        n = WHERE(DATA_P EQ FLOAT(NAN_VALUE_P), COUNT)
        IF (COUNT GT 0) THEN DATA_P[n] = !VALUES.F_NAN
      ENDIF
      ;--------------  
      IF NAN_STATUS_A EQ 0 THEN BEGIN
        n = WHERE(DATA_A EQ FLOAT(NAN_VALUE_A), COUNT)
        IF (COUNT GT 0) THEN DATA_A[n] = !VALUES.F_NAN
      ENDIF
      ;----------------------------------------------------------------------------------------- 
      ; CALCULATE CONFUSION MATRIX:
      ;-----------------------------------------------------------------------------------------
      ; APPLY ARRAY ARITHMETIC:
      ;-----------------------------------
      ; PREDICTION PLUS ACTUAL
      DATA_PpA = (DATA_P + DATA_A)
      ; PREDICTION MINUS ACTUAL
      DATA_PmA = (DATA_P - DATA_A)
      ;-----------------------------------
      ; GET CONFUSION MATRIX VARIABLES:
      ;-----------------------------------
      ; TRUE POSITIVE (TP a.k.a A)
      INDEX_TP = WHERE(DATA_PpA EQ 2.00, A_COUNT)
      A_PROP = (A_COUNT*1.0 / ELEMENTS_P*1.0)
      ;-------------- 
      ; TRUE NEGATIVE (TN a.k.a D)
      INDEX_TN = WHERE(DATA_PpA EQ 0.00, D_COUNT)
      D_PROP = (D_COUNT*1.0 / ELEMENTS_P*1.0)
      ;-------------- 
      ; FALSE POSITIVE (FP a.k.a B)
      INDEX_FP = WHERE(DATA_PmA EQ 1.00, B_COUNT)
      B_PROP = (B_COUNT*1.0 / ELEMENTS_P*1.0)
      ;-------------- 
      ; FALSE NEGATIVE (FN a.k.a C)
      INDEX_FN = WHERE(DATA_PmA EQ -1.00, C_COUNT)
      C_PROP = (C_COUNT*1.0 / ELEMENTS_P*1.0)
      ;-----------------------------------------------------------------------------------------
      ; CALCULATE ACCURACY MEASURES:
      ;-----------------------------------------------------------------------------------------
      ; SET COUNTS AS FLOAT
      A_COUNT = A_COUNT * 1.0
      B_COUNT = B_COUNT * 1.0
      C_COUNT = C_COUNT * 1.0
      D_COUNT = D_COUNT * 1.0
      ;--------------
      ; SAMPLE SIZE: N = (A+B+C+D)
      N = (A_COUNT + B_COUNT + C_COUNT + D_COUNT)
      ;--------------
      ; CORRECT CLASSIFICATION RATE (a.k.a ACCURACY): PROPORTION OF CORRECT PREDICTIONS. CCR = [(A+D) / (A+B+C+D)]
      CCR = ((A_COUNT + D_COUNT) / N)
      ;--------------
      ; MISCLASSIFICATION RATE: PROPORTION OF INCORRECT PREDICTIONS. MR = [(B+C) / (A+B+C+D)]
      MR = ((B_COUNT + C_COUNT) / N)
      ;--------------
      ; TRUE POSITIVE RATE (a.k.a SENSITIVITY): PROPORTION OF POSITIVE CASES CORRECTLY IDENTIFIED. TPR = [A / (A+C)]
      TPR = (A_COUNT / (A_COUNT + C_COUNT))
      ;--------------
      ; FALSE POSITIVE RATE: PROPORTION OF NEGATIVE CASES INCORRECTLY IDENTIFIED AS POSITIVE. FPR = [B / (B+D)]
      FPR = (B_COUNT / (B_COUNT + D_COUNT))
      ;--------------
      ; TRUE NEGATIVE RATE (a.k.a SPECIFICITY): PROPORTION OF NEGATIVE CASES CORRECTLY IDENTIFIED. TNR = [D / (D+B)]
      TNR = (D_COUNT / (D_COUNT + B_COUNT))
      ;--------------
      ; FALSE NEGATIVE RATE: PROPORTION OF POSITIVE CASES INCORRECTLY IDENTIFIED AS NEGATIVE. FNR = [C / (C+A)]
      FNR = (C_COUNT / (C_COUNT + A_COUNT))
      ;--------------
      ; POSITIVE PREDICTIVE POWER (a.k.a PRECISION): PROPORTION OF CORRECT POSITIVE PREDICTIONS. PPP = [A / (A+B)]
      PPP = (A_COUNT / (A_COUNT + B_COUNT))
      ;--------------
      ; NEGATIVE PREDICTIVE POWER: PROPORTION OF CORRECT NEGATIVE PREDICTIONS. NPP = [D / (D+C)]
      NPP = (D_COUNT / (D_COUNT + C_COUNT))
      ;--------------
      ; PREVALENCE: PROPORTION OF POSITIVE CASES. P = [(A+C) / (A+B+C+D)]
      P = ((A_COUNT + C_COUNT) / N)
      ;--------------
      ; OVERALL DIAGNOSTIC POWER: PROPORTION OF NEGATIVE CASES. ODP = [(B+D) / (A+B+C+D)] 
      ODP = ((B_COUNT + D_COUNT) / N)
      ;--------------
      ; ODDS RATIO: ODDR = [(A*D) / (B*C)]
      ODDR = ((A_COUNT * D_COUNT) / (B_COUNT * C_COUNT))
      ;--------------
      ; KAPPA: PROPORTION OF SPECIFIC AGREEMENT. KAPPA = [(A+D)-(((A+C)*(A+B)+(B+D)*(C+D))/N)]/[N-(((A+C)*(A+B)+(B+D)*(C+D))/N)]
      KAPPA = ((A_COUNT + D_COUNT) - (((A_COUNT + C_COUNT) * (A_COUNT + B_COUNT) + (B_COUNT + D_COUNT) * (C_COUNT + D_COUNT)) / N)) /(N - (((A_COUNT + C_COUNT) * (A_COUNT + B_COUNT) + (B_COUNT + D_COUNT) * (C_COUNT + D_COUNT)) /N))
      ;--------------
      ; GEOMETRIC G-MEANS 1: GM1 = SQRT((A/(A+C))*(A/(A+B)))
      GM1 = SQRT((A_COUNT / (A_COUNT + C_COUNT)) * (A_COUNT / (A_COUNT + B_COUNT)))
      ;--------------
      ; GEOMETRIC G-MEANS 2: GM2 = SQRT((A/(A+C))*(D/(D+B)))
      GM2 = SQRT((A_COUNT / (A_COUNT + C_COUNT)) * (D_COUNT / (D_COUNT + B_COUNT)))
      ;-----------------------------------------------------------------------------------------
      ; WRITE OUTPUT:
      ;-----------------------------------------------------------------------------------------
      ; ["DATEID","DAY","MONTH","YEAR","DOY","A","B","C","D","N", "CORRECT CLASSIFICATION RATE", $
      ; "MISCLASSIFICATION RATE", "TRUE POSITIVE RATE", "FALSE POSITIVE RATE","TRUE NEGATIVE RATE", $
      ; "FALSE NEGATIVE RATE","POSITIVE PREDICTIVE POWER","NEGATIVE PREDICTIVE POWER", "PREVALENCE", $
      ; "OVERALL DIAGNOSTIC POWER","ODDS RATIO","KAPPA","GEOMETRIC G-MEANS 1","GEOMETRIC G-MEANS 2"]
      ;-----------------------------------------------------------------------------------------  
      ; OPEN THE OUTPUT FILE
      OPENU, OUT_LUN, OUT_FILE, /APPEND, /GET_LUN
      ;--------------  
      ; WRITE DATA
      PRINTF, FORMAT='(10000(A,:,","))', OUT_LUN, i, '"' + FNS_P + '"', '"' + FNS_A + '"', STRTRIM(iD, 2), STRTRIM(iM, 2), STRTRIM(iY, 2), $ 
        STRTRIM(DOY, 2), STRTRIM(ROUND(A_COUNT), 2), STRTRIM(ROUND(B_COUNT), 2), STRTRIM(ROUND(C_COUNT), 2), $
        STRTRIM(ROUND(D_COUNT), 2), STRTRIM(ROUND(N), 2), STRTRIM(CCR, 2), STRTRIM(MR, 2), STRTRIM(TPR, 2), STRTRIM(FPR, 2), $
        STRTRIM(TNR, 2), STRTRIM(FNR, 2), STRTRIM(PPP, 2), STRTRIM(NPP, 2), STRTRIM(P, 2), STRTRIM(ODP, 2), $
        STRTRIM(ODDR, 2), STRTRIM(KAPPA, 2), STRTRIM(GM1, 2), STRTRIM(GM2, 2)
      ;--------------
      ; CLOSE THE OUTPUT FILE
      FREE_LUN, OUT_LUN
      ;-----------------------------------------------------------------------------------------
    ENDELSE
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------  
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR DATE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_D, 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR ; FOR i
  ;---------------------------------------------------------------------------------------------
  ; PRINT SCRIPT INFORMATION:
  ;-----------------------------------
  ; GET END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  ;--------------
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Confusion_Matrix'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END    