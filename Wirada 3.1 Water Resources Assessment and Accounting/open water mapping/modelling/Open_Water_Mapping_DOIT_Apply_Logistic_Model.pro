; ##############################################################################################
; NAME: Open_Water_Mapping_DOIT_Apply_Logistic_Model.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: MODIS Open Water Mapping
; DATE: 19/05/2010
; DLM: 05/10/2010
;
; DESCRIPTION: This tool applies a non-linear logistic model to the input data.
;
; INPUT:       Multiple single band MODIS or LANDSAT surface reflectance grids. If the input sensor
;              is MODIS each input date-set must include a QA State quality grid.
;
;              The user may select all of the files for a given date, and can also select multiple
;              date-sets; the code will automatically detect common dates and will ignore files that
;              are not required in the calculation.
;
;              As a minimum the input must include, MODIS bands 1, 2, 6, 7 and QA State; or LANDSAT
;              bands 3, 4, 5 and 7.
;
; OUTPUT:      One OWL grid per unique input date.
;
; PARAMETERS:  Via IDL widgets, set:
;
;              1.    'SELECT INPUT MrVBF DATA'
;              2.    'SELECT INPUT DATA'
;              3.    'SELECT THE DATE TYPE'
;              4.    'SELECT THE INPUT SENSOR'
;              4.1     'SET A VALUE AS NODATA'   (Landsat only)
;              4.1.1     'SET THE NODATA VALUE'  (Landsat only)
;              5.    'SELECT THE MODEL'
;              6.    'DEFINE THE MODEL PARAMETERS'
;              7.    'SELECT THE OUTPUT DIRECTORY'
;
; NOTES:       NDVI and NDWI are calculated on-the-fly using the input reflectance data.
;
;              BITWISE OPERATOR MASK...
;
;              In bitwise operators the 'AND operator' takes two binary 'objects' of equal length
;              and performs the following 'logical operation'. At each bit-location
;              (i.e. 0000000000000001 has 16-bits) each input is compared. If both objects have a
;              value of '1' at the same bit- location the result is 1. If the objects have any
;              other combination the result is 0.
;
;              For example:
;
;              1033 AND 1 = 0000010000001001 AND 0000000000000001
;                         = 0000000000000001
;                         = BINARY(1)
;
;              The result above (0000000000000001) occurs because the only bit that has a value of 1
;              in both 0000010000001001 and 0000000000000001 at the same bit-location is the last or
;              16th bit.
;
;              Another example:
;
;              8205 AND 8025 = 0010000000001101 AND 0001111101011001
;                            = 0000000000001001
;                            = BINARY(9)
;
; ##############################################################################################


;***********************************************************************************************
; FUNCTIONS: START
;***********************************************************************************************


; ##############################################################################################
FUNCTION ENTER_VALUE_WIDGET, TITLE, DEFAULT_VALUE
  XSIZE = STRLEN(TITLE[0])*10
  ;-----------------------------------
  ; REPEAT...UNTIL STATEMENT:
  CHECK_P = 0
  REPEAT BEGIN ; START 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', XSIZE=XSIZE)
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=DEFAULT_VALUE, TITLE=TITLE, /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, XOFFSET=400, YOFFSET=400, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  RESULT_TMP = RESULT.VALUE
  RESULT = FLOAT(RESULT_TMP[0])
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
FUNCTION BITWISE_OPERATOR, DATA, BIN, EQV, WV
  ;---------------------------------------------------------------------------------------------
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BIN) EQ EQV)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WV, COUNT)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [INDEX]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION BITWISE_OPERATOR_AND, DATA, BIN1, EQV1, BIN2, EQV2, WV
  ;---------------------------------------------------------------------------------------------
  ; APPLY BITWISE STATEMENT
  STATE = ((DATA AND BIN1) EQ EQV1) AND ((DATA AND BIN2) EQ EQV2)
  ; GET COUNT OF PIXELS THAT CONFORM TO THE STATEMENT
  INDEX = WHERE(STATE EQ WV, COUNT)
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [INDEX]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION SET_MODEL_PARAMETERS, NO_V
  ;---------------------------------------------------------------------------------------------
  ; SET THE MODEL PARAMETERS:
  ;---------------------------------------------------------------------------------------------
  IF NO_V EQ 0 THEN BEGIN
    ; THREE VARIABLE MODEL:
    PARENT = WIDGET_BASE(TITLE='DEFINE THE MODEL PARAMETERS:', TAB_MODE=2, XSIZE=310, /ROW, /GRID_LAYOUT)
      WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400
      CHILD_1 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)
      CHILD_2 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
      ;--------------------------------------
      ; CHILD_1:
      ;--------------------------------------
      GAMMA_0 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_0 = CW_FIELD(GAMMA_0, XSIZE=12, VALUE=DOUBLE(1.0000),   TITLE='GAMMA 0  ', /RETURN_EVENTS)
      GAMMA_1 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_1 = CW_FIELD(GAMMA_1, XSIZE=12, VALUE=DOUBLE(1.13203180), TITLE='GAMMA 1  ', /RETURN_EVENTS)
      GAMMA_2 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_2 = CW_FIELD(GAMMA_2, XSIZE=12, VALUE=DOUBLE(14.6610240),  TITLE='GAMMA 2  ', /RETURN_EVENTS)
      GAMMA_3 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_3 = CW_FIELD(GAMMA_3, XSIZE=12, VALUE=DOUBLE(-6.99523830),  TITLE='GAMMA 3  ', /RETURN_EVENTS)
      GAMMA_4 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_4 = CW_FIELD(GAMMA_4, XSIZE=12, VALUE=DOUBLE(-0.28353800),  TITLE='GAMMA 4  ', /RETURN_EVENTS)
      ;--------------------------------------
      ; CHILD_2:
      ;--------------------------------------
      X_0 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['MAX GROWTH'])
      X_1 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['GAMMA 1'])
      X_2 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['NDVI','NDWI','MrVBF'])
      X_3 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['NDVI','NDWI','MrVBF'])
      X_4 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['NDVI','NDWI','MrVBF'])
      ;--------------------------------------
      BUTTON_BASE = WIDGET_BASE(CHILD_2, XPAD=0, YPAD=0, /COLUMN, /ALIGN_RIGHT)
        VALUES=['OK']
        OK = CW_BGROUP(BUTTON_BASE, VALUES, /RETURN_NAME)
      ;--------------------------------------
      WIDGET_CONTROL, GAMMA_0, /REALIZE
        RESULT_G0 = WIDGET_EVENT(GAMMA_0)
        VALUE_G0 = RESULT_G0.VALUE
        G0 = VALUE_G0[0]
      WIDGET_CONTROL, GAMMA_1, /REALIZE
        RESULT_G1 = WIDGET_EVENT(GAMMA_1)
        VALUE_G1 = RESULT_G1.VALUE
        G1 = VALUE_G1[0]
      WIDGET_CONTROL, GAMMA_2, /REALIZE
        RESULT_G2 = WIDGET_EVENT(GAMMA_2)
        VALUE_G2 = RESULT_G2.VALUE
        G2 = VALUE_G2[0]
      WIDGET_CONTROL, GAMMA_3, /REALIZE
        RESULT_G3 = WIDGET_EVENT(GAMMA_3)
        VALUE_G3 = RESULT_G3.VALUE
        G3 = VALUE_G3[0]
      WIDGET_CONTROL, GAMMA_4, /REALIZE
        RESULT_G4 = WIDGET_EVENT(GAMMA_4)
        VALUE_G4 = RESULT_G4.VALUE
        G4 = VALUE_G4[0]
      ;--------------------------------------
      WIDGET_CONTROL, X_2, /REALIZE
        RESULT_X2 = WIDGET_EVENT(X_2)
        VALUE_X2 = RESULT_X2.INDEX
        X2 = VALUE_X2[0]
      WIDGET_CONTROL, X_3, /REALIZE
        RESULT_X3 = WIDGET_EVENT(X_3)
        VALUE_X3 = RESULT_X3.INDEX
        X3 = VALUE_X3[0]
      WIDGET_CONTROL, X_4, /REALIZE
        RESULT_X4 = WIDGET_EVENT(X_4)
        VALUE_X4 = RESULT_X4.INDEX
        X4 = VALUE_X4[0]
      ;--------------------------------------
      BUTTON_RESULT = WIDGET_EVENT(BUTTON_BASE)
      BUTTON_VALUE = BUTTON_RESULT.VALUE
    IF BUTTON_VALUE EQ 'OK' THEN WIDGET_CONTROL, PARENT, /DESTROY
    ;--------------------------------------
    ; RETURN VALUES:
    RETURN, [DOUBLE(G0), DOUBLE(G1), DOUBLE(G2), DOUBLE(G3), DOUBLE(G4), DOUBLE(X2), DOUBLE(X3), DOUBLE(X4)]
    ;-------------------------------------------------------------------------------------------
  ENDIF
  ;---------------------------------------------------------------------------------------------
  IF NO_V EQ 1 THEN BEGIN
    ; FIVE VARIABLE MODEL:
    PARENT = WIDGET_BASE(TITLE='DEFINE THE MODEL PARAMETERS:', TAB_MODE=2, XSIZE=310, /ROW, /GRID_LAYOUT)
      WIDGET_CONTROL, PARENT, XOFFSET=400, YOFFSET=400
      CHILD_1 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=0, /COLUMN)
      CHILD_2 = WIDGET_BASE(PARENT, TAB_MODE=1, XPAD=0, YPAD=2, /COLUMN)
      ;--------------------------------------
      ; CHILD_1:
      ;--------------------------------------
      GAMMA_0 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_0 = CW_FIELD(GAMMA_0, XSIZE=12, VALUE=DOUBLE(1.0000),   TITLE='GAMMA 0  ', /RETURN_EVENTS)
      GAMMA_1 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_1 = CW_FIELD(GAMMA_1, XSIZE=12, VALUE=DOUBLE(-3.41375620), TITLE='GAMMA 1  ', /RETURN_EVENTS)
      GAMMA_2 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_2 = CW_FIELD(GAMMA_2, XSIZE=12, VALUE=DOUBLE(-0.000959735270),  TITLE='GAMMA 2  ', /RETURN_EVENTS)
      GAMMA_3 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_3 = CW_FIELD(GAMMA_3, XSIZE=12, VALUE=DOUBLE(0.00417955330),  TITLE='GAMMA 3  ', /RETURN_EVENTS)
      GAMMA_4 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_4 = CW_FIELD(GAMMA_4, XSIZE=12, VALUE=DOUBLE(14.1927990),  TITLE='GAMMA 4  ', /RETURN_EVENTS)
      GAMMA_5 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_5 = CW_FIELD(GAMMA_5, XSIZE=12, VALUE=DOUBLE(-0.430407140),  TITLE='GAMMA 5  ', /RETURN_EVENTS)
      GAMMA_6 = WIDGET_BASE(CHILD_1, YSIZE=25, /COLUMN, /ALIGN_RIGHT)
        CW_6 = CW_FIELD(GAMMA_6, XSIZE=12, VALUE=DOUBLE(-0.0961932990),  TITLE='GAMMA 6  ', /RETURN_EVENTS)
      ;--------------------------------------
      ; CHILD_2:
      ;--------------------------------------
      X_0 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['MAX GROWTH'])
      X_1 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['GAMMA 1'])
      X_2 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['MIR(1550-1750nm)','MIR(2080-2350nm)', $
        'NDVI','NDWI','MrVBF'])
      X_3 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['MIR(1550-1750nm)','MIR(2080-2350nm)', $
        'NDVI','NDWI','MrVBF'])
      X_4 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['MIR(1550-1750nm)','MIR(2080-2350nm)', $
        'NDVI','NDWI','MrVBF'])
      X_5 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['MIR(1550-1750nm)','MIR(2080-2350nm)', $
        'NDVI','NDWI','MrVBF'])
      X_6 = WIDGET_DROPLIST(CHILD_2, SCR_XSIZE=125, YSIZE=25, TITLE='*   ', VALUE=['MIR(1550-1750nm)','MIR(2080-2350nm)', $
        'NDVI','NDWI','MrVBF'])
      ;--------------------------------------
      BUTTON_BASE = WIDGET_BASE(CHILD_2, XPAD=0, YPAD=0, /COLUMN, /ALIGN_RIGHT)
        VALUES=['OK']
        OK = CW_BGROUP(BUTTON_BASE, VALUES, /RETURN_NAME)
      ;--------------------------------------
      WIDGET_CONTROL, GAMMA_0, /REALIZE
        RESULT_G0 = WIDGET_EVENT(GAMMA_0)
        VALUE_G0 = RESULT_G0.VALUE
        G0 = VALUE_G0[0]
      WIDGET_CONTROL, GAMMA_1, /REALIZE
        RESULT_G1 = WIDGET_EVENT(GAMMA_1)
        VALUE_G1 = RESULT_G1.VALUE
        G1 = VALUE_G1[0]
      WIDGET_CONTROL, GAMMA_2, /REALIZE
        RESULT_G2 = WIDGET_EVENT(GAMMA_2)
        VALUE_G2 = RESULT_G2.VALUE
        G2 = VALUE_G2[0]
      WIDGET_CONTROL, GAMMA_3, /REALIZE
        RESULT_G3 = WIDGET_EVENT(GAMMA_3)
        VALUE_G3 = RESULT_G3.VALUE
        G3 = VALUE_G3[0]
      WIDGET_CONTROL, GAMMA_4, /REALIZE
        RESULT_G4 = WIDGET_EVENT(GAMMA_4)
        VALUE_G4 = RESULT_G4.VALUE
        G4 = VALUE_G4[0]
      WIDGET_CONTROL, GAMMA_5, /REALIZE
        RESULT_G5 = WIDGET_EVENT(GAMMA_5)
        VALUE_G5 = RESULT_G5.VALUE
        G5 = VALUE_G5[0]
      WIDGET_CONTROL, GAMMA_6, /REALIZE
        RESULT_G6 = WIDGET_EVENT(GAMMA_6)
        VALUE_G6 = RESULT_G6.VALUE
        G6 = VALUE_G6[0]
      ;--------------------------------------
      WIDGET_CONTROL, X_2, /REALIZE
        RESULT_X2 = WIDGET_EVENT(X_2)
        VALUE_X2 = RESULT_X2.INDEX
        X2 = VALUE_X2[0]
      WIDGET_CONTROL, X_3, /REALIZE
        RESULT_X3 = WIDGET_EVENT(X_3)
        VALUE_X3 = RESULT_X3.INDEX
        X3 = VALUE_X3[0]
      WIDGET_CONTROL, X_4, /REALIZE
        RESULT_X4 = WIDGET_EVENT(X_4)
        VALUE_X4 = RESULT_X4.INDEX
        X4 = VALUE_X4[0]
      WIDGET_CONTROL, X_5, /REALIZE
        RESULT_X5 = WIDGET_EVENT(X_5)
        VALUE_X5 = RESULT_X5.INDEX
        X5 = VALUE_X5[0]
      WIDGET_CONTROL, X_6, /REALIZE
        RESULT_X6 = WIDGET_EVENT(X_6)
        VALUE_X6 = RESULT_X6.INDEX
        X6 = VALUE_X6[0]
      ;--------------------------------------
      BUTTON_RESULT = WIDGET_EVENT(BUTTON_BASE)
      BUTTON_VALUE = BUTTON_RESULT.VALUE
    IF BUTTON_VALUE EQ 'OK' THEN WIDGET_CONTROL, PARENT, /DESTROY
    ;--------------------------------------
    ; RETURN VALUES:
    RETURN, [DOUBLE(G0), DOUBLE(G1), DOUBLE(G2), DOUBLE(G3), DOUBLE(G4), DOUBLE(X2), DOUBLE(X3), DOUBLE(X4), $
      DOUBLE(G5), DOUBLE(G6), DOUBLE(X5), DOUBLE(X6)]
    ;-------------------------------------------------------------------------------------------
  ENDIF
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION EXTRACT_MODIS, X_ALL
  ;---------------------------------------------------------------------------------------------
  ; EXTRACT FILES (SURFACE REFLECTANCE)
  RED = X_ALL[WHERE(STRMATCH(X_ALL, '*b01*') EQ 1)]
  NIR = X_ALL[WHERE(STRMATCH(X_ALL, '*b02*') EQ 1)]
  MIR2 = X_ALL[WHERE(STRMATCH(X_ALL, '*b06*') EQ 1)]
  MIR3 = X_ALL[WHERE(STRMATCH(X_ALL, '*b07*') EQ 1)]
  ; EXTRACT FILES (QUALITY STATE)
  STATE = X_ALL[WHERE(STRMATCH(X_ALL, '*state*') EQ 1)]
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [RED, NIR, MIR2, MIR3, STATE]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION EXTRACT_LANDSAT, X_ALL
  ;---------------------------------------------------------------------------------------------
  ; EXTRACT FILES (SURFACE REFLECTANCE)
  RED = X_ALL[WHERE(STRMATCH(X_ALL, '*b3*') EQ 1)]
  NIR = X_ALL[WHERE(STRMATCH(X_ALL, '*b4*') EQ 1)]
  MIR2 = X_ALL[WHERE(STRMATCH(X_ALL, '*b5*') EQ 1)]
  MIR3 = X_ALL[WHERE(STRMATCH(X_ALL, '*b7*') EQ 1)]
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, [RED, NIR, MIR2, MIR3]
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION NORMALISED_RATIO, B1, B2
  ;---------------------------------------------------------------------------------------------
  ; CALCULATE NORMALISED RATIO:
  ;---------------------------------------------------------------------------------------------
  NORM = (B1 - B2) / (B1 + B2 * 1.0)
  RETURN, NORM
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION THREE_VARIABLE_MODEL, G0, G1, G2, G3, G4, X2, X3, X4
  ;---------------------------------------------------------------------------------------------
  ; SET FUNCTION
  Z = G1 + (G2 * X2) + (G3 * X3) + (G4 * X4)
  ;---------------------------------------------------------------------------------------------
  ; APPLY LOGISTIC MODEL
  OWL_OUT = G0 / (1 + EXP(Z))
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, OWL_OUT
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################


; ##############################################################################################
FUNCTION FIVE_VARIABLE_MODEL, G0, G1, G2, G3, G4, G5, G6, X2, X3, X4, X5, X6
  ;---------------------------------------------------------------------------------------------
  ; SET FUNCTION
  Z = G1 + (G2 * X2) + (G3 * X3) + (G4 * X4) + (G5 * X5) + (G6 * X6)
  ;---------------------------------------------------------------------------------------------
  ; APPLY LOGISTIC MODEL
  OWL_OUT = G0 / (1 + EXP(Z))
  ;---------------------------------------------------------------------------------------------
  ; RETURN VALUES:
  RETURN, OWL_OUT
  ;---------------------------------------------------------------------------------------------
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


;***********************************************************************************************
; FUNCTIONS: END
;***********************************************************************************************


PRO Open_Water_Mapping_DOIT_Apply_Logistic_Model
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: Open_Water_Mapping_DOIT_Apply_Logistic_Model'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT MrVBF DATA:
  IN_MrVBF = DIALOG_PICKFILE(PATH='\\blackhole-bu\H$', TITLE='SELECT INPUT MrVBF DATA', FILTER=['*.img'], /MUST_EXIST, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_MrVBF[0] EQ '' THEN RETURN
  ;--------------
  ; LOAD MrVBF
  MrVBF = READ_BINARY(IN_MrVBF, DATA_TYPE=4)
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT DATA:
  IN_FILES = ENVI_PICKFILE(TITLE='SELECT THE INPUT DATA', FILTER='*.img', /MULTIPLE_FILES)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;--------------
  ; GET FILENAME SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  FNS = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; GET THE a-TH FILE NAME
    FNS[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SET DATE TYPE:
  TITLE ='SELECT THE DATE TYPE'
  VALUES = ['DOY/YEAR', 'DD/MM/YYYY']
  TYPE_DATE = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;--------------
  IF TYPE_DATE EQ 0 THEN BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, DOY_STARTPOS, DOY_LENGTH)
    DMY = GET_FNAME_DMY_DOYYYYY(FNS, 8, 4, 13, 3)
  ENDIF ELSE BEGIN
    ; GET UNIQUE FILENAME DATES (FILENAME, YEAR_STARTPOS, YEAR_LENGTH, MONTH_STARTPOS, MONTH_LENGTH, DAY_STARTPOS, DAY_LENGTH)
    DMY = GET_FNAME_DMY_DDMMYYYY(FNS, 15, 4, 13, 2, 11, 2)
  ENDELSE
  ;--------------
  ; GET UNIQUE DATES
  UNIQ_DATE = DMY[UNIQ(DMY)]
  ; SORT DATES (ASCENDING)
  UNIQ_DATE = UNIQ_DATE[SORT(UNIQ_DATE)]
  ; GET UNIQUE DATES
  UNIQ_DATE = UNIQ_DATE[UNIQ(UNIQ_DATE)]
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE INPUT SENSOR
  TITLE ='SELECT THE INPUT SENSOR'
  VALUES = ['MODIS', 'LANDSAT']
  TYPE_SENSOR = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;--------------
  ; SET SENSOR NAME
  IF TYPE_SENSOR EQ 0 THEN SNAME = 'MODIS' ELSE SNAME = 'ls5tm'
  ;---------------------------------------------------------------------------------------------
  ; SET LANDSAT NODATA VALUE
  IF TYPE_SENSOR EQ 1 THEN BEGIN
    ;-----------------------------------
    TITLE ='SET A VALUE AS NODATA'
    VALUES = ['YES', 'NO']
    STATUS_NAN = RADIO_BUTTON_WIDGET(TITLE, VALUES)
    ;-----------------------------------
    ; SET THE NODATA VALUE
    IF STATUS_NAN EQ 0 THEN BEGIN
      TITLE = 'SET THE NODATA VALUE'
      NAN_VALUE = ENTER_VALUE_WIDGET(TITLE, 255.00)
    ENDIF
    ;-----------------------------------
  ENDIF ELSE STATUS_NAN = 1
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE MODEL
  TITLE ='SELECT THE MODEL'
  VALUES = ['THREE VARIABLE', 'FIVE VARIABLE']
  TYPE_MODEL = RADIO_BUTTON_WIDGET(TITLE, VALUES)
  ;--------------
  ; SET MODEL NAME
  IF TYPE_MODEL EQ 0 THEN MNAME = '3VariableModel' ELSE MNAME = '5VariableModel'
  ;---------------------------------------------------------------------------------------------
  ; DEFINE THE MODEL PARAMETERS:
  ;---------------------------------------------------------------------------------------------
  ; REPEAT...UNTIL STATEMENT:
  REPEAT BEGIN ; START 'REPEAT'
    ;-------------------------------------------------------------------------------------------
    MATRIX_MODEL = SET_MODEL_PARAMETERS(TYPE_MODEL)
    ;--------------------------------------
    IF TYPE_MODEL EQ 0 THEN BEGIN ; THREE VARIABLE MODEL
      ;--------------------------------------
      ; SET VARIABLES
      LIST=['NDVI','NDWI','MrVBF']
      X_2 = LIST[STRTRIM(LONG(MATRIX_MODEL[5]), 2)]
      X_3 = LIST[STRTRIM(LONG(MATRIX_MODEL[6]), 2)]
      X_4 = LIST[STRTRIM(LONG(MATRIX_MODEL[7]), 2)]
      ;--------------
      ; SET PARAMETERS
      GAMMA_0 = MATRIX_MODEL[0]
      GAMMA_1 = MATRIX_MODEL[1]
      GAMMA_2 = MATRIX_MODEL[2]
      GAMMA_3 = MATRIX_MODEL[3]
      GAMMA_4 = MATRIX_MODEL[4]
      ;--------------------------------------
    ENDIF ELSE BEGIN ; FIVE VARIABLE MODEL
      ;--------------------------------------
      ; SET VARIABLES
      LIST=['MIR(1550-1750nm)','MIR(2080-2350nm)','NDVI','NDWI','MrVBF']
      X_2 = LIST[STRTRIM(LONG(MATRIX_MODEL[5]), 2)]
      X_3 = LIST[STRTRIM(LONG(MATRIX_MODEL[6]), 2)]
      X_4 = LIST[STRTRIM(LONG(MATRIX_MODEL[7]), 2)]
      X_5 = LIST[STRTRIM(LONG(MATRIX_MODEL[10]), 2)]
      X_6 = LIST[STRTRIM(LONG(MATRIX_MODEL[11]), 2)]
      ;--------------
      ; SET PARAMETERS
      GAMMA_0 = MATRIX_MODEL[0]
      GAMMA_1 = MATRIX_MODEL[1]
      GAMMA_2 = MATRIX_MODEL[2]
      GAMMA_3 = MATRIX_MODEL[3]
      GAMMA_4 = MATRIX_MODEL[4]
      GAMMA_5 = MATRIX_MODEL[8]
      GAMMA_6 = MATRIX_MODEL[9]
      ;--------------------------------------
    ENDELSE
    ;--------------------------------------
    ; PRINT INFORMATION
    PRINT, '  '
    PRINT, '  (GAMMA 0 = ', STRTRIM(GAMMA_0, 2), ') * (X 0 = ', 'MAX GROWTH', ')'
    PRINT, '  (GAMMA 1 = ', STRTRIM(GAMMA_1, 2), ') * (X 1 = ', 'GAMMA 1', ')'
    PRINT, '  (GAMMA 2 = ', STRTRIM(GAMMA_2, 2), ') * (X 2 = ', X_2, ')'
    PRINT, '  (GAMMA 3 = ', STRTRIM(GAMMA_3, 2), ') * (X 3 = ', X_3, ')'
    PRINT, '  (GAMMA 4 = ', STRTRIM(GAMMA_4, 2), ') * (X 4 = ', X_4, ')'
    IF TYPE_MODEL EQ 1 THEN BEGIN
      PRINT, '  (GAMMA 5 = ', STRTRIM(GAMMA_5, 2), ') * (X 5 = ', X_5, ')'
      PRINT, '  (GAMMA 6 = ', STRTRIM(GAMMA_6, 2), ') * (X 6 = ', X_6, ')'
    ENDIF
    PRINT, '  '
    ;--------------------------------------
    ; CHECK THE MODEL PARAMETERS
    TITLE ='IS THIS CORRECT'
    VALUES = ['YES', 'NO']
    CHECK_P = RADIO_BUTTON_WIDGET(TITLE, VALUES)
    ;--------------
    ; IF CHECK_P = 0 THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
    ;-------------------------------------------------------------------------------------------
  ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; DATE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(UNIQ_DATE)-1 DO BEGIN
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET FILES:
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
    INDEX = WHERE(DMY EQ UNIQ_DATE[i], COUNT)
    ;--------------
    ; GET FILES
    FILES_IN = IN_FILES[INDEX]
    ;--------------
    ; GET FILES SHORT
    FNS_IN = FNS[INDEX]
    ;-------------------------------------------------------------------------------------------
    ; GET DATA:
    ;-------------------------------------------------------------------------------------------
    ; GET SURFACE REFLECTANCE FILES
    IF TYPE_SENSOR EQ 0 THEN BANDS = EXTRACT_MODIS(FILES_IN) ELSE BANDS = EXTRACT_LANDSAT(FILES_IN)
    ;--------------
    ; SET DATATYPE
    IF TYPE_SENSOR EQ 0 THEN DT=2 ELSE DT=4
    ;--------------
    ; SET BANDS
    RED_IN = BANDS[0]
    NIR_IN = BANDS[1]
    MIR2_IN = BANDS[2]
    MIR3_IN = BANDS[3]
    IF TYPE_SENSOR EQ 0 THEN STATE_IN = BANDS[4]
    ;--------------
    ; LOAD DATA
    RED = READ_BINARY(RED_IN, DATA_TYPE=DT)
    NIR = READ_BINARY(NIR_IN, DATA_TYPE=DT)
    MIR2 = READ_BINARY(MIR2_IN, DATA_TYPE=DT)
    MIR3 = READ_BINARY(MIR3_IN, DATA_TYPE=DT)
    IF TYPE_SENSOR EQ 0 THEN STATE = READ_BINARY(STATE_IN, DATA_TYPE=DT)
    ;-------------------------------------------------------------------------------------------
    ; CHECK LANDSAT NODATA STATUS
    IF (TYPE_SENSOR EQ 1) AND (STATUS_NAN EQ 0) THEN BEGIN
      ;--------------------------------------
      ; SET RED NAN
      a = WHERE(RED EQ FLOAT(NODATA), COUNT_a)
      IF (COUNT_a GT 0) THEN RED[a] = !VALUES.F_NAN
      ; SET NIR NAN
      b = WHERE(NIR EQ FLOAT(NODATA), COUNT_b)
      IF (COUNT_b GT 0) THEN NIR[b] = !VALUES.F_NAN
      ; SET MIR2 NAN
      c = WHERE(MIR2 EQ FLOAT(NODATA), COUNT_c)
      IF (COUNT_c GT 0) THEN MIR2[c] = !VALUES.F_NAN
      ; SET MIR3 NAN
      d = WHERE(MIR3 EQ FLOAT(NODATA), COUNT_d)
      IF (COUNT_d GT 0) THEN MIR3[d] = !VALUES.F_NAN
      ;--------------------------------------
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; SET MODIS FILL (-32768)
    IF (TYPE_SENSOR EQ 0) THEN BEGIN
      ;--------------------------------------
      ; CONVERT TO FLOAT
      RED = FLOAT(RED)
      NIR = FLOAT(NIR)
      MIR2 = FLOAT(MIR2)
      MIR3 = FLOAT(MIR3)
      ;--------------------------------------
      ; SET NAN FOR FILL VALUES
      a = WHERE(RED EQ FLOAT(-32768), COUNT_a)
      IF (COUNT_a GT 0) THEN RED[a] = !VALUES.F_NAN
      b = WHERE(NIR EQ FLOAT(-32768), COUNT_b)
      IF (COUNT_b GT 0) THEN NIR[b] = !VALUES.F_NAN
      c = WHERE(MIR2 EQ FLOAT(-32768), COUNT_c)
      IF (COUNT_c GT 0) THEN MIR2[c] = !VALUES.F_NAN
      d = WHERE(MIR3 EQ FLOAT(-32768), COUNT_d)
      IF (COUNT_d GT 0) THEN MIR3[d] = !VALUES.F_NAN
      ;--------------------------------------
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; CALCULATE INDICIES:
    ;-------------------------------------------------------------------------------------------
    ; CALCULATE NDVI
    NDVI = NORMALISED_RATIO(NIR, RED)
    ;--------------
    ; CALCULATE NDWI
    NDWI = NORMALISED_RATIO(NIR, MIR2)
    ;-------------------------------------------------------------------------------------------
    ; CALCULATE OWL:
    ;-------------------------------------------------------------------------------------------
    ; SET BANDS:
    IF X_2 EQ 'NDVI' THEN X2 = NDVI
    IF X_2 EQ 'NDWI' THEN X2 = NDWI
    IF X_2 EQ 'MrVBF' THEN X2 = MrVBF
    IF X_2 EQ 'MIR(1550-1750nm)' THEN X2 = MIR2
    IF X_2 EQ 'MIR(2080-2350nm)' THEN X2 = MIR3
    ;--------------
    IF X_3 EQ 'NDVI' THEN X3 = NDVI
    IF X_3 EQ 'NDWI' THEN X3 = NDWI
    IF X_3 EQ 'MrVBF' THEN X3 = MrVBF
    IF X_3 EQ 'MIR(1550-1750nm)' THEN X3 = MIR2
    IF X_3 EQ 'MIR(2080-2350nm)' THEN X3 = MIR3
    ;--------------
    IF X_4 EQ 'NDVI' THEN X4 = NDVI
    IF X_4 EQ 'NDWI' THEN X4 = NDWI
    IF X_4 EQ 'MrVBF' THEN X4 = MrVBF
    IF X_4 EQ 'MIR(1550-1750nm)' THEN X4 = MIR2
    IF X_4 EQ 'MIR(2080-2350nm)' THEN X4 = MIR3
    ;--------------
    IF TYPE_MODEL EQ 1 THEN BEGIN
      ;--------------------------------------
      IF X_5 EQ 'NDVI' THEN X5 = NDVI
      IF X_5 EQ 'NDWI' THEN X5 = NDWI
      IF X_5 EQ 'MrVBF' THEN X5 = MrVBF
      IF X_5 EQ 'MIR(1550-1750nm)' THEN X5 = MIR2
      IF X_5 EQ 'MIR(2080-2350nm)' THEN X5 = MIR3
      ;--------------
      IF X_6 EQ 'NDVI' THEN X6 = IN_NDVI
      IF X_6 EQ 'NDWI' THEN X6 = IN_NDWI
      IF X_6 EQ 'MrVBF' THEN X6 = MrVBF
      IF X_6 EQ 'MIR(1550-1750nm)' THEN X6 = MIR2
      IF X_6 EQ 'MIR(2080-2350nm)' THEN X6 = MIR3
      ;--------------------------------------
    ENDIF
    ;--------------------------------------
    ; APPLY LOGISTIC MODEL:
    IF TYPE_MODEL EQ 0 THEN OWL = THREE_VARIABLE_MODEL(GAMMA_0, GAMMA_1, GAMMA_2, GAMMA_3, GAMMA_4, X2, X3, X4)
    IF TYPE_MODEL EQ 1 THEN OWL = FIVE_VARIABLE_MODEL(GAMMA_0, GAMMA_1, GAMMA_2, GAMMA_3, GAMMA_4, GAMMA_5, GAMMA_6, X2, X3, X4, X5, X6)
    ;-------------------------------------------------------------------------------------------
    ; APPLY MODIS CLOUD MASK:
    ;-------------------------------------------------------------------------------------------
    IF TYPE_SENSOR EQ 0 THEN BEGIN
      ;--------------------------------------
      ; REPLACE FILL CELLS
      INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
      IF (COUNT_FILL GT 0) THEN OWL[INDEX_FILL] = 255.00
      ;--------------
      ; REPLACE CLOUD CELLS ["Cloud"= 0000000000000001]
      INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1)
      IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN OWL[INDEX_CLOUD] = 255.00
      ;--------------
      ; REPLACE MIXED CLOUD CELLS ["MIXED"= 0000000000000010]
      INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
      IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN OWL[INDEX_MIXED] = 255.00
      ;--------------
      ; REPLACE CLOUD SHADOW CELLS ["Cloud_Shadow"= 0000000000000100]
      INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
      IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN OWL[INDEX_SHADOW] = 255.00
      ;--------------------------------------
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; SET NAN TO 255
    n = WHERE(FINITE(OWL, /NAN), COUNT_NAN)
    IF (COUNT_NAN GT 0) THEN OWL[n] = 255.00
	  ;--------------
    ; CONVERT TO BYTE
    OWL = BYTE((OWL LT 255) * (OWL+0.005) * 100.00 + (OWL EQ 255) * 255.00)
    ;-------------------------------------------------------------------------------------------
    ; WRITE DATA:
    ;-------------------------------------------------------------------------------------------
    ; SET THE OUTPUT FILE NAME
    FILE_OUT = OUT_DIRECTORY + SNAME + '.OWL.' + MNAME + '.' + STRTRIM(iY, 2) + STRTRIM(DOY, 2) +  '.img'
    ;--------------
    ; CREATE THE OUTPUT FILE
    OPENW, UNIT_OWL, FILE_OUT, /GET_LUN
    ;--------------
    ; CLOSE THE NEW FILES
    FREE_LUN, UNIT_OWL
    ;--------------------------------------
    ; OPEN THE OUTPUT FILE
    OPENU, UNIT_OWL, FILE_OUT, /GET_LUN, /APPEND
    ;--------------
    ; WRITE DATA
    WRITEU, UNIT_OWL, OWL
    ;--------------
    ; CLOSE THE OUTPUT FILE
    FREE_LUN, UNIT_OWL
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR DATE ', STRTRIM(i+1, 2), ' OF ', STRTRIM(N_ELEMENTS(UNIQ_DATE), 2)
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
  PRINT,'FINISHED PROCESSING: Open_Water_Mapping_DOIT_Apply_Logistic_Model'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END