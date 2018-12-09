

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


PRO OPEN_WATER_HARDCODE

    ; SET MrVBF
    IN_MrVBF='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics\MrVBF\SRTM.DEM.3s.01.MrVBF.Aust.500m.img'
    ; LOAD MrVBF
    MrVBF = READ_BINARY(IN_MrVBF, DATA_TYPE=4)
    
    
    BANDS = EXTRACT_MODIS(FILES_IN)
    
    ;-------------------------------------------------------------------------------------------
    ; SET BANDS: (Full filename and path, for a specific date)
    ;--------------
    RED_IN = BAND[0]
    NIR_IN = BAND[1]
    MIR2_IN = BAND[2]
    MIR3_IN = BAND[3]
    STATE_IN = BAND[4]
    ;--------------------------------------
    ; LOAD DATA
    RED = READ_BINARY(RED_IN, DATA_TYPE=2)
    NIR = READ_BINARY(NIR_IN, DATA_TYPE=2)
    MIR2 = READ_BINARY(MIR2_IN, DATA_TYPE=2)
    MIR3 = READ_BINARY(MIR3_IN, DATA_TYPE=2)
    STATE = READ_BINARY(STATE_IN, DATA_TYPE=2)
    ;-------------------------------------------------------------------------------------------
    ; CONVERT TO FLOAT (To set NAN)
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
    ;-------------------------------------------------------------------------------------------
    ; CALCULATE INDICIES
    NDVI = NORMALISED_RATIO(NIR, RED)
    NDWI = NORMALISED_RATIO(NIR, MIR2)
    ;-------------------------------------------------------------------------------------------
    ; CALCULATE OPEN WATER (APPLY MODEL)
    OWL = FIVE_VARIABLE_MODEL(1.00, -3.4137561, -0.000959735270, 0.00417955330, 14.1927990, $
      -0.430407140, -0.0961932990, MIR2, MIR3, NDVI, NDWI, MrVBF)
    ;-------------------------------------------------------------------------------------------
    ; APPLY MODIS CLOUD MASK:
    ;--------------
    ; REPLACE 'FILL' CELLS
    INDEX_FILL = WHERE(STATE EQ FLOAT(65535), COUNT_FILL)
    IF (COUNT_FILL GT 0) THEN OWL[INDEX_FILL] = 255.00
    ;--------------
    ; REPLACE 'CLOUD CELLS' ["Cloud"= 0000000000000001]
    INDEX_CLOUD = BITWISE_OPERATOR_AND(STATE, 1, 1, 2, 0, 1)
    IF (N_ELEMENTS(INDEX_CLOUD) GT 1) THEN OWL[INDEX_CLOUD] = 255.00
    ;--------------
    ; REPLACE 'MIXED CLOUD' CELLS ["MIXED"= 0000000000000010]
    INDEX_MIXED = BITWISE_OPERATOR(STATE, 3, 2, 1)
    IF (N_ELEMENTS(INDEX_MIXED) GT 1) THEN OWL[INDEX_MIXED] = 255.00
    ;--------------
    ; REPLACE 'CLOUD SHADOW' CELLS ["Cloud_Shadow"= 0000000000000100]
    INDEX_SHADOW = BITWISE_OPERATOR(STATE, 4, 0, 0)
    IF (N_ELEMENTS(INDEX_SHADOW) GT 1) THEN OWL[INDEX_SHADOW] = 255.00
    ;-------------------------------------------------------------------------------------------
    ; SET NAN TO 255
    n = WHERE(FINITE(OWL, /NAN), COUNT_NAN)
    IF (COUNT_NAN GT 0) THEN OWL[n] = 255.00
    ;-------------------------------------------------------------------------------------------
    ; CONVERT TO BYTE
    OWL = BYTE((OWL LT 255) * (OWL+0.005) * 100.00 + (OWL EQ 255) * 255.00)
    ;-------------------------------------------------------------------------------------------
    ; WRITE DATA:
    ;--------------
    ; SET THE OUTPUT FILENAME (Adds output path, year, and day of year strings)
    FILE_OUT = OUT_DIRECTORY + 'MOD09A1.005.AUST.OWL.' + STRTRIM(iY, 2) + STRTRIM(DOY, 2) +  '.img'
    ;--------------------------------------
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
    

END