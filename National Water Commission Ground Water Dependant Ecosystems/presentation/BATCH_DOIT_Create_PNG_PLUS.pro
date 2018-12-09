; ##############################################################################################
; NAME: BATCH_DOIT_Create_PNG_PLUS.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 29/10/2010
; DLM: 18/11/2010
;
; DESCRIPTION: This tool create one PNG file for each input file.
;
; INPUT:       One or more ENVI compatible single-band grids. The current input file filter is set 
;              as: ['*.tif','*.img','*.flt','*.bin']. If you select one or more multi-band grids the
;              tool will still function however it will produce an output PNG for the first band only. 
;
; OUTPUT:      One PNG file (.png) for each input file or band.
;               
; PARAMETERS:  Via IDL widgets, set:
; 
;              1.    SELECT THE INPUT DATA: see INPUT
;              
;              2.    Load Color Table: Select a colour table. The output png will display data
;                    using the selected colour ramp.
;               
;              3.    Define an input nodata value: If your input data contains a 'fill' or 'nodata' 
;                    value that you want to exclude from the processing select YES.
;               
;              3.1   Define the input nodata value: The input nodata value.
;              
;              4.    Select the No-Data Colour: No Data will be displayed in this colour in the output
;                    PNG files.
;                  
;              5.    Add a Shapefile to the Map: Select YES to overlay the input data with a shapefile
;                    vector of your choice. The shapefile may contain multiple elements (shapes), it
;                    may be of either a polygon or polyline format. 
;              
;              6.    Select the Input Shapefile: Select the shapefile from file.
;              
;              7.    Select the Shapefile Line Colour: The shapefile lines will be displayed in this 
;                    colour.
;              
;              8.    Set the Shapefile Line Thickness: Select the width of the shapfile lines. 1 is 
;                    normal.
;                  
;              9.    Set the Shapefile Line Style: The shapefile lines will be displayed in the
;                    selected style. For example, dotted, dashed, solid etc.
;                  
;              10.   Select a Colour to Fill the Shapefile: Select YES to fill shapefile polygons 
;                    with a solid colour selected in 10.1.
;              
;              10.1  Select the Shapefile Fill Colour: Select the colour to fill shapefile polygons.
;              
;              11.   Add Annotation to the Map: Select YES to add annotation (text) to the output
;                    PNG files.
;                    
;              12.   Use the Input Filenames to Annotate the Map: Select YES to use the input grid
;                    filename to annotate the output PNG.
;                    
;              12.1  Enter Text: If you select no in 12. you must define the text to annotate the 
;                    image with. Note that this text is printed on each of the output PNG files
;                    as defined. This option is useful if you want to add a title to the series.       
;                    
;              13.   Select the Annotation Colour: Select the draw colour of the annotation. 
;              
;              14.   Set the Character Size: Select the size of the annotation. 1 is normal.
;              
;              15.   Set the Character Line Thickness: Select the draw width of each character.
;                    1 is normal.
;                    
;              16.   Set the Annotation Orientation (degrees): Set the draw orientation of the
;                    annotation. 0 is horizontal, 90 is vertical etc.
;                    
;              17.   Select the Text Font: Select the Font type. You can enter any valid Windows 
;                    font.             
;              
;              18.   Set the Annotation Position: Select where the annotation will be printed
;                    on the output PNG. For example, top left, bottom left, top centre etc.
;                    
;              19.   Draw a Border Around the Map: Select YES to draw a border around the contents
;                    of the PNG.
;              
;              19.1   Select the Map Border Colour: If YES in 19.
;              
;              20.  Set display limits: Select YES to set a new minimum and a new maximum 
;                  value (see 5.1).
;               
;              20.1 Define the new display limits: Select new minimum and maximum values. 
;                  
;                  This feature can be used to standardise the output colour ramp  
;                  for a series of input data, or to display a subset - narrow range of values - 
;                  with greater contrast. 
;                  
;                  For example, say the input contains values from 0 to 100. The user knows a
;                  -priori that most values fall between 10 and 30. The user may apply a new display 
;                  minimum of 10 and maximum of 30. Values between 10 and 30 are stretched to make 
;                  optimum use of the available PNG brightness levels (0-255 RGB), and hence display  
;                  the selected value range with the best possible contrast. You should use this 
;                  feature with care as data outside of the selected range are effectively removed; 
;                  values less than the minimum are set as 0, values greater than the maximum are 
;                  set as 255.
;                  
;              21.  Select the Output Directory: The output data is saved to this location.
;              
; NOTES:       An interactive ENVI session is needed to run this tool.
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
;              TVIMAGE (by David Fanning, see: www.dfanning.com/programs/TVIMAGE.pro)
;              TVREAD (by David Fanning, see: www.dfanning.com/programs/TVREAD.pro)
;              FSC_Color (by David Fanning, see: www.dfanning.com/programs/FSC_Color.pro)
;              XCOLORS (by David Fanning, see: www.dfanning.com/programs/xcolors.pro)
;               
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO BATCH_DOIT_Create_PNG_PLUS
  ;---------------------------------------------------------------------------------------------
  ; GET START TIME
  T_TIME = SYSTIME(1)
  ;--------------
  PRINT,''
  PRINT,'BEGIN PROCESSING: BATCH_DOIT_Create_PNG_PLUS'
  PRINT,''
  ;---------------------------------------------------------------------------------------------  
  ;*********************************************************************************************
  ; INPUT/OUTPUT:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------  
  ; SELECT THE INPUT DATA:
  PATH = 'H:\Projects\NWC_Groundwater_Dependent_Ecosystems\gamma\graphics\data\'
  IN_FILES = DIALOG_PICKFILE(PATH=PATH, TITLE='Select the Input Data', FILTER=['*.tif','*.img','*.flt','*.bin'], $
    /MUST_EXIST, /MULTIPLE_FILES)
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
  ; SET THE COLOR TABLE TYPE
  XCOLORS, TITLE='Load Colour Table', COLORINFO=COLORINFO_STRUCT, /BLOCK
  ;--------------
  ; SET COLOR TABLE PARAMETERS
  CT_RED = COLORINFO_STRUCT.R
  CT_GREEN = COLORINFO_STRUCT.G
  CT_BLUE = COLORINFO_STRUCT.B
  CT_TYPE = COLORINFO_STRUCT.TYPE
  CT_NAME = COLORINFO_STRUCT.NAME
  CT_INDEX = COLORINFO_STRUCT.INDEX
  ;---------------------------------------------------------------------------------------------
  ; SET THE NODATA VALUE
  NAN_VALUE = FUNCTION_WIDGET_If_Radio_Then_Set_Value(TITLE='No Data Widget', CNT='0', $
    LABEL_IF='Define an Input No-Data Value:', VALUE_IF=['Yes', 'No'], $
    LABEL_THEN='Input No-Data Value:',VALUE_THEN=255, /FLOATING)
  ;--------------
  IF FINITE(NAN_VALUE) EQ 1 THEN BEGIN
    ; SET THE NODATA COLOUR
    COLOUR_NODATA = PICKCOLORNAME(TITLE='Select the No-Data Colour')
    TRIPLE_NODATA = FSC_Color(COLOUR_NODATA, /TRIPLE) ; GET NODATA COLOUR TRIPLE
    ;--------------
    ; SET THE NODATA COLOUR TABLE:
    ;--------------
    ; MAKE COLOUR VECTORS
    NAN_R = FINDGEN(256)
    NAN_G = FINDGEN(256)
    NAN_B = FINDGEN(256)
    ; FILL COLOUR VECTORS
    NAN_R[*] = TRIPLE_NODATA[0]
    NAN_G[*] = TRIPLE_NODATA[1]
    NAN_B[*] = TRIPLE_NODATA[2]
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; SHAPEFILE
  VT = FUNCTION_WIDGET_Set_Radio_Button(TITLE='Shapfile Parameters', LABEL='Add One or More Shapefiles to the Map:', $
    VALUE=['Yes', 'No'])
  ;--------------
  IF (VT NE 1) AND (FINITE(VT) EQ 1) THEN BEGIN
    ; SELECT THE INPUT SHAPEFILE:
    PATH = 'C:\Documents and Settings\war409\My Documents\data\spatial\Vector'  
    IN_SHAPE = DIALOG_PICKFILE(PATH=PATH, TITLE='Select the Input Shapefile', FILTER=['*.shp'], $
      /MULTIPLE_FILES, /MUST_EXIST)
    IF IN_SHAPE[0] EQ '' THEN RETURN ; ERROR CHECK:
    ;--------------
    ; CREATE SHAPE PARAMETER ARRAYS:
    COLOUR_LINE = MAKE_ARRAY(N_ELEMENTS(IN_SHAPE), /STRING)
    THICKNESS = MAKE_ARRAY(N_ELEMENTS(IN_SHAPE), /LONG)
    LINESTYLE = MAKE_ARRAY(N_ELEMENTS(IN_SHAPE), /LONG)
    COLOUR_FILL = MAKE_ARRAY(N_ELEMENTS(IN_SHAPE), /STRING) 
    FOR s=0, N_ELEMENTS(IN_SHAPE)-1 DO BEGIN
      FNAME_START = STRPOS(IN_SHAPE[s], '\', /REVERSE_SEARCH)+1
      FNAME_LENGTH = (STRLEN(IN_SHAPE[s])-FNAME_START)-4
      SNS = STRMID(IN_SHAPE[s], FNAME_START, FNAME_LENGTH)
      PRINT, SNS
      ; SET THE SHAPEFILE PARAMETERS:
      COLOUR_LINE[s] += PICKCOLORNAME(TITLE='Set Colour: '+SNS)
      THICKNESS[s] += FUNCTION_WIDGET_Set_Value(TITLE=SNS, LABEL='Set the Shapefile Line Thickness:', $
        VALUE=1, /LONG)
      LINESTYLE[s] += FUNCTION_WIDGET_Droplist(TITLE=SNS+'  ', LABEL='Line Style:', $
        VALUE=['0 Solid','1 Dotted','2 Dashed','3 Dash Dot','4 Dash Dot Dot','5 Long Dashes'])
      FT = FUNCTION_WIDGET_Set_Radio_Button(TITLE=SNS, LABEL='Select a Colour to Fill the Shapefile:', $
        VALUE=['Yes', 'No'])
      IF (FT NE 1) AND (FINITE(FT) EQ 1) THEN COLOUR_FILL[s] += PICKCOLORNAME(TITLE=SNS) ELSE COLOUR_FILL[s] += '-1'
    ENDFOR
  ENDIF
  ;---------------------------------------------------------------------------------------------  
  ; ANNOTATION
  AT = FUNCTION_WIDGET_Set_Radio_Button(TITLE='ANNOTATION Parameters', LABEL='Add Annotation to the Map:', VALUE=['Yes', 'No'])
  ;--------------
  IF (AT NE 1) AND (FINITE(AT) EQ 1) THEN BEGIN
    TEXT_IN = FUNCTION_WIDGET_If_Radio_Then_Set_Value(TITLE='ANNOTATION Parameters', CNT='1', $
      LABEL_IF='Use the Input Filenames to Annotate the Map:', VALUE_IF=['Yes', 'No'], $
      LABEL_THEN='Enter Text:', /STRING)
    COLOUR_TEXT = PICKCOLORNAME(TITLE='Select the Annotation Colour')
    CSIZE = FUNCTION_WIDGET_Set_Value(TITLE='Annotation Parameters', LABEL='Set the Character Size:', $
      VALUE=1, /LONG)
    CTHICK = FUNCTION_WIDGET_Set_Value(TITLE='Annotation Parameters', LABEL='Set the Character Line Thickness:', $
      VALUE=1, /LONG)
    ORIENTATION = FUNCTION_WIDGET_Set_Value(TITLE='Annotation Parameters', LABEL='Set the Annotation Orientation (degrees):', $
      VALUE=0.00, /FLOAT)
    POSITION =  FUNCTION_WIDGET_Droplist(TITLE='Annotation Parameters', LABEL='Annotation Position:',$
      VALUE=['0 Upper Left','1 Centre Top','2 Upper Right','3 Lower Left','4 Centre Bottom','5 Lower Right'])
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; MAP BORDER
  BT = FUNCTION_WIDGET_Set_Radio_Button(TITLE='Map Border',LABEL='Draw a Border Around the Map:', VALUE=['Yes', 'No'])
  IF (BT NE 1) AND (FINITE(BT) EQ 1) THEN COLOUR_BORDER = PICKCOLORNAME(TITLE='Select the Map Border Colour')
  ;---------------------------------------------------------------------------------------------
  ; SET THE CONTRAST STRETCH STATUS
  ST = FUNCTION_WIDGET_Set_Radio_Button(TITLE='Stretch Parameters',LABEL='Set Fixed Display Data Limits:', VALUE=['Yes', 'No'])
  ;--------------
  ; SET THE CONTRAST STRETCH PARAMETERS:
  ;--------------
  IF (ST NE 1) AND (FINITE(ST) EQ 1) THEN BEGIN
    ; REPEAT...UNTIL STATEMENT: 
    CHECK_P = 0
    REPEAT BEGIN ; START 'REPEAT'
    ;--------------
    S_VALUES = FUNCTION_WIDGET_Set_Value_Pair(TITLE='Display Data Limits', LABEL_A='Minimum:', LABEL_B='Maximum:', $
      VALUE_A=0.0000, VALUE_B=100.0000, /FLOAT)
    ;--------------
    ; SET PARAMETERS
    LOW = S_VALUES[0]
    HIGH = S_VALUES[1]
    ;--------------    
    ; ERROR CHECK
    IF (HIGH LE LOW) THEN BEGIN
      PRINT, ''
      PRINT, 'THE INPUT IS NOT VALID: ', 'The Maximum value must be greater than the Minimum value!'
      CHECK_P = 1
    ENDIF ELSE CHECK_P = 0  
    ;-------------- 
    ; IF CHECK_P = 0 (I.E. 'YES') THEN EXIT THE 'REPEAT...UNTIL STATEMENT'
    ENDREP UNTIL (CHECK_P EQ 0) ; END 'REPEAT'
  ENDIF  
  ;---------------------------------------------------------------------------------------------
  ; SELECT THE OUTPUT DIRECTORY
  PATH = 'H:\Projects\NWC_Groundwater_Dependent_Ecosystems\gamma\graphics'
  OUT_DIRECTORY = DIALOG_PICKFILE(PATH=PATH, TITLE='Select the Output Directory', /DIRECTORY)
  ;--------------
  ; ERROR CHECK
  IF OUT_DIRECTORY EQ '' THEN RETURN
  ;---------------------------------------------------------------------------------------------
  ;*********************************************************************************************
  ; FILE LOOP:
  ;*********************************************************************************************
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(IN_FILES)-1 DO BEGIN ; FOR i
    ;-------------------------------------------------------------------------------------------
    ; GET START TIME: DATE LOOP
    L_TIME = SYSTIME(1)
    ;-------------------------------------------------------------------------------------------
    ; GET DATA:
    ;-----------------------------------
    FILE_IN = IN_FILES[i] ; SET THE i-TH FILE
    FNS_IN = FNS[i] ; SET THE i-TH FILENAME
    ENVI_OPEN_FILE, FILE_IN, R_FID=FID_IN, /NO_REALIZE ; OPEN FILE
    ;--------------
    ; GET MAP INFORMATION:
    ;--------------    
    ENVI_FILE_QUERY, FID_IN, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DT
    DIMS_IN = [NS, NL] ; SET FILE DIMENSIONS
    MAPINFO = ENVI_GET_MAP_INFO(FID=FID_IN)
    PROJFULL = MAPINFO.PROJ
    DATUM = MAPINFO.PROJ.DATUM
    PROJ = MAPINFO.PROJ.NAME
    UNITS = MAPINFO.PROJ.UNITS
    CXSIZE = DOUBLE(MAPINFO.PS[0])
    CYSIZE = DOUBLE(MAPINFO.PS[1])
    LEFT = DOUBLE(MAPINFO.MC[2])
    TOP = DOUBLE(MAPINFO.MC[3])
    RIGHT = LEFT + (DOUBLE(DIMS_IN[0]) * DOUBLE(CXSIZE))
    BOTTOM = TOP - (DOUBLE(DIMS_IN[1]) * DOUBLE(CYSIZE))
    ;-------------------------------------------------------------------------------------------
    DATA = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS, POS=0) ; GET DATA
    DATA_IN = DATA
    ;-----------------------------------
    INDEX_NAN = WHERE(FINITE(DATA_IN, /NAN), COUNT_FINITE) ; GET FINITE NODATA COUNT
    INDEX_INFINITE = WHERE(FINITE(DATA_IN, /INFINITY), COUNT_INFINITY) ; GET INFINITE NODATA COUNT
    ;--------------
    IF NAN_VALUE NE !VALUES.F_NAN THEN BEGIN
      nan = WHERE(DATA_IN EQ NAN_VALUE, COUNT_NAN) ; GET NODATA POSITION
      IF (COUNT_NAN GT 0) THEN DATA_IN[nan] = !VALUES.F_NAN ; SET NODATA
    ENDIF
    ;-------------------------------------------------------------------------------------------
    IF ST EQ 0 THEN BEGIN ; APPLY NEW LIMITS
      l = WHERE(DATA_IN LT LOW, COUNT_l) ; GET POSITION OF VALUES LT LOW
      IF (COUNT_l GT 0) THEN DATA_IN[l] = LOW ; SET VALUES LT LOW TO THE MINIMUM LIMIT VALUE
      h = WHERE(DATA_IN GT HIGH, COUNT_h) ; GET POSITION OF VALUES GT HIGH
      IF (COUNT_h GT 0) THEN DATA_IN[h] = HIGH ; SET VALUES GT HIGH TO THE MAXIMUM LIMIT VALUE
    ENDIF 
    ;-------------------------------------------------------------------------------------------
    ; APPLY BYTE STRETCH:
    ;--------------
    RANGE_X = 255 ; SET NEW HISTOGRAM RANGE  
    RANGE_DATA = (MAX(DATA_IN, /NAN) - MIN(DATA_IN, /NAN)) ; SET ORIGINAL HISTOGRAM RANGE (Maximum of DATA - Minimum of Data)
    SLOPE = (RANGE_X / RANGE_DATA) * 1.00 ; CALCULATE SLOPE
    INTERCEPT = (SLOPE * MIN(DATA_IN, /NAN)) ; CALCULATE INTERCEPT
    DATA_IN = FIX((SLOPE*DATA_IN)-INTERCEPT) ; APPLY STRETCH
    DATA_PNG = BYTE(TEMPORARY(DATA_IN)) ; CONVERT DATATYPE TO BYTE
    ;-------------------------------------------------------------------------------------------
    ;*******************************************************************************************
    ; DISPLAY DATA:
    ;*******************************************************************************************
    ;-------------------------------------------------------------------------------------------
    ; LOAD COLOUR TABEL
    DEVICE, DECOMPOSED = 0
    TVLCT, CT_RED, CT_GREEN, CT_BLUE  
    ;--------------
    ; SET WINDOW PARAMETERS:
    ;-------------- 
    XRANGE = [MIN(LEFT), MAX(RIGHT)]
    YRANGE = [MIN(BOTTOM), MAX(TOP)]
    ASPECTRATIO = ABS(YRANGE[1] - YRANGE[0]) / ABS(XRANGE[1]-XRANGE[0])
    IF ASPECTRATIO LE 1 THEN BEGIN ; YRANGE IS GE XRANGE
      WINDOW, XSIZE=1000, YSIZE=1000*ASPECTRATIO, /FREE
    ENDIF ELSE BEGIN ; YRANGE IS LT XRANGE
      WINDOW, XSIZE=1000*ASPECTRATIO, YSIZE=1000, /FREE
    ENDELSE
    ;ERASE, COLOR=FSC_Color(COLOUR_BACKGROUND) ; SET WINDOW BACKGROUND COLOUR
    ;--------------
    ; ESTABLISH THE MAP SPACE (SET MAP PROJECTION OF DISPLAY WINDOW) - Default is Cylindrical Equidistant
    IF BT EQ 0 THEN MAP_SET, LIMIT=[BOTTOM, LEFT, TOP, RIGHT], COLOR=FSC_Color(COLOUR_BORDER) ; INC. BORDER
    IF BT EQ 1 THEN MAP_SET, LIMIT=[BOTTOM, LEFT, TOP, RIGHT], /NOBORDER
    ;--------------
    ; WARP THE INPUT DATA TO THE MAP SPACE
    WARP_IMAGE = MAP_IMAGE(DATA_PNG, STARTX, STARTY, XSIZE, YSIZE, COMPRESS=1, MAP_STRUCTURE=PROJ, $
      LATMIN=BOTTOM, LONMIN=LEFT, LATMAX=TOP, LONMAX=RIGHT)
    ;--------------
    ; DRAW WARPED IMAGE IN THE DISPLAY WINDOW
    TVIMAGE, WARP_IMAGE, STARTX, STARTY, XSIZE=XSIZE, YSIZE=YSIZE, /ORDER, /TV
    IMAGE_A = TVREAD(XSTART, YSTART, NCOLS, NROWS) ; RETURN DISPLAY WINDOW AS 24BIT IMAGE
    ;-------------------------------------------------------------------------------------------
    ; CREATE NODATA IMAGE:
    ;-----------------------------------
    IF FINITE(NAN_VALUE) EQ 1 THEN BEGIN
      DATA_NAN = DATA ; SET DATA VARIABLE
      ;--------------
      IF NAN_VALUE LE 0 THEN BEGIN
        nan = WHERE(DATA_NAN NE NAN_VALUE, COUNT_NAN) ; GET NODATA POSITION
        IF (COUNT_NAN GT 0) THEN DATA_NAN[nan] = 1 ; SET NON NODATA ELEMENTS TO 1
      ENDIF ELSE BEGIN
        nan = WHERE(DATA_NAN NE NAN_VALUE, COUNT_NAN) ; GET NODATA POSITION
        IF (COUNT_NAN GT 0) THEN DATA_NAN[nan] = 0 ; SET NON NODATA ELEMENTS TO 0
      ENDELSE
      ;--------------
      ; SET NON NODATA ELEMENTS TO BE WHITE
      IF NAN_VALUE LE 0 THEN NAN_R[255] = 255 ELSE NAN_R[0] = 255
      IF NAN_VALUE LE 0 THEN NAN_G[255] = 255 ELSE NAN_G[0] = 255
      IF NAN_VALUE LE 0 THEN NAN_B[255] = 255 ELSE NAN_B[0] = 255
      ;--------------
      ; LOAD THE NODATA COLOUR TABEL
      TVLCT, NAN_R, NAN_G, NAN_B
      ;--------------
      ; WARP THE INPUT DATA TO THE MAP SPACE
      WARP_NAN = MAP_IMAGE(DATA_NAN, STARTX, STARTY, XSIZE, YSIZE, COMPRESS=1, MAP_STRUCTURE=PROJ, $
        LATMIN=BOTTOM, LONMIN=LEFT, LATMAX=TOP, LONMAX=RIGHT)
      ;--------------
      ; DRAW WARPED IMAGE IN THE DISPLAY WINDOW
      TVIMAGE, WARP_NAN, STARTX, STARTY, XSIZE=XSIZE, YSIZE=YSIZE, /ORDER, /TV
      IMAGE_B = TVREAD(XSTART, YSTART, NCOLS, NROWS) ; RETURN DISPLAY WINDOW AS 24BIT IMAGE
      ;-----------------------------------
      ; SET NON NODATA ELEMENTS TO BE TRANSPARENT: (SET WHITE PIXELS AS TRANSPARENT)
      ;-----------------------------------
      IMAGE_B2 = TRANSPOSE(IMAGE_B, [1,2,0]) ; SET IMAGE AS FRAME-INTERLEAVED (FOR MANIPULATION)
      ;--------------
      ; GET COLOUR VECTORS
      NAN_R2 = IMAGE_B2[*,*,0]
      NAN_G2 = IMAGE_B2[*,*,1]
      NAN_B2 = IMAGE_B2[*,*,2]
      ;--------------
      ; GET POSITION OF NON NODATA ELEMENTS (WHITE COLOURED PIXELS)
      WHITE_INDEX = WHERE((NAN_R2 EQ 255) AND (NAN_G2 EQ 255) AND (NAN_B2 EQ 255), COUNT)
      ;--------------        
      s = Size(IMAGE_B2, /DIMENSIONS) ; GET WARPED IMAGE DIMENSIONS
      XSIZE_B2 = s[0] & YSIZE_B2 = s[1] ; SET ALPHA VECTOR DIMENSIONS
      ALPHA = BYTARR(XSIZE_B2, YSIZE_B2) + 255B ; CREATE ALPHA VECTOR
      IF COUNT GT 0 THEN ALPHA[WHITE_INDEX] = 0 ; UPDATE ALPHA VECTOR (SET TRANSPARENT ELEMENTS AS 0)
      IMAGE_TRANSPARENT = [[[NAN_R2]], [[NAN_G2]], [[NAN_B2]], [[ALPHA]]] ; BUILD THE TRANSPARENT IMAGE
      IMAGE_TRANSPARENT = TRANSPOSE(IMAGE_TRANSPARENT, [2,0,1]) ; SET IMAGE AS PIXEL-INTERLEAVED (FOR DISPLAY OR WRITING)
      ; AT THIS POINT YOU CLOUD WRITE THE NODATA IMAGE (WITH TRANSPARENCY) TO DISK i.e. WRITE_PNG, 'C:\TMP3.png', IMAGE_TRANSPARENT
      ;-----------------------------------
      ; COMBINE THE TRANSPARENT NODATA IMAGE AND THE ORIGINAL DATA IMAGE:
      ;-----------------------------------  
      IMAGE_B3 = TRANSPOSE(IMAGE_TRANSPARENT, [1,2,0]) ; SET IMAGE AS FRAME-INTERLEAVED (FOR MANIPULATION)
      ALPHA_VECTOR = IMAGE_B3[*,*,3] ; GET ALPHA VECTOR
      SCALED_ALPHA = SCALE_VECTOR(ALPHA_VECTOR , 0.0,  1.0) ; SCALE ALPHA VECTOR FROM 0 255 TO 0 1
      s = Size(IMAGE_B3[*,*,0:2], /DIMENSIONS) ; GET IMAGE DIMENSIONS   
      ALPHA = REBIN(SCALED_ALPHA, s[0], s[1], s[2]) ; RESIZE ALPHA (AS A STAND ALONE 24BIT IMAGE)      
      FOREGROUND = IMAGE_B3[*,*,0:2] ; SET FORGROUND IMAGE (TRANSPARENT NODATA IMAGE)
      ;--------------
      BACKGROUND = TRANSPOSE(IMAGE_A, [1,2,0]) ; SET ORIGINAL DATA IMAGE AS FRAME-INTERLEAVED
      IMAGE_COMBINE = FOREGROUND*ALPHA + (1 - ALPHA) * BACKGROUND ; USE ALPHA FORMULA TO COMBINE THE FOREGROUND AND BACKGROUND
      ;--------------
      TVIMAGE, IMAGE_COMBINE, TRUE=3, STARTX, STARTY, XSIZE=XSIZE, YSIZE=YSIZE ; DRAW COMBINED IMAGE IN THE DISPLAY WINDOW
      ;-----------------------------------
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; ADD IMAGE ANNOTATION
    ;-----------------------------------
    IF AT EQ 0 THEN BEGIN
      !P.FONT = 0 ; ENABLE DEVICE (MS WINDOWS) FONTS
      ;--------------
      IF (FINITE(TEXT_IN) EQ 0) THEN ANNOTATION = FNS_IN ELSE ANNOTATION = TEXT_IN
      ;--------------
      ; SET DRAW COORDINATES:
      ;--------------      
      MID_X = (STARTX + XSIZE)/2 ; CENTRE
      END_X = (STARTX + XSIZE) ; RIGHT
      END_Y = (STARTY + YSIZE) ; TOP
      ;--------------      
      IF POSITION EQ 0 THEN BEGIN ; Upper Left
        XPOS = STARTX+(10*CSIZE)
        YPOS = END_Y-(20*CSIZE)
        XYOUTS, LONG(XPOS), LONG(YPOS), ANNOTATION, ORIENTATION=ORIENTATION, COLOR=FSC_Color(COLOUR_TEXT), $    
          CHARSIZE=CSIZE, CHARTHICK=CTHICK, FONT=1, ALIGNMENT=0.0, /DEVICE
      ENDIF      
      IF POSITION EQ 1 THEN BEGIN ; Centre Top
        XPOS = MID_X
        YPOS = END_Y-(20*CSIZE)
        XYOUTS, LONG(XPOS), LONG(YPOS), ANNOTATION, ORIENTATION=ORIENTATION, COLOR=FSC_Color(COLOUR_TEXT), $    
          CHARSIZE=CSIZE, CHARTHICK=CTHICK, FONT=1, ALIGNMENT=0.5, /DEVICE
      END      
      IF POSITION EQ 2 THEN BEGIN ; Upper Right
        XPOS = END_X-(10*CSIZE)
        YPOS = END_Y-(20*CSIZE)
        XYOUTS, LONG(XPOS), LONG(YPOS), ANNOTATION, ORIENTATION=ORIENTATION, COLOR=FSC_Color(COLOUR_TEXT), $    
          CHARSIZE=CSIZE, CHARTHICK=CTHICK, FONT=1, ALIGNMENT=1.0, /DEVICE
      END
      IF POSITION EQ 3 THEN BEGIN ; Lower Left
        XPOS = STARTX+(10*CSIZE) 
        YPOS = STARTY+(5*CSIZE)  
        XYOUTS, LONG(XPOS), LONG(YPOS), ANNOTATION, ORIENTATION=ORIENTATION, COLOR=FSC_Color(COLOUR_TEXT), $    
          CHARSIZE=CSIZE, CHARTHICK=CTHICK, FONT=1, ALIGNMENT=0.0, /DEVICE
      ENDIF
      IF POSITION EQ 4 THEN BEGIN ; Centre Bottom
        XPOS = MID_X
        YPOS = STARTY+(5*CSIZE) 
        XYOUTS, LONG(XPOS), LONG(YPOS), ANNOTATION, ORIENTATION=ORIENTATION, COLOR=FSC_Color(COLOUR_TEXT), $    
          CHARSIZE=CSIZE, CHARTHICK=CTHICK, FONT=1, ALIGNMENT=0.5, /DEVICE
      ENDIF
      IF POSITION EQ 5 THEN BEGIN ; Lower Right
        XPOS = END_X-(10*CSIZE)
        YPOS = STARTY+(5*CSIZE) 
        XYOUTS, LONG(XPOS), LONG(YPOS), ANNOTATION, ORIENTATION=ORIENTATION, COLOR=FSC_Color(COLOUR_TEXT), $    
          CHARSIZE=CSIZE, CHARTHICK=CTHICK, FONT=1, ALIGNMENT=1.0, /DEVICE
      ENDIF
      ;-----------------------------------
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; DRAW SHAPEFILE
    ;-----------------------------------
    IF VT EQ 0 THEN BEGIN
      
      FOR s=0, N_ELEMENTS(IN_SHAPE)-1 DO BEGIN
        SHAPE = OBJ_NEW('IDLffShape', IN_SHAPE[s]) ; OPEN THE SHAPEFILE AND CREATE THE SHAPE OBJECT
        SHAPE ->GetProperty, ATTRIBUTE_NAMES=ATNAMES ; GET ATTRIBUTE NAMES
        SHAPE ->IDLffShape::GetProperty, N_ENTITIES=NUM_ENT ; GET ENTITIES (SHAPES)
        ENTITIES = PTR_NEW(/ALLOCATE_HEAP) ; Get all attribute pointers from the file
        *ENTITIES = SHAPE ->GetEntity(/ALL, /ATTRIBUTES)
        
        ;--------------
        FOR k=0, N_ELEMENTS(*ENTITIES)-1 DO BEGIN
          ENTITY = (*ENTITIES)[k] ; SET THE kTH ENTITY
          IF ENTITY.shape_type EQ 5 OR ENTITY.shape_type EQ 15 OR  ENTITY.shape_type EQ 25 THEN BEGIN
            ; Polygon = 5
            ; PolygonZ (ignoring Z) = 15
            ; PolygonM (ignoring M) = 25
            IF PTR_VALID(ENTITY.parts) THEN BEGIN
              CUTS = [*ENTITY.parts, ENTITY.n_vertices]
              FOR j=0, ENTITY.n_parts-1 DO BEGIN ; LOOP THROUGH EACH POLYGON
                CX = (*ENTITY.vertices)[0, CUTS[j]:CUTS[j+1]-1] ; VECTOR NODES X
                CY = (*ENTITY.vertices)[1, CUTS[j]:CUTS[j+1]-1] ; VECTOR NODES Y         
                IF COLOUR_FILL[s] NE '-1' THEN POLYFILL, CX, CY, COLOR=FSC_Color(COLOUR_FILL[s])            
                PLOTS, CX, CY, COLOR=FSC_Color(COLOUR_LINE[s]), LINESTYLE=LINESTYLE[s], THICK=THICKNESS[s]              
              ENDFOR
            ENDIF
          ENDIF
          
          ;--------------   
          IF ENTITY.shape_type EQ 3 OR  ENTITY.shape_type EQ 13 OR ENTITY.shape_type EQ 23 THEN BEGIN 
            ; PolyLine = 3
            ; PolyLineZ (ignoring Z) = 13
            ; PolyLineM (ignoring M) = 23
            IF Ptr_Valid(ENTITY.parts) THEN BEGIN
              CUTS = [*ENTITY.parts, entity.n_vertices]
              FOR j=0, ENTITY.n_parts-1 DO BEGIN ; LOOP THROUGH EACH POLYLINE
                PlotS, (*ENTITY.vertices)[0, CUTS[j]:CUTS[j+1]-1], (*ENTITY.vertices)[1, CUTS[j]:CUTS[j+1]-1], $
                  COLOR=FSC_Color(COLOUR_LINE[s]), LINESTYLE=LINESTYLE[s], THICK=THICKNESS[s]
              ENDFOR
            ENDIF
          ENDIF
          
        ENDFOR
        
        ;-----------------------------------
        ; CLEAN UP
        SHAPE->IDLffShape::DestroyEntity, ENTITY ; DELETE SHAPEFILE POINTER
        OBJ_DESTROY, SHAPE ; CLOSE SHAPEFILE
        ;-----------------------------------
        
        
      ENDFOR
      ;-----------------------------------
    ENDIF
    ;------------------------------------------------------------------------------------------- 
    ; WRITE DATA:
    ;-----------------------------------
    OUTNAME = OUT_DIRECTORY + FNS_IN + '.png' ; BUILD OUTNAME
    WRITE_PNG, OUTNAME, TVRD(/TRUE)
    ;--------------
    ; CLEAN UP:
    WDELETE ; DELETE IMAGE WINDOW
    ;-------------------------------------------------------------------------------------------
    ; PRINT LOOP INFORMATION:
    ;-----------------------------------   
    ; GET END TIME
    SECONDS = (SYSTIME(1)-L_TIME)
    ;--------------
    PRINT, '  PROCESSING TIME: ', STRTRIM(SECONDS, 2), ' SECONDS, FOR FILE ', STRTRIM(i+1, 2), ' OF ', $
      STRTRIM(N_ELEMENTS(IN_FILES), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
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
  PRINT,'FINISHED PROCESSING: BATCH_DOIT_Create_PNG_PLUS'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

 