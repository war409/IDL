
; ENVI/IDL script to convert geotiff to flat binary

PRO tiff_to_bin
  start_time = SYSTIME(1)
  PRINT,''
  PRINT,'Begin Processing: mndwi'
  PRINT,''
  
  inpath = '\\wron\RemoteSensing\LANDSAT\GA_LANDSAT\PATH_95\'
  outpath = 'C:\landsat\'
  
  input_folder = inpath + 'LS5_TM_NBAR_P54_GANBAR01-002_095_084_19900812' + '\scene01\'
  output_folder = outpath + 'zone02\' + '19900812\' + '84\'
  
  ; zone 1
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_20050110_1'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_084_20050110_1'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_20100124_1'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_084_20100124_1'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19900625'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19981021'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_084_19981021'
  
  ; zone 2
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19980802'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_084_19980802'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19890724'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_084_19890724'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19981021'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19900727'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_084_19900727'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19900812'
  ;'LS5_TM_NBAR_P54_GANBAR01-002_095_084_19900812'
  
  files = FILE_SEARCH(input_folder, '*.tif') ; Get a list of files in the current directory.
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
    
    ; Open file.
    envi_open_file, filename, r_fid=fid
    
    if (fid eq -1) then begin
      envi_batch_exit
      return
    endif
    
    ; Set the keywords.
    envi_file_query, fid, dims=dims, nb=nb
    t_fid = lonarr(nb) + fid
    pos = lindgen(nb)
    
    ; Create the new output file.
    File_Out = output_folder + filename_short + '.img'
    envi_doit, 'cf_doit', $
    fid=t_fid, pos=pos, dims=dims, $
    remove=0, out_name=File_Out, $
    r_fid=r_fid
    
    PRINT, '  Processing Time: ', STRTRIM((SYSTIME(1)-itime), 2), ' seconds, for file ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(files), 2) 
  ENDFOR    

  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(((SYSTIME(1) - start_time) / 60), 2), ' minutes (', STRTRIM((((SYSTIME(1) - start_time) / 60) / 60), 2), ' hours).'
END


