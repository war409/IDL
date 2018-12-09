; ######################################################################
; NAME: CONVERT_BINARY_TO_NETCDF_DAILYDURATION_VERSION.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren 
; DATE: 26/11/2009
; DLM: 27/11/2009
; DESCRIPTION: BATCH CONVERT BINARY TO NETCDF.
; INPUT: VIA WIDGETS. ONE OR MORE BINARY FILES (.FLT, .DAT, .BIN)
; OUTPUT: ONE NETCDF FILE FOR EACH INPUT BINARY FILE.
; SET PARAMETERS: 
; NOTES: THIS VERSION OF THE TOOL CONVERTS ONE OR MORE BINARY FILES THAT
;        HAVE IDENTICAL DIMENSIONS, VARIABLE NAMES AND DATATYPE. 
;        THE FIRST BINARY FILE IN THE LIST MUST HAVE AN ASSOCIATED HDF (ENVI 
;        -HEADER) FILE CONTAINING MAP INFO; SAMPLES, LINES, PROJECTION ETC.
;        
;        ALL INPUT BINARY FILES MUST HAVE THE SAME FILE EXTENSION - SEE LINE
;        78 OF THE CODE.
;        
;        SEE LINE 277 - THE CODE GETS DATE (ATTRIBUTE TIME) FROM THE INPUT 
;        FILE NAME. 
;        
;        SEE ALSO: 'NETCDF_GET_VARIABLES_AND_ATTRIBUTES.pro' 
;                  'NETCDF_TIMESERIES_EXTRACT.pro'
; ######################################################################
; 
PRO CONVERT_BINARY_TO_NETCDF_DAILYDURATION_VERSION
  ; GET START TIME FOR WHOLE
  F_TIME = SYSTIME(1)
  PRINT,''
  PRINT,'BEGIN PROCESSING: CONVERT_BINARY_TO_NETCDF'
  PRINT,''
  ;---------------------------------------------------------------------
  ; DEFINE INPUT TYPE
  OP_BASE = WIDGET_AUTO_BASE(TITLE='DEFINE')
  LIST=['SINGLE FILE','MORE THAN ONE FILE IN A FOLDER','ALL FILES IN A FOLDER']
  WO_OP = WIDGET_PMENU(OP_BASE, LIST=LIST, uvalue='INTYPE', $
    PROMPT='SELECT AN INPUT TYPE', XSIZE=30, /AUTO)  
  RESULT_OP = AUTO_WID_MNG(OP_BASE) 
  IF (RESULT_OP.ACCEPT EQ 0) THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED OPERATOR IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF ELSE BEGIN
    INPUTTYPE = LIST(RESULT_OP.INTYPE)
  ENDELSE
  ;---------------------------------------------------------------------
  ; DEFINE INPUT FILE OR FILES
  IF INPUTTYPE EQ 'SINGLE FILE' THEN BEGIN
    ;-------------------------------------------------------------------
    ; SET THE INPUT FILE
    INFILE = ENVI_PICKFILE(TITLE='SELECT INPUT FILE')
    ; ERROR CHECK
    IF INFILE EQ '' THEN BEGIN
      PRINT,''
      PRINT, 'THE SELECTED INPUT FILE IS NOT VALID'
      PRINT,''
      RETURN
    ENDIF ELSE BEGIN
      ALLFILENAME = ''
    ENDELSE
    ;-------------------------------------------------------------------
  ENDIF 
  IF INPUTTYPE EQ 'MORE THAN ONE FILE IN A FOLDER' THEN BEGIN
    ;-------------------------------------------------------------------
    ; SET THE INPUT FILE
    INFILE = ENVI_PICKFILE(TITLE='SELECT INPUT FILES', /MULTIPLE_FILES)
    ALLFILENAME = ''  
    ;-------------------------------------------------------------------
  ENDIF
  IF INPUTTYPE EQ 'ALL FILES IN A FOLDER' THEN BEGIN
    ;------------------------------------------------------------------- 
    ; SET THE INPUT PATH & FOLDER
    INPATH = ENVI_PICKFILE(TITLE='SELECT INPUT FOLDER', /DIRECTORY)
    ; ERROR CHECK
    IF INPATH EQ '' THEN BEGIN
      PRINT,''
      PRINT, 'THE SELECTED INPUT FOLDER IS NOT VALID'
      PRINT,''
      RETURN
    ENDIF ELSE BEGIN
      ; GET INPUT FILENAME LIST
      ALLFILELIST = FILE_SEARCH(INPATH, "*.flt", COUNT=COUNT)
      ; MAKE EMPTY STRING ARRAY TO HOLD FILE NAMES
      ALLFILENAME = STRARR(COUNT)
      FOR j=0, COUNT-1 DO BEGIN
        ALLFILE = ALLFILELIST[j]
        ALLFILENAME[j] = ALLFILE
      ENDFOR
    ENDELSE
    ;-------------------------------------------------------------------
  ENDIF
  ;---------------------------------------------------------------------
  ; GET FILENAME LIST AND COUNT
  ; SET 'ALLFILENAME' FILE LIST IF NEEDED
  IF INPUTTYPE NE 'ALL FILES IN A FOLDER' THEN ALLFILENAME = INFILE
  ; GET INPUT FILE COUNT
  FILE_COUNT = N_ELEMENTS(ALLFILENAME)
  ;---------------------------------------------------------------------
  ; SELECT INTPUT HDR FILE
  ; PICK FILE WIDGET
  INHDR = DIALOG_PICKFILE(TITLE='SELECT INPUT FILE HEADER (HDR)')
  ; ERROR CHECK
  IF INHDR EQ '' THEN BEGIN
    PRINT,''
    PRINT, 'THE SELECTED HDR FILE IS NOT VALID'
    PRINT,''
    RETURN
  ENDIF
  ; GET MAP INFO
  ; OPEN THE INPUT HDR FILE
  OPENR, HDRLUN, INHDR, /GET_LUN
  HDR_LINE = ''
  WHILE NOT EOF(HDRLUN) DO BEGIN
    READF, HDRLUN, HDR_LINE
    TMP = STRSPLIT(HDR_LINE(0), '=', /EXTRACT)
    HDR_KEY = STRSPLIT(TMP(0), ' ', /EXTRACT)
    IF HDR_KEY(0) EQ 'samples' THEN XS = LONG(TMP(1))
    IF HDR_KEY(0) EQ 'lines' THEN YS = LONG(TMP(1))
    IF HDR_KEY(0) EQ 'header' THEN OFFSET = LONG(TMP(1))
    IF HDR_KEY(0) EQ 'data' THEN TYPE = LONG(TMP(1))
    IF HDR_KEY(0) EQ 'map' THEN BEGIN
      MAPINFO_TMP = STRSPLIT(TMP(1), '{', /EXTRACT)
      MAPINFO_TMP = STRSPLIT(MAPINFO_TMP(1), ',', /EXTRACT)
      MAPINFO = {ulx:0.,uly:0.,spacing:0.}
      MAPINFO.ulx =MAPINFO_TMP(3)
      MAPINFO.uly = MAPINFO_TMP(4)
      MAPINFO.spacing = MAPINFO_TMP(5)
    ENDIF
  ENDWHILE
  ; CLOSE THE HDR FILE AND FREE LUN
  CLOSE, HDRLUN & FREE_LUN, HDRLUN
  ;---------------------------------------------------------------------
  ; SET THE OUTPUT PATH
  OUTPATH = ENVI_PICKFILE(TITLE='SELECT OUTPUT FOLDER', /DIRECTORY)
  ;--------------------------------------------------------------------- 
  ; OPEN EACH INPUT FILE IN THE LIST 'ALLFILENAME'
  FOR i=0, FILE_COUNT-1 DO BEGIN ; START 'FOR i'
    ; SET LOOP TIME
    T_TIME = SYSTIME(1)
    ; CREATE EMPTY ARRAY TO HOLD THE INPUT FILE DATA
    IMG = 0
    IF TYPE EQ 1 THEN IMG = BYTARR(XS, YS)
    IF TYPE EQ 2 THEN IMG = INTARR(XS, YS)
    IF TYPE EQ 4 THEN IMG = FLTARR(XS, YS)
    IF TYPE EQ 12 THEN IMG = UINTARR(XS, YS)
    ; GET INPUT FILENAME
    INFILENAME = ALLFILENAME[i]
    ;------------------------------------------------------------------- 
    ; OPEN INPUT FILE AND GET DATA
    OPENR, INLUN, INFILENAME, /GET_LUN
    ; SET/OBTAIN THE POINTER POSITION
    POINT_LUN, INLUN, OFFSET
    ; FILL ARRAY 'IMG' WITH INLUN DATA
    READU, INLUN, IMG
    ; CLOSE THE INPUT FILE AND FREE LUN
    CLOSE, INLUN & FREE_LUN, INLUN
    ;-------------------------------------------------------------------
    ; SET THE OUTPUT FILE NAME
    ; GET FILENAME FROM FULL NAME&PATH
    START = STRPOS(INFILENAME, '\', /REVERSE_SEARCH)+1
    LENGTH = (STRLEN(INFILENAME)-START)-4
    FNAME = STRMID(INFILENAME, START, LENGTH)
    ; BUILD THE OUTPUT FILENAME
    OUTFILE = OUTPATH + '\' + FNAME + '.nc'
    ;-------------------------------------------------------------------
    ; CREATE THE NEW (EMPTY) NETCDF FILE
    NETID = NCDF_CREATE(OUTFILE, /CLOBBER)
    ; FILL THE NEW NETCDF FILE WITH ZERO
    NCDF_CONTROL, NETID, /FILL
    ; DEFINE THE NETCDF FILE T DIMENSION
    TDIM = NCDF_DIMDEF(NETID, 'time', 1)
    ; DEFINE THE NETCDF FILE Y DIMENSION
    YDIM = NCDF_DIMDEF(NETID, 'latitude', YS)
    ; DEFINE THE NETCDF FILE X DIMENSION
    XDIM = NCDF_DIMDEF(NETID, 'longitude', XS)
    ;-------------------------------------------------------------------
    ; DEFINE PRIMARY AND COORDINATE VARIABLES
    ; DEFINE THE VARIABLE 'time'
    VIDT = NCDF_VARDEF(NETID, 'time', [TDIM], /LONG)
    ; DEFINE THE VARIABLE 'latitude'
    VIDY = NCDF_VARDEF(NETID, 'latitude', [YDIM], /FLOAT)
    ; DEFINE THE VARIABLE 'longitude'
    VIDX = NCDF_VARDEF(NETID, 'longitude', [XDIM], /FLOAT)
    ; DEFINE THE VARIABLE 'precipitation'
    VID = NCDF_VARDEF(NETID, 'precipitation', [XDIM, YDIM, TDIM], /FLOAT)
    ;-------------------------------------------------------------------
    ; WRITE ATTRIBUTE DATA
    LONGNAME = 'long_name'
    UNITS = 'units'
    ; VARIABLE 'time' -
    TIME_ATT1 = 'time'
    NCDF_ATTPUT, NETID, VIDT, LONGNAME, TIME_ATT1, /CHAR
    TIME_ATT2 = 'days since 1900-01-01 0:0:0'
    NCDF_ATTPUT, NETID, VIDT, UNITS, TIME_ATT2, /CHAR
    ; VARIABLE 'latitude' -
    LAT_ATT1 = 'latitude'
    NCDF_ATTPUT, NETID, VIDY, LONGNAME, LAT_ATT1, /CHAR
    LAT_ATT2 = 'degrees_north'
    NCDF_ATTPUT, NETID, VIDY, UNITS, LAT_ATT2, /CHAR
    ; VARIABLE 'longitude' -
    LON_ATT1 = 'longitude'
    NCDF_ATTPUT, NETID, VIDX, LONGNAME, LON_ATT1, /CHAR
    LON_ATT2 = 'degrees_east'
    NCDF_ATTPUT, NETID, VIDX, UNITS, LON_ATT2, /CHAR
    ; VARIABLE 'precipitation' -
    PREP_ATT1 = -999.00
    PREP_ATT1NAME = '_FillValue'
    NCDF_ATTPUT, NETID, VID, PREP_ATT1NAME, PREP_ATT1, /FLOAT
    PREP_ATT2 = 'total rainfall'
    NCDF_ATTPUT, NETID, VID, LONGNAME, PREP_ATT2, /CHAR 
    PREP_ATT3 = 'mm'
    NCDF_ATTPUT, NETID, VID, UNITS, PREP_ATT3, /CHAR
    PREP_ATT4 = 'time: sum'
    PREP_ATT4NAME = 'cell_methods'
    NCDF_ATTPUT, NETID, VID, PREP_ATT4NAME, PREP_ATT4, /CHAR
    ;-------------------------------------------------------------------
    ; WRITE GLOBAL ATTRIBUTE DATA
    ; ATTRIBUTE 'conventions'
    GATNAME = 'conventions'
    GATVALUE = 'CF-1.4'
    NCDF_ATTPUT, NETID, GATNAME, GATVALUE, /GLOBAL, /CHAR
    ; ATTRIBUTE 'title'
    GATNAME = 'title'
    GATVALUE = 'WIRADA PPT and AET Project Blended Rainfall for Australia'
    NCDF_ATTPUT, NETID, GATNAME, GATVALUE, /GLOBAL, /CHAR
    ; ATTRIBUTE 'institution'
    GATNAME = 'institution'
    GATVALUE = 'CSIRO, Water for a Healthy Country Flagship'
    NCDF_ATTPUT, NETID, GATNAME, GATVALUE, /GLOBAL, /CHAR
    ; ATTRIBUTE 'source'
    GATNAME = 'source'
    GATVALUE = 'analysis of rain gauges and satellite observed precipitation rates'
    NCDF_ATTPUT, NETID, GATNAME, GATVALUE, /GLOBAL, /CHAR
    ; ATTRIBUTE 'comment'
    GATNAME = 'comment'
    GATVALUE = 'precipitation is 24 hour total from local time 9am the day before to 9am on the current day'
    NCDF_ATTPUT, NETID, GATNAME, GATVALUE, /GLOBAL, /CHAR
    ; ATTRIBUTE 'history'
    GATNAME = 'history'
    GATVALUE = ('Blended Precipitation Dataset.'+ STRING(13B) + $
      'Version 2009/08 Experimental.' + STRING(13B) + $
      '' + STRING(13B) + $
      'Compiled using method described by Li and Shao, 2009, "An improved' + STRING(13B) + $
      'statistical approach to blending TRMM and raingauge data sets", WfHC' + STRING(13B) + $
      'Technical Report, CSIRO, from Bureau of Meteorology daily precipitation' + STRING(13B) + $
      'product IDCJDC03.200907 and the daily accumulation of 3B42 TRMM' + STRING(13B) + $
      'multi-satellite precipitation analysis (Renzullo, 2008, "Considerations' + STRING(13B) + $
      'for the blending of multiple precipitation data sets for hydrological' + STRING(13B) + $
      'applications",' + STRING(13B) + $
      'http://www.isac.cnt.it/~ipwg/meetings/beijing/beijing2008-pres-post.html).' + STRING(13B) + $
      '' + STRING(13B) + $
      'Physical quantity is precipitation (mm) in the 24 hours up to 9am on the' + STRING(13B) + $
      'date of the data variable (and in the file name).')
    NCDF_ATTPUT, NETID, GATNAME, GATVALUE, /GLOBAL, /CHAR
    ;-------------------------------------------------------------------
    ; WRITE PRIMARY VARIABLE DATA TO THE NEW NETCDF FILE 
    ; SET THE ENDEF KEYWORD TO LEAVE DEFINE MODE AND ENTER DATA MODE
    NCDF_CONTROL, NETID, /ENDEF
    ; SET NaN IN PRIMARY VARIABLE TO -999.00
    k = WHERE((FINITE(IMG, /NaN)), COUNT)
    IF (COUNT GT 0) THEN IMG[k] = -999.00
    ; (RE)SET COUNT
    COUNT = [LONG(XS), LONG(YS), LONG(1)]
    ; WRITE TO NETCDF VARIABLE
    NCDF_VARPUT, NETID, VID, IMG, COUNT=COUNT
    ;-------------------------------------------------------------------
    ; GET LATITUDE AND LONGITUDE ARRAYS
    NCDF_VARGET, NETID, VID, VAR_1
    DIMS = SIZE(VAR_1, /DIMENSIONS)
    YLEN = DIMS[0]
    XLEN = DIMS[1]
    YARR = INDGEN(YLEN)*1
    XARR = INDGEN(XLEN)*1
    IF i EQ 0 THEN BEGIN
      ENVI_OPEN_FILE, INFILENAME, R_FID=FID 
      ENVI_CONVERT_FILE_COORDINATES, FID, XARR, YARR, XMAP, YMAP, /TO_MAP
    ENDIF
    ;-------------------------------------------------------------------
    ; FILL TIME WITH DATE FROM THE FILENAME
    ; USE FNAME
    YEAR = STRMID(FNAME, 5, 4)
    MONTH = STRMID(FNAME, 9, 2)
    DAY = STRMID(FNAME, 11, 2)
    ; BUILD DATE
    DTD = IMSL_DATETODAYS(DAY, MONTH, YEAR) 
    TMAP = [DTD]
    ;-------------------------------------------------------------------
    ; WRITE COORDINATE VARIABLE DATA
    NCDF_VARPUT, NETID, VIDT, TMAP
    NCDF_VARPUT, NETID, VIDY, YMAP
    NCDF_VARPUT, NETID, VIDX, XMAP
    ;-------------------------------------------------------------------
    ; CLOSE THE NETCDF FILE
    NCDF_CLOSE, NETID
    ;-------------------------------------------------------------------
    ; PRINT LOOP TIME
    SECONDS = (SYSTIME(1)-T_TIME)
    PRINT, ''
    PRINT, '    PROCESSING TIME: ', STRTRIM(SECONDS, 2),'  SECONDS, FOR BINARY FILE: ', INFILENAME
  ENDFOR ; END 'FOR i'
  ;---------------------------------------------------------------------
  PRINT,''
  ; PRINT THE PROCESSING TIME
  MINUTES = (SYSTIME(1)-F_TIME)/60
  PRINT, '  TOTAL PROCESSING TIME: ', STRTRIM(MINUTES, 2), '  MINUTES'
  PRINT,''
  PRINT,'FINISHED PROCESSING: CONVERT_BINARY_TO_NETCDF'
  PRINT,'' 
END