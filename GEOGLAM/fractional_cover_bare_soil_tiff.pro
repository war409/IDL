; ##############################################################################################
; Name: fractional_cover_bare_soil_tiff.pro
; Language: IDL
; Author: Juan Pablo Guerschman & Garth Warren
; Date: 03072014
; DLM: 09072014 (Garth Warren)
; Description: 
; Input: 
; Output: 
; Parameters: 
; Notes: 
; ##############################################################################################



FUNCTION date_string, day, month, year
  COMPILE_OPT idl2
  
  count = N_ELEMENTS(day)
  return_strings = MAKE_ARRAY(count, 4, /STRING)
  day_of_year_suffix = MAKE_ARRAY(count, /STRING)
  month_suffix = MAKE_ARRAY(count, /STRING)
  day_suffix = MAKE_ARRAY(count, /STRING)
  
  day_of_year = JULDAY(month, day, year)  -  JULDAY(1, 1, year) + 1
  k = WHERE((day_of_year LE 9))
  l = WHERE((day_of_year GT 9) AND (day_of_year LE 99))
  m = WHERE((month LE 9))
  n = WHERE((day LE 9))
  
  day_of_year_suffix[*] = ''
  month_suffix[*] = ''
  day_suffix[*] = ''
  
  IF (k[0] NE -1) THEN day_of_year_suffix[k] = '00'
  IF (l[0] NE -1) THEN day_of_year_suffix[l] = '0'
  IF (m[0] NE -1) THEN month_suffix[m] = '0'
  IF (n[0] NE -1) THEN day_suffix[n] = '0'
  
  return_strings[*,0] = day_suffix + STRTRIM(day, 2)
  return_strings[*,1] = month_suffix + STRTRIM(month, 2)
  return_strings[*,2] = STRTRIM(year, 2)
  return_strings[*,3] = day_of_year_suffix + STRTRIM(day_of_year, 2)
  
  RETURN, return_strings
END



FUNCTION input_names, dates
  COMPILE_OPT IDL2
  
  ;directory = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\'
  directory = '\\Redfish-bu\geoglam\fractional_cover\'
  CALDAT, dates, month, day, year
  count = N_ELEMENTS(day)
  date_strings = date_string(day, month, year) 
  returnarray = MAKE_ARRAY(2, 4, count, /STRING)
  
  ; Set the band names.
  FOR i = 0, 3 DO BEGIN
    CASE i OF
      0: band = 'aust.005.PV.img'
      1: band = 'aust.005.NPV.img'
      2: band = 'aust.005.BS.img'
      3: band = 'aust.005.FLAG.img'
    ENDCASE
    
    filename = STRCOMPRESS(directory + $
      date_strings[*,2] + '\' + $
      'FractCover.V3_0_1.' + $
      date_strings[*,2] + '.' + $
      date_strings[*,3] + '.' + $
      band, $
      /REMOVE_ALL)
    
    shortfilename = STRCOMPRESS('FractCover.V3_0_1.' + $
      date_strings[*,2] + '.' + $
      date_strings[*,3] + '.' + $
      band, $
      /REMOVE_ALL)
    
    returnarray[0,i,*] = filename
    returnarray[1,i,*] = shortfilename
  ENDFOR
  
  RETURN, returnarray
END


FUNCTION output_names, dates
  COMPILE_OPT IDL2
  
  directory = 'C:\GEOGLAM\fractional_cover\test\' ; directory = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\geoTIFF\bare_soil\'
  CALDAT, dates, month, day, year
  count = N_ELEMENTS(day)
  date_strings = date_string(day, month, year) 
  returnarray = MAKE_ARRAY(2, 4, count, /STRING)
  
  ; Set the band names.
  FOR i = 0, 3 DO BEGIN
    CASE i OF
      0: band = 'aust.005.PV.tif'
      1: band = 'aust.005.NPV.tif'
      2: band = 'aust.005.BS.tif'
      3: band = 'aust.005.FLAG.tif'
    ENDCASE
    
    filename = STRCOMPRESS(directory + $
      'FractCover.V3_0_1.' + $
      date_strings[*,2] + '.' + $
      date_strings[*,3] + '.' + $
      band, $
      /REMOVE_ALL)
    
    shortfilename = STRCOMPRESS('FractCover.V3_0_1.' + $
      date_strings[*,2] + '.' + $
      date_strings[*,3] + '.' + $
      band, $
      /REMOVE_ALL)
    
    returnarray[0,i,*] = filename
    returnarray[1,i,*] = shortfilename
  ENDFOR
  
  RETURN, returnarray
END


FUNCTION reclass, data, new_min, new_max, old_min, old_max
  colours = INTARR(256) ; An empty vector to hold the modified colour values.
  vector = FINDGEN(256) ; A vector used in the histogram stretch calculation.
  new_difference = FLOAT(new_max) - FLOAT(new_min) ; The range of the new colour values.
  old_difference =  FLOAT(old_max) - FLOAT(old_min) ; The range of the old colour values.
  slope = new_difference / old_difference ; Calculate the ratio between the new and old colour range.
  v1 = slope * FLOAT(old_min)
  v2 = slope * vector
  v3 = v2 - v1
  v4 = FIX(v3 + 0.5) ; Convert to Integer.
  index = UNIQ(v4) ; Get the unique colour values - this is used as an index to subset the original colour values.
  colours[new_min:new_max] = data[index] ; Fill the output array with the new modified values.
  colours[new_max+1:-1] = 255 ; Top up the output array with the no data value.
  
  RETURN, colours
END



FUNCTION modis_eight_day_dates, start_date, end_date
  COMPILE_OPT idl2
  
  CALDAT, start_date, start_month, start_day, start_year ; Get the start date in calendar date format.
  CALDAT, end_date, end_month, end_day, end_year ; Get the end date in calendar date format.
  
  ; Get the eight day date, by-year, in Julien date format.
  FOR i = start_year, end_year DO BEGIN
    dates = INDGEN(46) * 8 +  JULDAY(1, 1, i)
    IF i EQ start_year THEN all_dates = dates ELSE all_dates = [all_dates, dates]
  ENDFOR
  
  ; Create an index of file-dates that occur between the start and end dates.
  index = WHERE((all_dates GE start_date) AND (all_dates LE end_date)) 
  dates = all_dates[index]
  
  RETURN, dates
END



PRO fractional_cover_bare_soil_tiff
  COMPILE_OPT idl2
  start_time = SYSTIME(1)
  
  ; Set the input parameters.
  start_date = JULDAY(1, 1, 2001) ; Start date.
  end_date =  JULDAY(1, 5, 2001) ; End date.
  mask = 'C:\Users\war409\Documents\data\programming\idl\GEOGLAM\FractCover.tif' ; Example grid.
  
  land = READ_TIFF(mask, GEOTIFF=GEOTIFF) ; Read the land mask.
  dimensions = SIZE(land) ; Get the dimensions of the land mask.
  dims = [dimensions[1], dimensions[2]] ; Set the dims variable.
  dates = modis_eight_day_dates(start_date, end_date) ; Get the eight day dates that fall between the selected start and end dates. 
  
  ; Set the input files.
  input_files = input_names(dates)
  input_filenames = input_files[0,2,*]
  input_shortnames = input_files[1,2,*]
  
  ; Set the output files.
  output_files = output_names(dates)
  output_filenames = output_files[0,2,*]
  output_shortnames = output_files[1,2,*]
  
  ; Make sure the input files exist.
  k = WHERE((FILE_TEST(input_filenames) EQ 1))
  IF (k[0] EQ -1) THEN STOP
  input_filenames = input_filenames[k]
  input_shortnames = input_shortnames[k]
  output_filenames = output_filenames[k]
  output_shortnames = output_shortnames[k]
  dates = dates[k]
  
  ; Make sure the output files do not exist.
  k = WHERE((FILE_TEST(output_filenames) NE 1))
  IF (k[0] EQ -1) THEN STOP
  output_filenames = output_filenames[k]
  output_shortnames = output_shortnames[k]
  input_filenames = input_filenames[k]
  input_shortnames = input_shortnames[k] 
  dates = dates[k]
  
  
  
  ; **************************************************************************************
  ; Load a Brewer colour ramp in Red Green Blue format.
;  CGLOADCT, 11, RGB_TABLE=rgb_table, /BREWER ;, /REVERSE ;, CLIP=[0,128]
  ; Run the following from the console to see the available colour ramps.
;  index = [1, 3, 4, 7, 9, 13, 14, 16, 18, 19, 20, 21, 22, 24, 25, 26]
;  FOR j=1, 16 DO cgLoadCT, index[j], NCOLORS=16, BOTTOM=16*j, /BREWER
;  CIndex, /BREWER
  
  ; Format the colour table so that values are between 0 and 100, instead of between 1 and 256.
;  rgb = INTARR(256,3) ; Create an empty array to store the modified colour values.
;  rgb[*,0] = reclass(rgb_table[*,0], 0, 100, 1, 256) ; Modify the red band.
;  rgb[*,1] = reclass(rgb_table[*,1], 0, 100, 1, 256) ; Modify the green band.
;  rgb[*,2] = reclass(rgb_table[*,2], 0, 100, 1, 256) ; Modify the blue band.
  ; **************************************************************************************
  
  
  
  ; **************************************************************************************
  
  ; Use the code below instead of the code above - hand built brown to yellow to green colour map...

;  red = [38, 42, 45, 50, 54, 57, 62, 65, 69, 72, 77, 80, 84, 88, 92, 95, 101, 106, 109, $
;    113, 116, 121, 125, 130, 133, 137, 144, 146, 152, 156, 160, 165, 169, 173, 176, 181, $
;    185, 189, 196, 200, 205, 209, 214, 220, 225, 229, 234, 239, 245, 250, 255, 255, 252, $
;    250, 250, 247, 245, 242, 242, 240, 237, 235, 235, 232, 230, 227, 227, 224, 222, 222, $
;    219, 217, 214, 214, 212, 209, 207, 204, 204, 201, 199, 196, 194, 194, 191, 189, 186, $
;    184, 181, 181, 179, 176, 173, 171, 168, 168, 166, 163, 161, 158, 156]
;  
;  green = [115, 117, 120, 122, 125, 128, 130, 133, 135, 138, 140, 143, 145, 148, 150, 153, $
;    158, 161, 163, 166, 168, 171, 173, 176, 179, 181, 186, 189, 191, 194, 196, 199, 201, $
;    204, 207, 209, 212, 214, 219, 222, 224, 227, 230, 235, 237, 240, 242, 245, 250, 252, $
;    255, 254, 249, 244, 243, 237, 233, 228, 226, 222, 218, 213, 211, 207, 203, 198, 195, $
;    192, 188, 188, 183, 179, 176, 172, 169, 165, 162, 157, 156, 152, 149, 144, 141, 139, $
;    135, 132, 128, 125, 122, 119, 117, 113, 109, 106, 104, 101, 98, 95, 93, 88, 85] 
;  
;  blue = [0, 9, 13, 17, 21, 24, 27, 30, 34, 37, 41, 44, 47, 50, 53, 57, 60, 64, 67, 70, $
;    74, 77, 80, 84, 87, 91, 95, 98, 103, 107, 110, 113, 117, 120, 124, 128, 131, 135, 140, $
;    144, 148, 152, 156, 162, 166, 170, 172, 176, 182, 187, 191, 189, 184, 180, 177, 173, $
;    169, 165, 162, 158, 154, 150, 148, 144, 140, 136, 132, 128, 126, 124, 121, 117, 114, $
;    109, 106, 102, 99, 96, 94, 91, 88, 84, 81, 79, 75, 72, 69, 66, 63, 62, 59, 55, 52, 50, $
;    47, 45, 43, 39, 37, 35, 31] 
  
  ; Use instead of the code above - hand built alternate brown to yellow to green colour map.
  red = [0, 9, 18, 24, 30, 34, 39, 43, 49, 54, 56, 61, 65, 70, 74, 78, 84, 88, 92, 98, 103, $
    107, 110, 115, 119, 123, 128, 133, 140, 145, 150, 154, 159, 163, 167, 171, 175, 181, $
    186, 191, 198, 203, 207, 213, 218, 223, 231, 236, 241, 246, 251, 255, 252, 250, 247, $
    245, 242, 240, 240, 237, 235, 232, 230, 227, 224, 222, 219, 217, 217, 214, 212, 209, $
    207, 204, 201, 199, 196, 194, 191, 189, 186, 184, 181, 179, 176, 173, 171, 168, 168, $
    166, 163, 161, 158, 156, 153, 150, 148, 145, 143, 140, 135]
  
  green = [115, 117, 120, 122, 125, 128, 130, 133, 135, 138, 140, 143, 145, 148, 150, 153, $
    156, 158, 161, 166, 168, 171, 173, 176, 179, 181, 184, 186, 191, 194, 196, 199, 201, $
    204, 207, 209, 212, 214, 217, 219, 224, 227, 230, 232, 235, 237, 242, 245, 247, 250, $
    252, 255, 250, 245, 242, 237, 233, 229, 226, 221, 217, 213, 209, 205, 200, 196, 192, $
    189, 186, 183, 179, 175, 172, 167, 163, 160, 155, 153, 148, 145, 140, 137, 133, 130, $
    128, 123, 120, 116, 114, 112, 108, 105, 103, 97, 95, 93, 89, 85, 83, 81, 74]
  
  blue = [17, 18, 23, 26, 29, 31, 34, 37, 39, 43, 45, 49, 51, 55, 57, 60, 64, 66, 69, $
    73, 77, 80, 83, 86, 89, 92, 95, 101, 105, 109, 112, 115, 119, 122, 124, 128, 131, $
    135, 139, 143, 148, 152, 156, 160, 162, 166, 172, 176, 181, 185, 189, 191, 187, 182, $
    178, 174, 170, 165, 163, 159, 155, 151, 147, 143, 139, 135, 132, 128, 126, 122, 119, $
    115, 112, 108, 105, 101, 98, 95, 92, 89, 84, 81, 78, 75, 72, 69, 67, 64, 61, 58, 55, $
    53, 51, 47, 44, 42, 40, 36, 34, 32, 27]
  
  rgb = INTARR(256,3)
  rgb[0:100,0] = red
  rgb[0:100,1] = green
  rgb[0:100,2] = blue
  rgb[101:-1,0] = 255
  rgb[101:-1,1] = 255
  rgb[101:-1,2] = 255
  
  ; **************************************************************************************
  
  
  ; Loop through each date.
  FOR i=0, N_ELEMENTS(dates)-1 DO BEGIN
    start_time_i = SYSTIME(1)
    date_i = dates[i]
    
    BS = READ_BINARY(input_filenames[i], DATA_DIMS=DIMS, DATA_TYPE=1)
    BS_min = MIN(BS[WHERE(BS NE 255)])
    BS_max = MAX(BS[WHERE(BS NE 255)])
    BS_scaled = BYTSCL(BS, max=BS_max, min=BS_min, TOP=BS_max)
    BS_scaled[WHERE(BS EQ 255)] = 255
    
    WRITE_TIFF, output_filenames[i], BS_scaled, GEOTIFF=GEOTIFF, RED=rgb[*,0], GREEN=rgb[*,1], BLUE=rgb[*,2]
    
    IF (i EQ 0) THEN PRINT, ''
    PRINT, STRTRIM(((SYSTIME(1) - start_time_i)), 2), ' seconds, for date ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(dates), 2)
  ENDFOR
  
  PRINT, ''
  PRINT, STRTRIM(((SYSTIME(1) - start_time) / 60), 2), ' minutes (', STRTRIM((((SYSTIME(1) - start_time) / 60) / 60), 2), ' hours)'
END


