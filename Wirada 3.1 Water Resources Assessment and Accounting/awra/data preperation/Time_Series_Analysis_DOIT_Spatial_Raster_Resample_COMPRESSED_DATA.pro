; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Spatial_Raster_Resample_COMPRESSED_DATA.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 10/03/2010
; DLM: 10/03/2010
;
; DESCRIPTION: This tool alters the proportions of a raster dataset by
;              changing the cell size. The extent of the output raster
;              will remain the same unless the user selects the 'ALIGN
;              CELLS WITH THE EXISTING FILE' option, in which case the
;              extents will move the minimum distance to ensure that the
;              cell alignment of the output matches the existing raster.
;              
;              This tool differs from 
;              Time_Series_Analysis_DOIT_Spatial_Raster_Resample.pro in that
;              the input data is in compressed format.
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
PRO Time_Series_Analysis_DOIT_Spatial_Raster_Resample_COMPRESSED_DATA
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Spatial_Raster_Resample_COMPRESSED_DATA'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SELECT THE INPUT DIRECTORY
  IN_DIR = DIALOG_PICKFILE(PATH='\\File-wron\Working\work\war409\Work\Imagery\MODIS\PV',$
    TITLE='SELECT THE INPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  OUT_DIR = DIALOG_PICKFILE(PATH='\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Observed\MODIS\pv\resample',$
    TITLE='SELECT THE OUTPUT DIRECTORY', /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------------------------------------------------------------------
  ; SET THE EXAMPLE INPUT FILE:
  IN_EX = '\\File-wron\Working\work\war409\Work\Imagery\Template\FractCover.2000.049.aust.005.PV.img'
  ;-------------------------------------------------------------------------
  ; SET THE EXAMPLE OUTPUT FILE:
  OUT_EX = '\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Modelled\SurfWet\Median8Day\2004001.img'
  ;-------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  BASE = WIDGET_BASE(TITLE='IDL WIDGET')
  FIELD = CW_FIELD(BASE, XSIZE=8, VALUE=255, TITLE='SET THE NODATA VALUE ', /RETURN_EVENTS)
  WIDGET_CONTROL, BASE, /REALIZE
  RESULT = WIDGET_EVENT(BASE)
  NODATA1 = RESULT.VALUE
  NODATA = NODATA1[0]
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; SELECT THE RESIZE METHOD
  VALUES = ['NEAREST NEIGHBOUR', 'BILINEAR INTERPOLATION', 'CUBIC CONVOLUTION', 'PIXEL AGGREGATE']
  BASE = WIDGET_BASE(TITLE='IDL', /ROW)
  BGROUP = CW_BGROUP(BASE, VALUES, /COLUMN, /EXCLUSIVE, UVALUE='BUTTON', LABEL_TOP='SELECT THE RESIZE METHOD')
  WIDGET_CONTROL, BASE, /REALIZE
  EV = WIDGET_EVENT(BASE)
  RESIZEMETHOD = EV.VALUE
  WIDGET_CONTROL, BASE, /DESTROY
  ;-------------------------------------------------------------------------
  ; GET FILE INFORMATION FOR THE RESAMPLE PROCESS:
  ;-------------------------------------------------------------------------
  ; OPEN THE EXAMPLE INPUT FILE
  ENVI_OPEN_FILE, IN_EX, R_FID=FID_INEX, /NO_REALIZE
  ;-------------------------------------------------------------------------
  ; QUERY THE EXAMPLE INPUT FILE
  ENVI_FILE_QUERY, FID_INEX, DIMS=DIMS_IN, NS=NS_IN, NL=NL_IN, NB=NB_IN, $
    INTERLEAVE=INTERLEAVE_IN, DATA_TYPE=DATATYPE_IN, XSTART=XSTART_IN, $
    FILE_TYPE=FILE_TYPE_IN,YSTART=YSTART_IN, OFFSET=OFFSET_IN, $
    DATA_OFFSETS=DATA_OFFSETS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN
  ;-------------------------------------------------------------------------
  ; GET MAP INFORMATION
  MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_INEX)
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
  ; OPEN THE EXAMPLE OUTPUT FILE
  ENVI_OPEN_FILE, OUT_EX, R_FID=FID_OUTEX, /NO_REALIZE
  ;-----------------------------------------------------------------------
  ; QUERY THE EXAMPLE OUTPUT FILE
  ENVI_FILE_QUERY, FID_OUTEX, DIMS=DIMS_EXAMPLE, NS=NS_EXAMPLE, NL=NL_EXAMPLE, NB=NB_EXAMPLE, $
    INTERLEAVE=INTERLEAVE_EXAMPLE, DATA_TYPE=DATATYPE_EXAMPLE, XSTART=XSTART_EXAMPLE, $
    FILE_TYPE=FILE_TYPE_EXAMPLE,YSTART=YSTART_EXAMPLE, OFFSET=OFFSET_EXAMPLE, DATA_OFFSETS=DATA_OFFSETS_EXAMPLE
  ;----------------------------------------------------------------------
  ; GET MAP INFORMATION
  MAPINFO_EXAMPLE = ENVI_GET_MAP_INFO(FID=FID_OUTEX)
  DATUM_EXAMPLE = MAPINFO_EXAMPLE.PROJ.DATUM
  PROJ_EXAMPLE = MAPINFO_EXAMPLE.PROJ.NAME
  UNITS_EXAMPLE = MAPINFO_EXAMPLE.PROJ.UNITS
  SIZEX_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.PS[0])
  SIZEY_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.PS[1])
  CXUL_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[2])
  CYUL_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[3])
  LOCX_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[0])
  LOCY_EXAMPLE = FLOAT(MAPINFO_EXAMPLE.MC[1])
  ;----------------------------------------------------------------------
  ; SET THE OUTPUT CELL SIZE
  SIZEX_OUT = SIZEX_EXAMPLE
  SIZEY_OUT = SIZEY_EXAMPLE
  ;-------------------------------------------------------------------------
  ; SET INPUT FILES:
  ;-------------------------------------------------------------------------
  ; SET WORKSPACE
  CD, 'C:'
  CD, '/Documents and Settings/war409'
  ; CHANGE THE WORKING DIRECTORY
  CD, IN_DIR, CURRENT=OWD
  ; GET LIST OF FILES IN THE WORKING DIRECTORY                  ** DEFINE **
  IN_FILES = FILE_SEARCH('*005.PV.img.gz')
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ; SET FILE COUNT
  COUNT_F = N_ELEMENTS(IN_FILES)
  ; RESET THE WORKING DIRECTORY
  CD, OWD
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; FILE LOOP:
  ;*************************************************************************
  FOR i=0, COUNT_F-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET THE CURRENT FILE
    FNAME = IN_FILES[i]
    ;-----------------------------------------------------------------------
    ; BUILD THE COMPRESSED INPUT FILE NAME
    FNAME_FULL = IN_DIR + '\' + FNAME
    ;-----------------------------------------------------------------------
    ; UNCOMPRESS THE CURRENT INPUT FILE (UNZIP WITH 7-ZIP VIA MS DOS)
    SPAWN, '7z x ' + FNAME_FULL + ' -o' + OUT_DIR, /NOSHELL
    ;-----------------------------------------------------------------------
    ; MANIPULATE FILE NAME TO GET FILE NAME SHORT
    FNAME_LENGTH = (STRLEN(FNAME)-0)-7
    FNAME_SHORT = STRMID(FNAME, 0, FNAME_LENGTH[0])
    ; SET THE TEMP UNCOMPRESSED FILE NAME                           ** DEFINE **
    DATA_IN = OUT_DIR + FNAME_SHORT + '.img'
    ; SET THE TEMP UNCOMPRESSED HDR FILE NAME
    DATA_INHDR = OUT_DIR + FNAME_SHORT + '.hdr'
    ;-----------------------------------------------------------------------
    ; BUILD AN ENVI HEADER FILE FOR THE UNCOMPRESSED FILE
    ENVI_SETUP_HEAD, FNAME=DATA_IN, NB=NB_IN, NL=NL_IN, NS=NS_IN, DATA_TYPE=DATATYPE_IN, $
      PIXEL_SIZE=[SIZEX_IN, SIZEY_IN], MAP_INFO=MAPINFO_IN, INTERLEAVE=INTERLEAVE_IN, $
      XSTART=XSTART_IN, YSTART=YSTART_IN, FILE_TYPE=FILE_TYPE_IN, OFFSET=OFFSET_IN, $
      DATA_OFFSETS=DATA_OFFSETS_IN, UNITS=UNITS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN, /WRITE
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; RESAMPLE DATA:
    ;***********************************************************************
    ; OPEN THE UNCOMPRESSED FILE
    ENVI_OPEN_FILE, DATA_IN, R_FID=FID_UN, /NO_REALIZE
    ;-----------------------------------------------------------------------
    ; QUERY THE FILE
    ENVI_FILE_QUERY, FID_UN, DIMS=DIMS_UN, NS=NS_UN, NL=NL_UN, NB=NB_UN, $
      INTERLEAVE=INTERLEAVE_UN, DATA_TYPE=DATATYPE_UN, XSTART=XSTART_UN, $
      FILE_TYPE=FILE_TYPE_UN,YSTART=YSTART_UN, OFFSET=OFFSET_UN, $
      DATA_OFFSETS=DATA_OFFSETS_UN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_UN
    ;-----------------------------------------------------------------------
    ; GET MAP INFORMATION
    MAPINFO_UN = ENVI_GET_MAP_INFO(FID=FID_UN)
    PROJ_FULL_UN = MAPINFO_UN.PROJ
    DATUM_UN = MAPINFO_UN.PROJ.DATUM
    PROJ_UN = MAPINFO_UN.PROJ.NAME
    UNITS_UN = MAPINFO_UN.PROJ.UNITS
    SIZEX_UN = FLOAT(MAPINFO_UN.PS[0])
    SIZEY_UN = FLOAT(MAPINFO_UN.PS[1])
    CXUL_UN = FLOAT(MAPINFO_UN.MC[2])
    CYUL_UN = FLOAT(MAPINFO_UN.MC[3])
    LOCX_UN = FLOAT(MAPINFO_UN.MC[0])
    LOCY_UN = FLOAT(MAPINFO_UN.MC[1])
    ;-----------------------------------------------------------------------
    ; GET DATA
    DATA_UN = ENVI_GET_DATA(FID=FID_UN, DIMS=DIMS_UN, POS=0)
    ;-----------------------------------------------------------------------
    ; DATA TYPE CHECK - TO SET NAN DATA MUST BE FLOAT OR DOUBLE
    IF DATATYPE_IN NE 4 THEN BEGIN
      DATA_UN = FLOAT(DATA_UN)
      DATATYPE_UN = 4
    ENDIF ELSE BEGIN
      DATATYPE_NEW = DATATYPE_UN
    ENDELSE
    ;-----------------------------------------------------------------------
    ; SET NAN
    k = WHERE(DATA_UN EQ FLOAT(NODATA), COUNT)
    IF (COUNT GT 0) THEN DATA_UN[k] = !VALUES.F_NAN
    ;-----------------------------------------------------------------------
    ; BUILD TEMPORARY NAN FILE NAME
    OUTNAME_UN = OUT_DIR + '\' + FNAME_SHORT + '.NAN.TEMP' + '.img'
    OUTNAME_UNHDR = OUT_DIR + '\' + FNAME_SHORT + '.NAN.TEMP' + '.hdr'
    ;-----------------------------------------------------------------------
    ; WRITE DATA TO A TEMPORARY FILE
    ENVI_WRITE_ENVI_FILE, DATA_UN, MAP_INFO=MAPINFO_UN, OUT_NAME=OUTNAME_UN, $
      PIXEL_SIZE=[SIZEX_UN,SIZEY_UN], OUT_DT=DATATYPE_UN, $
      NS=NS_UN, NL=NL_UN, NB=NB_UN, FILE_TYPE=FILE_TYPE_UN, OFFSET=OFFSET_UN, $
      UNITS=UNITS_UN, /NO_OPEN
    ;-----------------------------------------------------------------------
    ; OPEN NEW INPUT FILE
    ENVI_OPEN_FILE, OUTNAME_UN, R_FID=FID_UNIN, /NO_REALIZE
    ;-----------------------------------------------------------------------
    ; SET REBIN FACTORS
    RFACTX = SIZEX_OUT/SIZEX_UN
    RFACTY = SIZEY_OUT/SIZEY_UN
    RFACT = [RFACTX, RFACTY]
    ;-----------------------------------------------------------------------
    ; RESAMPLE
    ENVI_DOIT, 'RESIZE_DOIT', FID=FID_UNIN, DIMS=DIMS_UN, INTERP=RESIZEMETHOD, $
      POS=0, R_FID=FID_OUT, RFACT=RFACT, /IN_MEMORY, /NO_REALIZE
    ;-----------------------------------------------------------------------
    ; QUERY RESIZED FILE
    ENVI_FILE_QUERY, FID_OUT, DIMS=DIMS_OUT, NS=NS_OUT, NL=NL_OUT, NB=NB_OUT, $
      INTERLEAVE=INTERLEAVE_OUT, DATA_TYPE=DATATYPE_OUT, XSTART=XSTART_OUT, $
      FILE_TYPE=FILE_TYPE_OUT,YSTART=YSTART_OUT, OFFSET=OFFSET_OUT, DATA_OFFSETS=DATA_OFFSETS_OUT
    ;-----------------------------------------------------------------------
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
    ;-----------------------------------------------------------------------
    ; GET NEW COORDINATE Y ORIGIN
    DiffY = FLOAT(CYUL_TMP-CYUL_EXAMPLE)
    DYovCellY = ROUND(DiffY/SIZEY_TMP)
    ShiftY = FLOAT(((DYovCellY*SIZEY_TMP)+CYUL_EXAMPLE)-CYUL_TMP)
    CYUL_NEW = FLOAT(CYUL_TMP+ShiftY)
    ;-----------------------------------------------------------------------
    ; GET NEW COORDINATE X ORIGIN
    DiffX = FLOAT(CXUL_TMP-CXUL_EXAMPLE)
    DXovCellX = ROUND(DiffX/SIZEX_TMP)
    ShiftX = FLOAT(((DXovCellX*SIZEX_TMP)+CXUL_EXAMPLE)-CXUL_TMP)
    CXUL_NEW = FLOAT(CXUL_TMP+ShiftX)
    ;-----------------------------------------------------------------------
    ; CREATE NEW MAP INFORMATION
    PS = [SIZEX_OUT, SIZEY_OUT]
    MC = [LOCX_IN, LOCY_IN, CXUL_NEW, CYUL_NEW]
    MAPINFO_NEW = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=PROJ_FULL_TMP, UNITS=UNITS_TMP, $
      DATUM=DATUM_TMP, /GEOGRAPHIC)
    ;-----------------------------------------------------------------------
    ; GET DATA
    DATA_TMP = ENVI_GET_DATA(FID=FID_OUT, DIMS=DIMS_OUT, POS=0)
    ;-----------------------------------------------------------------------
    ; BUILD FINAL OUTPUT FILE NAME
    OUTNAME_RE = OUT_DIR + '\' + FNAME_SHORT + '.RESAMPLE' + '.SNAP' + '.img'
    ;-----------------------------------------------------------------------
    ; WRITE DATA WITH NEW MAP INFORMATION
    ENVI_WRITE_ENVI_FILE, DATA_TMP, MAP_INFO=MAPINFO_NEW, OUT_NAME=OUTNAME_RE, $
      BNAMES=BNAME_OUT, PIXEL_SIZE=[SIZEX_OUT,SIZEY_OUT], OUT_DT=DATATYPE_OUT, $
      NS=NS_OUT, NL=NL_OUT, NB=NB_OUT, FILE_TYPE=FILE_TYPE_OUT, OFFSET=OFFSET_OUT, $
      UNITS=UNITS_TMP, /NO_OPEN
    ;-----------------------------------------------------------------------
    ; DELETE THE TEMP FILES
    FILE_DELETE, DATA_IN
    FILE_DELETE, DATA_INHDR
    FILE_DELETE, OUTNAME_UN
    FILE_DELETE, OUTNAME_UNHDR
    ;-----------------------------------------------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', $
      STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_F, 2)
    PRINT,''
    ;-----------------------------------------------------------------------
  ENDFOR ; END 'FOR i'
  ;-------------------------------------------------------------------------
  ; PRINT END TIME
  MINUTES = (SYSTIME(1)-T_TIME)/60
  HOURS = MINUTES/60
  PRINT,''
  PRINT,'TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), ' MINUTES (', STRTRIM(HOURS, 2),   ' HOURS)'
  PRINT,''
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Spatial_Raster_Resample_COMPRESSED_DATA'
  PRINT,''
  ;-------------------------------------------------------------------------
END