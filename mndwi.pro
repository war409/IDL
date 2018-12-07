


FUNCTION FUNCTION_Segment, elements, segment
  segment_length = ROUND((elements) * segment) 
  count_temporary = CEIL((elements) / segment_length)
  count = count_temporary[0]
  segment_start = 0 
  segment_end = FLOAT(segment_length) 
  RETURN, [segment, count, segment_start, segment_end, segment_length] 
END



FUNCTION names, directory, satellite, band, year, month, day
  COMPILE_OPT IDL2
  
  count = N_ELEMENTS(year)
  month_suffix = MAKE_ARRAY(count, /STRING)
  k = WHERE((month LE 9))
  month_suffix[*] = ''
  IF (k[0] NE -1) THEN month_suffix[k] = '0'
  month = month_suffix + STRTRIM(month, 2)
  
  day_suffix = MAKE_ARRAY(count, /STRING)
  k = WHERE((day LE 9))
  day_suffix[*] = ''
  IF (k[0] NE -1) THEN day_suffix[k] = '0'
  day = day_suffix + STRTRIM(day, 2) 
  
  
  CASE satellite OF
      1: satellite = 'LS5_TM_NBAR_P54_GANBAR01-002_'
      2: satellite = 'LS7_ETM_NBAR_P54_GANBAR01-002_'
   ENDCASE
  
  CASE band OF
      1: band = '_B10'
      2: band = '_B20'
      3: band = '_B30'
      4: band = '_B40'
      5: band = '_B50'
      6: band = '_B70'
   ENDCASE
   
   filename = STRCOMPRESS(directory + $
                          satellite + '095_083_' + $
                          STRTRIM(year, 2) + $
                          month + $
                          day + $
                          band + $
                           '.img', $
                          /REMOVE_ALL)
                          
  shortfilename = STRCOMPRESS(satellite + '095_083_' + $
                              STRTRIM(year, 2) + $
                              month + $
                              day + $
                              band + $
                              '.img', $
                              /REMOVE_ALL)
  
  returnarray = MAKE_ARRAY(2, count, /STRING)
  returnarray[0,*] = filename
  returnarray[1,*] = shortfilename
  
  RETURN, returnarray
END



PRO mndwi
  start_time = SYSTIME(1) 
  PRINT,''
  PRINT,'Begin Processing: mndwi'
  PRINT,''

  ;---------------------------------------------------------------------------------------------
  ; Set Parameters...
  ;---------------------------------------------------------------------------------------------
  
  prefix = 'LS5_TM_NBAR_P54_GANBAR01-002_095_083_19890724_'
  
  ; Set the input directory.
  input_directory = 'C:\landsat\19890724\095_083\'
  
  ; Set the green band.
  satellite = 1
  date = JULDAY(7, 24, 1989)
  CALDAT, date, month, day, year
  band = 2
  green = names(input_directory, satellite, band, year, month, day)
  green_filenames = green[0,*]
  green_shortnames = green[1,*]
  
  ; Set the SWIR band.
  satellite = 1
  date = JULDAY(7, 24, 1989)
  CALDAT, date, month, day, year
  band = 5
  swir1 = names(input_directory, satellite, band, year, month, day)
  swir1_filenames = swir1[0,*]
  swir1_shortnames = swir1[1,*]
  
  ; Set the output folder.
  ; output_directory = DIALOG_PICKFILE(PATH='\\wron\Working\work\RVR_CC\2013-14_SAF\data\awap\rain\monthly\', TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  ; IF output_directory EQ '' THEN return 
  ; output_directory = '\\wron\Project\FloodModelling\scratch\don179\mNDWI\above_minus0.30'
  output_directory = 'C:\landsat\'
  
  ; Build an output file for the mean.
  filename = output_directory + prefix + 'mNDWI_minus0pt30' + '.flt' 
  OPENW, lun, filename, /GET_LUN 
  FREE_LUN, lun
  
  ;---------------------------------------------------------------------------------------------
  ; Get Data...
  ;---------------------------------------------------------------------------------------------
  
  green_matrix = READ_BINARY(green_filenames[0], DATA_TYPE=2)
  swir_matrix = READ_BINARY(swir1_filenames[0], DATA_TYPE=2)
  
;  green_matrix = FLOAT(green_matrix)
;  swir_matrix = FLOAT(swir_matrix)
  
  ;---------------------------------------------------------------------------------------------
  ; Calculate mNDWI and write the results to file...
  ;---------------------------------------------------------------------------------------------
  
;  ; Remove the no data values.
;  k1 = WHERE(green_matrix EQ FLOAT(-999.0), nodata_count)
;  IF (nodata_count GT 0) THEN green_matrix[k1] = !VALUES.F_NAN
;  
;  ; Remove the no data values.
;  k2 = WHERE(swir_matrix EQ FLOAT(-999.0), nodata_count)
;  IF (nodata_count GT 0) THEN swir_matrix[k2] = !VALUES.F_NAN
  
  ; Calculate mNDWI.
  ndwi = 1.0 * (green_matrix - swir_matrix) / (green_matrix + swir_matrix)
  ndwi = ROUND(ndwi * 100) / 100
  
  ; Threshold the data.
  ndwi = WHERE(ndwi GE -0.3)
  
;  ; Reset the no data values.
;  k3 = WHERE(FINITE(ndwi, /NAN), nodata_count)
;  IF (nodata_count GT 0) THEN ndwi[k3] = FLOAT(-999.0)
    
  ; Write the result to file.
  OPENU, lun, filename, /APPEND, /GET_LUN
  WRITEU, lun, ndwi
  FREE_LUN, lun
  
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(((SYSTIME(1) - start_time) / 60), 2), ' minutes (', STRTRIM((((SYSTIME(1) - start_time) / 60) / 60), 2), ' hours).'
END





