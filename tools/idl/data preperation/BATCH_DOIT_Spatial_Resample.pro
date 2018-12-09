; ##############################################################################################
; NAME: BATCH_DOIT_Spatial_Resample.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 18/02/2010
; DLM: 13/10/2010
;
; DESCRIPTION: This tool alters the proportions of a raster dataset by changing the cell size. 
;              The extent of the output raster will remain the same unless the user selects the 
;              'ALIGN CELLS WITH THE EXISTING FILE' option, in which case the extents will move 
;              the minimum distance to ensure that the cell alignment of the output matches the 
;              existing file.
;
; INPUT:       One or more single-band or multi-band image files.
;
; OUTPUT:      One new raster file per input.
;
; PARAMETERS:  Via widgets. The user may choose whether to use the cell size of an existing file, 
;              or enter the new cell size manually. If the user opts to use the cell size of an
;              existing file the user may also select whether or not to align (snap cells) the 
;              output with the existing file.
;
;              1.  SELECT THE INPUT DATA: see INPUT
;              
;              2.  RESAMPLE-BY: see PARAMETERS above
;              
;              2.1  SET THE NEW CELL SIZE (optional): enter the cell size for the output raster 
;                   dataset.
;              
;              2.2  SELECT AN EXISTING FILE (optional): select an example dataset; the output 
;                   raster will use the cell size of the example file. 
;              
;              3.  SELECT THE ALIGNMENT TYPE: select whether the output grid cells should align
;                  with the example 'EXISTING' grid.
;              
;              4.  SELECT THE RESAMPLE METHOD: see NOTES
;              
;              5.  SELECT THE OUTPUT DIRECTORY: The output data is saved to this location.
;
; NOTES:       The input data must have identical dimensions. If the input is a flat binary file,
;              or an ENVI standard file it must have an associated ENVI header file (.hdr). 
;
;              An interactive ENVI session is needed to run this tool.
;              
;              RESAMPLING METHODS;
;
;              The user may select one of four interpolation methods. When 'down' sampling data 
;              it is recommended to use either the NEAREST NEIGHBOUR or PIXEL AGGREGATE method.
;              
;              NEAREST NEIGHBOUR assignment will determine the location of the closest cell 
;              centre on the input raster and assign the value of that cell to the cell on the 
;              output.
;                
;              BILINEAR INTERPOLATION uses the value of the four nearest input cell centers to 
;              determine the value on the output.
;                
;              CUBIC CONVOLUTION is similar to bilinear interpolation except the weighted average 
;              is calculated from the 16 nearest input cell centres and their values.
;                
;              PIXEL AGGREGATE uses the average of the surrounding pixels to determine the output 
;              value.
;              
;              FUNCTIONS:
;               
;              This program calls one or more external functions. You will need to compile the  
;              necessary functions in IDL, or save the functions to the current IDL workspace  
;              prior to running this tool. To open a different workspace, select Switch  
;              Workspace from the File menu.
;               
;              Functions used in this program include:
;               
;              FUNCTION_WIDGET_Radio_Button
;              FUNCTION_WIDGET_Enter_Value
;              
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_Spatial_Resample
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Spatial_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;--------------------------------------------------------------------------------------------- 
  ; SELECT THE INPUT DATA
  PATH='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09_terra_aqua_mosaics'
  FILTER=['*.tif','*.img','*.flt','*.bin']
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT THE INPUT DATA', FILTER=FILTER, /MUST_EXIST, $
    /MULTIPLE_FILES, /OVERWRITE_PROMPT)
  ;--------------
  ; ERROR CHECK:
  IF IN_FILES[0] EQ '' THEN RETURN
  ;--------------
  ; SORT FILE LIST
  IN_FILES = IN_FILES[SORT(IN_FILES)]
  ;--------------
  ; MANIPULATE FILENAME TO GET FILENAME SHORT:
  ;--------------
  ; GET FNAME_SHORT
  FNAME_START = STRPOS(IN_FILES, '\', /REVERSE_SEARCH)+1
  FNAME_LENGTH = (STRLEN(IN_FILES)-FNAME_START)-4
  ;--------------
  ; GET FILENAME ARRAY
  IN_FSHORT = MAKE_ARRAY(1, N_ELEMENTS(IN_FILES), /STRING)
  FOR a=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN
    ; ADD THE a-TH FILENAME TO THE FILENAME ARRAY
    IN_FSHORT[*,a] += STRMID(IN_FILES[a], FNAME_START[a], FNAME_LENGTH[a])
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; SET THE RESAMPLE-BY TYPE
  VALUES = ['ENTER A NEW CELL SIZE', 'SELECT AN EXISTING FILE']
  TYPE_BY = FUNCTION_WIDGET_Radio_Button('RESAMPLE-BY  ', VALUES)
  ;-----------------------------------
  IF TYPE_BY EQ 0 THEN BEGIN
    ;--------------
    XSIZE_NEW = FUNCTION_WIDGET_Enter_Value('SET THE NEW CELL SIZE  ', 50.00)
    YSIZE_NEW = XSIZE_NEW
    ;--------------
    TYPE_SNAP = 0
    ;--------------
  ENDIF ELSE BEGIN
    ;--------------
    ; SET FILE
    IN_EXAMPLE = DIALOG_PICKFILE(PATH=PATH, TITLE='SELECT AN EXISTING FILE', FILTER=FILTER, /MUST_EXIST)
    ;--------------
    ; OPEN FILE
    ENVI_OPEN_FILE, IN_EXAMPLE, R_FID=FID_EXAMPLE, /NO_REALIZE
    ;--------------
    ; GET MAP INFORMATION
    MAPINFO_EXAMPLE = ENVI_GET_MAP_INFO(FID=FID_EXAMPLE)
    PROJ_EXAMPLE = MAPINFO_EXAMPLE.PROJ
    DATUM_EXAMPLE = MAPINFO_EXAMPLE.PROJ.DATUM
    PROJ_EXAMPLE = MAPINFO_EXAMPLE.PROJ.NAME
    UNITS_EXAMPLE = MAPINFO_EXAMPLE.PROJ.UNITS
    XSIZE_EXAMPLE = DOUBLE(MAPINFO_EXAMPLE.PS[0])
    YSIZE_EXAMPLE = DOUBLE(MAPINFO_EXAMPLE.PS[1])
    XUL_EXAMPLE = DOUBLE(MAPINFO_EXAMPLE.MC[2])
    YUL_EXAMPLE = DOUBLE(MAPINFO_EXAMPLE.MC[3])
    ;--------------
    ; SET THE NEW CELL SIZE
    XSIZE_NEW = XSIZE_EXAMPLE
    YSIZE_NEW = YSIZE_EXAMPLE
    ;--------------  
    ; SELECT THE ALIGNMENT TYPE
    VALUES = ['DO NOT ALIGN CELLS WITH THE EXISTING FILE', 'ALIGN CELLS WITH THE EXISTING FILE']
    TYPE_SNAP = FUNCTION_WIDGET_Radio_Button('SELECT THE ALIGNMENT TYPE  ', VALUES)
    ;--------------
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE RESAMPLE METHOD
  VALUES = ['NEAREST NEIGHBOUR', 'BILINEAR INTERPOLATION', 'CUBIC CONVOLUTION', 'PIXEL AGGREGATE']
  TYPE_RESAMPLE = FUNCTION_WIDGET_Radio_Button('SELECT THE RESAMPLE METHOD  ', VALUES)
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY:
  TITLE='SELECT THE OUTPUT DIRECTORY'
  ;--------------  
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE=TITLE, /DIRECTORY, /OVERWRITE_PROMPT)
  ;-------------- 
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; START 'FOR i'
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET DATA:
    ;------------------------------------------------------------------------------------------- 
    FILE_IN = IN_FILES[i] ; GET THE i-TH INPUT FILENAME
    FSHORT_IN = IN_FSHORT[i] ; GET THE i-TH INPUT FILENAME SHORT
    ;--------------
    ; BUILD THE OUTPUT FILENAME
    IF TYPE_SNAP EQ 0 THEN SUFFIX = '.RESAMPLE.img' ELSE SUFFIX = '.RESAMPLE.SNAP.img'
    FILE_OUT = OUT_DIRECTORY + FSHORT_IN + SUFFIX
    ;--------------------------------------
    ; OPEN THE i-TH INPUT FILE
    ENVI_OPEN_FILE, FILE_IN, R_FID=FID_IN, /NO_REALIZE
    ;--------------
    ; QUERY THE i-TH INPUT FILE
    ENVI_FILE_QUERY, FID_IN, DIMS=DIMS_IN, DATA_TYPE=DATATYPE_IN, NS=NS_IN, NL=NL_IN
    ;--------------
    ; GET MAP INFORMATION
    MAPINFO_IN = ENVI_GET_MAP_INFO(FID=FID_IN)
    PROJ_IN = MAPINFO_IN.PROJ
    DATUM_IN = MAPINFO_IN.PROJ.DATUM
    PROJNAME_IN = MAPINFO_IN.PROJ.NAME
    UNITS_IN = MAPINFO_IN.PROJ.UNITS
    XSIZE_IN = DOUBLE(MAPINFO_IN.PS[0])
    YSIZE_IN = DOUBLE(MAPINFO_IN.PS[1])
    XUL_IN = DOUBLE(MAPINFO_IN.MC[2])
    YUL_IN = DOUBLE(MAPINFO_IN.MC[3])
    XO_IN = DOUBLE(MAPINFO_IN.MC[0])
    YO_IN = DOUBLE(MAPINFO_IN.MC[1])
    ;--------------------------------------
    ; GET DATA
    DATA_IN = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS_IN, POS=0)
    ;-------------------------------------------------------------------------------------------
    ; RESAMPLE DATA:
    ;-------------------------------------------------------------------------------------------
    ; SET THE RESAMPLE FACTOR
    RFACT_X = XSIZE_NEW / XSIZE_IN
    RFACT_Y = YSIZE_NEW / YSIZE_IN
    RFACTOR = [RFACT_X, RFACT_Y] 
    ;-------------------------------------------------------------------------------------------
    ; RESAMPLE
    IF TYPE_BY EQ 0 THEN BEGIN
        ;--------------------------------------
        ; RESAMPLE
        ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN, DIMS=DIMS_IN, INTERP=TYPE_RESAMPLE, $
          POS=0, R_FID=FID_R, RFACT=RFACTOR, OUT_NAME=FILE_OUT, /NO_REALIZE
        ;--------------
        ; CORRECT THE FALSE SHIFT CREATED BY 'RESIZE_DOIT'
        ;--------------
        ; QUERY THE RESAMPLED DATA
        ENVI_FILE_QUERY, FID_R, DIMS=DIMS_TEMP, DATA_TYPE=DATATYPE_TEMP, NB=NB_TEMP, NL=NL_TEMP, $
          NS=NS_TEMP, INTERLEAVE=INTERLEAVE_TEMP, FILE_TYPE=FILE_TYPE_TEMP, FNAME=FNAME_TEMP, BNAMES=BNAMES_TEMP
        ;--------------
        ; UPDATE MAP INFORMATION
        PS = [XSIZE_NEW, YSIZE_NEW]
        MC = [XO_IN, YO_IN, XUL_IN, YUL_IN]
        MAPINFO_NEW = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=PROJ_IN, UNITS=UNITS_IN, DATUM=DATUM_IN)
        ;--------------
        ; UPDATE HEADER
        ENVI_SETUP_HEAD, FNAME=FILE_OUT, BNAMES=BNAMES_TEMP, FILE_TYPE=FILE_TYPE_TEMP, UNITS=UNITS_IN, $
          NB=NB_TEMP, NS=NS_TEMP, NL=NL_TEMP, PIXEL_SIZE=[XSIZE_NEW, YSIZE_NEW], MAP_INFO=MAPINFO_NEW, $
          INTERLEAVE=INTERLEAVE_TEMP, DATA_TYPE=DATATYPE_TEMP, /WRITE
        ;--------------------------------------
    ENDIF ELSE BEGIN
      ;--------------
      IF TYPE_SNAP EQ 0 THEN BEGIN
        ;--------------------------------------
        ; RESAMPLE
        ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN, DIMS=DIMS_IN, INTERP=TYPE_RESAMPLE, $
          POS=0, R_FID=FID_R, RFACT=RFACTOR, OUT_NAME=FILE_OUT, /NO_REALIZE
        ;--------------
        ; CORRECT THE FALSE SHIFT CREATED BY 'RESIZE_DOIT'
        ;--------------
        ; QUERY THE RESAMPLED DATA
        ENVI_FILE_QUERY, FID_R, DIMS=DIMS_TEMP, DATA_TYPE=DATATYPE_TEMP, NB=NB_TEMP, NL=NL_TEMP, $
          NS=NS_TEMP, INTERLEAVE=INTERLEAVE_TEMP, FILE_TYPE=FILE_TYPE_TEMP, FNAME=FNAME_TEMP, BNAMES=BNAMES_TEMP
        ;--------------
        ; UPDATE MAP INFORMATION
        PS = [XSIZE_NEW, YSIZE_NEW]
        MC = [XO_IN, YO_IN, XUL_IN, YUL_IN]
        MAPINFO_NEW = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=PROJ_IN, UNITS=UNITS_IN, DATUM=DATUM_IN)
        ;--------------
        ; UPDATE HEADER
        ENVI_SETUP_HEAD, FNAME=FILE_OUT, BNAMES=BNAMES_TEMP, FILE_TYPE=FILE_TYPE_TEMP, UNITS=UNITS_IN, $
          NB=NB_TEMP, NS=NS_TEMP, NL=NL_TEMP, PIXEL_SIZE=[XSIZE_NEW, YSIZE_NEW], MAP_INFO=MAPINFO_NEW, $
          INTERLEAVE=INTERLEAVE_TEMP, DATA_TYPE=DATATYPE_TEMP, /WRITE
        ;--------------------------------------
      ENDIF ELSE BEGIN
        ;---------------------------------------------------------------------------------------
        ; ALIGN CELLS
        ;---------------------------------------------------------------------------------------
        ; RESAMPLE
        ENVI_DOIT, 'RESIZE_DOIT', FID=FID_IN, DIMS=DIMS_IN, INTERP=TYPE_RESAMPLE, $
          POS=0, R_FID=FID_R, RFACT=RFACTOR, OUT_NAME=FILE_OUT, /NO_REALIZE
        ;--------------
        ; QUERY THE RESAMPLED DATA
        ENVI_FILE_QUERY, FID_R, DIMS=DIMS_TEMP, DATA_TYPE=DATATYPE_TEMP, NB=NB_TEMP, NL=NL_TEMP, $
          NS=NS_TEMP, INTERLEAVE=INTERLEAVE_TEMP, FILE_TYPE=FILE_TYPE_TEMP, FNAME=FNAME_TEMP, BNAMES=BNAMES_TEMP
        ;--------------
        ; GET NEW X COORDINATE ORIGIN
        X_DIFF = XUL_IN - XUL_EXAMPLE
        X_CELLDIFF = ROUND(X_DIFF / XSIZE_NEW)
        XSHIFT = ((X_CELLDIFF * XSIZE_NEW) + XUL_EXAMPLE) - XUL_IN  
        XUL_NEW = XUL_IN + XSHIFT
        ;--------------        
        ; SET NEW Y COORDINATE ORIGIN
        Y_DIFF = YUL_IN - YUL_EXAMPLE
        Y_CELLDIFF = ROUND(Y_DIFF / YSIZE_NEW)
        YSHIFT = ((Y_CELLDIFF * YSIZE_NEW) + YUL_EXAMPLE) - YUL_IN  
        YUL_NEW = YUL_IN + YSHIFT
        ;--------------
        ; UPDATE MAP INFORMATION
        PS = [XSIZE_NEW, YSIZE_NEW]
        MC = [XO_IN, YO_IN, XUL_NEW, YUL_NEW]
        MAPINFO_NEW = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=PROJ_IN, UNITS=UNITS_IN, DATUM=DATUM_IN)
        ;-------------
        ; UPDATE HEADER
        ENVI_SETUP_HEAD, FNAME=FILE_OUT, BNAMES=BNAMES_TEMP, FILE_TYPE=FILE_TYPE_TEMP, UNITS=UNITS_IN, $
          NB=NB_TEMP, NS=NS_TEMP, NL=NL_TEMP, PIXEL_SIZE=[XSIZE_NEW, YSIZE_NEW], MAP_INFO=MAPINFO_NEW, $
          INTERLEAVE=INTERLEAVE_TEMP, DATA_TYPE=DATATYPE_TEMP, /WRITE
        ;-----------------------------------
      ENDELSE      
      ;--------------
    ENDELSE
    ;-------------------------------------------------------------------------------------------    
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    ; PRINT
    PRINT,'  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), $
      ' OF ', STRTRIM(N_ELEMENTS(IN_FILES), 2)
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Spatial_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END  
