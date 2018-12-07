; ##############################################################################################
; NAME: Batch_Spatial_Resample.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 18/02/2010
; DLM: 09/05/2011
;
; DESCRIPTION:  This tool alters the proportions of the input raster dataset by changing the cell
;               size to that of the user selected example raster dataset.
;
; INPUT:        One or more single band gridded date-sets.
;
; OUTPUT:       One new gridded file per input.
;
; PARAMETERS:   Via pop-up dialog widgets.
;
; NOTES:        The input data must have identical dimensions. If the input is a flat binary file,
;               or an ENVI standard file it must have an associated ENVI header file (.hdr).
;
;               An interactive ENVI session is needed to run this tool.
;
;               RESAMPLING METHODS;
;
;               The user may select one of four interpolation methods. When 'down' sampling data
;               it is recommended to use either the NEAREST NEIGHBOUR or PIXEL AGGREGATE method.
;
;               NEAREST NEIGHBOUR assignment will determine the location of the closest cell
;               centre on the input raster and assign the value of that cell to the cell on the
;               output.
;
;               BILINEAR INTERPOLATION uses the value of the four nearest input cell centers to
;               determine the value on the output.
;
;               CUBIC CONVOLUTION is similar to bilinear interpolation except the weighted average
;               is calculated from the 16 nearest input cell centres and their values.
;
;               PIXEL AGGREGATE uses the average of the surrounding pixels to determine the output
;               value.
;
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO Batch_Spatial_Resample
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Batch_Spatial_Resample'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_Files = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_Files[0] EQ '' THEN RETURN ; Error check.
  In_Files = In_Files[SORT(In_Files)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_Files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_Files)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS = MAKE_ARRAY(N_ELEMENTS(In_Files), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(In_Files[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; Select an existing file:
  Path='H:\war409\gamma\rain\'
  In_Example = DIALOG_PICKFILE(PATH=Path, TITLE='Define The Output Cell Size Using An Existing File', FILTER=Filter, /MUST_EXIST)
  ;-------------- ; Open the selected file:
  ENVI_OPEN_FILE, In_Example, R_FID=FID_Example, /NO_REALIZE
  ;-------------- ; Get map information for the selected file:
  MAPINFO_Example = ENVI_GET_MAP_INFO(FID=FID_Example)
  Proj_Example = MAPINFO_Example.PROJ ; Map projection.
  Datum_Example = MAPINFO_Example.PROJ.DATUM ; Map datum.
  ProjName_Example = MAPINFO_Example.PROJ.NAME ; Projection name.
  Units_Example = MAPINFO_Example.PROJ.UNITS ; Coordinate system units.
  xSize_Example = FLOAT(MAPINFO_Example.PS[0]) ; Cell width.
  ySize_Example = FLOAT(MAPINFO_Example.PS[1]) ; Cell hight.
  xUL_Example = FLOAT(MAPINFO_Example.MC[2]) ; X-Coordinate upper left.
  yUL_Example = FLOAT(MAPINFO_Example.MC[3]) ; Y-Coordinate upper left.
  ;-------------- ; Set the output cell size:
  xSize_Out = xSize_Example
  ySize_Out = ySize_Example
  ;---------------------------------------------------------------------------------------------
  ; Select the alignment option:
  Alignment = FUNCTION_WIDGET_Droplist(TITLE='Set Alignment Method', VALUE=['No re-alignment', $
    'Snap SILO/BILO to MODIS 500m', 'Snap SILO/BILO to MODIS 250m','Snap MODIS 500m to SILO/BILO', $
    'Snap MODIS 250m to SILO/BILO'])
  ;---------------------------------------------------------------------------------------------
  ; Select the resample method:
  Resample = FUNCTION_WIDGET_Droplist(TITLE='Set Resample Method', VALUE=['Nearest Neighbour', $
    'Bilinear Interpolation', 'Cubic Convolution','Pixel Aggregation'])
  ;---------------------------------------------------------------------------------------------
  ; Set No Data:
  No_DATA = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: No Data', ACCEPT_STRING='Set a grid value to NaN', $
    DECLINE_STRING='Do not set a grid value to NaN', DEFAULT='-999.00', /FLOAT)
  IF (No_DATA[0] NE -1) THEN NaN = No_DATA[1] ; Set NaN value.
  ;---------------------------------------------------------------------------------------------
  ; Select the output data type:
  Out_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Output Datatype', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (Out_DataType EQ 7) OR (Out_DataType EQ 8) OR (Out_DataType EQ 9) OR (Out_DataType EQ 10) OR (Out_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set an output scaling factor:
  IF (Out_DataType EQ 1) OR (Out_DataType EQ 2) OR (Out_DataType EQ 3) THEN BEGIN
    Scaling = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: Scaling', ACCEPT_STRING='Set a Scaling Value', $
      DECLINE_STRING='Do Not Set a Scaling Value', DEFAULT='10.00', /FLOAT)
  ENDIF ELSE Scaling = -1
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='\\Tidalwave-bu\H$\Projects\NWC_Groundwater_Dependent_Ecosystems\Gamma\OWL\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;---------------------------------------------------------------------------------------------
  ; File loop:
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Loop through each input file:
    LoopStart = SYSTIME(1) ;  Get loop start time.
    ;-------------- ; Get data:
    File_In = In_Files[i] ; Get the ith file.
    FNS_In = FNS[i] ; Get the ith short filename.
    ENVI_OPEN_FILE, File_In, R_FID=FID_In, /NO_REALIZE ; Open the ith input file.
    ENVI_FILE_QUERY, FID_In, DIMS=DIMS_In, DATA_TYPE=DataType_In, NS=NS_In, NL=NL_In ; Query the ith input file.
    ;-------------- ; Get map information for the ith file:
    MAPINFO_In = ENVI_GET_MAP_INFO(FID=FID_In)
    Proj_In = MAPINFO_In.PROJ ; Map projection.
    Datum_In = MAPINFO_In.PROJ.DATUM ; Map datum.
    ProjName_In = MAPINFO_In.PROJ.NAME ; Projection name.
    Units_In = MAPINFO_In.PROJ.UNITS ; Coordinate system units.
    xSize_In = FLOAT(MAPINFO_In.PS[0]) ; Cell width.
    ySize_In = FLOAT(MAPINFO_In.PS[1]) ; Cell hight.
    xUL_In = FLOAT(MAPINFO_In.MC[2]) ; X-Coordinate upper left.
    yUL_In = FLOAT(MAPINFO_In.MC[3]) ; Y-Coordinate upper left.
    xO_IN = FLOAT(MAPINFO_In.MC[0]) ; X-Coordinate origin.
    yO_IN = FLOAT(MAPINFO_In.MC[1]) ; Y-Coordinate origin.
    ;-------------- ; Read data:
    Data_In = ENVI_GET_DATA(FID=FID_In, DIMS=DIMS_In, POS=0)
    ;-------------- ; Write temporary file: (Vanilla Resample)
    IF (Alignment EQ 0) THEN BEGIN
      IF (No_DATA[0] NE -1) THEN BEGIN
        IF (DataType_In NE 4) THEN Data_In = FLOAT(Data_In) ; Convert to float.
        k = WHERE(Data_In EQ FLOAT(NaN), NaN_Count)
        IF (NaN_Count GT 0) THEN Data_In[k] = !VALUES.F_NAN
        ENVI_WRITE_ENVI_FILE, Data_In, DATA_TYPE=4, INTERLEAVE=0, MAP_INFO=MAPINFO_In, $
          NB=1, NL=NL_In, NS=NS_In, PIXEL_SIZE=[xSize_In, ySize_In], OUT_DT=4, /NO_COPY, $
          /NO_OPEN, R_FID=FID_In, /IN_MEMORY
      ENDIF
    ENDIF
    ;-------------- ; Write temporary file: (SILO to MODIS Resample)
    IF (Alignment EQ 1) OR (Alignment EQ 2) THEN BEGIN
      IF (No_DATA[0] NE -1) THEN BEGIN
        Array_New = MAKE_ARRAY(901, 701, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store SILO data with MODIS extents.
        IF (DataType_In NE 4) THEN Data_In = FLOAT(Data_In) ; Convert to float.
        Array_New[40:40+840, 0:680] = Data_In ; Add the input data to the empty array.
        k = WHERE(Array_New EQ FLOAT(NaN), NaN_Count)
        IF (NaN_Count GT 0) THEN Array_New[k] = !VALUES.F_NAN
      ENDIF ELSE BEGIN
        Array_New = MAKE_ARRAY(901, 701, /FLOAT) ; Define an array to store SILO data with MODIS extents.
        Array_New[40:40+840, 0:680] = Data_In ; Add the input data to the empty array.
      ENDELSE
      ; Create new map information:
      PS = [xSize_Out, ySize_Out]
      MC = [xO_IN, yO_IN, xUL_In-2, yUL_In]
      MAPINFO_New = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=Proj_In, UNITS=Units_In, DATUM=Datum_In)
      ; Write the new array to temporary memory:
      IF (No_DATA[0] NE -1) THEN BEGIN
        ENVI_WRITE_ENVI_FILE, Array_New, DATA_TYPE=4, INTERLEAVE=0, MAP_INFO=MAPINFO_New, $
          NB=1, NL=701, NS=901, PIXEL_SIZE=[xSize_In, ySize_In], OUT_DT=4, /NO_COPY, $
          /NO_OPEN, R_FID=FID_In, /IN_MEMORY
      ENDIF ELSE BEGIN
        ENVI_WRITE_ENVI_FILE, Array_New, DATA_TYPE=DataType_In, INTERLEAVE=0, MAP_INFO=MAPINFO_New, $
          NB=1, NL=701, NS=901, PIXEL_SIZE=[xSize_In, ySize_In], OUT_DT=DataType_In, /NO_COPY, $
          /NO_OPEN, R_FID=FID_In, /IN_MEMORY
      ENDELSE
      ENVI_FILE_QUERY, FID_In, DIMS=DIMS_In, DATA_TYPE=DataType_In, NS=NS_In, NL=NL_In ; Query the new file.
    ENDIF
    ;-------------- ; Write temporary file: (MODIS 500m to SILO Resample)
    IF (Alignment EQ 3) THEN BEGIN
      IF (No_DATA[0] NE -1) THEN BEGIN
        Array_New = MAKE_ARRAY(10012, 7457, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store SILO data with MODIS extents.
        IF (DataType_In NE 4) THEN Data_In = FLOAT(Data_In) ; Convert to float.
        Array_New[431:431+9579, 5:5+7450] = Data_In ; Add the input data to the empty array.
        k = WHERE(Array_New EQ FLOAT(NaN), NaN_Count)
        IF (NaN_Count GT 0) THEN Array_New[k] = !VALUES.F_NAN
      ENDIF ELSE BEGIN
        Array_New = MAKE_ARRAY(10012, 7457, /FLOAT) ; Define an array to store SILO data with MODIS extents.
        Array_New[431:431+9579, 5:5+7450] = Data_In ; Add the input data to the empty array.
      ENDELSE
      ; Create new map information:
      PS = [xSize_Out, ySize_Out]
      MC = [xO_IN, yO_IN, xUL_In-2.02459, yUL_In]
      MAPINFO_New = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=Proj_In, UNITS=Units_In, DATUM=Datum_In)
      ; Write the new array to temporary memory:
      IF (No_DATA[0] NE -1) THEN BEGIN
        ENVI_WRITE_ENVI_FILE, Array_New, DATA_TYPE=4, INTERLEAVE=0, MAP_INFO=MAPINFO_New, $
          NB=1, NL=7457, NS=10012, PIXEL_SIZE=[xSize_In, ySize_In], OUT_DT=4, /NO_COPY, $
          /NO_OPEN, R_FID=FID_In, /IN_MEMORY
      ENDIF ELSE BEGIN
        ENVI_WRITE_ENVI_FILE, Array_New, DATA_TYPE=DataType_In, INTERLEAVE=0, MAP_INFO=MAPINFO_New, $
          NB=1, NL=7457, NS=10012, PIXEL_SIZE=[xSize_In, ySize_In], OUT_DT=DataType_In, /NO_COPY, $
          /NO_OPEN, R_FID=FID_In, /IN_MEMORY
      ENDELSE
      ENVI_FILE_QUERY, FID_In, DIMS=DIMS_In, DATA_TYPE=DataType_In, NS=NS_In, NL=NL_In ; Query the new file.
    ENDIF
    ;-------------- ; Write temporary file: (MODIS 250m to SILO Resample)
    IF (Alignment EQ 4) THEN BEGIN
      IF (No_DATA[0] NE -1) THEN BEGIN
        Array_New = MAKE_ARRAY(20024, 14913, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store SILO data with MODIS extents.
        IF (DataType_In NE 4) THEN Data_In = FLOAT(Data_In) ; Convert to float.
        Array_New[863:863+19159, 11:11+14901] = Data_In ; Add the input data to the empty array.
        k = WHERE(Array_New EQ FLOAT(NaN), NaN_Count)
        IF (NaN_Count GT 0) THEN Array_New[k] = !VALUES.F_NAN
      ENDIF ELSE BEGIN
        Array_New = MAKE_ARRAY(19160, 14913, /FLOAT) ; Define an array to store SILO data with MODIS extents.
        Array_New[0:19159, 11:11+14901] = Data_In ; Add the input data to the empty array.
      ENDELSE
      ; Create new map information:
      PS = [xSize_Out, ySize_Out]
      MC = [xO_IN, yO_IN, xUL_In-2.0269, yUL_In]
      MAPINFO_New = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=Proj_In, UNITS=Units_In, DATUM=Datum_In)
      ; Write the new array to temporary memory:
      IF (No_DATA[0] NE -1) THEN BEGIN
        ENVI_WRITE_ENVI_FILE, Array_New, DATA_TYPE=4, INTERLEAVE=0, MAP_INFO=MAPINFO_New, $
          NB=1, NL=14913, NS=20024, PIXEL_SIZE=[xSize_In, ySize_In], OUT_DT=4, /NO_COPY, $
          /NO_OPEN, R_FID=FID_In, /IN_MEMORY
      ENDIF ELSE BEGIN
        ENVI_WRITE_ENVI_FILE, Array_New, DATA_TYPE=DataType_In, INTERLEAVE=0, MAP_INFO=MAPINFO_New, $
          NB=1, NL=14913, NS=19160, PIXEL_SIZE=[xSize_In, ySize_In], OUT_DT=DataType_In, /NO_COPY, $
          /NO_OPEN, R_FID=FID_In, /IN_MEMORY
      ENDELSE
      ENVI_FILE_QUERY, FID_In, DIMS=DIMS_In, DATA_TYPE=DataType_In, NS=NS_In, NL=NL_In ; Query the new file.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Resample data:
    ;-------------------------------------------------------------------------------------------
    ; Set the resample factor:
    Resample_X = xSize_Out / xSize_In
    Resample_Y = ySize_Out / ySize_In
    rFactor = [Resample_X, Resample_Y]
    ;-------------- ; Set the output filename:
    File_Out = Out_Directory + FNS_In + '.img'
    ;-------------- ; Resample:
    IF (Alignment EQ 0) THEN BEGIN ; Vanilla resample:
      ENVI_DOIT, 'RESIZE_DOIT', FID=FID_In, DIMS=DIMS_In, INTERP=Resample, RFACT=rFactor, $
        POS=0, R_FID=FID_Resample, /IN_MEMORY, /NO_REALIZE ; Resample.
      ;-------------- ; Correct the false shift created in RESIZE_DOIT:
      ENVI_FILE_QUERY, FID_Resample, DIMS=DIMS_Resample, DATA_TYPE=DataType_Resample, $
        NB=NB_Resample, NL=NL_Resample, NS=NS_Resample, INTERLEAVE=Interleave_Resample, $
        FILE_TYPE=FILE_TYPE_Resample, FNAME=FNAME_Resample, BNAMES=BNAMES_Resample
      PS = [xSize_Out, ySize_Out]
      MC = [xO_IN, yO_IN, xUL_In, yUL_In]
      MAPINFO_New = ENVI_MAP_INFO_CREATE(MC=MC, PS=PS, PROJ=Proj_In, UNITS=Units_In, DATUM=Datum_In) ; Update map information:
      ;-------------- ; Write the resampled data to file:
      Data_Out = ENVI_GET_DATA(FID=FID_Resample, DIMS=DIMS_Resample, POS=0) ; Get data.
      IF (Scaling[0] NE -1) THEN Data_Out = Data_Out * Scaling[1]
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Data_Out, /NAN), k_Count)
        IF (k_Count GT 0) THEN Data_Out[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF
      ENVI_WRITE_ENVI_FILE, Data_Out, DATA_TYPE=DataType_Resample, MAP_INFO=MAPINFO_New, $
        OUT_NAME=File_Out, PIXEL_SIZE=[xSize_Out, ySize_Out], UNITS=Units_In, OUT_DT=Out_DataType, /NO_OPEN
    ENDIF
    IF (Alignment EQ 1) THEN BEGIN ; Resample SILO to MODIS 500m:
      ENVI_DOIT, 'RESIZE_DOIT', FID=FID_In, DIMS=DIMS_In, INTERP=Resample, RFACT=rFactor, $
        POS=0, R_FID=FID_Resample, /IN_MEMORY, /NO_REALIZE ; Resample.
      ;-------------- ; Set output extents to MODIS.
      ENVI_FILE_QUERY, FID_Resample, DIMS=DIMS_Resample, DATA_TYPE=DataType_Resample, NS=NS_In, NL=NL_In
      Data_Out = ENVI_GET_DATA(FID=FID_Resample, DIMS=DIMS_Resample, POS=0)
      Output_Data = Data_Out[5:9584, 5:7455] ; Remove data outside of the MODIS extents.
      IF (Scaling[0] NE -1) THEN Output_Data = Output_Data * Scaling[1]
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Output_Data, /NAN), k_Count)
        IF (k_Count GT 0) THEN Output_Data[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF
      ;-------------- ; Write the resampled data to file:
      ENVI_WRITE_ENVI_FILE, Output_Data, DATA_TYPE=Out_DataType, MAP_INFO=MAPINFO_Example, $
        OUT_NAME=File_Out, PIXEL_SIZE=[xSize_Out, ySize_Out], UNITS=Units_In, OUT_DT=Out_DataType, /NO_OPEN
    ENDIF
    IF (Alignment EQ 2) THEN BEGIN ; Resample SILO to MODIS 250m:
      ENVI_DOIT, 'RESIZE_DOIT', FID=FID_In, DIMS=DIMS_In, INTERP=Resample, RFACT=rFactor, $
        POS=0, R_FID=FID_Resample, /IN_MEMORY, /NO_REALIZE ; Resample.
      ;-------------- ; Set output extents to MODIS.
      ENVI_FILE_QUERY, FID_Resample, DIMS=DIMS_Resample, DATA_TYPE=DataType_Resample, NS=NS_In, NL=NL_In
      Data_Out = ENVI_GET_DATA(FID=FID_Resample, DIMS=DIMS_Resample, POS=0)
      Output_Data = Data_Out[2:19161, 2:14903] ; Remove data outside of the MODIS extents.
      IF (Scaling[0] NE -1) THEN Output_Data = Output_Data * Scaling[1]
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Output_Data, /NAN), k_Count)
        IF (k_Count GT 0) THEN Output_Data[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF
      ;-------------- ; Write the resampled data to file:
      ENVI_WRITE_ENVI_FILE, Output_Data, DATA_TYPE=Out_DataType, MAP_INFO=MAPINFO_Example, $
        OUT_NAME=File_Out, PIXEL_SIZE=[xSize_Out, ySize_Out], UNITS=Units_In, OUT_DT=Out_DataType, /NO_OPEN
    ENDIF
    IF (Alignment EQ 3) OR (Alignment EQ 4) THEN BEGIN ; Resample MODIS to SILO:
      ENVI_DOIT, 'RESIZE_DOIT', FID=FID_In, DIMS=DIMS_In, INTERP=Resample, RFACT=rFactor, $
        POS=0, R_FID=FID_Resample, /IN_MEMORY, /NO_REALIZE ; Resample.
      ;-------------- ; Set output extents to SILO.
      ENVI_FILE_QUERY, FID_Resample, DIMS=DIMS_Resample, DATA_TYPE=DataType_Resample, NS=NS_In, NL=NL_In
      Data_Out = ENVI_GET_DATA(FID=FID_Resample, DIMS=DIMS_Resample, POS=0)
      Output_Data = Data_Out[80:80+840, 0:680]
      IF (Scaling[0] NE -1) THEN Output_Data = Output_Data * Scaling[1]
      IF (No_DATA[0] NE -1) THEN BEGIN
        k = WHERE(FINITE(Output_Data, /NAN), k_Count)
        IF (k_Count GT 0) THEN Output_Data[k] = FLOAT(NaN) ; Reset NaN.
      ENDIF
      ;-------------- ; Write the resampled data to file:
      ENVI_WRITE_ENVI_FILE, Output_Data, DATA_TYPE=Out_DataType, MAP_INFO=MAPINFO_Example, $
        OUT_NAME=File_Out, PIXEL_SIZE=[xSize_Out, ySize_Out], UNITS=Units_In, OUT_DT=Out_DataType, /NO_OPEN
    ENDIF
    ;-------------------------------------------------------------------------------------------
    Seconds = (SYSTIME(1)-LoopStart) ; Get the file loop end time.
    PRINT, '  Processing Time: ', STRTRIM(Seconds, 2), ' seconds, for file ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(In_Files), 2)
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60 ; Get the program end time.
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2),   ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

