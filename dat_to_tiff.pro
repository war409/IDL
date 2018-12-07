


PRO dat_to_tiff
  PRINT, 'Start'
  
  template_file = '\\wron\Working\work\war409\work\imagery\modis\template\cmrset.2000.02.250m.total.tif' 
  template_data = READ_TIFF(template_file, GEOTIFF=GEOTIFF)

  d_in = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_EFM_data\MODIS\Products\CMRSET\Month_'
  d_out = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_EFM_data\MODIS\Products\CMRSET\Month_\Geotiff'
  
  files = DIALOG_PICKFILE(PATH=d_in, TITLE='SELECT THE INPUT DATA', FILTER=['*.img','*.flt','*.bin','*.bsq','*total.dat'], /MUST_EXIST, /MULTIPLE_FILES, /OVERWRITE_PROMPT)  
  
  fstart = STRPOS(files, '\', /REVERSE_SEARCH)+1
  flength = (STRLEN(files)-fstart)-4
  fout = MAKE_ARRAY(N_ELEMENTS(files), /STRING)
  FOR a=0, N_ELEMENTS(files)-1 DO fout[a] += d_out + '\' + STRMID(files[a], fstart[a], flength[a]) + '.tif'
  
  FOR i=0, N_ELEMENTS(files)-1 DO BEGIN
    
    PRINT, ''
    PRINT, files[i]
    PRINT, fout[i]
    
    data = READ_BINARY(files[i], DATA_TYPE=4) 
    out = MAKE_ARRAY(19160, 14902, /FLOAT) 
    out[*] = data 
    
    WRITE_TIFF, fout[i], out, GEOTIFF=GEOTIFF, /FLOAT
    
  ENDFOR
  
  PRINT, ''
  PRINT, 'End'
END













