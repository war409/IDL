; ######################################################################
; NAME: TOPOGRAPHIC_MODELING.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren 
; DATE: 08/12/2009
; DLM: 04/01/2010
; DESCRIPTION: THIS TOOL PERFORMS TOPOGRAPHIC MODELING ON INPUT ELEVATION 
;              DATA. 
; INPUT: ONE DEM OR SIMILAR.
; OUTPUT: ONE MULTI-BAND TOPOGRAHIC MODEL IMAGE.
; PARAMETERS: VIA WIDGETS.
; NOTES: SLOPE AND PERCENT OF SLOPE ARE CREATED AS DEFAULT. THE USER MAY
;        CREATE ADDITIONAL TOPOGRAPHIC LAYERS.
; ######################################################################
; 
PRO TOPOGRAPHIC_MODELING
  ; GET START TIME FOR WHOLE
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: TOPOGRAPHIC_MODELING'
  PRINT,''
  ;---------------------------------------------------------------------
  ; SET THE INPUT FILE
  INFILE = ENVI_PICKFILE(TITLE='Select Input File')
  ; ERROR CHECK
  IF INFILE EQ '' THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED INPUT FILE IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ;---------------------------------------------------------------------
  ; GET INPUT FILE COUNT
  FILE_COUNT = N_ELEMENTS(INFILE)
  ;---------------------------------------------------------------------
  ; SET THE OUTPUT PATH
  OUTPATH = ENVI_PICKFILE(TITLE='Select Output Folder', /DIRECTORY)
  ;---------------------------------------------------------------------
  ; SET DEM UNIT TYPE
  BASE = WIDGET_AUTO_BASE(TITLE='Select The DEM Unit Method')
  LIST=['XYZ Use The Same Units', $
        'XYZ Do Not Use The Same Units: XY Degrees; Z Meters']
  WM = WIDGET_MENU(BASE, LIST=LIST, UVALUE='DEMTYPE', ROWS=2, /AUTO)
  RESULT = AUTO_WID_MNG(BASE) 
  IF (RESULT.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTION IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF ELSE BEGIN
    DEMTYPE = RESULT.DEMTYPE
  ENDELSE
  ;---------------------------------------------------------------------
  ; SET TOPO BPTR
  BASE2 = WIDGET_AUTO_BASE(TITLE='Select Which Topographic Data To Create')
  LIST2=['Aspect', 'Shaded relief', 'Profile convexity', 'Plan convexity', $
    'Longitudinal convexity', 'Cross-sectional convexity', 'Minimum curvature', $
    'Maximum curvature','RMS']
  WM2 = WIDGET_MENU(BASE2, LIST=LIST2, UVALUE='TopoTYPE', ROWS=2, /AUTO)
  RESULT2 = AUTO_WID_MNG(BASE2) 
  IF (RESULT.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTION IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF ELSE BEGIN
    TopoTYPE = RESULT2.TopoTYPE
  ENDELSE
  ;---------------------------------------------------------------------
  ; SELECT OUTPUT TYPE: IDL RADIO-BUTTON WIDGET
  VALUES = ['Single Multi-Band File', 'Multiple Single-Band File']
  BASE3 = WIDGET_BASE(TITLE='IDL', /ROW) 
  BGROUP = CW_BGROUP(BASE3, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', $
    LABEL_TOP='SELECT OUTPUT TYPE')
  WIDGET_CONTROL, BASE3, /REALIZE
  EV = WIDGET_EVENT(BASE3)
  OUTTYPE = EV.VALUE
  WIDGET_CONTROL, BASE3, /DESTROY
  ;---------------------------------------------------------------------
  ; OPEN INPUT FILE
  ENVI_OPEN_FILE, INFILE, R_FID=FID
  ;---------------------------------------------------------------------
  ; QUERY THE CURRENT FILE BY FID
  ENVI_FILE_QUERY, FID, SNAME=SNAME, DIMS=INDIMS, BNAMES=BNAME, NS=NS, NL=NL
  ;---------------------------------------------------------------------
  ; GET ENVI TOPOGRAPHIC OUTPUTS...     
  ;---------------------------------------------------------------------
  ; SET OUTPUT BAND NAME LIST
  OUT_BNAMES_IN = ['Aspect', 'Shaded.Relief','Profile.Convexity','Plan.Convexity', $
    'Longitudinal.Convexity', 'Cross.sectional.Convexity', 'Minimum.Curvature', $
    'Maximum.Curvature','RMS']
  BNAMES_ARR = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  BNAMES_INARR = TopoTYPE*BNAMES_ARR
  OUT_BNAMES_POS = WHERE(BNAMES_INARR GT 0)
  OUT_BNAMES_LIST = OUT_BNAMES_IN[OUT_BNAMES_POS]
  OUT_BNAMES = ['Degree.Slope', OUT_BNAMES_LIST]
  ;---------------------------------------------------------------------
  ; GET BPTR ARRAY
  BPTR_ARR = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  BPTR_INARR = TopoTYPE*BPTR_ARR
  BPTR_POS1 = WHERE(BPTR_INARR GT 0)
  BPTR_POS2 = BPTR_ARR[BPTR_POS1]
  OUT_BPTR = [0, BPTR_POS2]
  ;---------------------------------------------------------------------
  ; GET Z FACTOR...
  ;---------------------------------------------------------------------
  ; GET INPUT FILE PROJECTION AND MAP INFORMATION
  PROJ = ENVI_GET_PROJECTION(FID=FID, PIXEL_SIZE=PIXEL_SIZE)
  MAP_INFO = ENVI_GET_MAP_INFO(FID=FID)  
  LONSTART = MAP_INFO.mc[2] ; CX
  LATSTART = MAP_INFO.mc[3] ; CY
  NCOL = NS ; CX
  NROW = NL ; CY
  PIXELX = PIXEL_SIZE[0]
  PIXELY = PIXEL_SIZE[1]
  ;---------------------------------------------------------------------
  IF (DEMTYPE[0] NE 1) AND (DEMTYPE[1] NE 0) THEN BEGIN
    ;-------------------------------------------------------------------
    ; GET MIDDLE COORDINATES
    LONEND = (LONSTART+(PIXELX*NCOL))-PIXELX
    LATEND = (LATSTART-(PIXELY*NROW))+PIXELY
    LONMID = LONSTART+((LONEND-LONSTART)/2)
    LATMID = LATSTART+((LATEND-LATSTART)/2)
    ; CONVERT MIDDLE LATITUDE TO RADIANS
    ; LONMIDRAD = LONMID*0.0174532925
    LONMIDRAD = EOS_EH_CONVANG(LONMID, 1)
    ; LATMIDRAD = -LATMID*0.0174532925
    LATMIDRAD = EOS_EH_CONVANG(LATMID, 1)
    ; GET Z FACTOR LON
    ZFACTORLON = 1.00/(113200.00*COS(LONMIDRAD))
    ; GET Z FACTOR LAT
    ZFACTORLAT = 1.00/(113200.00*COS(LATMIDRAD))
    ; GET LON PIXEL SIZE IN METERS
    SIZEX = PIXELX/ZFACTORLON
    IF SIZEX LT 0 THEN SIZEX = -SIZEX
    ; GET LAT PIXEL SIZE IN METERS
    SIZEY = PIXELY/ZFACTORLAT
    IF SIZEY LT 0 THEN SIZEY = -SIZEY
    ;-------------------------------------------------------------------
    ; APPLY TOPOGRAPHIC MODEL
    ENVI_DOIT, 'TOPO_DOIT', AZIMUTH=23.0, DIMS=INDIMS, ELEVATION=67.0, FID=FID, OUT_BNAME=OUT_BNAMES, $
      OUT_NAME=OUT_NAME, PIXEL_SIZE=[SIZEX,SIZEY], POS=[0], R_FID=R_FID1, BPTR=OUT_BPTR, /IN_MEMORY
    ;-------------------------------------------------------------------
  ENDIF ELSE BEGIN
    ;-------------------------------------------------------------------
    ; APPLY TOPOGRAPHIC MODEL
    ENVI_DOIT, 'TOPO_DOIT', AZIMUTH=23.0, DIMS=INDIMS, ELEVATION=67.0, FID=FID, OUT_BNAME=OUT_BNAMES, $
      OUT_NAME='TEMP1', PIXEL_SIZE=[PIXELX,PIXELY], POS=[0], R_FID=R_FID1, BPTR=OUT_BPTR, /IN_MEMORY
    ;-------------------------------------------------------------------
  ENDELSE
  ;---------------------------------------------------------------------
  ; GET PERCENT OF SLOPE...
  ;---------------------------------------------------------------------
  ; BUILD EXPRESSION
  EXP = '(TAN(B1*0.0174532925)*100)'
  ;---------------------------------------------------------------------
  ; APPLY EXPRESSION
  ENVI_DOIT, 'MATH_DOIT', DIMS=INDIMS, EXP=EXP, FID=R_FID1, OUT_BNAME=['Percent.Slope'], $
    OUT_NAME='TEMP2', POS=[0], R_FID=R_FID2, /IN_MEMORY
  ;---------------------------------------------------------------------
  ; WRITE DATA TO OUTPUT...
  ;---------------------------------------------------------------------
  IF OUTTYPE EQ 0 THEN BEGIN
    ;-------------------------------------------------------------------
    ; BUILD THE OUTPUT FILENAME
    OUTFILE = OUTPATH + '\' + SNAME + '.Topo.img'
    ;-------------------------------------------------------------------
    ; QUERY THE TEMP OUTPUT FILES
    ENVI_FILE_QUERY, R_FID1, NS=NS1, NL=NL1, NB=NB1, BNAMES=BNAMES1, DATA_TYPE=DATATYPE
    ENVI_FILE_QUERY, R_FID2, NS=NS2, NL=NL2, NB=NB2, BNAMES=BNAMES2, DATA_TYPE=DATATYPE
    ;-------------------------------------------------------------------
    ; BUILD THE FID & POS ARRAY
    NB3 = NB1 + NB2
    FID3 = LONARR(NB3)
    POS3 = LONARR(NB3)
    FOR j=0, NB1-1 DO BEGIN
      FID3[j] = R_FID1
      POS3[j] = j
    ENDFOR
    FOR j=NB1, NB3-1 DO BEGIN
      FID3[j] = R_FID2
      POS3[j] = j-NB1
    ENDFOR
    FID3 = [FID3,FID]
    POS3=[POS3,0]
    BNAMES_OUT = [BNAMES1,BNAMES2,SNAME]
    ;-------------------------------------------------------------------
    ; WRITE TO OUTPUT
    ENVI_DOIT, 'CF_DOIT', FID=FID3, DIMS=INDIMS, POS=POS3, $
      OUT_DT=DATATYPE, OUT_NAME=OUTFILE, R_FID=R_FID3, OUT_BNAME=BNAMES_OUT
    ;-------------------------------------------------------------------
    ; CLOSE FILES IN MEMORY
    ENVI_FILE_MNG, ID=FID, /REMOVE
    ENVI_FILE_MNG, ID=R_FID1, /REMOVE 
    ENVI_FILE_MNG, ID=R_FID2, /REMOVE
    ;-------------------------------------------------------------------
  ENDIF ELSE BEGIN ; 'Multiple Single-Band File'
    ;-------------------------------------------------------------------
    ; QUERY THE TEMP OUTPUT FILES
    ENVI_FILE_QUERY, R_FID1, NS=NS1, NL=NL1, NB=NB1, BNAMES=BNAMES1, DATA_TYPE=DATATYPE
    ENVI_FILE_QUERY, R_FID2, NS=NS2, NL=NL2, NB=NB2, BNAMES=BNAMES2, DATA_TYPE=DATATYPE
    ;-------------------------------------------------------------------
    ; BUILD THE FID & POS ARRAY
    NB3 = NB1 + NB2
    FID3 = LONARR(NB3)
    POS3 = LONARR(NB3)
    FOR j=0, NB1-1 DO BEGIN
      FID3[j] = R_FID1
      POS3[j] = j
    ENDFOR
    FOR j=NB1, NB3-1 DO BEGIN
      FID3[j] = R_FID2
      POS3[j] = j-NB1
    ENDFOR
    FID3 = [FID3,FID]
    POS3=[POS3,0]
    BNAMES_OUT = [BNAMES1,BNAMES2,SNAME]
    ;-----------------------------------------------------------------
    ; OUTPUT FILE & BAND LOOP:
    ;-----------------------------------------------------------------
    FIDCOUNT = N_ELEMENTS(FID3)-1
    FOR j=0, FIDCOUNT-1 DO BEGIN ; START 'FOR j'
      ;--------------------------------------------------------------- 
      ; SAVE BAND TO OUTPUT:
      ;--------------------------------------------------------------- 
      ; GET FID
      OFID = FID3[j]
      ; GET POS      
      OPOS = POS3[j]
      ; GET BAND NAME
      BANDNAME = BNAMES_OUT[j]
      ;--------------------------------------------------------------- 
      ; BUILD OUTNAME
      OUTNAME = OUTPATH + '\' + BANDNAME + '.img'
      ;---------------------------------------------------------------
      ; WRITE DATA
      ENVI_DOIT, 'CF_DOIT', FID=OFID, DIMS=INDIMS, POS=OPOS, OUT_DT=DATATYPE, $
        OUT_NAME=OUTNAME, R_FID=RFID, OUT_BNAME=BANDNAME, /NO_REALIZE
      ;---------------------------------------------------------------
    ENDFOR ; END 'FOR j' 
    ;-------------------------------------------------------------------
  ENDELSE 
  ;---------------------------------------------------------------------
  PRINT,''
  ; PRINT THE PROCESSING TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  PRINT, '  TOTAL PROCESSING TIME:  ', STRTRIM(MINUTES, 2), ' MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: TOPOGRAPHIC_MODELING'
  PRINT,'' 
END
  