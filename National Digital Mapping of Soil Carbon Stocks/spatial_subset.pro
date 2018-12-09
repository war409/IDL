; ##############################################################################################
; NAME: spatial_subset.pro
; LANGUAGE: ENVI + IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 09/03/2010
; DLM: 22/02/2013
;
; DESCRIPTION:  This tool subsets the spatial extents of the input data. The user may manually 
;               enter new dimension parameters or choose to use the dimensions of an existing 
;               file.
;
; INPUT:        One or more single-band gridded datasets.
;
; OUTPUT:       One subsetted dataset per input. The output filename is the same name as the 
;               input with the added suffix '.subset'.
;
; PARAMETERS:   Define the parameters via in-program pop-up dialog widgets...
;
;               1.  Select the input data.
;              
;               2.  Select the output folder.
;              
;               3.  Define the spatial subset.
;                   
;                   Define the spatial subset using the ENVI subset widget (see the ENVI help 
;                   for more information).
;
; NOTES:        The input data must have identical dimensions. An interactive ENVI session is 
;               needed to run this tool. The input data must have an associated ENVI header file.
;
;               Note that when you select subset by file in the ENVI subset widget the subset is 
;               one cell too many in the X and Y direction. To correct this manually subtract one 
;               (cell) from the ‘Samples’ ‘To’ text box and from the ‘Lines’ ‘To’ text box.
;              
;               For more information contact Garth.Warren@csiro.au
;              
; ##############################################################################################


PRO spatial_subset
  time = SYSTIME(1) ; Get the current system time.

  ;---------------------------------------------------------------------------------------------
  ; Set the input / output arguments.
  ;---------------------------------------------------------------------------------------------
  
  ; Select the input data...
  filenames = DIALOG_PICKFILE(PATH='C:\saf\awap\tmin\2000\', TITLE='Select The Input Data', FILTER=['*.img','*.flt','*.bin'], /MUST_EXIST, /MULTIPLE_FILES)
  IF filenames[0] EQ '' THEN RETURN ; Error check.
  filenames = filenames[SORT(filenames)] ; Sort the input file list.
  
  ; Remove the file path from the input filenames...
  start = STRPOS(filenames, '\', /REVERSE_SEARCH)+1 ; Get the position of the first filename character (after the file path).
  length = (STRLEN(filenames)-start)-4 ; Get the length of each path-less filename.
  names = MAKE_ARRAY(N_ELEMENTS(filenames), /STRING) ; Create an array to store the input file names.
  FOR k=0, N_ELEMENTS(filenames)-1 DO BEGIN ; Fill the filename array.
    names[k] += STRMID(filenames[k], start[k], length[k]) ; Get the kth filename (remove the file path).
  ENDFOR
  
  ;---------------------------------------------------------------------------------------------
  
  ; Set the output folder...
  output_directory = DIALOG_PICKFILE(PATH='C:\saf\awap\tmin\2000\5km\', TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF output_directory EQ '' THEN RETURN ; Error check.
  
  ;--------------------------------------------------------------------------------------------- 
  
  ; Define the spatial subset...
  first = filenames[0] ; Set the first input file to help define the subset.
  ENVI_OPEN_FILE, first, R_FID=FID_first, /NO_REALIZE ; Open the example input file.
  ENVI_FILE_QUERY, FID_first, DIMS=DIMS_first, FILE_TYPE=type_first, NS=NS_first, NL=NL_first ; Query the example input file:
  
  ; Get map information...
  mapinfo = ENVI_GET_MAP_INFO(FID=FID_first)
  projection = mapinfo.PROJ
  datum = mapinfo.PROJ.DATUM
  projectionname = mapinfo.PROJ.NAME
  units = mapinfo.PROJ.UNITS
  xsize = FLOAT(mapinfo.PS[0])
  ysize = FLOAT(mapinfo.PS[1])
  cxul = FLOAT(mapinfo.MC[2])
  cyul = FLOAT(mapinfo.MC[3])
  cxlo = FLOAT(mapinfo.MC[0])
  cylo = FLOAT(mapinfo.MC[1])
  
  ; Set the spatial subset...
  base = WIDGET_AUTO_BASE(TITLE='Define The Spatial Subset')
  subsetwidget = WIDGET_SUBSET(base, UVALUE='SUBSET', FID=FID_first, DIMS=DIMS_first, /AUTO)
  subset = AUTO_WID_MNG(base) 
  IF (subset.ACCEPT EQ 0) THEN BEGIN ; Error check.
    PRINT,'** Invalid Subset **' 
    RETURN 
  ENDIF
  dims_subset = subset.SUBSET ; Set the output dimensions.
  
  ; Set the output number of samples and lines...
  IF dims_subset[1] EQ 0 THEN ns_subset = (dims_subset[2] + 1) ELSE ns_subset = (dims_subset[2] - dims_subset[1]) + 1 
  IF dims_subset[3] EQ 0 THEN nl_subset = (dims_subset[4] + 1) ELSE nl_subset = (dims_subset[4] - dims_subset[3]) + 1 
  
  ;---------------------------------------------------------------------------------------------
  ; File loop.
  ;---------------------------------------------------------------------------------------------
  
  FOR i=0, N_ELEMENTS(filenames)-1 DO BEGIN ; Loop through each input file:
    itime = SYSTIME(1) ; Get the loop start time.
    
    ; Get data...
    filename = filenames[i] ; Set the i-th input filename.
    name = names[i] ; Set the i-th short filename.
    output_filename = output_directory + name + '.subset.flt' ; Build the output filename.
    ENVI_OPEN_FILE, filename, R_FID=FID_In, /NO_REALIZE ; Open the input file in ENVI.
    ENVI_FILE_QUERY, FID_In, DATA_TYPE=output_type ; Query the i-th input file.
    
    ; Subset the input data...
    data_subset = ENVI_GET_DATA(FID=FID_In, DIMS=dims_subset, POS=0) 
    
    ; Set the output mapinfo structure...
    mapinfo_subset = ENVI_MAP_INFO_CREATE(DATUM=datum, NAME=projectionname, PROJ=projection, PS=[xsize, ysize], $ 
                                            MC=[cxlo, cylo, cxul + (DCOMPLEX(dims_subset[1]) * DCOMPLEX(xsize)), $ 
                                            cyul - (DCOMPLEX(dims_subset[3]) * DCOMPLEX(ysize))], UNITS=units) 
    
    ; Write the subset to file...
    ENVI_WRITE_ENVI_FILE, data_subset, OUT_NAME=output_filename, MAP_INFO=mapinfo_subset, PIXEL_SIZE=[xsize, ysize], $ 
                             OUT_DT=output_type, NS=ns_subset, NL=nl_subset, FILE_TYPE=type_first, UNITS=units, /NO_OPEN 
     
    PRINT, '  Processing Time: ', STRTRIM(((SYSTIME(1)-itime) / 60), 2), ' minutes, for file ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(filenames), 2) 
  ENDFOR

  ; Print the elapsed processing time to the console... 
  
  minutes = (SYSTIME(1) - time) / 60 
  hours = minutes / 60 
  
  PRINT,''
  PRINT,'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)'
  PRINT,''
END
;-----------------------------------------------------------------------------------------------

