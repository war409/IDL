; ##############################################################################################
; NAME: Batch_Create_PNG.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 29/10/2010
; DLM: 14/09/2011
;
; DESCRIPTION: This tool create one PNG file for each input file.
;
; INPUT:       One or more ENVI compatible single-band grids. The current input file filter is set 
;              as: ['*.tif','*.img','*.flt','*.bin']. If you select one or more multi-band grids the
;              tool will still function however it will produce an output PNG for the first band only. 
;
; OUTPUT:      One PNG file (.png) for each input file or band.
;               
; PARAMETERS:  Define the parameters via in-program pop-up dialog widgets.
;              
; NOTES:       An interactive ENVI session is needed to run this tool.
; 
;              This program calls one or more external functions. You will need to compile the  
;              necessary functions in IDL, or save the functions to the current IDL workspace  
;              prior to running this tool. To open a different workspace, select Switch  
;              Workspace from the File menu.
;               
;              For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO Batch_Create_PNG
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Batch_Create_PNG'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\Tidalwave-bu\H$\projects\NWC_Groundwater_Dependent_Ecosystems\gamma\graphics\'
  ;Path='H:\projects\NWC_Groundwater_Dependent_Ecosystems\gamma\graphics\data\cmrset.monthly.bias.500m'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_Files = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_Files[0] EQ '' THEN RETURN ; Error check.
  In_Files = In_Files[BSORT(In_Files)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_Files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_Files)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS = MAKE_ARRAY(N_ELEMENTS(In_Files), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(In_Files[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  In_Dates = FUNCTION_WIDGET_Date(IN_FILES=FNS, /JULIAN) ; Get the input file name dates.
  IF In_Dates[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_Files = In_Files[SORT(In_Dates)] ; Sort file name by date.
    FNS = FNS[SORT(In_Dates)] ; Sort file name by date.
    Dates_Unique = In_Dates[UNIQ(In_Dates)] ; Get unique input dates.
    Dates_Unique = Dates_Unique[BSORT(Dates_Unique)] ; Sort the unique dates.   
    Dates_Unique = Dates_Unique[UNIQ(Dates_Unique)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; Set the color table:
  XCOLORS, TITLE='Load Colour Table', COLORINFO=COLORINFO_STRUCT, /BLOCK
  ;-------------- ; Set color table parameters
  CT_RED = COLORINFO_STRUCT.R
  CT_GREEN = COLORINFO_STRUCT.G
  CT_BLUE = COLORINFO_STRUCT.B
  CT_TYPE = COLORINFO_STRUCT.TYPE
  CT_NAME = COLORINFO_STRUCT.NAME
  CT_INDEX = COLORINFO_STRUCT.INDEX
  ;---------------------------------------------------------------------------------------------
  ; Set No Data:
  No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='9999.00', /FLOAT)
  IF (No_DATA[0] NE -1) THEN NaN = No_DATA[1] ; Set NaN value.
  ;--------------
  IF (No_DATA[0] NE -1) THEN BEGIN
    COLOUR_NODATA = PICKCOLORNAME(TITLE='Select The No-Data Colour') ; Set the no data colour.
    TRIPLE_NODATA = FSC_Color(COLOUR_NODATA, /TRIPLE) ; Get the no data triple.
    ;-------------- ; Set the nodata colour table:
    NAN_R = FINDGEN(256)
    NAN_G = FINDGEN(256)
    NAN_B = FINDGEN(256)
    NAN_R[*] = TRIPLE_NODATA[0] ; Fill red vector.
    NAN_G[*] = TRIPLE_NODATA[1] ; Fill green vector.
    NAN_B[*] = TRIPLE_NODATA[2] ; Fill blue vector.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set the input shapefile:
  AddShape = FUNCTION_WIDGET_Droplist(TITLE='Add Shapefile To The Map:', VALUE=['Add Shapefile', 'Do Not Add Shapefile'])
  ;-------------- ; Select the input shapefile:
  IF (AddShape[0] EQ 0) THEN BEGIN
    Path = '\\wron\Working\work\war409\tmp'
    IN_SHAPE = DIALOG_PICKFILE(PATH=Path, TITLE='Select the Input Shapefile', FILTER=['*.shp'], /MULTIPLE_FILES, /MUST_EXIST)
    IF IN_SHAPE[0] EQ '' THEN RETURN ; Error check.
    ;-------------- ; Set the shapefile parameters:
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
  ; Set Annotation:
  AddAnnotation = FUNCTION_WIDGET_Droplist(TITLE='Add Annotation To The Map:', VALUE=['Add Annotation', 'Do Not Add Annotation'])
  IF (AddAnnotation[0] EQ 0) THEN BEGIN
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
  ; Set the contrast stretch:
  ST = FUNCTION_WIDGET_Droplist(TITLE='Stretch Parameters:', VALUE=['Set Fixed Display Limits', 'Do Not Set Fixed Display Limits'])
  ;-------------- ;  Set the contrast stretch parameters:
  IF (ST NE 1) AND (FINITE(ST) EQ 1) THEN BEGIN
    CHECK_P = 0 ; Repeat / until statement:
    REPEAT BEGIN
      S_VALUES = FUNCTION_WIDGET_Set_Value_Pair(TITLE='Display Data Limits', LABEL_A='Minimum:', LABEL_B='Maximum:', VALUE_A=0.0000, VALUE_B=120.0000, /FLOAT)
      low = S_VALUES[0]
      high = S_VALUES[1]
      IF (high LE low) THEN BEGIN ; Error check.
        PRINT, ''
        PRINT, 'THE INPUT IS NOT VALID: ', 'The Maximum value must be greater than the Minimum value!'
        CHECK_P = 1
      ENDIF ELSE CHECK_P = 0
    ENDREP UNTIL (CHECK_P EQ 0)
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='\\Tidalwave-bu\H$\projects\NWC_Groundwater_Dependent_Ecosystems\gamma\graphics\cmrset\'
  ;Path='H:\projects\NWC_Groundwater_Dependent_Ecosystems\gamma\graphics\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; File loop:
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN
    LoopStartTime_File = SYSTIME(1) ; Get the loop start time.
    ;-------------- ; Manipulate dates:
    CALDAT, Dates_Unique[i], iM, iD, iY ; Convert the i-th julday to calday.
    IF (iM LE 9) THEN M_String = '0' + STRING(STRTRIM(iM,2)) ELSE M_String = STRING(STRTRIM(iM,2))  ; Add leading zero.
    IF (iD LE 9) THEN D_String = '0' + STRING(STRTRIM(iD,2)) ELSE D_String = STRING(STRTRIM(iD,2))  ; Add leading zero.
    Y_String = STRING(STRTRIM(iY,2))
    IF iM EQ 1 THEN Month = "January"
    IF iM EQ 2 THEN Month = "February"
    IF iM EQ 3 THEN Month = "March"
    IF iM EQ 4 THEN Month = "April"
    IF iM EQ 5 THEN Month = "May"
    IF iM EQ 6 THEN Month = "June"
    IF iM EQ 7 THEN Month = "July"
    IF iM EQ 8 THEN Month = "August"
    IF iM EQ 9 THEN Month = "September"
    IF iM EQ 10 THEN Month = "October"
    IF iM EQ 11 THEN Month = "November"
    IF iM EQ 12 THEN Month = "December"
    ;-------------- ; Set input:
    ENVI_OPEN_FILE, In_Files[i], R_FID=FID_IN, /NO_REALIZE ; Open file.
    ENVI_FILE_QUERY, FID_IN, DIMS=DIMS, NS=NS, NL=NL, NB=NB, BNAMES=BNAMES, FNAME=FNAME, DATA_TYPE=DT ; Get map information.
    DIMS_IN = [NS, NL]
    MAPINFO = ENVI_GET_MAP_INFO(FID=FID_IN)
    PROJFULL = MAPINFO.PROJ
    DATUM = MAPINFO.PROJ.DATUM
    PROJ = MAPINFO.PROJ.NAME
    UNITS = MAPINFO.PROJ.UNITS
    CXSIZE = FLOAT(MAPINFO.PS[0])
    CYSIZE = FLOAT(MAPINFO.PS[1])
    LEFT = FLOAT(MAPINFO.MC[2])
    TOP = FLOAT(MAPINFO.MC[3])
    RIGHT = LEFT + (FLOAT(DIMS_IN[0]) * FLOAT(CXSIZE))
    BOTTOM = TOP - (FLOAT(DIMS_IN[1]) * FLOAT(CYSIZE))
    ;-------------- ; Get data:
    DATA = ENVI_GET_DATA(FID=FID_IN, DIMS=DIMS, POS=0)
    DATA_IN = DATA
    ;-------------- ; Reset NaN:
    IF (No_DATA[0] NE -1) THEN BEGIN
      index_nan = WHERE(DATA_IN EQ NaN, COUNT_NAN)
      IF (COUNT_NAN GT 0) THEN DATA_IN[index_nan] = !VALUES.F_NAN
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Set data limits:
    IF ST EQ 0 THEN BEGIN 
      l = WHERE(DATA_IN LT LOW, COUNT_l)
      IF (COUNT_l GT 0) THEN DATA_IN[l] = LOW
      h = WHERE(DATA_IN GT HIGH, COUNT_h)
      IF (COUNT_h GT 0) THEN DATA_IN[h] = HIGH
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Set byte stretch:
    RANGE_X = 255 ; Set the new histogram range.  
    RANGE_DATA = (MAX(DATA_IN, /NAN) - MIN(DATA_IN, /NAN)) ; Get the original histogram range.
    SLOPE = (RANGE_X / RANGE_DATA) * 1.00 ; Calculate slope.
    INTERCEPT = (SLOPE * MIN(DATA_IN, /NAN)) ; Calculate intercept.
    DATA_IN2 = FIX((SLOPE*DATA_IN)-INTERCEPT) ; Apply stretch.
    DATA_PNG = BYTE(DATA_IN2) ; Convert data to byte format.
    ;-------------------------------------------------------------------------------------------
    ; Display data:
    ;-------------------------------------------------------------------------------------------
    DEVICE, DECOMPOSED = 0
    TVLCT, CT_RED, CT_GREEN, CT_BLUE ; Load the selected colour table.
    ;-------------- ; Set the map window:
    XRANGE = [MIN(LEFT), MAX(RIGHT)]
    YRANGE = [MIN(BOTTOM), MAX(TOP)]
    ASPECTRATIO = ABS(YRANGE[1] - YRANGE[0]) / ABS(XRANGE[1]-XRANGE[0])
    IF ASPECTRATIO LE 1 THEN BEGIN ; If the Y-range is GE X-range:
      WINDOW, XSIZE=2500, YSIZE=2500*ASPECTRATIO, /FREE
    ENDIF ELSE BEGIN ; If the Y-range is LT X-range:
      WINDOW, XSIZE=2500*ASPECTRATIO, YSIZE=2500, /FREE
    ENDELSE
    MAP_SET, LIMIT=[BOTTOM, LEFT, TOP, RIGHT], /NOBORDER ; Set the map space (inc. the map projection of the display window).
    WARP_IMAGE = MAP_IMAGE(DATA_PNG, STARTX, STARTY, XSIZE, YSIZE, COMPRESS=1, $ ; Warp the input data to the map space.
      MAP_STRUCTURE=PROJ, LATMIN=BOTTOM, LONMIN=LEFT, LATMAX=TOP, LONMAX=RIGHT)
    TVIMAGE, WARP_IMAGE, STARTX, STARTY, XSIZE=XSIZE, YSIZE=YSIZE, /ORDER, /TV ; Draw warped image in the display window.
    IMAGE_A = TVREAD(XSTART, YSTART, NCOLS, NROWS) ; Save the display window as a 24 bit image.
    ;-------------- ; Create the no data mask:
    IF (No_DATA[0] NE -1) THEN BEGIN
      index_nan = WHERE(DATA NE NaN, COUNT_NAN)
      IF (COUNT_NAN GT 0) THEN DATA[index_nan] = 0 ; Set non-NaN elements as 0.
      ;-------------- ; Set non-NaN elements as white:
      NAN_R[0] = 255
      NAN_G[0] = 255
      NAN_B[0] = 255
      ;TVLCT, NAN_R, NAN_G, NAN_B ; Load the no-data colour table.
      WARP_NAN = MAP_IMAGE(DATA, STARTX, STARTY, XSIZE, YSIZE, COMPRESS=1, $ ; Warp the input data to the map space.
      MAP_STRUCTURE=PROJ, LATMIN=BOTTOM, LONMIN=LEFT, LATMAX=TOP, LONMAX=RIGHT)
      TVIMAGE, WARP_NAN, STARTX, STARTY, XSIZE=XSIZE, YSIZE=YSIZE, /ORDER, /TV ; Draw warped image in the display window.
      IMAGE_B = TVREAD(XSTART, YSTART, NCOLS, NROWS) ; Save the display window as a 24 bit image.
      ;-------------- ; Set non-NaN elements as transparent.
      IMAGE_A2 = TRANSPOSE(IMAGE_A, [1,2,0]) ; Get the transpose (frame-interleaved for manipulation) of the 24 bit image of the input data.
      NAN_R3 = IMAGE_A2[*,*,0] ; Get the red vector.
      NAN_G3 = IMAGE_A2[*,*,1] ; Get the green vector.
      NAN_B3 = IMAGE_A2[*,*,2] ; Get the blue vector.
      size = Size(IMAGE_A2, /DIMENSIONS) ; Get the dimensions of the 24 bit image.
      ALPHA = BYTARR(size[0], size[1]) + 255B ; Create the alpha vector.
      TMP = MAKE_ARRAY(size[0], size[1], VALUE = 255) ; Create an array to hold the no data mask.
      IF MAX(IMAGE_B[2,*,*]) GT 0 THEN BEGIN
        TMP[*,*] = IMAGE_B[2,*,*] 
        index_nan = WHERE(TMP EQ max(IMAGE_B[2,*,*]), COUNT_NAN) ; Get index of non-NaN elements.
      ENDIF ELSE BEGIN 
        TMP[*,*] = IMAGE_B[1,*,*]
        index_nan = WHERE(TMP EQ max(IMAGE_B[1,*,*]), COUNT_NAN) ; Get index of non-NaN elements.
      ENDELSE
      ALPHA[index_nan] = 0 ; Set non-NaN elements as 0. No-data elements will remain 255.
      IMAGE_TRANSPARENT = [[[NAN_R3]], [[NAN_G3]], [[NAN_B3]], [[ALPHA]]] ; Build the no-data mask image.
      IMAGE_TRANSPARENT = TRANSPOSE(IMAGE_TRANSPARENT, [2,0,1]) ; Set the no-data image as pixel-interleaved (for display or writing).
      ;-------------- ; Combine the no-data mask image and the original 24 bit image of the input data.
      IMAGE_B3 = TRANSPOSE(IMAGE_TRANSPARENT, [1,2,0]) ; Set no-data mask image as frame-interleaved (for manipulation).
      alpha_channel = IMAGE_B3[*,*,3] ; Get the image alpha channel.
      SCALED_ALPHA = SCALE_VECTOR(alpha_channel, 0.0,  1.0) ; Scale the alpha channel from 0.0 to 1.0.
      size = Size(IMAGE_B3[*,*,0:2], /DIMENSIONS) ; Get the dimensions of the no-data mask image.
      ALPHA = REBIN(SCALED_ALPHA, size[0], size[1], size[2]) ; Format the alpha channel as a stand alone 24 bit image.   
      FOREGROUND = IMAGE_B3[*,*,0:2] ; Set the foreground image (no-data masked input image).
      BACKGROUND = BYTARR(size[0], size[1], 3) + 255B ; Set the background image.
      IMAGE_COMBINE = FOREGROUND*ALPHA + (1 - ALPHA)*BACKGROUND ; Combine the foreground and background images.
      TVIMAGE, IMAGE_COMBINE, TRUE=3, STARTX, STARTY, XSIZE=XSIZE, YSIZE=YSIZE ; Draw the combined image in the display window.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Draw shapefile:
    ;-------------------------------------------------------------------------------------------
    IF (AddShape[0] EQ 0) THEN BEGIN
      FOR s=0, N_ELEMENTS(IN_SHAPE)-1 DO BEGIN
        SHAPE = OBJ_NEW('IDLffShape', IN_SHAPE[s]) ; Open the current shapefile and create the shapefile object.
        SHAPE ->GetProperty, ATTRIBUTE_NAMES=ATNAMES ; Get the attribute names.
        SHAPE ->IDLffShape::GetProperty, N_ENTITIES=NUM_ENT ; Get the shapefile entities.
        ENTITIES = PTR_NEW(/ALLOCATE_HEAP) ; Get all attribute pointers from the file
        *ENTITIES = SHAPE ->GetEntity(/ALL, /ATTRIBUTES)
        FOR k=0, N_ELEMENTS(*ENTITIES)-1 DO BEGIN
          ENTITY = (*ENTITIES)[k] ; Set the currrent entity.
          ;-------------- ; Draw point or polygon elements:
          IF ENTITY.shape_type EQ 5 OR ENTITY.shape_type EQ 15 OR  ENTITY.shape_type EQ 25 THEN BEGIN 
            IF PTR_VALID(ENTITY.parts) THEN BEGIN
              CUTS = [*ENTITY.parts, ENTITY.n_vertices]
              FOR j=0, ENTITY.n_parts-1 DO BEGIN ; Loop through each shapefile element (point or polygon elements only):
                CX = (*ENTITY.vertices)[0, CUTS[j]:CUTS[j+1]-1] ; X-vector nodes.
                CY = (*ENTITY.vertices)[1, CUTS[j]:CUTS[j+1]-1] ; Y-vector nodes.
                IF COLOUR_FILL[s] NE '-1' THEN POLYFILL, CX, CY, COLOR=FSC_Color(COLOUR_FILL[s])            
                PLOTS, CX, CY, COLOR=FSC_Color(COLOUR_LINE[s]), LINESTYLE=LINESTYLE[s], THICK=THICKNESS[s]              
              ENDFOR
            ENDIF
          ENDIF
          ;-------------- ; Draw polyline elements:
          IF ENTITY.shape_type EQ 3 OR  ENTITY.shape_type EQ 13 OR ENTITY.shape_type EQ 23 THEN BEGIN 
            IF Ptr_Valid(ENTITY.parts) THEN BEGIN
              CUTS = [*ENTITY.parts, entity.n_vertices]
              FOR j=0, ENTITY.n_parts-1 DO BEGIN ; Loop through each shapefile element (polyline elements only):
                PlotS, (*ENTITY.vertices)[0, CUTS[j]:CUTS[j+1]-1], (*ENTITY.vertices)[1, CUTS[j]:CUTS[j+1]-1], $
                  COLOR=FSC_Color(COLOUR_LINE[s]), LINESTYLE=LINESTYLE[s], THICK=THICKNESS[s]
              ENDFOR
            ENDIF
          ENDIF
        ENDFOR
        SHAPE->IDLffShape::DestroyEntity, ENTITY ; Delete shapefile pointer.
        OBJ_DESTROY, SHAPE ; Close shapefile.
      ENDFOR
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Add annotation:
    ;-------------------------------------------------------------------------------------------
    IF (AddAnnotation[0] EQ 0) THEN BEGIN
      !P.FONT = 0 ; Enable device (ms windows) fonts.
      ;annotation = Month + '  ' + Y_string
      annotation = Month
      ;-------------- ; Set the draw coordinates:
      MID_X = (STARTX + XSIZE)/2 ; Centre.
      END_X = (STARTX + XSIZE) ; Right.
      END_Y = (STARTY + YSIZE) ; Top.
      ;-------------- ; Draw at upper left:
      IF (POSITION EQ 0) THEN BEGIN
        XPOS = STARTX+(10*CSIZE)
        YPOS = END_Y-(20*CSIZE)
        XYOUTS, LONG(XPOS),LONG(YPOS),annotation,ORIENTATION=ORIENTATION,COLOR=FSC_Color(COLOUR_TEXT),CHARSIZE=CSIZE,CHARTHICK=CTHICK,FONT=1,ALIGNMENT=0.0,/DEVICE
      ENDIF
      ;-------------- ; Draw at centre top:
      IF (POSITION EQ 1) THEN BEGIN
        XPOS = MID_X
        YPOS = END_Y-(20*CSIZE)
        XYOUTS, LONG(XPOS),LONG(YPOS),annotation,ORIENTATION=ORIENTATION,COLOR=FSC_Color(COLOUR_TEXT),CHARSIZE=CSIZE,CHARTHICK=CTHICK,FONT=1,ALIGNMENT=0.5,/DEVICE
      END
      ;-------------- ; Draw at upper right:
      IF (POSITION EQ 2) THEN BEGIN
        XPOS = END_X-(10*CSIZE)
        YPOS = END_Y-(20*CSIZE)
        XYOUTS, LONG(XPOS),LONG(YPOS),annotation,ORIENTATION=ORIENTATION,COLOR=FSC_Color(COLOUR_TEXT),CHARSIZE=CSIZE,CHARTHICK=CTHICK,FONT=1,ALIGNMENT=1.0,/DEVICE
      END
      ;-------------- ; Draw at lower left:
      IF (POSITION EQ 3) THEN BEGIN
        XPOS = STARTX+(10*CSIZE)
        YPOS = STARTY+(5*CSIZE)
        XYOUTS, LONG(XPOS),LONG(YPOS),annotation,ORIENTATION=ORIENTATION,COLOR=FSC_Color(COLOUR_TEXT),CHARSIZE=CSIZE,CHARTHICK=CTHICK,FONT=1,ALIGNMENT=0.0,/DEVICE
      ENDIF
      ;-------------- ; Draw at centre bottom:
      IF (POSITION EQ 4) THEN BEGIN
        XPOS = MID_X
        YPOS = STARTY+(5*CSIZE)
        XYOUTS, LONG(XPOS),LONG(YPOS),annotation,ORIENTATION=ORIENTATION,COLOR=FSC_Color(COLOUR_TEXT),CHARSIZE=CSIZE,CHARTHICK=CTHICK, FONT=1,ALIGNMENT=0.5,/DEVICE
      ENDIF
      ;-------------- ; Draw at lower right:
      IF (POSITION EQ 5) THEN BEGIN
        XPOS = END_X-(10*CSIZE)
        YPOS = STARTY+(5*CSIZE)
        XYOUTS, LONG(XPOS),LONG(YPOS),annotation,ORIENTATION=ORIENTATION,COLOR=FSC_Color(COLOUR_TEXT),CHARSIZE=CSIZE,CHARTHICK=CTHICK,FONT=1,ALIGNMENT=1.0,/DEVICE
      ENDIF
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Write image to file:
    ;-------------------------------------------------------------------------------------------
    OUTNAME = OUT_DIRECTORY + FNS[i] + '.png' ; Set the output filename.
    sz = Size(WARP_NAN[*,*], /DIMENSIONS)
    WRITE_PNG, OUTNAME, TVRD(STARTX,STARTY,sz[0],sz[1],/TRUE) ; Write.
    WDELETE ; Destroy image window.
    ;-------------------------------------------------------------------------------------------
    Minutes = (SYSTIME(1)-LoopStartTime_File)/60 ; Get the file loop end time
    PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for file ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(In_Files), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60 ; Subtract the program End-Time from the program Start-Time.
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2), ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

 