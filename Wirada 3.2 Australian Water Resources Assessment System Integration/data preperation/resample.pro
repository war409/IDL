; ##############################################################################################
; NAME: resample.pro
; LANGUAGE: IDL+ENVI
; AUTHOR: Garth Warren
; DATE: 20/04/2010
; DLM: 21/08/2013
;
;
; DESCRIPTION:  This tool alters the proportions of the input raster dataset by changing the cell
;               size to that of the user selected example raster dataset.
;
;
; INPUT:        One or more single band gridded date-sets.
;
;
; OUTPUT:       One new gridded file per input.
;
;
; PARAMETERS:   Via pop-up dialog widgets.
;
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
;
; ##############################################################################################



; **********************************************************************************************
PRO resample
  time = SYSTIME(1) ; Get the procedure start time.
  
  ;*********************************************************************************************
  ; Set the input arguments: 
  ;*********************************************************************************************
  
  template_filename = '\\wron\Working\work\war409\work\imagery\modis\template\'
  
;  input_folders = ['\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2002\2002\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2003\2003\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2004\2004\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2005\2005\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2006\2006\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2007\2007\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2008\2008\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2009\2009\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2010\2010\', $
;                   '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2011\2011\'] 
;  
;  output_folders = ['\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2002\2002-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2003\2003-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2004\2004-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2005\2005-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2006\2006-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2007\2007-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2008\2008-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2009\2009-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2010\2010-out-new\', $
;                    '\\wron\Working\work\war409\work\imagery\amsr-e\LPRM_AMSRE_D_SOILM3.002\2011\2011-out-new\']
  
  input_folder = '\\wron\Working\work\war409\work\imagery\globcover\workspace\subset\img\' ; Set the input directory.
  output_folder = '\\wron\Working\work\war409\work\imagery\globcover\workspace\subset\out\' ; Set the output directory.
  
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  ;---------------------------------------------------------------------------------------------
  
  files = DIALOG_PICKFILE(PATH=input_folder, $
                           TITLE='Select The Input Data', $
                           FILTER=['*.tif','*.img','*.flt','*.bin'], $
                           /MUST_EXIST, $
                           /MULTIPLE_FILES) 
                           
  IF files[0] EQ '' THEN RETURN ; Error check.
  
  files = files[SORT(files)] ; Sort the input file list.
  start = STRPOS(files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  length = (STRLEN(files)-start)-4 ; Get the length of each path-less file name.
  filenames = MAKE_ARRAY(N_ELEMENTS(files), /STRING) ; Create an array to store the input file names.
  
  FOR a=0, N_ELEMENTS(files)-1 DO BEGIN ; Remove the file path from the input file names.
    filenames[a] += STRMID(files[a], start[a], length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  
  ;---------------------------------------------------------------------------------------------
  ; Select an existing template file:
  ;---------------------------------------------------------------------------------------------
  
  template = DIALOG_PICKFILE(PATH=template_filename, $
                              TITLE='Define The Output Cell Size Using An Existing File', $
                              FILTER=['*.tif','*.img','*.flt','*.bin'], $
                              /MUST_EXIST) 
                              
  ENVI_OPEN_FILE, template, R_FID=FID, /NO_REALIZE ; Open the selected file.
  template_mapinfo = ENVI_GET_MAP_INFO(FID=FID) ; Get map information.
  template_projection = template_mapinfo.PROJ ; Get the map projection.
  template_datum = template_mapinfo.PROJ.DATUM ; Get the map datum.
  template_units = template_mapinfo.PROJ.UNITS ; Get the coordinate system units.
  template_xsize = FLOAT(template_mapinfo.PS[0]) ; Get the cell width.
  template_ysize = FLOAT(template_mapinfo.PS[1]) ; Get the cell hight.
  template_xul = FLOAT(template_mapinfo.MC[2]) ; Get the x-coordinate upper left.
  template_yul = FLOAT(template_mapinfo.MC[3]) ; Get the y-coordinate upper left.
  output_xsize = template_xsize ; Set the output cell size.
  output_ysize = template_ysize ; Set the output cell size.
  
  ;---------------------------------------------------------------------------------------------
  ; Select the alignment method:
  ;---------------------------------------------------------------------------------------------
  
  alignment = FUNCTION_WIDGET_Droplist(TITLE='Set Alignment Method', $
                                          VALUE=['No re-alignment', $             ; 0
                                                 'Snap AWRA to MODIS 500m', $   ; 1
                                                 'Snap AWRA to MODIS 250m', $   ; 2
                                                 'Snap MODIS 250m to AWRA', $   ; 3
                                                 'Snap MODIS 500m to AWRA', $   ; 4
                                                 'Snap MODIS 1000m to AWRA', $  ; 5
                                                 'Snap AMSR-E to AWRA'])   ; 6
                                                 
  ;---------------------------------------------------------------------------------------------
  ; Select the resample method:
  ;---------------------------------------------------------------------------------------------
  
  resample = FUNCTION_WIDGET_Droplist(TITLE='Set resample Method', $
                                         VALUE=['Nearest Neighbour', $
                                                'Bilinear Interpolation', $
                                                'Cubic Convolution',$
                                                'Pixel Aggregation']) 
                                                
  ;---------------------------------------------------------------------------------------------
  ; Set the no data value:
  ;---------------------------------------------------------------------------------------------
  
  nodata = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: No Data', $
                                                      ACCEPT_STRING='Set a grid value to NaN', $
                                                      DECLINE_STRING='Do not set a grid value to NaN', $
                                                      DEFAULT='-9999.00', /FLOAT) 
                                                      
  IF (nodata[0] NE -1) THEN NaN = nodata[1] ; Set the NaN value.
  
  ;---------------------------------------------------------------------------------------------
  ; Select the output data type:
  ;---------------------------------------------------------------------------------------------
  
  output_datatype = FUNCTION_WIDGET_Droplist(TITLE='Select Output Datatype', $
                                                VALUE=['0 : UNDEFINED : Undefined', $
                                                      '1 : BYTE : Byte', $
                                                      '2 : INT : Integer', $
                                                      '3 : LONG : Longword integer', $
                                                      '4 : FLOAT : Floating point', $
                                                      '5 : DOUBLE : Double-precision floating', $
                                                      '6 : COMPLEX : Complex floating', $
                                                      '7 : STRING : String', $
                                                      '8 : STRUCT : Structure', $
                                                      '9 : DCOMPLEX : Double-precision complex', $
                                                      '10 : POINTER : Pointer', $
                                                      '11 : OBJREF : Object reference', $
                                                      '12 : UINT : Unsigned Integer', $
                                                      '13 : ULONG : Unsigned Longword Integer', $
                                                      '14 : LONG64 : 64-bit Integer', $
                                                      '15 : ULONG64 : Unsigned 64-bit Integer']) 
                                                      
  IF (output_datatype EQ 7) OR (output_datatype EQ 8) OR (output_datatype EQ 9) OR (output_datatype EQ 10) OR (output_datatype EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  
  ;---------------------------------------------------------------------------------------------
  ; Set an output scaling factor:
  ;---------------------------------------------------------------------------------------------
  
  IF (output_datatype EQ 1) OR (output_datatype EQ 2) OR (output_datatype EQ 3) THEN BEGIN
    scale = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: scale', $
                                                      ACCEPT_STRING='Set a scale Value', $
                                                      DECLINE_STRING='Do Not Set a scale Value', $
                                                      DEFAULT='10.00', $
                                                      /FLOAT) 
  ENDIF ELSE scale = -1
  
  ;*********************************************************************************************
  ; Set the resample parameters: 
  ;*********************************************************************************************
  
  ;---------------------------------------------------------------------------------------------
  ; Directory loop:
  ;---------------------------------------------------------------------------------------------  
  
;  FOR h=0, N_ELEMENTS(input_folders)-1 DO BEGIN ; Directory loop.
;    htime = SYSTIME(1) ; Get the loop start time.
;    
;    input_folder = input_folders[h] ; Set the current input directory.
;    output_folder = output_folders[h] ; Set the current output directory.
;    
;    files = FILE_SEARCH(input_folder, '*[.img, .bin]') ; Get a list of files in the current directory.
;    files = files[SORT(files)] ; Sort the input file list.
;    start = STRPOS(files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
;    length = (STRLEN(files)-start)-4 ; Get the length of each path-less file name.
;    filenames = MAKE_ARRAY(N_ELEMENTS(files), /STRING) ; Create an array to store the input file names.
;    
;    FOR a=0, N_ELEMENTS(files)-1 DO BEGIN ; Remove the file path from the input file names.
;      filenames[a] += STRMID(files[a], start[a], length[a]) ; Get the a-the file name (trim away the file path).
;    ENDFOR
    
    ;-------------------------------------------------------------------------------------------
    ; File loop: 
    ;-------------------------------------------------------------------------------------------
    
    FOR i=0, N_ELEMENTS(files)-1 DO BEGIN ; File loop.
      itime = SYSTIME(1) ; Get the loop start time.
      
      ;-----------------------------------------------------------------------------------------
      ; Get data:
      ;-----------------------------------------------------------------------------------------
      
      filename = files[i] ; Get the current file.
      filename_short = filenames[i] ; Get the current short filename.
      ENVI_OPEN_FILE, filename, R_FID=inFID, /NO_REALIZE ; Open the current input file.
      ENVI_FILE_QUERY, inFID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the current input file.
      input_mapinfo = ENVI_GET_MAP_INFO(FID=inFID) ; Get map information.
      input_projection = input_mapinfo.PROJ ; Get the map projection.
      input_datum = input_mapinfo.PROJ.DATUM ; Get the map datum.
      projection_name = input_mapinfo.PROJ.NAME ; Get the projection name.
      input_units = input_mapinfo.PROJ.UNITS ; Get the coordinate system units.
      input_xsize = FLOAT(input_mapinfo.PS[0]) ; Get the cell width.
      input_ysize = FLOAT(input_mapinfo.PS[1]) ; Get the cell hight.
      input_xul = FLOAT(input_mapinfo.MC[2]) ; Get the x-coordinate upper left.
      input_yul = FLOAT(input_mapinfo.MC[3]) ; Get the y-coordinate upper left.
      input_xorigin = FLOAT(input_mapinfo.MC[0]) ; Get the x-coordinate origin.
      input_yorigin = FLOAT(input_mapinfo.MC[1]) ; Get the y-coordinate origin.
      data = ENVI_GET_DATA(FID=inFID, DIMS=dimensions, POS=0) ; Read data.
        
      ;-----------------------------------------------------------------------------------------
      ; Write a copy of the current file to memory. Set missing (no data) values to NaN:
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 0) THEN BEGIN 
        IF (nodata[0] NE -1) THEN BEGIN 
          
          IF (datatype NE 4) THEN data = FLOAT(data) 
          
          k = WHERE(data EQ FLOAT(NaN), NaN_Count) 
          IF (NaN_Count GT 0) THEN data[k] = !VALUES.F_NAN 
          
          ENVI_WRITE_ENVI_FILE, data, $ 
                                  DATA_TYPE=4, $ 
                                  INTERLEAVE=0, $ 
                                  MAP_INFO=input_mapinfo, $ 
                                  NB=1, $ 
                                  NL=lines, $ 
                                  NS=samples, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $ 
                                  OUT_DT=4, $ 
                                  /NO_COPY, $ 
                                  /NO_OPEN, $ 
                                  R_FID=inFID, $ 
                                  /IN_MEMORY 
        ENDIF 
      ENDIF 
      
      ;-----------------------------------------------------------------------------------------
      ; AWRA to MODIS. Write a temporary file: 
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 1) OR (alignment EQ 2) THEN BEGIN
        
        IF (nodata[0] NE -1) THEN BEGIN
          array = MAKE_ARRAY(901, 701, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store AWRA/SILO data with MODIS extents.
          IF (datatype NE 4) THEN data = FLOAT(data) ; Convert to float.
          array[40:40+840, 0:680] = data ; Add the input data to the empty array.
          k = WHERE(array EQ FLOAT(NaN), NaN_Count)
          IF (NaN_Count GT 0) THEN array[k] = !VALUES.F_NAN
        ENDIF ELSE BEGIN
          array = MAKE_ARRAY(901, 701, /FLOAT) ; Define an array to store AWRA/SILO data with MODIS extents.
          array[40:40+840, 0:680] = data ; Add the input data to the empty array.
        ENDELSE
        
        new_mapinfo = ENVI_MAP_INFO_CREATE(MC=[input_xorigin, input_yorigin, input_xul-2, input_yul], $ ; Create new map information.
                                             PS=[output_xsize, output_ysize], $
                                             PROJ=input_projection, $
                                             UNITS=input_units, $
                                             DATUM=input_datum) 
                                             
        IF (nodata[0] NE -1) THEN BEGIN ; Write the array to memory.
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=4, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=701, $
                                  NS=901, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=4, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDIF ELSE BEGIN
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=datatype, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=701, $
                                  NS=901, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=datatype, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDELSE
        ENVI_FILE_QUERY, inFID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the new file.
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; MODIS 250m to AWRA. Write a temporary file.
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 3) THEN BEGIN
      
        IF (nodata[0] NE -1) THEN BEGIN
          array = MAKE_ARRAY(20024, 14913, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store MODIS data with AWRA/SILO extents.
          IF (datatype NE 4) THEN data = FLOAT(data) ; Convert to float.
          array[863:863+19159, 11:11+14901] = data ; Add the input data to the empty array.
          k = WHERE(array EQ FLOAT(NaN), NaN_Count)
          IF (NaN_Count GT 0) THEN array[k] = !VALUES.F_NAN
        ENDIF ELSE BEGIN
          array = MAKE_ARRAY(19160, 14913, /FLOAT) ; Define an array to store MODIS data with AWRA/SILO extents.
          array[0:19159, 11:11+14901] = data ; Add the input data to the empty array.
        ENDELSE
        
        new_mapinfo = ENVI_MAP_INFO_CREATE(MC=[input_xorigin, input_yorigin, input_xul-2.0269, input_yul], $ ; Create new map information.
                                             PS=[output_xsize, output_ysize], $
                                             PROJ=input_projection, $
                                             UNITS=input_units, $
                                             DATUM=input_datum)  
        
        IF (nodata[0] NE -1) THEN BEGIN ; Write the new array to temporary memory.
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=4, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=14913, $
                                  NS=20024, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=4, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDIF ELSE BEGIN
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=datatype, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=14913, $
                                  NS=19160, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=datatype, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDELSE
        ENVI_FILE_QUERY, inFID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the new file.
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; MODIS 500m to AWRA. Write a temporary file: 
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 4) THEN BEGIN
      
        IF (nodata[0] NE -1) THEN BEGIN
          array = MAKE_ARRAY(10012, 7457, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store MODIS data with AWRA/SILO extents.
          IF (datatype NE 4) THEN data = FLOAT(data) ; Convert to float.
          array[431:431+9579, 5:5+7450] = data ; Add the input data to the empty array.
          k = WHERE(array EQ FLOAT(NaN), NaN_Count)
          IF (NaN_Count GT 0) THEN array[k] = !VALUES.F_NAN
        ENDIF ELSE BEGIN
          array = MAKE_ARRAY(10012, 7457, /FLOAT) ; Define an array to store MODIS data with AWRA/SILO extents.
          array[431:431+9579, 5:5+7450] = data ; Add the input data to the empty array.
        ENDELSE
        
        new_mapinfo = ENVI_MAP_INFO_CREATE(MC=[input_xorigin, input_yorigin, input_xul-2.02459, input_yul], $ ; Create new map information.
                                             PS=[output_xsize, output_ysize], $
                                             PROJ=input_projection, $
                                             UNITS=input_units, $
                                             DATUM=input_datum) 
        
        IF (nodata[0] NE -1) THEN BEGIN ; Write the new array to temporary memory.
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=4, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=7457, $
                                  NS=10012, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=4, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDIF ELSE BEGIN
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=datatype, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=7457, $
                                  NS=10012, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=datatype, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDELSE
        ENVI_FILE_QUERY, inFID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the new file.
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; MODIS 1000m to AWRA. Write temporary file: 
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 5) THEN BEGIN
      
        IF (nodata[0] NE -1) THEN BEGIN
          array = MAKE_ARRAY(5006, 3729, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store MODIS data with AWRA/SILO extents.
          IF (datatype NE 4) THEN data = FLOAT(data) ; Convert to float.
          array[215:215+4789, 2:2+3725] = data ; Add the input data to the empty array.
          k = WHERE(array EQ FLOAT(NaN), NaN_Count)
          IF (NaN_Count GT 0) THEN array[k] = !VALUES.F_NAN
        ENDIF ELSE BEGIN
          array = MAKE_ARRAY(5006, 3729, /FLOAT) ; Define an array to store MODIS data with AWRA/SILO extents.
          array[215:215+4789, 2:2+3725] = data ; Add the input data to the empty array.
        ENDELSE
        
        new_mapinfo = ENVI_MAP_INFO_CREATE(MC=[input_xorigin, input_yorigin, input_xul-4.04918, input_yul], $ ; Create new map information.
                                             PS=[output_xsize, output_ysize], $
                                             PROJ=input_projection, $
                                             UNITS=input_units, $
                                             DATUM=input_datum) 
        
        IF (nodata[0] NE -1) THEN BEGIN ; Write the new array to temporary memory.
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=4, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=3729, $
                                  NS=5006, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=4, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDIF ELSE BEGIN
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=datatype, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=3729, $
                                  NS=5006, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=datatype, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY
        ENDELSE
        ENVI_FILE_QUERY, inFID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the new file.
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; AMSR-E to AWRA. Write temporary file: 
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 6) THEN BEGIN
      
        IF (nodata[0] NE -1) THEN BEGIN
          array = MAKE_ARRAY(173, 139, VALUE=FLOAT(NaN), /FLOAT) ; Define an array to store AMSR-E data with AWRA/SILO extents.
          IF (datatype NE 4) THEN data = FLOAT(data) ; Convert to float.
          array[1:1+171, 1:1+137] = data ; Add the input data to the empty array.
          k = WHERE(array EQ FLOAT(NaN), NaN_Count)
          IF (NaN_Count GT 0) THEN array[k] = !VALUES.F_NAN
        ENDIF ELSE BEGIN
          array = MAKE_ARRAY(173, 139, /FLOAT) ; Define an array to store AMSR-E data with AWRA/SILO extents.
          array[1:1+171, 1:1+137] = data ; Add the input data to the empty array.
        ENDELSE
        
        new_mapinfo = ENVI_MAP_INFO_CREATE(MC=[input_xorigin, input_yorigin, input_xul-0.25, input_yul+0.25], $ ; Create new map information.
                                             PS=[output_xsize, output_ysize], $ 
                                             PROJ=input_projection, $ 
                                             UNITS=input_units, $ 
                                             DATUM=input_datum) 
        
        IF (nodata[0] NE -1) THEN BEGIN ; Write the new array to temporary memory.
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=4, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=139, $
                                  NS=173, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=4, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY         
        ENDIF ELSE BEGIN
          ENVI_WRITE_ENVI_FILE, array, $
                                  DATA_TYPE=datatype, $
                                  INTERLEAVE=0, $
                                  MAP_INFO=new_mapinfo, $
                                  NB=1, $
                                  NL=139, $
                                  NS=173, $
                                  PIXEL_SIZE=[input_xsize, input_ysize], $
                                  OUT_DT=datatype, $
                                  /NO_COPY, $
                                  /NO_OPEN, $
                                  R_FID=inFID, $
                                  /IN_MEMORY                
        ENDELSE
        ENVI_FILE_QUERY, inFID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the new file. 
      ENDIF
      
      ;*****************************************************************************************
      ; Resample:
      ;*****************************************************************************************
      
      factor = [output_xsize / input_xsize, output_ysize / input_ysize] ; Set the resample factor.
      output_filename = output_folder + filename_short + '.img' ; Set the output filename.
      
      ;-----------------------------------------------------------------------------------------
      ; Resample using default settings: 
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 0) THEN BEGIN 
        ENVI_DOIT, 'RESIZE_DOIT', FID=inFID, $ ; Resample.
                                   DIMS=dimensions, $
                                   INTERP=resample, $
                                   RFACT=factor, $
                                   POS=0, $
                                   R_FID=FID_resample, $
                                   /IN_MEMORY, $
                                   /NO_REALIZE 
                                   
        ENVI_FILE_QUERY, FID_resample, $ ; Correct the false shift created by RESIZE_DOIT.
                           DIMS=DIMS_resample, $
                           DATA_TYPE=DataType_resample, $
                           NB=NB_resample, $
                           NL=NL_resample, $
                           NS=NS_resample, $
                           INTERLEAVE=Interleave_resample, $
                           FILE_TYPE=FILE_TYPE_resample,$
                           FNAME=FNAME_resample, $
                           BNAMES=BNAMES_resample
                           
        new_mapinfo = ENVI_MAP_INFO_CREATE(MC=[input_xorigin, input_yorigin, input_xul, input_yul], $ ; Update the map information.
                                             PS=[output_xsize, output_ysize], $
                                             PROJ=input_projection, $
                                             UNITS=input_units, $
                                             DATUM=input_datum) 
                                             
        output_data = ENVI_GET_DATA(FID=FID_resample, DIMS=DIMS_resample, POS=0) ; Get data.
        
        IF (scale[0] NE -1) THEN output_data = output_data * scale[1] ; Scale the data if needed.
        
        IF (nodata[0] NE -1) THEN BEGIN ; Reset NaN cells back to the original no data value.
          k = WHERE(FINITE(output_data, /NAN), k_Count)
          IF (k_Count GT 0) THEN output_data[k] = FLOAT(NaN) 
        ENDIF
        
        ENVI_WRITE_ENVI_FILE, output_data, $ ; Write the resampled data to file.
                                DATA_TYPE=DataType_resample, $
                                MAP_INFO=new_mapinfo, $
                                OUT_NAME=output_filename, $
                                PIXEL_SIZE=[output_xsize, output_ysize], $
                                UNITS=input_units, $
                                OUT_DT=output_datatype, $
                                /NO_OPEN
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; Resample data at the AWRA-L resolution / extents to the MODIS 500 m resolution / extent:
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 1) THEN BEGIN 
        ENVI_DOIT, 'RESIZE_DOIT', $ ; Resample.
                    FID=inFID, $
                    DIMS=dimensions, $
                    INTERP=resample, $
                    RFACT=factor, $
                    POS=0, $
                    R_FID=FID_resample, $
                    /IN_MEMORY, $
                    /NO_REALIZE 
        
        ; Adjust the output extents to match the MODIS extents.
        ENVI_FILE_QUERY, FID_resample, DIMS=DIMS_resample, DATA_TYPE=DataType_resample, NS=samples, NL=lines
        output_data = ENVI_GET_DATA(FID=FID_resample, DIMS=DIMS_resample, POS=0)
        
        output_data = output_data[5:9584, 5:7455] ; Remove data outside of the MODIS extents.
        
        IF (scale[0] NE -1) THEN output_data = output_data * scale[1] ; Scale the data if needed.
        
        IF (nodata[0] NE -1) THEN BEGIN ; Reset NaN cells back to the original no data value.
          k = WHERE(FINITE(output_data, /NAN), k_Count)
          IF (k_Count GT 0) THEN output_data[k] = FLOAT(NaN) 
        ENDIF
        
        ENVI_WRITE_ENVI_FILE, output_data, $ ; Write the resampled data to file.
                                DATA_TYPE=output_datatype, $
                                MAP_INFO=template_mapinfo, $
                                OUT_NAME=output_filename, $
                                PIXEL_SIZE=[output_xsize, output_ysize], $
                                UNITS=input_units, $
                                OUT_DT=output_datatype, $
                                /NO_OPEN
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; Resample data at the AWRA-L resolution / extents to the MODIS 250 m resolution / extent:
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 2) THEN BEGIN 
        ENVI_DOIT, 'RESIZE_DOIT', $ ; Resample.
                    FID=inFID, $
                    DIMS=dimensions, $
                    INTERP=resample, $
                    RFACT=factor, $
                    POS=0, $
                    R_FID=FID_resample, $
                    /IN_MEMORY, $
                    /NO_REALIZE
        
        ; Adjust the output extents to match the MODIS extents.
        ENVI_FILE_QUERY, FID_resample, DIMS=DIMS_resample, DATA_TYPE=DataType_resample, NS=samples, NL=lines
        output_data = ENVI_GET_DATA(FID=FID_resample, DIMS=DIMS_resample, POS=0)
        
        output_data = output_data[2:19161, 2:14903] ; Remove data outside of the MODIS extents.
        
        IF (scale[0] NE -1) THEN output_data = output_data * scale[1] ; Scale the data if needed.
        
        IF (nodata[0] NE -1) THEN BEGIN ; Reset NaN cells back to the original no data value.
          k = WHERE(FINITE(output_data, /NAN), k_Count)
          IF (k_Count GT 0) THEN output_data[k] = FLOAT(NaN)
        ENDIF
        
        ENVI_WRITE_ENVI_FILE, Output_Data, $ ; Write the resampled data to file.
                                DATA_TYPE=output_datatype, $
                                MAP_INFO=template_mapinfo, $
                                OUT_NAME=output_filename, $
                                PIXEL_SIZE=[output_xsize, output_ysize], $
                                UNITS=input_units, $
                                OUT_DT=output_datatype, $
                                /NO_OPEN
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; Resample data at the MODIS (either 250m, 500m or 1000m) resolution / extents to the AWRA (SILO) resolution / extent:
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 3) OR (alignment EQ 4) OR (alignment EQ 5) THEN BEGIN 
        ENVI_DOIT, 'RESIZE_DOIT', $ ; Resample.
                    FID=inFID, $ 
                    DIMS=dimensions, $ 
                    INTERP=resample, $ 
                    RFACT=factor, $ 
                    POS=0, $ 
                    R_FID=FID_resample, $ 
                    /IN_MEMORY, $ 
                    /NO_REALIZE 
                    
        ; Adjust the output extents to match the AWRA-L extents.
        ENVI_FILE_QUERY, FID_resample, DIMS=DIMS_resample, DATA_TYPE=DataType_resample, NS=samples, NL=lines
        output_data = ENVI_GET_DATA(FID=FID_resample, DIMS=DIMS_resample, POS=0) 
        output_data = output_data[80:80+840, 0:680]
        
        IF (scale[0] NE -1) THEN output_data = output_data * scale[1] ; Scale the data if needed.
        
        IF (nodata[0] NE -1) THEN BEGIN ; Reset NaN cells back to the original no data value.
          k = WHERE(FINITE(output_data, /NAN), k_Count) 
          IF (k_Count GT 0) THEN output_data[k] = FLOAT(NaN) 
        ENDIF
        
        ENVI_WRITE_ENVI_FILE, output_data, $ ; Write the resampled data to file.
                                DATA_TYPE=output_datatype, $
                                MAP_INFO=template_mapinfo, $
                                OUT_NAME=output_filename, $
                                PIXEL_SIZE=[output_xsize, output_ysize], $
                                UNITS=input_units, $
                                OUT_DT=output_datatype, $
                                /NO_OPEN
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      ; Resample data at AMSR-E resolution / extents to the AWRA (SILO) resolution / extent:
      ;-----------------------------------------------------------------------------------------
      
      IF (alignment EQ 6) THEN BEGIN 
        
        factor = [0.025 / 0.25, 0.025 / 0.25] ; Set resample factor A.
        
        ENVI_DOIT, 'RESIZE_DOIT', $ ; Resample A.
          FID=inFID, $ 
          DIMS=dimensions, $ 
          INTERP=resample, $ 
          RFACT=factor, $ 
          POS=0, $ 
          R_FID=FID_resample, $ 
          /IN_MEMORY, $ 
          /NO_REALIZE
        
        ; Adjust the output extents to match the AWRA-L extents.
        ENVI_FILE_QUERY, FID_resample, DIMS=DIMS_resample, DATA_TYPE=DataType_resample, NS=samples, NL=lines
        output_data = ENVI_GET_DATA(FID=FID_resample, DIMS=DIMS_resample, POS=0) 
        output_data = output_data[10:10+1681, 9:9+1361]
        
        temp_mapinfo = ENVI_MAP_INFO_CREATE(MC=[1.0000, 1.0000, 111.975, -9.975000], $ ; Set the temporary mapinfo.
                                              PS=[0.02500000000, 0.02500000000], $ 
                                              PROJ=input_projection, $ 
                                              UNITS=input_units, $ 
                                              DATUM=input_datum) 
        
        ENVI_WRITE_ENVI_FILE, output_data, $ ; Write the resampled data to file.
          DATA_TYPE=output_datatype, $
          MAP_INFO=temp_mapinfo, $
          PIXEL_SIZE=[0.02500000000, 0.02500000000], $
          UNITS=input_units, $
          OUT_DT=output_datatype, $
          R_FID=inFID, $
          /NO_OPEN, $
          /IN_MEMORY
                            
        ENVI_FILE_QUERY, inFID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the new file.
        
        factor = [0.0500 / 0.02500, 0.0500 / 0.02500] ; Set resample factor B.
        
        ENVI_DOIT, 'RESIZE_DOIT', FID=inFID, $ ; Resample B.
          DIMS=dimensions, $
          INTERP=resample, $
          RFACT=factor, $
          POS=0, $
          R_FID=FID_resample, $
          /IN_MEMORY, $
          /NO_REALIZE 
        
        ENVI_FILE_QUERY, FID_resample, $ ; Correct the false shift created by RESIZE_DOIT.
          DIMS=DIMS_resample, $
          DATA_TYPE=DataType_resample, $
          NB=NB_resample, $
          NL=NL_resample, $
          NS=NS_resample, $
          INTERLEAVE=Interleave_resample, $
          FILE_TYPE=FILE_TYPE_resample,$
          FNAME=FNAME_resample, $
          BNAMES=BNAMES_resample
        
        output_data = ENVI_GET_DATA(FID=FID_resample, DIMS=DIMS_resample, POS=0) ; Get data.
        
        IF (scale[0] NE -1) THEN output_data = output_data * scale[1] ; Scale the data if needed.
        
        IF (nodata[0] NE -1) THEN BEGIN ; Reset NaN cells back to the original no data value.
          k = WHERE(FINITE(output_data, /NAN), k_Count)
          IF (k_Count GT 0) THEN output_data[k] = FLOAT(NaN) 
        ENDIF
        
        ENVI_WRITE_ENVI_FILE, output_data, $ ; Write the resampled data to file.
                                DATA_TYPE=DataType_resample, $
                                MAP_INFO=template_mapinfo, $
                                OUT_NAME=output_filename, $
                                PIXEL_SIZE=[0.50000000000, 0.50000000000], $
                                UNITS=input_units, $
                                OUT_DT=output_datatype, $
                                /NO_OPEN      
      ENDIF
      
      ;-----------------------------------------------------------------------------------------
      PRINT, '  Processing Time: ', STRTRIM((SYSTIME(1)-itime), 2), ' seconds, for file ', STRTRIM(i+1, 2), $ 
              ' of ', STRTRIM(N_ELEMENTS(files), 2) 
      ;-----------------------------------------------------------------------------------------
      
    ENDFOR ; File loop.
  
;    ;-------------------------------------------------------------------------------------------
;    PRINT, '  Processing Time: ', STRTRIM((SYSTIME(1)-htime), 2), ' seconds, for file ', STRTRIM(h+1, 2), $ 
;              ' of ', STRTRIM(N_ELEMENTS(input_folders), 2) 
;    ;-------------------------------------------------------------------------------------------
;  
;  ENDFOR ; Directory loop.
  
  ;---------------------------------------------------------------------------------------------
  minutes = (SYSTIME(1)-time) / 60 
  hours = minutes / 60 
  PRINT, ''
  PRINT, 'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)' 
  PRINT, ''
  ;---------------------------------------------------------------------------------------------
END
; **********************************************************************************************




