; ##############################################################################################
; NAME: binary_to_netcdf.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren
; DATE: 20/04/2012
; DLM: 23/04/2012
; 
; 
; DESCRIPTION: Convert one or more flat binary files to netCDF. 
; 
; 
; INPUT:       One single-band flat binary file per input.
; 
; 
; OUTPUT:      One netCDF per flat binary input.
; 
; 
; PARAMETERS:  Define the parameters via in-program pop-up dialog widgets.
;
;
; NOTES:       This tool converts one or more binary files that have identical dimensions, variable 
;              names and datatype. The first binary file in the selected list must have an 
;              associated hdf (ENVI meta header) file containing map info; samples, lines, 
;              projection etc.
;
;
; ##############################################################################################



; **********************************************************************************************
PRO binary_to_netcdf
  systemtime = SYSTIME(1) ; Get the procedure start time.

  ;---------------------------------------------------------------------------------------------
  ; Set the input arguments: 
  ;---------------------------------------------------------------------------------------------

  inputfolder = 'C:\Documents and Settings\war409\MODIS\MOD15A2.005.MASK\' ; Set the input directory.
  outputfolder = 'C:\Documents and Settings\war409\MODIS\' ; Set the output directory.
  
  name = 'LAI'
  longname = 'MOD15A2 LAI'
  units = 'unknown'
  fillvalue = -999.00
  
  ; Set the input files.
  filenames = ENVI_PICKFILE(DEFAULT=inputfolder, TITLE='SELECT INPUT FILES', /MULTIPLE_FILES) 
  filecount = N_ELEMENTS(filenames) 
  
  ; Set the output directory.
  outputdirectory = ENVI_PICKFILE(DEFAULT=outputfolder, TITLE='SELECT OUTPUT FOLDER', /DIRECTORY) 
  
  ; Get map information.
  ENVI_OPEN_FILE, filenames[0], R_FID=FID, /NO_REALIZE ; Open the first input file.
  ENVI_FILE_QUERY, FID, DIMS=dimensions, DATA_TYPE=datatype, NS=samples, NL=lines ; Query the current input file.
  offset = dimensions[1] ; Set the data offset.

  ;---------------------------------------------------------------------------------------------
  ; Reformat Data: 
  ;---------------------------------------------------------------------------------------------
  
  FOR i=0, filecount-1 DO BEGIN 
    itime = SYSTIME(1) ; Get the loop start time.
    
    ;-------------------------------------------------------------------------------------------
    ; Get data: 
    ;-------------------------------------------------------------------------------------------
    
    ; Create an empty arry to hold file data.
    IF (datatype EQ 1) THEN data = BYTARR(samples, lines)
    IF (datatype EQ 2) THEN data = INTARR(samples, lines)
    IF (datatype EQ 4) THEN data = FLTARR(samples, lines)
    IF (datatype EQ 5) THEN data = DBLARR(samples, lines)
    IF (datatype EQ 12) THEN data = UINTARR(samples, lines)
    
    OPENR, LUN, filenames[i], /GET_LUN ; Open the current input file.
    POINT_LUN, LUN, offset ; Obtain the pointer position.
    READU, LUN, data ; Add file data to empty array.
    CLOSE, LUN & FREE_LUN, LUN ; Close the current input file and free the LUN.
    
    ;-------------------------------------------------------------------------------------------
    ; Build netCDF: 
    ;-------------------------------------------------------------------------------------------
    
    ; Get the current input filename without the file path and the file extension.
    start = STRPOS(filenames[i], '\', /REVERSE_SEARCH)+1 
    length = (STRLEN(filenames[i])-start)-4 
    short = STRMID(filenames[i], start, length) 
    
    nc = NCDF_CREATE(outputdirectory + '\' + short + '.nc', /CLOBBER) ; Create a new empty netCDF.
    NCDF_CONTROL, nc, /FILL ; Fill the netCDF with temporary data.
    
    ; Define the netCDF dimensions.
    time = NCDF_DIMDEF(nc, 'time', 1) ; Set the time dimension.
    latitude = NCDF_DIMDEF(nc, 'latitude', lines) ; Set the latitude (y-axis) dimension.
    longitude = NCDF_DIMDEF(nc, 'longitude', samples) ; Set the longitude (x-axis) dimension.
    
    ; Define the netCDF variables.
    variable = NCDF_VARDEF(nc, name, [longitude, latitude, time], /FLOAT) ; Set the main variable.
    variabletime = NCDF_VARDEF(nc, 'time', [time], /LONG) ; Set the time dimension variable.
    variablelatitude = NCDF_VARDEF(nc, 'latitude', [latitude], /FLOAT) ; Set the latitude (y-axis) dimension variable.
    variablelongitude = NCDF_VARDEF(nc, 'longitude', [longitude], /FLOAT) ; Set the longitude (x-axis) dimension variable.
    
    ; Define the time dimension variable attributes.
    NCDF_ATTPUT, nc, variabletime, 'long_name', 'time', /CHAR 
    NCDF_ATTPUT, nc, variabletime, 'units', 'days since 2000-01-01 0:0:0', /CHAR 
    
    ; Define the latitude dimension variable attributes.
    NCDF_ATTPUT, nc, variablelatitude, 'long_name', 'latitude', /CHAR 
    NCDF_ATTPUT, nc, variablelatitude, 'units', 'degrees_north', /CHAR 
    
    ; Define the longitude dimension variable attributes.
    NCDF_ATTPUT, nc, variablelongitude, 'long_name','longitude', /CHAR 
    NCDF_ATTPUT, nc, variablelongitude, 'units', 'degrees_east', /CHAR 
    
    ; Define the main variable attributes.
    NCDF_ATTPUT, nc, variable, '_FillValue', fillvalue, /FLOAT 
    NCDF_ATTPUT, nc, variable, 'long_name', longname, /CHAR 
    NCDF_ATTPUT, nc, variable, 'units', units, /CHAR 
    
    ; Define the global attributes.
    NCDF_ATTPUT, nc, 'title', 'MODIS MOD15A2.005 LAI 1000 meters', /GLOBAL, /CHAR ; Set the title attribute.
    NCDF_ATTPUT, nc, 'institution', 'CSIRO, Water for a Healthy Country Flagship', /GLOBAL, /CHAR ; Set the institution attribute.
    NCDF_ATTPUT, nc, 'source', 'USGS', /GLOBAL, /CHAR ; Set the source attribute.
    NCDF_ATTPUT, nc, 'comment', $ 
                       'Pixels with the bit fields: cloud (see band 3), ocean (see band 4), and internal cloud (see band 4) were masked from the data. NetCDF time series produced 25 April 2012.', /GLOBAL, /CHAR ; Set the comments attribute.
    
    ;-------------------------------------------------------------------------------------------
    ; Write data to the netCDF: 
    ;-------------------------------------------------------------------------------------------
    
    ; Write data to the main variable.
    NCDF_CONTROL, nc, /ENDEF
    fillindex = WHERE((FINITE(data, /NaN)), count) ; Replace any NaN or infinite values in the main variable with the fill value '-999.00'.
    IF (count GT 0) THEN data[fillindex] = fillvalue
    shape = [LONG(samples), LONG(lines), LONG(1)] ; Set the variable shape.
    ;ENVI_OPEN_FILE, filenames[i], R_FID=FID ; Open the current input file.
    ;ENVI_FILE_QUERY, FID, DIMS=dimensions, DATA_datatype=datatype, NS=samples, NL=lines ; Query the current input file.
    ;data = ENVI_GET_DATA(FID=FID, DIMS=dimensions, POS=0) ; Get data.
    NCDF_VARPUT, nc, variable, data, COUNT=shape ; Write data to the main variable.
    
    ; Get latitude and longitude variable data.
    NCDF_VARGET, nc, variable, VAR ; Query the main variable.
    ncshape = SIZE(VAR, /DIMENSIONS) ; Get the shape of the main variable.
    latitude = INDGEN(ncshape[1])*1 ; Create an empty array to store the latitude data. 
    longitude = INDGEN(ncshape[0])*1 ; Create an empty array to store the longitude data.
    
    ; Write data to the dimension variables.
    time = [LONG(49 + float(STRTRIM(i, 2)*8))] ; Define the time variable.
    NCDF_VARPUT, nc, variabletime, time ; Add data to the time variable.
    ENVI_CONVERT_FILE_COORDINATES, FID, latitude, latitude, CX, CY, /TO_MAP ; Get latitude map coordinates.
    NCDF_VARPUT, nc, variablelatitude, CY ; Add data to the latitude variable.
    ENVI_CONVERT_FILE_COORDINATES, FID, longitude, longitude, CX, CY, /TO_MAP ; Get longitude map coordinates.
    NCDF_VARPUT, nc, variablelongitude, CX ; Add data to the longitude variable.
    NCDF_CLOSE, nc ; Close the connection to the netCDF.

    ;-------------------------------------------------------------------------------------------
    PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for file: ', STRTRIM(i+1, 2), $ 
            ' of ', STRTRIM(filecount, 2) 
    ;-------------------------------------------------------------------------------------------
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  minutes = (SYSTIME(1)-systemtime) / 60 
  hours = minutes / 60 
  PRINT, ''
  PRINT, 'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)'
  PRINT, ''
  ;---------------------------------------------------------------------------------------------
END
; **********************************************************************************************



