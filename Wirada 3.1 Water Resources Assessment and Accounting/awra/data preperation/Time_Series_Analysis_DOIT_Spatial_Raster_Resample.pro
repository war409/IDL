; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Spatial_Raster_Resample.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 18/02/2010
; DLM: 04/03/2010 - NODATA Function added
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
; PARAMETERS:  Via widgets. The user may choose whether to use the cell
;              size of an existing file, or enter the new cell size
;              manually. If the user opts to use the cell size of an
;              existing file the user may also select whether or not to
;              align (snap cells) the output with the existing file.
;
;              'SELECT THE INPUT FILES'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SELECT NODATA STATUS'
;              'SET THE NODATA VALUE'
;              'SELECT THE RESIZE TYPE'
;              'DEFINE THE OUTPUT CELL SIZE' or 'SELECT AN EXISTING FILE'
;              'SELECT THE ALIGNMENT TYPE'
;              'SELECT THE RESIZE METHOD'
;
; NOTES:       The input data must have identical dimensions. Each input
;              file must have an associated ENVI header file (.hdr), see:
;              'Time_Series_Analysis_DOIT_Create_ENVI_Header_Files.pro'
;
;              RESAMPLING METHODS;
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
PRO Time_Series_Analysis_DOIT_Spatial_Raster_Resample
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Spatial_Raster_Resample'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE INPUT TIME-SERIES
  INPUT = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics', $
    TITLE='SELECT THE INPUT TIME-SERIES', FILTER=['*.tif','*.img','*.flt','*.bin'], /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SORT FILE LIST
  INPUT = INPUT[SORT(INPUT)]
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUTFOLDER = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics', $
    TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SET THE NODATA STATUS
  VALUES = ['ENTER A NODATA VALUE', 'DO NOT ENTER A NODATA VALUE']
  BASE = WIDGET_BASE(TITLE='IDL WIDGET', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, UVALUE='BUTTON', LABEL_TOP='SELECT NODATA STATUS', $
    /COLUMN, /EXCLUSIVE)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  STATUS = RESULT.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  IF STATUS EQ 0 THEN BEGIN
    BASE = WIDGET_BASE(TITLE='IDL WIDGET')
    FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=255, TITLE='SET THE NODATA VALUE  ', /RETURN_EVENTS)
    WIDGET_CONTROL, BASE, /REALIZE
    RESULT = WIDGET_EVENT(BASE)
    NODATA1 = RESULT.VALUE
    NODATA = NODATA1[0]
    WIDGET_CONTROL, BASE, /DESTROY
  ENDIF
  ;-------------------------------------------------------------------------
  ; SET FILE COUNT
  FCOUNT = N_ELEMENTS(INPUT)
  ;-------------------------------------------------------------------------
  ; GET THE FIRST FILE IN THE LIST
  IN_FIRST = INPUT[0]
  ;-------------------------------------------------------------------------
  ; OPEN FILE
  ENVI_OPEN_FILE, IN_FIRST, R_FID=FID_FIRST, /NO_REALIZE
  ;-------------------------------------------------------------------------
  ; QUERY FILE
  ENVI_FILE_QUERY, FID_FIRST, DIMS=DIMS_IN, NS=NS_IN, NL=NL_IN, NB=NB_IN, $
    INTERLEAVE=INTERLEAVE_IN, DATA_TYPE=DATATYPE_IN, XSTART=XSTART_IN, $
    FILE_TYPE=FILE_TYPE_IN,YSTART=YSTART_IN, OFFSET=OFFSET_IN, $
    DATA_OFFSETS=DATA_OFFSETS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN
  ;-------------------------------------------------------------------------
  ; GET MAP INFORMATION
  MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_FIRST)
  PROJ_FULL_IN = MAPINFO_IN.PROJ
  DATUM_IN = MAPINFO_IN.PROJ.DATUM
  PROJ_IN = MAPINFO_IN.PROJ.NAME
  UNITS_IN = MAPINFO_IN.PROJ.UNITS
  SIZEX_IN = FLOAT(MAPINFO_IN.PS[0])
  SIZEY_IN = FLOAT(MAPINFO_IN.PS[1])
  CXUL_IN = FLOAT(MAPINFO_IN.MC[2])
  CYUL_IN = FLOAT(MAPINFO_IN.MC[3])
  LOCX_IN = FLOAT(MAPINFO_IN.MC[0])
  LOCY_IN = FLOAT(MAPINFO_IN.MC[1])
  ;-------------------------------------------------------------------------
  ;------------------------------------------------------------------------
  ; SELECT AN EXISTING FILE
  IN_EXAMPLE = DIALOG_PICKFILE(PATH='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics', $
    TITLE='SELECT AN EXISTING FILE', /MUST_EXIST, /OVERWRITE_PROMPT)
  ;-----------------------------------------------------------------------
  ; OPEN FILE
  ENVI_OPEN_FILE, IN_EXAMPLE, R_FID=FID_EXAMPLE, /NO_REALIZE
  ;-----------------------------------------------------------------------
  ; QUERY FILE
  ENVI_FILE_QUERY, FID_EXAMPLE, DIMS=DIMS_EXAMPLE, NS=NS_EXAMPLE, NL=NL_EXAMPLE, NB=NB_EXAMPLE, $
    INTERLEAVE=INTERLEAVE_EXAMPLE, DATA_TYPE=DATATYPE_EXAMPLE, XSTART=XSTART_EXAMPLE, $
    FILE_TYPE=FILE_TYPE_EXAMPLE,YSTART=YSTART_EXAMPLE, OFFSET=OFFSET_EXAMPLE, DATA_OFFSETS=DATA_OFFSETS_EXAMPLE
  ;----------------------------------------------------------------------
  ; GET MAP INFORMATION ; EXAMPLE RASTER
  MAPINFO_EXAMPLE = ENVI_GET_MAP_INFO(FID=FID_EXAMPLE)
  DATUM_EXAMPLE = MAPINFO_EXAMPLE.PROJ.DATUM
  PROJ_EXAMPLE = MAPINFO_EXAMPLE.PROJ.NAME
  UNITS_EXAMPLE = MAPINFO_EXAMPLE.PROJ.UNITS
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
  ;------------------------------------------------------------------------
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
    ; GET THE CURRENT INPUT FILE
    INFILE = INPUT[i]
    ;-----------------------------------------------------------------------
    ; GET FILENAME FROM NAME & PATH
    START = STRPOS(INFILE, '\', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(INFILE)-START)-4
    FNAME = STRMID(INFILE, START, LENGTH)
    INPATH = STRMID(INFILE, 0, START)
    OUTPATH = OUTFOLDER
    ;-----------------------------------------------------------------------
    ; OPEN FILE
    ENVI_OPEN_FILE, INFILE, R_FID=FID_IN1, /NO_REALIZE
    ;-----------------------------------------------------------------------
    ; QUERY FILE
    ENVI_FILE_QUERY, FID_IN1, DATA_TYPE=DATATYPE_IN
    ;-----------------------------------------------------------------------
    ; SET REBIN FACTORS
    RFACTX = SIZEX_OUT/SIZEX_IN
    RFACTY = SIZEY_OUT/SIZEY_IN
    RFACT = [RFACTX, RFACTY]
    ;-----------------------------------------------------------------------
    ; GET DATA
    DATA_IN = ENVI_GET_DATA(FID=FID_IN1, DIMS=DIMS_IN, POS=0)
    ;-----------------------------------------------------------------------
    ; SET NAN
    IF STATUS EQ 0 THEN BEGIN
      ;---------------------------------------------------------------------
      ; DATA TYPE CHECK
      IF DATATYPE_IN LT 4 THEN DATA_IN = FLOAT(DATA_IN)
      ;---------------------------------------------------------------------
      ; SET NAN
      k = WHERE(DATA_IN EQ FLOAT(NODATA), COUNT)
      IF (COUNT GT 0) THEN DATA_IN[k] = !VALUES.F_NAN
      ;---------------------------------------------------------------------
    ENDIF
    ;-----------------------------------------------------------------------
    ; BUILD TEMP FILE NAME
    OUTNAME_IN = OUTPATH + FNAME + '.NAN.TEMP' + '.img'
    OUTNAME_INHDR = OUTPATH + FNAME + '.NAN.TEMP' + '.hdr'
    ;-----------------------------------------------------------------------
    ; WRITE DATA TO A TEMPORARY FILE
    ENVI_WRITE_ENVI_FILE, DATA_IN, MAP_INFO=MAPINFO_IN, OUT_NAME=OUTNAME_IN, $
      PIXEL_SIZE=[SIZEX_IN, SIZEY_IN], OUT_DT=DATATYPE_IN, NS=NS_IN, NL=NL_IN, $
      NB=NB_IN, FILE_TYPE=FILE_TYPE_IN, OFFSET=OFFSET_IN, UNITS=UNITS_IN, /NO_OPEN
    ;-----------------------------------------------------------------------
    ; OPEN NEW INPUT FILE
    ENVI_OPEN_FILE, OUTNAME_IN, R_FID=FID_IN2, /NO_REALIZE
    ;-----------------------------------------------------------------------
    ;-----------------------------------------------------------------------
    IF SNAPTYPE EQ 0 THEN BEGIN
      ;*********************************************************************
      ; RESIZE INPUT DATA: ALIGN CELLS
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; RESAMPLE
      ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN2, DIMS=DIMS_IN, INTERP=RESIZEMETHOD, $
        POS=0, R_FID=FID_OUT, RFACT=RFACT, /IN_MEMORY, /NO_REALIZE
      ;---------------------------------------------------------------------
      ; QUERY RESIZED FILE
      ENVI_FILE_QUERY, FID_OUT, DIMS=DIMS_OUT, NS=NS_OUT, NL=NL_OUT, NB=NB_OUT, $
        INTERLEAVE=INTERLEAVE_OUT, DATA_TYPE=DATATYPE_OUT, XSTART=XSTART_OUT, $
        FILE_TYPE=FILE_TYPE_OUT,YSTART=YSTART_OUT, OFFSET=OFFSET_OUT, DATA_OFFSETS=DATA_OFFSETS_OUT
      ;---------------------------------------------------------------------
      ; GET MAP INFORMATION
      MAPINFO_TMP = ENVI_GET_MAP_INFO(FID=FID_OUT)
      PROJ_FULL_TMP = MAPINFO_TMP.PROJ
      DATUM_TMP = MAPINFO_TMP.PROJ.DATUM
      PROJ_TMP = MAPINFO_TMP.PROJ.NAME
      UNITS_TMP = MAPINFO_TMP.PROJ.UNITS
      SIZEX_TMP = FLOAT(MAPINFO_TMP.PS[0])
      SIZEY_TMP = FLOAT(MAPINFO_TMP.PS[1])
      CXUL_TMP = FLOAT(MAPINFO_TMP.MC[2])
      CYUL_TMP = FLOAT(MAPINFO_TMP.MC[3])
      LOCX_TMP = FLOAT(MAPINFO_TMP.MC[0])
      LOCY_TMP = FLOAT(MAPINFO_TMP.MC[1])
      ;---------------------------------------------------------------------
      ; GET NEW COORDINATE Y ORIGIN
      DiffY = FLOAT(CYUL_TMP-CYUL_EXAMPLE)
      DYovCellY = ROUND(DiffY/SIZEY_TMP)
      ShiftY = FLOAT(((DYovCellY*SIZEY_TMP)+CYUL_EXAMPLE)-CYUL_TMP)
      CYUL_NEW = FLOAT(CYUL_TMP+ShiftY)
      ;---------------------------------------------------------------------
      ; GET NEW COORDINATE X ORIGIN
      DiffX = FLOAT(CXUL_TMP-CXUL_EXAMPLE)
      DXovCellX = ROUND(DiffX/SIZEX_TMP)
      ShiftX = FLOAT(((DXovCellX*SIZEX_TMP)+CXUL_EXAMPLE)-CXUL_TMP)
      CXUL_NEW = FLOAT(CXUL_TMP+ShiftX)
      ;---------------------------------------------------------------------
      ; CREATE NEW MAP INFORMATION
      PS = [SIZEX_OUT, SIZEY_OUT]
      MC = [LOCX_IN, LOCY_IN, CXUL_NEW, CYUL_NEW]
      MAPINFO_NEW = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=PROJ_FULL_TMP, UNITS=UNITS_TMP, $
        DATUM=DATUM_TMP, /GEOGRAPHIC)
      ;---------------------------------------------------------------------
      ; GET DATA
      DATA_TMP = ENVI_GET_DATA(FID=FID_OUT, DIMS=DIMS_OUT, POS=0)
      ;---------------------------------------------------------------------
      ; BUILD OUTNAME
      OUTNAME = OUTPATH + FNAME + '.RESAMPLE' + '.SNAP' + '.img'
      ;---------------------------------------------------------------------
      ; WRITE DATA WITH NEW MAP INFORMATION
      ENVI_WRITE_ENVI_FILE, DATA_TMP, MAP_INFO=MAPINFO_NEW, OUT_NAME=OUTNAME, $
        BNAMES=BNAME_OUT, PIXEL_SIZE=[SIZEX_OUT,SIZEY_OUT], OUT_DT=DATATYPE_OUT, $
        NS=NS_OUT, NL=NL_OUT, NB=NB_OUT, FILE_TYPE=FILE_TYPE_OUT, OFFSET=OFFSET_OUT, $
        UNITS=UNITS_TMP, /NO_OPEN
      ;---------------------------------------------------------------------
    ENDIF ELSE BEGIN
      ;*********************************************************************
      ; RESIZE INPUT DATA: DO NOT ALIGN CELLS
      ;*********************************************************************
      ;---------------------------------------------------------------------
      ; BUILD OUTNAME
      OUTNAME = OUTPATH + FNAME + '.RESAMPLE' + '.img'
      ;---------------------------------------------------------------------
      ; RESAMPLE
      ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN2, DIMS=DIMS_IN, INTERP=RESIZEMETHOD, $
        OUT_NAME=OUTNAME, POS=0, R_FID=RFID, RFACT=RFACT, /NO_REALIZE
      ;---------------------------------------------------------------------
    ENDELSE
    ;-----------------------------------------------------------------------
    ; DELETE THE NAN TEMP FILE
    FILE_DELETE, OUTNAME_IN
    FILE_DELETE, OUTNAME_INHDR
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
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Spatial_Raster_Resample'
  PRINT,''
  ;-------------------------------------------------------------------------
END
