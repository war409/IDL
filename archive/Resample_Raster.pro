; ##########################################################################
; NAME: Resample_Raster.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 18/02/2010
; DLM: 18/02/2010
; 
; DESCRIPTION: This tool alters the proportions of a raster dataset by 
;              changing the cell size. The extent of the output raster
;              will remain the same unless the user selects the 'ALIGN 
;              CELLS WITH THE EXISTING FILE' option, in which case the 
;              extents will move the minimum distance to ensure that the 
;              cell alignment of the output matches the existing raster.
;              
; INPUT:       One or more single-band or multi-band image files. 
; 
; OUTPUT:      One new file per input.
; 
; PARAMETERS:  Via widgets. The user may select whether to use the cell
;              size of an existing file, or enter the new cell size
;              manually. If the user opts to use the cell size of an 
;              existing file the user may also select whether or not to
;              align (snap cells) the output with the existing file.   
;      
;              'SELECT THE INPUT TYPE'
;              'SELECT THE INPUT FILE' or 'SELECT THE INPUT FILES'   
;              'SELECT THE RESIZE TYPE'
;              'DEFINE THE OUTPUT CELL SIZE' or 'SELECT AN EXISTING FILE'
;              'SELECT THE ALIGNMENT TYPE'
;              'SELECT THE RESIZE METHOD'     
;                          
; NOTES:       RESAMPLING METHODS
;        
;              The user may select one of four interpolation 
;              methods. When 'down' sampling data you should use
;              either NEAREST NEIGHBOUR or PIXEL AGGREGATE.
;              NEAREST NEIGHBOUR assignment will determine the location  
;                of the closest cell centre  on the input raster and   
;                assign the value of that cell to the cell on the output.
;              BILINEAR INTERPOLATION uses the value of the four nearest 
;                input cell centers to determine the value on the output. 
;              CUBIC CONVOLUTION is similar to bilinear interpolation 
;                except the weighted average is calculated from the 16 
;                nearest input cell centres and their values.
;              PIXEL AGGREGATE uses the average of the surrounding pixels 
;                to determine the output value.
;                
; ##########################################################################
; 
PRO Resample_Raster
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Resample_Raster'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE INPUT TYPE
  VALUES = ['ONE FILE', 'MORE THAN ONE FILE']
  BASE = WIDGET_BASE(TITLE='IDL', /ROW)  
  BGROUP = CW_BGROUP(BASE, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', $
    LABEL_TOP='SELECT THE INPUT TYPE')
  WIDGET_CONTROL, BASE, /REALIZE
  EV = WIDGET_EVENT(BASE)
  INTYPE = EV.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SELECT THE INPUT DATA: 
  ;-------------------------------------------------------------------------
  ; SELECT SINGLE FILE 
  IF INTYPE EQ 0 THEN BEGIN
    INPUT = DIALOG_PICKFILE(PATH='C:\', TITLE='SELECT THE INPUT FILE', /MUST_EXIST, /OVERWRITE_PROMPT)
  ENDIF
  ;-------------------------------------------------------------------------
  ; SELECT MULTIPLE FILES   
  IF INTYPE EQ 1 THEN BEGIN
    INPUT = DIALOG_PICKFILE(PATH='C:\', TITLE='SELECT THE INPUT FILES', /MULTIPLE_FILES, /MUST_EXIST, /OVERWRITE_PROMPT)
  ENDIF
  ;-------------------------------------------------------------------------
  ; SET FILE COUNT
  FCOUNT = N_ELEMENTS(INPUT)
  ;-------------------------------------------------------------------------
  ; SELECT RESIZE TYPE
  VALUES = ['ENTER THE OUTPUT CELL SIZE', 'SELECT AN EXISTING FILE']
  BASE = WIDGET_BASE(TITLE='IDL', /ROW)  
  BGROUP = CW_BGROUP(BASE, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', LABEL_TOP='SELECT THE RESIZE TYPE')
  WIDGET_CONTROL, BASE, /REALIZE
  EV = WIDGET_EVENT(BASE)
  RESIZETYPE = EV.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  IF RESIZETYPE EQ 0 THEN BEGIN
    ;-----------------------------------------------------------------------
    ; SET PARAMETER
    PA_BASE = WIDGET_AUTO_BASE(TITLE='ENVI IDL')
    WO_PA = WIDGET_PARAM(PA_BASE, DT=2, UVALUE='PARAM', $
      PROMPT='DEFINE THE OUTPUT CELL SIZE', XSIZE=25, /AUTO)
    RESULT_PA = AUTO_WID_MNG(PA_BASE)
    IF (RESULT_PA.ACCEPT EQ 0) THEN BEGIN
      PRINT,''
      PRINT, 'THE SELECTED PARAMETER IS NOT VALID'
      PRINT,''
      RETURN
    ENDIF ELSE BEGIN
      SIZEX_OUT = FLOAT(RESULT_PA.PARAM)
      SIZEY_OUT = FLOAT(RESULT_PA.PARAM)
      SNAPTYPE = 1
    ENDELSE
    ;-----------------------------------------------------------------------
  ENDIF ELSE BEGIN
    ;-----------------------------------------------------------------------
    ; SELECT AN EXISTING FILE 
    IN_EXAMPLE = DIALOG_PICKFILE(PATH='C:\', TITLE='SELECT AN EXISTING FILE', /MUST_EXIST, /OVERWRITE_PROMPT)
    ;-----------------------------------------------------------------------
    ; OPEN FILE
    ENVI_OPEN_FILE, IN_EXAMPLE, /NO_REALIZE, R_FID=FID_EXAMPLE
    ;-----------------------------------------------------------------------
    ; QUERY FILE
    ENVI_FILE_QUERY, FID_EXAMPLE, DIMS=INDIMS, NS=NS, NL=NL, DATA_TYPE=DATATYPE
    ;----------------------------------------------------------------------
    ; GET MAP INFORMATION ; EXAMPLE RASTER
    MAPINFO_EXAMPLE = ENVI_GET_MAP_INFO(FID=FID_EXAMPLE) 
    DATUM_EXAMPLE = MAPINFO_EXAMPLE.PROJ.DATUM
    PROJ_EXAMPLE = MAPINFO_EXAMPLE.PROJ.NAME
    SIZEX_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.PS[0])
    SIZEY_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.PS[1])    
    CXUL_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[2])
    CYUL_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[3])
    ;----------------------------------------------------------------------
    ; SET THE OUTPUT CELL SIZE
    SIZEX_OUT = SIZEX_EXAMPLE
    SIZEY_OUT = SIZEY_EXAMPLE
    ;----------------------------------------------------------------------
    ; SELECT THE ALIGNMENT TYPE
    VALUES = ['ALIGN CELLS WITH THE EXISTING FILE', 'DO NOT ALIGN CELLS WITH THE EXISTING FILE']
    BASE = WIDGET_BASE(TITLE='IDL', /ROW)  
    BGROUP = CW_BGROUP(BASE, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', LABEL_TOP='SELECT THE ALIGNMENT TYPE')
    WIDGET_CONTROL, BASE, /REALIZE
    EV = WIDGET_EVENT(BASE)
    SNAPTYPE = EV.VALUE
    WIDGET_CONTROL, BASE, /DESTROY   
    ;----------------------------------------------------------------------
  ENDELSE
  ;------------------------------------------------------------------------
  ; SELECT THE RESIZE METHOD
  VALUES = ['NEAREST NEIGHBOUR', 'BILINEAR INTERPOLATION', 'CUBIC CONVOLUTION', 'PIXEL AGGREGATE']
  BASE = WIDGET_BASE(TITLE='IDL', /ROW)  
  BGROUP = CW_BGROUP(BASE, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', LABEL_TOP='SELECT THE RESIZE METHOD')
  WIDGET_CONTROL, BASE, /REALIZE
  EV = WIDGET_EVENT(BASE)
  RESIZEMETHOD = EV.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  FOR i=0, FCOUNT-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET INPUT FILE
    INFILE = INPUT[i]
    ;-----------------------------------------------------------------------
    ; GET FILENAME FROM NAME & PATH
    START = STRPOS(INFILE, '\', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(INFILE)-START)-4
    FNAME = STRMID(INFILE, START, LENGTH)
    INPATH = STRMID(INFILE, 0, START)
    ;-----------------------------------------------------------------------
    ; OPEN FILE
    ENVI_OPEN_FILE, INFILE, /NO_REALIZE, R_FID=FID_IN 
    ;-----------------------------------------------------------------------
    ; QUERY FILE ; IF MULTI-BAND LOOP THROUGH BANDS
    ENVI_FILE_QUERY, FID_IN, DIMS=INDIMS2, BNAMES=BNAME2, NS=NS2, NL=NL2, NB=NB2, DATA_TYPE=DATATYPE2
    ;-----------------------------------------------------------------------
    ; GET MAP INFORMATION
    MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_IN)
    PROJ_FULL_IN = MAPINFO_IN.PROJ
    DATUM_IN = MAPINFO_IN.PROJ.DATUM
    PROJ_IN = MAPINFO_IN.PROJ.NAME
    SIZEX_IN = FLOAT(MAPINFO_IN.PS[0])
    SIZEY_IN = FLOAT(MAPINFO_IN.PS[1])    
    CXUL_IN = FLOAT(MAPINFO_IN.MC[2])
    CYUL_IN = FLOAT(MAPINFO_IN.MC[3])
    LOCX_IN = FLOAT(MAPINFO_IN.MC[0])
    LOCY_IN = FLOAT(MAPINFO_IN.MC[1])
    ;-----------------------------------------------------------------------
    ; SET REBIN FACTORS
    RFACTX = SIZEX_OUT/SIZEX_IN
    RFACTY = SIZEY_OUT/SIZEY_IN
    RFACT = [RFACTX, RFACTY]
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; RESIZE BY-BAND PER-FILE
    ;***********************************************************************
    IF NB2 GT 1 THEN BEGIN
      ;---------------------------------------------------------------------
      ; CREATE FID ARRAY
      FIDARR = LONARR(NB2)
      ; CREATE BAND NAME ARRAY
      BNAMEARR = STRARR(NB2)
      ; CREATE POS ARRAYS
      POSARR = LONARR(NB2)
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; BAND LOOP: FILL PER-FILE BAND INFORMATION ARRAYS
      ;*********************************************************************
      FOR j=0, NB2-1 DO BEGIN ; START 'FOR j'
        ;-------------------------------------------------------------------
        ; GET BAND NAME
        BNAMEOUT = BNAME2[j]       
        ;-------------------------------------------------------------------
        ; RESAMPLE EACH BAND
        ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN, DIMS=INDIMS2, INTERP=RESIZEMETHOD, $
          OUT_BNAME=BNAMEOUT, /IN_MEMORY, POS=j, R_FID=FID_OUT, RFACT=RFACT 
        ;-------------------------------------------------------------------   
        ; FILL ARRAYS
        FIDARR[j] = FID_OUT
        BNAMEARR[j] = BNAMEOUT
        POSARR[j] = 0
        ;-------------------------------------------------------------------  
      ENDFOR ; END 'FOR j'
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; RESIZE INPUT DATA: ALIGN CELLS
      ;*********************************************************************
      IF SNAPTYPE EQ 0 THEN BEGIN
        ;-------------------------------------------------------------------
        ; QUERY RESIZED FILE
        ENVI_FILE_QUERY, FIDARR, DIMS=INDIMS2B
        ;-------------------------------------------------------------------
        ; WRITE DATA
        ENVI_DOIT, 'CF_DOIT', FID=FIDARR, DIMS=INDIMS2B, POS=POSARR, OUT_DT=DATATYPE2, $
          R_FID=FID_OUT2, OUT_BNAME=BNAMEARR, /NO_REALIZE, /IN_MEMORY
        ;-------------------------------------------------------------------
        ; QUERY RESIZED FILE
        ENVI_FILE_QUERY, FID_OUT2, SNAME=SNAME3, DIMS=INDIMS3, BNAMES=BNAME3, NS=NS3, $
          NL=NL3, NB=NB3, DATA_TYPE=DATATYPE3
        ;-------------------------------------------------------------------          
        ; GET MAP INFORMATION
        MAPINFO_TMP = ENVI_GET_MAP_INFO(FID=FID_OUT2)
        PROJ_FULL_TMP = MAPINFO_TMP.PROJ
        DATUM_TMP = MAPINFO_TMP.PROJ.DATUM
        PROJ_TMP = MAPINFO_TMP.PROJ.NAME
        SIZEX_TMP = FLOAT(MAPINFO_TMP.PS[0])
        SIZEY_TMP = FLOAT(MAPINFO_TMP.PS[1])    
        CXUL_TMP = FLOAT(MAPINFO_TMP.MC[2])
        CYUL_TMP = FLOAT(MAPINFO_TMP.MC[3])
        LOCX_TMP = FLOAT(MAPINFO_TMP.MC[0])
        LOCY_TMP = FLOAT(MAPINFO_TMP.MC[1])
        ;-------------------------------------------------------------------        
        ; GET NEW COORDINATE Y ORIGIN
        DiffY = FLOAT(CYUL_TMP-CYUL_EXAMPLE)
        DYovCellY = ROUND(DiffY/SIZEY_TMP)
        ShiftY = FLOAT(((DYovCellY*SIZEY_TMP)+CYUL_EXAMPLE)-CYUL_TMP)
        CYUL_NEW = FLOAT(CYUL_TMP+ShiftY)
        ;-------------------------------------------------------------------
        ; GET NEW COORDINATE X ORIGIN
        DiffX = FLOAT(CXUL_TMP-CXUL_EXAMPLE)
        DXovCellX = ROUND(DiffX/SIZEX_TMP)
        ShiftX = FLOAT(((DXovCellX*SIZEX_TMP)+CXUL_EXAMPLE)-CXUL_TMP)
        CXUL_NEW = FLOAT(CXUL_TMP+ShiftX)
        ;-------------------------------------------------------------------
        ; CREATE NEW MAP INFORMATION
        PS = [SIZEX_OUT, SIZEY_OUT]
        MC = [LOCX_IN, LOCY_IN, CXUL_NEW, CYUL_NEW]
        MAPINFO_NEW = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=PROJ_FULL_IN, /GEOGRAPHIC)
        ;-------------------------------------------------------------------
        ; CREATE FID ARRAY
        FIDARR2 = LONARR(NB2)
        ; CREATE POS ARRAYS
        POSARR2 = LONARR(NB2)
        ;-------------------------------------------------------------------
        ;*******************************************************************
        ; BAND LOOP: ALIGN EACH BAND
        ;*******************************************************************
        FOR k=0, NB2-1 DO BEGIN ; START 'FOR k'
          ;-----------------------------------------------------------------
          ; GET DATA
          DATA_TMP = ENVI_GET_DATA(FID=FID_OUT2, DIMS=INDIMS3, POS=k)
          ;-----------------------------------------------------------------
          ; WRITE DATA WITH NEW MAP INFORMATION
          ENVI_WRITE_ENVI_FILE, DATA_TMP, MAP_INFO=MAPINFO_NEW, /IN_MEMORY, $
            PIXEL_SIZE=[SIZEX_OUT,SIZEY_OUT], OUT_DT=DATATYPE3, $
            NS=NS3, NL=NL3, R_FID=FID_OUT3, /NO_OPEN
          ;-----------------------------------------------------------------
          ; FILL ARRAYS
          FIDARR2[k] = FID_OUT3
          POSARR2[k] = 0
          ;-----------------------------------------------------------------  
        ENDFOR ; END 'FOR j'
        ;-------------------------------------------------------------------
        ; BUILD OUTNAME
        OUTNAME = INPATH + FNAME + '.RESAMPLE' + '.SNAP' + '.img'
        ;-------------------------------------------------------------------
        ; WRITE DATA (RESIZE FILE)
        ENVI_DOIT, 'CF_DOIT', FID=FIDARR2, DIMS=INDIMS3, POS=POSARR2, OUT_DT=DATATYPE3, $
          R_FID=FID_OUT2, OUT_BNAME=BNAME3, /NO_REALIZE, OUT_NAME=OUTNAME
        ;-------------------------------------------------------------------
      ENDIF ELSE BEGIN
        ;*******************************************************************
        ; RESIZE INPUT DATA: DO NOT ALIGN CELLS
        ;*******************************************************************
        ;-------------------------------------------------------------------
        ; BUILD OUTNAME
        OUTNAME = INPATH + FNAME + '.RESAMPLE' + '.img'
        ;-------------------------------------------------------------------
        ; QUERY RESIZED FILE
        ENVI_FILE_QUERY, FIDARR, DIMS=INDIMS2B, DATA_TYPE=DATATYPE2B
        ;-------------------------------------------------------------------        
        ; WRITE DATA (RESIZE FILE)
        ENVI_DOIT, 'CF_DOIT', FID=FIDARR, DIMS=INDIMS2B, POS=POSARR, OUT_DT=DATATYPE2B, $
          OUT_NAME=OUTNAME, R_FID=RFID, OUT_BNAME=BNAMEARR, /NO_REALIZE
        ;-------------------------------------------------------------------
      ENDELSE
      ;---------------------------------------------------------------------
    ENDIF ELSE BEGIN
      ;*********************************************************************
      ; RESIZE BY-FILE
      ;*********************************************************************
      ;---------------------------------------------------------------------
      IF SNAPTYPE EQ 0 THEN BEGIN
        ;*******************************************************************
        ; RESIZE INPUT DATA: ALIGN CELLS
        ;*******************************************************************
        ;-------------------------------------------------------------------
        ; RESAMPLE
        ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN, DIMS=INDIMS2, INTERP=RESIZEMETHOD, $
          OUT_BNAME=BNAME2, /IN_MEMORY, POS=0, R_FID=FID_OUT2, RFACT=RFACT 
        ;-------------------------------------------------------------------
        ; QUERY RESIZED FILE
        ENVI_FILE_QUERY, FID_OUT2, SNAME=SNAME3, DIMS=INDIMS3, BNAMES=BNAME3, NS=NS3, $
          NL=NL3, NB=NB3, DATA_TYPE=DATATYPE3
        ;-------------------------------------------------------------------          
        ; GET MAP INFORMATION
        MAPINFO_TMP = ENVI_GET_MAP_INFO(FID=FID_OUT2)
        PROJ_FULL_TMP = MAPINFO_TMP.PROJ
        DATUM_TMP = MAPINFO_TMP.PROJ.DATUM
        PROJ_TMP = MAPINFO_TMP.PROJ.NAME
        SIZEX_TMP = FLOAT(MAPINFO_TMP.PS[0])
        SIZEY_TMP = FLOAT(MAPINFO_TMP.PS[1])    
        CXUL_TMP = FLOAT(MAPINFO_TMP.MC[2])
        CYUL_TMP = FLOAT(MAPINFO_TMP.MC[3])
        LOCX_TMP = FLOAT(MAPINFO_TMP.MC[0])
        LOCY_TMP = FLOAT(MAPINFO_TMP.MC[1])
        ;-------------------------------------------------------------------        
        ; GET NEW COORDINATE Y ORIGIN
        DiffY = FLOAT(CYUL_TMP-CYUL_EXAMPLE)
        DYovCellY = ROUND(DiffY/SIZEY_TMP)
        ShiftY = FLOAT(((DYovCellY*SIZEY_TMP)+CYUL_EXAMPLE)-CYUL_TMP)
        CYUL_NEW = FLOAT(CYUL_TMP+ShiftY)
        ;-------------------------------------------------------------------
        ; GET NEW COORDINATE X ORIGIN
        DiffX = FLOAT(CXUL_TMP-CXUL_EXAMPLE)
        DXovCellX = ROUND(DiffX/SIZEX_TMP)
        ShiftX = FLOAT(((DXovCellX*SIZEX_TMP)+CXUL_EXAMPLE)-CXUL_TMP)
        CXUL_NEW = FLOAT(CXUL_TMP+ShiftX)
        ;-------------------------------------------------------------------
        ; CREATE NEW MAP INFORMATION
        PS = [SIZEX_OUT, SIZEY_OUT]
        MC = [LOCX_IN, LOCY_IN, CXUL_NEW, CYUL_NEW]
        MAPINFO_NEW = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=PROJ_FULL_IN, /GEOGRAPHIC)
        ;-------------------------------------------------------------------
        ; GET DATA
        DATA_TMP = ENVI_GET_DATA(FID=FID_OUT2, DIMS=INDIMS3, POS=0)
        ;-------------------------------------------------------------------
        ; BUILD OUTNAME
        OUTNAME = INPATH + FNAME + '.RESAMPLE' + '.SNAP' + '.img'
        ;-------------------------------------------------------------------
        ; WRITE DATA WITH NEW MAP INFORMATION
        ENVI_WRITE_ENVI_FILE, DATA_TMP, MAP_INFO=MAPINFO_NEW, OUT_NAME=OUTNAME, $
          BNAMES=BNAME3, PIXEL_SIZE=[SIZEX_OUT,SIZEY_OUT], OUT_DT=DATATYPE3, $
          NS=NS3, NL=NL3, NB=NB3, /NO_OPEN
        ;-------------------------------------------------------------------
      ENDIF ELSE BEGIN
        ;*******************************************************************
        ; RESIZE INPUT DATA: DO NOT ALIGN CELLS
        ;*******************************************************************
        ;-------------------------------------------------------------------
        ; BUILD OUTNAME
        OUTNAME = INPATH + FNAME + '.RESAMPLE' + '.img'
        ;-------------------------------------------------------------------
        ; RESAMPLE    
        ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN, DIMS=INDIMS2, INTERP=RESIZEMETHOD, $
          OUT_BNAME=BNAME2, OUT_NAME=OUTNAME, POS=0, R_FID=RFID, RFACT=RFACT
        ;-------------------------------------------------------------------
      ENDELSE
      ;---------------------------------------------------------------------
    ENDELSE
    ;-----------------------------------------------------------------------
    ; PRINT END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    PRINT, ''
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2),'  SECONDS, FOR FILE: ', STRTRIM(i+1, 2), ' OF ', STRTRIM(FCOUNT, 2)
    ;-----------------------------------------------------------------------   
  ENDFOR ; END 'FOR i'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Resample_Raster'
  PRINT,''
  ;-------------------------------------------------------------------------
END 