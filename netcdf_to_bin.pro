


PRO netCDF_to_bin
  ;-------------------------------------------------------------------------
  time = SYSTIME(1) 
  PRINT,''
  PRINT,'Start Processing: netCDF_to_bin'
  PRINT,''
  
  input_folder = 'C:\temp\PET\tmax\' ; Set the input directory.
  output_folder = 'C:\temp\PET\' ; Set the output directory.
  
  ;variable_name = 'rad' ; Set the variable name.
  ;variable_name = 'rain' ; Set the variable name.
  variable_name = 'tmax' ; Set the variable name.
  ;variable_name = 'tmin' ; Set the variable name.
  
  
  
  files = FILE_SEARCH(input_folder, '*[.nc]') ; Get a list of files in the current directory.
  files = files[SORT(files)] ; Sort the input file list.
  start = STRPOS(files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  length = (STRLEN(files)-start)-4 ; Get the length of each path-less file name.
  filenames = MAKE_ARRAY(N_ELEMENTS(files), /STRING) ; Create an array to store the input file names.
  
  FOR a=0, N_ELEMENTS(files)-1 DO BEGIN ; Remove the file path from the input file names.
    filenames[a] += STRMID(files[a], start[a], length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  
  FOR i=0, N_ELEMENTS(files)-1 DO BEGIN ; File loop.
    itime = SYSTIME(1) ; Get the loop start time.
  
    filename = files[i] ; Get the current file.
    filename_short = filenames[i] ; Get the current short filename.
    
    nc = NCDF_OPEN(filename ,/NOWRITE) ; Open netCDF.
    variable = NCDF_VARID(nc, variable_name) ; Get the variable ID.
    NCDF_VARGET, nc, variable, data ; Get data.
    
    ; Write output.
    
    File_Out = output_folder + filename_short + '.img'
    OPENW, UNIT_Out, File_Out, /GET_LUN ; Create the output file.
    FREE_LUN, UNIT_Out ; Close the output file.
    
    OPENU, UNIT_Out, File_Out, /APPEND, /GET_LUN
    WRITEU, UNIT_Out, data
    FREE_LUN, UNIT_Out
    
    ;-------------------------------------------------------------------------------------------
    PRINT, '  Processing Time: ', STRTRIM((SYSTIME(1)-itime), 2), ' seconds, for file ', STRTRIM(i+1, 2), $ 
            ' of ', STRTRIM(N_ELEMENTS(files), 2) 
    ;-------------------------------------------------------------------------------------------
  ENDFOR    
  ;---------------------------------------------------------------------------------------------
  minutes = (SYSTIME(1)-time) / 60 
  hours = minutes / 60 
  PRINT, ''
  PRINT, 'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)' 
  PRINT, ''
  ;---------------------------------------------------------------------------------------------
END

