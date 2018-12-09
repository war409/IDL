; ##########################################################################
; NAME: Time_Series_Analysis_DOIT_Convert_HDF_To_IMG_And_Resample.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: Evaluating AWRA outputs (Activity 6, WRAA, WIRADA)
; DATE: 02/03/2010
; DLM: 04/03/2010 - NODATA Function added
;
; DESCRIPTION: This tool firstly converts uncompressed HDF SD data to flat binary
;              format. The tool then alters the proportions of the first output by
;              changing the cell size based on THE EXAMPLE OUTPUT FILE. The extent
;              of the final output will move the minimum distance to ensure that
;              the cell alignment matches the example file.
;
; INPUT:       One of more compressed HDF files (*.hdf.gz). This script works by
;              searching sub-directories (of the input directory) for compressed
;              HDF data. One example input file and one example output file,
;              describing the original file dimensions and the new resampled
;              dimensions respectively.
;
; OUTPUT:      One flat binary file (.img) per input. The output date is written
;              to the output directory.
;
; PARAMETERS:  Set:
;
;              'SELECT THE INPUT DIRECTORY'
;              'SELECT THE OUTPUT DIRECTORY'
;              'SET THE EXAMPLE INPUT FILE'
;              'SET THE EXAMPLE OUTPUT FILE'
;              'SELECT THE RESIZE METHOD' (via IDL widget)
;
; NOTES:       Before running this tool you must install 7-zip see:
;
;              '\\File-wron\Working\work\war409\Work\General\software\7z\7z465.exe'
;
;              After installing the above software use the SPAWN command to
;              identify the current working directory and copy '7z.exe' into
;              this location. See:
;
;              '\\File-wron\Working\work\war409\Work\General\software\7z\7z.exe'
;
;              See line 166; define the file search filter.
;
;              The input data must have identical dimensions.
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
PRO Time_Series_Analysis_DOIT_Convert_HDF_To_IMG_And_Resample
  ;-------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: Time_Series_Analysis_DOIT_Convert_HDF_To_IMG_And_Resample'
  PRINT,''
  ;-------------------------------------------------------------------------
  ;*************************************************************************
  ; INPUT/OUTPUT:
  ;*************************************************************************
  ; SET THE INPUT DIRECTORY
  IN_DIR = '\\File-wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MCD43B3.005'
  ;-------------------------------------------------------------------------
  ; SET THE OUTPUT DIRECTORY:
  OUT_DIR = '\\File-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Observed\MODIS\albedo\resample1'
  ;-------------------------------------------------------------------------
  ; SET THE EXAMPLE INPUT FILE:
  IN_EX = '\\File-wron\Working\work\war409\Work\Imagery\MODIS\Template\MCD43B3.2000.049.aust.005.b20.1000m_0300_5000nm_albedo_white.img'
  ;-------------------------------------------------------------------------
  ; SET THE EXAMPLE OUTPUT FILE:
  OUT_EX = '\\file-wron\Working\wirada\WRAA\6_AWRA\Data\AWRA_eval\Resample\Modelled\SurfWet\Median8Day\2004001.img'
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
  ; GET SUB-DIRECTORY LIST:
  ;-------------------------------------------------------------------------
  ; SET WORKSPACE
  CD, 'C:'
  CD, '/Documents and Settings/war409'
  ; CHANGE CWD TO THE INPUT DIRECTORY
  CD, IN_DIR, CURRENT=OWD
  ; GET LIST OF FOLDERS IN THE NEW CWD
  IN_SUBDIR = FILE_SEARCH(/TEST_DIRECTORY)
  ; RESET THE WORKING DIRECTORY
  CD, OWD
  ; SORT SUB-DIRECTORY LIST
  IN_SUBDIR = IN_SUBDIR[SORT(IN_SUBDIR)]
  ; SET SUB-DIRECTORY COUNT
  COUNT_SD = N_ELEMENTS(IN_SUBDIR)
  ;*************************************************************************
  ; SUB-DIRECTORY LOOP:
  ;*************************************************************************
  FOR i=0, COUNT_SD-1 DO BEGIN ; START 'FOR i'
    ;-----------------------------------------------------------------------
    ; GET START TIME: LOOP
    L_TIME = SYSTIME(1)
    ;-----------------------------------------------------------------------
    ; GET THE CURRENT DIRECTORY
    C_SUBDIR = IN_DIR + '\' + IN_SUBDIR[i]
    ;-----------------------------------------------------------------------
    ; CHANGE THE WORKING DIRECTORY
    CD, C_SUBDIR, CURRENT=OWD
    ; GET LIST OF FILES IN THE WORKING DIRECTORY                ** DEFINE **
    IN_FILES = FILE_SEARCH('*1000m_0300_5000nm_albedo_white.hdf.gz')
    ; RESET THE WORKING DIRECTORY
    CD, OWD
    ;-----------------------------------------------------------------------
    ; SET FILE COUNT
    COUNT_F = N_ELEMENTS(IN_FILES)
    ;-----------------------------------------------------------------------
    ;***********************************************************************
    ; FILE LOOP:
    ;***********************************************************************
    FOR j=0, COUNT_F-1 DO BEGIN ; START 'FOR i'
      ;---------------------------------------------------------------------
      ; GET THE CURRENT FILE
      FNAME = IN_FILES[j]
      ;---------------------------------------------------------------------
      ; BUILD THE COMPRESSED INPUT FILE NAME
      FNAME_FULL = C_SUBDIR + '\' + FNAME
      ;---------------------------------------------------------------------
      ; UNCOMPRESS THE CURRENT INPUT FILE (UNZIP WITH 7-ZIP VIA MS DOS)
      SPAWN, '7z x ' + FNAME_FULL + ' -o' + OUT_DIR, /NOSHELL
      ;---------------------------------------------------------------------
      ; BUILD THE HDF FILE NAME:
      ;---------------------------------------------------------------------
      ; MANIPULATE FILE NAME TO GET FILE NAME SHORT
      FNAME_LENGTH = (STRLEN(FNAME)-0)-7
      FNAME_SHORT = STRMID(FNAME, 0, FNAME_LENGTH[0])
      ; SET HDF FILE NAME
      HDF_IN = OUT_DIR + '\' + FNAME_SHORT + '.hdf'
      ;---------------------------------------------------------------------
      ; CREATE THE OUTPUT FILE:
      ;---------------------------------------------------------------------
      ; BUILD THE OUTPUT NAME
      OUTNAME = OUT_DIR + '\' + FNAME_SHORT + '.img'
      OUTNAME_HDR = OUT_DIR + '\' + FNAME_SHORT + '.hdr'
      ; CREATE THE FILE
      OPENW, UNIT_OUT, OUTNAME, /GET_LUN
      ; CLOSE THE NEW FILE
      FREE_LUN, UNIT_OUT
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; GET HDF DATA:
      ;*********************************************************************
      ; OPEN THE HDF FILE
      SD_FILEID = HDF_SD_START(HDF_IN, /READ)
      ;---------------------------------------------------------------------
      ; SET THE SD DATASET ID
      SDSID = HDF_SD_SELECT(SD_FILEID, 0)
      ;---------------------------------------------------------------------
      ; GET FILE INFORMATION
      HDF_SD_FILEINFO, SD_FILEID, DATASETS, ATTRIBUTES
      HDF_SD_GETINFO, SDSID, NAME=SDSNAME
      ;---------------------------------------------------------------------
      ; GET FILE DATA
      HDF_SD_GETDATA, SDSID, DATA
      ;---------------------------------------------------------------------
      ; CLOSE THE SD FILE
      HDF_SD_END, SD_FILEID
      ;---------------------------------------------------------------------
      ; DELETE THE UNCOMPRESSED HDF FILE
      FILE_DELETE, HDF_IN
      ;---------------------------------------------------------------------
      ; WRITE DATA TO FILE:
      ;---------------------------------------------------------------------
      ; OPEN THE OUTPUT FILE
      OPENU, UNIT_OUT, OUTNAME, /APPEND, /GET_LUN
      ; APPEND DATA TO THE OUTPUT FILE
      WRITEU, UNIT_OUT, DATA
      ; CLOSE THE OUTPUT FILES
      FREE_LUN, UNIT_OUT
      ;---------------------------------------------------------------------
      ;*********************************************************************
      ; RESAMPLE DATA:
      ;*********************************************************************
      ; BUILD AN ENVI HEADER FILE FOR THE UNCOMPRESSED FILE
      ENVI_SETUP_HEAD, FNAME=OUTNAME, NB=NB_IN, NL=NL_IN, NS=NS_IN, DATA_TYPE=DATATYPE_IN, $
        PIXEL_SIZE=[SIZEX_IN, SIZEY_IN], MAP_INFO=MAPINFO_IN, INTERLEAVE=INTERLEAVE_IN, $
        XSTART=XSTART_IN, YSTART=YSTART_IN, FILE_TYPE=FILE_TYPE_IN, OFFSET=OFFSET_IN, $
        DATA_OFFSETS=DATA_OFFSETS_IN, UNITS=UNITS_IN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_IN, /WRITE
      ;---------------------------------------------------------------------
      ; OPEN FILE
      ENVI_OPEN_FILE, OUTNAME, R_FID=FID_UN, /NO_REALIZE
      ;---------------------------------------------------------------------
      ;---------------------------------------------------------------------
      ; QUERY THE FILE
      ENVI_FILE_QUERY, FID_UN, DIMS=DIMS_UN, NS=NS_UN, NL=NL_UN, NB=NB_UN, $
        INTERLEAVE=INTERLEAVE_UN, DATA_TYPE=DATATYPE_UN, XSTART=XSTART_UN, $
        FILE_TYPE=FILE_TYPE_UN,YSTART=YSTART_UN, OFFSET=OFFSET_UN, $
        DATA_OFFSETS=DATA_OFFSETS_UN, DATA_IGNORE_VALUE=DATA_IGNORE_VALUE_UN
      ;---------------------------------------------------------------------
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
      ;---------------------------------------------------------------------
      ; GET DATA
      DATA_UN = ENVI_GET_DATA(FID=FID_UN, DIMS=DIMS_UN, POS=0)
      ;---------------------------------------------------------------------
	  ; DATA TYPE CHECK
	  IF DATATYPE_UN LT 4 THEN BEGIN
	  	DATA_UN = FLOAT(DATA_UN)
		DATATYPE_UN = 4
	  ENDIF
      ; SET NAN
      k = WHERE((DATA_UN LT 0.00) OR (DATA_UN GT 10000.00), COUNT)
      IF (COUNT GT 0) THEN DATA_UN[k] = !VALUES.F_NAN
      ;---------------------------------------------------------------------
      ; BUILD TEMP FILE NAME
      OUTNAME_UN = OUT_DIR + '\' + FNAME_SHORT + '.NAN.TEMP' + '.img'
      OUTNAME_UN_HDR = OUT_DIR + '\' + FNAME_SHORT + '.NAN.TEMP' + '.hdr'
      ;---------------------------------------------------------------------
      ; WRITE DATA TO A TEMPORARY FILE
      ENVI_WRITE_ENVI_FILE, DATA_UN, MAP_INFO=MAPINFO_UN, OUT_NAME=OUTNAME_UN, $
        PIXEL_SIZE=[SIZEX_UN,SIZEY_UN], OUT_DT=DATATYPE_UN, $
        NS=NS_UN, NL=NL_UN, NB=NB_UN, FILE_TYPE=FILE_TYPE_UN, OFFSET=OFFSET_UN, $
        UNITS=UNITS_UN, /NO_OPEN
      ;---------------------------------------------------------------------
      ; OPEN NEW INPUT FILE
      ENVI_OPEN_FILE, OUTNAME_UN, R_FID=FID_UNIN, /NO_REALIZE
      ;---------------------------------------------------------------------
      ;---------------------------------------------------------------------
      ; SET REBIN FACTORS
      RFACTX = SIZEX_OUT/SIZEX_UN
      RFACTY = SIZEY_OUT/SIZEY_UN
      RFACT = [RFACTX, RFACTY]
      ;---------------------------------------------------------------------
      ; RESAMPLE
      ENVI_DOIT, 'RESIZE_DOIT', FID=FID_UNIN, DIMS=DIMS_UN, INTERP=RESIZEMETHOD, $
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
      OUTNAME_RE = OUT_DIR + '\' + FNAME_SHORT + '.RESAMPLE' + '.SNAP' + '.img'
      ;---------------------------------------------------------------------
      ; WRITE DATA WITH NEW MAP INFORMATION
      ENVI_WRITE_ENVI_FILE, DATA_TMP, MAP_INFO=MAPINFO_NEW, OUT_NAME=OUTNAME_RE, $
        BNAMES=BNAME_OUT, PIXEL_SIZE=[SIZEX_OUT,SIZEY_OUT], OUT_DT=DATATYPE_OUT, $
        NS=NS_OUT, NL=NL_OUT, NB=NB_OUT, FILE_TYPE=FILE_TYPE_OUT, OFFSET=OFFSET_OUT, $
        UNITS=UNITS_TMP, /NO_OPEN
      ;---------------------------------------------------------------------
      ; DELETE THE ORIGINAL OUTPUT FILE
      FILE_DELETE, OUTNAME
      FILE_DELETE, OUTNAME_HDR
      FILE_DELETE, OUTNAME_UN
      FILE_DELETE, OUTNAME_UN_HDR
      ;---------------------------------------------------------------------
    ENDFOR ; END 'FOR j'
    ;-----------------------------------------------------------------------
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ; PRINT LOOP INFORMATION
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR SUB-DIRECTORY ', $
      STRTRIM(i+1, 2), ' OF ', STRTRIM(COUNT_SD, 2)
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
  PRINT,'FINISHED PROCESSING: Time_Series_Analysis_DOIT_Convert_HDF_To_IMG_And_Resample'
  PRINT,''
  ;-------------------------------------------------------------------------
END
