; ##############################################################################################
; Name: fractional_cover_tiff.pro
; Language: IDL
; Author: Juan Pablo Guerschman & Garth Warren
; Date: 03072014
; DLM: 01072014 (Garth Warren)
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
  
;  directory = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\geoTIFF\';bs_pv_npv\'
  directory = '\\Redfish-bu\geoglam\fractional_cover\test\'
  CALDAT, dates, month, day, year
  count = N_ELEMENTS(day)
  date_strings = date_string(day, month, year) 
  returnarray = MAKE_ARRAY(2, 5, count, /STRING)
  
  ; Set the band names.
  FOR i = 0, 4 DO BEGIN
    CASE i OF
      0: band = 'aust.005.PV.tif'
      1: band = 'aust.005.NPV.tif'
      2: band = 'aust.005.BS.tif'
      3: band = 'aust.005.FLAG.tif'
      4: band = 'aust.005.BS.PV.NPV.tif'
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



PRO fractional_cover_tiff
  COMPILE_OPT idl2
  start_time = SYSTIME(1)
  
  ; Set the input parameters.
  start_date = JULDAY(1, 1, 2001) ; Start date.
  end_date =  JULDAY(1, 5, 2001) ; End date.
  mask = '\\REDFISH-BU\GEOGLAM\fractional_cover\FractCover.tif'
  
  land = READ_TIFF(mask, GEOTIFF=GEOTIFF) ; Read the land mask.
  dimensions = SIZE(land) ; Get the dimensions of the land mask.
  dims = [dimensions[1], dimensions[2]] ; Set the dims variable.
  dates = modis_eight_day_dates(start_date, end_date) ; Get the eight day dates that fall between the selected start and end dates. 
  
  ; Set the input PV files.
  pv_files = input_names(dates)
  pv_filenames = pv_files[0,0,*]
  pv_shortnames = pv_files[1,0,*]
  
  ; Set the input NPV files.
  npv_files = input_names(dates)
  npv_filenames = npv_files[0,1,*]
  npv_shortnames = npv_files[1,1,*]  
  
  ; Set the input BS files.
  bs_files = input_names(dates)
  bs_filenames = bs_files[0,2,*]
  bs_shortnames = bs_files[1,2,*]  
  
  ; Set the output filenamess.
  output_files = output_names(dates)
  output_filenames = output_files[0,4,*]
  output_shortnames = output_files[1,4,*]
  
  ; Make sure the input files exist.
  k = WHERE((FILE_TEST(pv_filenames) EQ 1))
  IF (k[0] EQ -1) THEN STOP
  pv_filenames = pv_filenames[k]
  pv_shortnames = pv_shortnames[k]
  npv_filenames = npv_filenames[k]
  npv_shortnames = npv_shortnames[k]
  bs_filenames = bs_filenames[k]
  bs_shortnames = bs_shortnames[k]
  output_filenames = output_filenames[*,*,k]
  dates = dates[k]

  ; Make sure the input files exist.
  k = WHERE((FILE_TEST(npv_filenames) EQ 1))
  IF (k[0] EQ -1) THEN STOP
  pv_filenames = pv_filenames[k]
  pv_shortnames = pv_shortnames[k]
  npv_filenames = npv_filenames[k]
  npv_shortnames = npv_shortnames[k]
  bs_filenames = bs_filenames[k]
  bs_shortnames = bs_shortnames[k]
  output_filenames = output_filenames[*,*,k]
  dates = dates[k]
  
  ; Make sure the input files exist.
  k = WHERE((FILE_TEST(bs_filenames) EQ 1))
  IF (k[0] EQ -1) THEN STOP
  pv_filenames = pv_filenames[k]
  pv_shortnames = pv_shortnames[k]
  npv_filenames = npv_filenames[k]
  npv_shortnames = npv_shortnames[k]
  bs_filenames = bs_filenames[k]
  bs_shortnames = bs_shortnames[k]
  output_filenames = output_filenames[*,*,k]
  dates = dates[k]
  
  ; Loop through each date.
  FOR i=0, N_ELEMENTS(dates)-1 DO BEGIN
    start_time_i = SYSTIME(1)
    date_i = dates[i]
    
    ; Read the input data.
    PV = READ_BINARY(pv_filenames[i], DATA_DIMS=DIMS, DATA_TYPE=1)
    PV_min = MIN(PV[WHERE(PV NE 255)])
    PV_max = MAX(PV[WHERE(PV NE 255)])
    PV_scaled = BYTSCL(PV, max=PV_max, min=PV_min, TOP=PV_max)
    PV_scaled[WHERE(PV EQ 255)] = 255
    
    ; Read the input data.
    NPV = READ_BINARY(npv_filenames[i], DATA_DIMS=DIMS, DATA_TYPE=1)
    NPV_min = MIN(NPV[WHERE(NPV NE 255)])
    NPV_max = MAX(NPV[WHERE(NPV NE 255)])
    NPV_scaled = BYTSCL(NPV, max=NPV_max, min=NPV_min, TOP=NPV_max)
    NPV_scaled[WHERE(NPV EQ 255)] = 255
    
    ; Read the input data.
    BS = READ_BINARY(bs_filenames[i], DATA_DIMS=DIMS, DATA_TYPE=1)
    BS_min = MIN(BS[WHERE(BS NE 255)])
    BS_max = MAX(BS[WHERE(BS NE 255)])
    BS_scaled = BYTSCL(BS, max=BS_max, min=BS_min, TOP=BS_max)
    BS_scaled[WHERE(BS EQ 255)] = 255
    
    ; Write a multi-band RGB image; where BS is shown in red, PV in green, and NPV in blue.
    WRITE_TIFF, output_filenames[i], GEOTIFF=GEOTIFF, PLANARCONFIG=2, RED=BS_scaled, GREEN=PV_scaled, BLUE=NPV_scaled
    
    
    
    
    ; Convert RGB to grayscale.
;    gray = 0.3 * Reform(BS_scaled) + 0.59 * Reform(PV_scaled) + 0.11 * Reform(NPV_scaled
       
;    WRITE_TIFF, output_filenames[i], gray, GEOTIFF=GEOTIFF ;, RED=BS_scaled, GREEN=PV_scaled, BLUE=NPV_scaled
    
;    rgb = INTARR(256,3)
;    rgb[0:100,0] = red
;    rgb[0:100,1] = green
;    rgb[0:100,2] = blue
;    rgb[101:-1,0] = 255
;    rgb[101:-1,1] = 255
;    rgb[101:-1,2] = 255
;    
;    
;    bands = BYTARR(3, DIMS[0] * DIMS[1])
;    bands[0,*] = BS_scaled
;    bands[1,*] = PV_scaled
;    bands[2,*] = NPV_scaled
    
;    rgb = INTARR(256,3)
;    rgb[*,0] = INDGEN(256, /BYTE)
;    rgb[*,1] = INDGEN(256, /BYTE)
;    rgb[*,2] = INDGEN(256, /BYTE)
    
;    WRITE_TIFF, output_filenames[i], bands, GEOTIFF=GEOTIFF, RED=rgb[*,0], GREEN=rgb[*,1], BLUE=rgb[*,2]    
    
    
    
        
    IF (i EQ 0) THEN PRINT, ''
    PRINT, STRTRIM(((SYSTIME(1) - start_time_i)), 2), ' seconds, for date ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(dates), 2)
  ENDFOR
  
  PRINT, ''
  PRINT, STRTRIM(((SYSTIME(1) - start_time) / 60), 2), ' minutes (', STRTRIM((((SYSTIME(1) - start_time) / 60) / 60), 2), ' hours)'
END


