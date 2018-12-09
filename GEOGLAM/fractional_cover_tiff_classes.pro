; ##############################################################################################
; Name: fractional_cover_tiff_classes.pro
; Language: IDL
; Author: Juan Pablo Guerschman & Garth Warren
; Date: 03072014
; DLM: 31072014 (Garth Warren)
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



FUNCTION output_classnames, dates
  COMPILE_OPT IDL2
  
;  directory = '\\wron\RemoteSensing\MODIS\products\Guerschman_etal_RSE2009\data\v3.0.1\geoTIFF\';bs_pv_npv\'
  directory = '\\Redfish-bu\geoglam\fractional_cover\'
  CALDAT, dates, month, day, year
  count = N_ELEMENTS(day)
  date_strings = date_string(day, month, year) 
  returnarray = MAKE_ARRAY(3, 6, count, /STRING)
  
  ; Set the band names.
  FOR i = 0, 2 DO BEGIN
    CASE i OF
      0: band = 'aust.005.PV'
      1: band = 'aust.005.NPV'
      2: band = 'aust.005.BS'
    ENDCASE
    
    FOR j = 0, 5 DO BEGIN
      CASE j OF
        0: class = '0to20.tif'
        1: class = '20to40.tif'
        2: class = '40to60.tif'
        3: class = '60to80.tif'
        4: class = '80to100.tif'
        5: class = 'classes.tif'
      ENDCASE
      
      filename = STRCOMPRESS(directory + $
        'FractCover.V3_0_1.' + $
        date_strings[*,2] + '.' + $
        date_strings[*,3] + '.' + $
        band + '.' + $
        class, $
        /REMOVE_ALL)
      
      returnarray[i,j,*] = filename
    ENDFOR
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



FUNCTION threshold_data, array, operator_1, threshold_1, operator_2, operator_3, threshold_2
  COMPILE_OPT idl2
  
  dims = SIZE(array) ; Get the array dimensions.
  array_out = MAKE_ARRAY(N_ELEMENTS(operator_1), dims[1], dims[2], /BYTE) ; Create an array to hold the ouput classes.
  
  ; Threshold the data.
  FOR i=0, N_ELEMENTS(operator_1)-1 DO BEGIN
    
    IF operator_2[i] EQ 'NA' THEN BEGIN
      IF operator_1[i] EQ 'EQ' THEN array_out[i,*,*] = (array EQ threshold_1[i])
      IF operator_1[i] EQ 'LE' THEN array_out[i,*,*] = (array LE threshold_1[i]) 
      IF operator_1[i] EQ 'LT' THEN array_out[i,*,*] = (array LT threshold_1[i])
      IF operator_1[i] EQ 'GE' THEN array_out[i,*,*] = (array GE threshold_1[i])
      IF operator_1[i] EQ 'GT' THEN array_out[i,*,*] = (array GT threshold_1[i])
    ENDIF
    
    IF operator_2[i] EQ 'AND' THEN BEGIN
      IF operator_1[i] EQ 'EQ' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) AND (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) AND (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) AND (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) AND (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) AND (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'LE' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array LE threshold_1[i]) AND (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array LE threshold_1[i]) AND (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array LE threshold_1[i]) AND (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array LE threshold_1[i]) AND (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array LE threshold_1[i]) AND (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'LT' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array LT threshold_1[i]) AND (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array LT threshold_1[i]) AND (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array LT threshold_1[i]) AND (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array LT threshold_1[i]) AND (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array LT threshold_1[i]) AND (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'GE' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array GE threshold_1[i]) AND (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array GE threshold_1[i]) AND (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array GE threshold_1[i]) AND (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array GE threshold_1[i]) AND (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array GE threshold_1[i]) AND (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'GT' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array GT threshold_1[i]) AND (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array GT threshold_1[i]) AND (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array GT threshold_1[i]) AND (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array GT threshold_1[i]) AND (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array GT threshold_1[i]) AND (array GT threshold_2[i]))   
      ENDIF
    ENDIF
    
    IF operator_2[i] EQ 'OR' THEN BEGIN
      IF operator_1[i] EQ 'EQ' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) OR (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) OR (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) OR (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) OR (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array EQ threshold_1[i]) OR (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'LE' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array LE threshold_1[i]) OR (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array LE threshold_1[i]) OR (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array LE threshold_1[i]) OR (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array LE threshold_1[i]) OR (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array LE threshold_1[i]) OR (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'LT' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array LT threshold_1[i]) OR (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array LT threshold_1[i]) OR (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array LT threshold_1[i]) OR (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array LT threshold_1[i]) OR (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array LT threshold_1[i]) OR (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'GE' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array GE threshold_1[i]) OR (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array GE threshold_1[i]) OR (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array GE threshold_1[i]) OR (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array GE threshold_1[i]) OR (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array GE threshold_1[i]) OR (array GT threshold_2[i]))   
      ENDIF
      IF operator_1[i] EQ 'GT' THEN BEGIN 
        IF operator_3[i] EQ 'EQ' THEN array_out[i,*,*] = ((array GT threshold_1[i]) OR (array EQ threshold_2[i]))
        IF operator_3[i] EQ 'LE' THEN array_out[i,*,*] = ((array GT threshold_1[i]) OR (array LE threshold_2[i]))
        IF operator_3[i] EQ 'LT' THEN array_out[i,*,*] = ((array GT threshold_1[i]) OR (array LT threshold_2[i]))
        IF operator_3[i] EQ 'GE' THEN array_out[i,*,*] = ((array GT threshold_1[i]) OR (array GE threshold_2[i]))
        IF operator_3[i] EQ 'GT' THEN array_out[i,*,*] = ((array GT threshold_1[i]) OR (array GT threshold_2[i]))   
      ENDIF
    ENDIF
    
  ENDFOR
  
  return, array_out
END



PRO fractional_cover_tiff_classes
  COMPILE_OPT idl2
  start_time = SYSTIME(1)
  
  ; Set the input parameters.
  start_date = JULDAY(1, 1, 2001) ; Start date.
  end_date =  JULDAY(1, 5, 2001) ; End date.
;  mask = 'C:\Users\war409\Documents\data\programming\idl\GEOGLAM\FractCover.tif' ; Example grid.
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
;  output_files = output_names(dates)
;  output_filenames = output_files[0,4,*]
;  output_shortnames = output_files[1,4,*]
  
  ; Set the output threshold-class filenames.
  output_filenames = output_classnames(dates)
  
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
    
    ; Threshold the data (break up each input into classes).
    PV_classes = threshold_data(PV_scaled, ['GE','GE','GE','GE','GE'], [0,20,40,60,80], ['AND','AND','AND','AND','AND'], ['LT','LT','LT','LT','LE'], [20,40,60,80,100])
    NPV_classes = threshold_data(NPV_scaled, ['GE','GE','GE','GE','GE'], [0,20,40,60,80], ['AND','AND','AND','AND','AND'], ['LT','LT','LT','LT','LE'], [20,40,60,80,100])
    BS_classes = threshold_data(BS_scaled, ['GE','GE','GE','GE','GE'], [0,20,40,60,80], ['AND','AND','AND','AND','AND'], ['LT','LT','LT','LT','LE'], [20,40,60,80,100])
    
    ; Format the data as 2D arrays...
    
    pv1 = MAKE_ARRAY(9580, 7451, /BYTE)
    pv1[*,*] = PV_classes[0,*,*]
    pv2 = MAKE_ARRAY(9580, 7451, /BYTE)
    pv2[*,*] = PV_classes[1,*,*]
    pv3 = MAKE_ARRAY(9580, 7451, /BYTE)
    pv3[*,*] = PV_classes[2,*,*]
    pv4 = MAKE_ARRAY(9580, 7451, /BYTE)
    pv4[*,*] = PV_classes[3,*,*]    
    pv5 = MAKE_ARRAY(9580, 7451, /BYTE)
    pv5[*,*] = PV_classes[4,*,*]

    npv1 = MAKE_ARRAY(9580, 7451, /BYTE)
    npv1[*,*] = NPV_classes[0,*,*]
    npv2 = MAKE_ARRAY(9580, 7451, /BYTE)
    npv2[*,*] = NPV_classes[1,*,*]
    npv3 = MAKE_ARRAY(9580, 7451, /BYTE)
    npv3[*,*] = NPV_classes[2,*,*]
    npv4 = MAKE_ARRAY(9580, 7451, /BYTE)
    npv4[*,*] = NPV_classes[3,*,*]    
    npv5 = MAKE_ARRAY(9580, 7451, /BYTE)
    npv5[*,*] = NPV_classes[4,*,*]
    
    bs1 = MAKE_ARRAY(9580, 7451, /BYTE)
    bs1[*,*] = BS_classes[0,*,*]
    bs2 = MAKE_ARRAY(9580, 7451, /BYTE)
    bs2[*,*] = BS_classes[1,*,*]
    bs3 = MAKE_ARRAY(9580, 7451, /BYTE)
    bs3[*,*] = BS_classes[2,*,*]
    bs4 = MAKE_ARRAY(9580, 7451, /BYTE)
    bs4[*,*] = BS_classes[3,*,*]    
    bs5 = MAKE_ARRAY(9580, 7451, /BYTE)
    bs5[*,*] = BS_classes[4,*,*]
    
    ; Reclassify the grid values so that the cell value shows the threshold category...
    
    pv2[WHERE(pv2 EQ 1)] = 2
    pv3[WHERE(pv3 EQ 1)] = 3
    pv4[WHERE(pv4 EQ 1)] = 4
    pv5[WHERE(pv5 EQ 1)] = 5
    
    npv2[WHERE(npv2 EQ 1)] = 2
    npv3[WHERE(npv3 EQ 1)] = 3
    npv4[WHERE(npv4 EQ 1)] = 4
    npv5[WHERE(npv5 EQ 1)] = 5
      
    bs2[WHERE(bs2 EQ 1)] = 2
    bs3[WHERE(bs3 EQ 1)] = 3
    bs4[WHERE(bs4 EQ 1)] = 4
    bs5[WHERE(bs5 EQ 1)] = 5
    
    ; Combine the individual class grids into single grids per FC...
    
    pv_out = pv1 + pv2 + pv3 + pv4 + pv5
    npv_out = npv1 + npv2 + npv3 + npv4 + npv5
    bs_out = bs1 + bs2 + bs3 + bs4 + bs5
    
    ; Write the data...
    
    WRITE_TIFF, output_filenames[0,5,i], pv_out, GEOTIFF=GEOTIFF, RED=[255,233,163,76,56,38], GREEN=[255,255,255,230,168,115], BLUE=[255,190,115,0,0,0]
    WRITE_TIFF, output_filenames[1,5,i], npv_out, GEOTIFF=GEOTIFF, RED=[255,232,223,197,169,132], GREEN=[255,190,115,0,0,0], BLUE=[255,255,255,255,230,168]
    WRITE_TIFF, output_filenames[2,5,i], bs_out, GEOTIFF=GEOTIFF, RED=[255,255,255,255,168,115], GREEN=[255,235,211,170,112,76], BLUE=[255,175,127,0,0,0]
    
    WRITE_TIFF, output_filenames[0,0,i], pv1, GEOTIFF=GEOTIFF, RED=[255, 233], GREEN=[255, 255], BLUE=[255, 190]
    WRITE_TIFF, output_filenames[0,1,i], pv2, GEOTIFF=GEOTIFF, RED=[255, 163], GREEN=[255, 255], BLUE=[255, 115]
    WRITE_TIFF, output_filenames[0,2,i], pv3, GEOTIFF=GEOTIFF, RED=[255, 76], GREEN=[255, 230], BLUE=[255, 0]
    WRITE_TIFF, output_filenames[0,3,i], pv4, GEOTIFF=GEOTIFF, RED=[255, 56], GREEN=[255, 168], BLUE=[255, 0]
    WRITE_TIFF, output_filenames[0,4,i], pv5, GEOTIFF=GEOTIFF, RED=[255, 38], GREEN=[255, 115], BLUE=[255, 0]
    
    WRITE_TIFF, output_filenames[1,0,i], npv1, GEOTIFF=GEOTIFF, RED=[255, 232], GREEN=[255, 190], BLUE=[255, 255]
    WRITE_TIFF, output_filenames[1,1,i], npv2, GEOTIFF=GEOTIFF, RED=[255, 223], GREEN=[255, 115], BLUE=[255, 255]
    WRITE_TIFF, output_filenames[1,2,i], npv3, GEOTIFF=GEOTIFF, RED=[255, 197], GREEN=[255, 0], BLUE=[255, 255]
    WRITE_TIFF, output_filenames[1,3,i], npv4, GEOTIFF=GEOTIFF, RED=[255, 169], GREEN=[255, 0], BLUE=[255, 230]
    WRITE_TIFF, output_filenames[1,4,i], npv5, GEOTIFF=GEOTIFF, RED=[255, 132], GREEN=[255, 0], BLUE=[255, 168]
    
    WRITE_TIFF, output_filenames[2,0,i], bs1, GEOTIFF=GEOTIFF, RED=[255, 255], GREEN=[255, 235], BLUE=[255, 175]
    WRITE_TIFF, output_filenames[2,1,i], bs2, GEOTIFF=GEOTIFF, RED=[255, 255], GREEN=[255, 211], BLUE=[255, 127]
    WRITE_TIFF, output_filenames[2,2,i], bs3, GEOTIFF=GEOTIFF, RED=[255, 255], GREEN=[255, 170], BLUE=[255, 0]
    WRITE_TIFF, output_filenames[2,3,i], bs4, GEOTIFF=GEOTIFF, RED=[255, 168], GREEN=[255, 112], BLUE=[255, 0]
    WRITE_TIFF, output_filenames[2,4,i], bs5, GEOTIFF=GEOTIFF, RED=[255, 115], GREEN=[255, 76], BLUE=[255, 0]
    
    IF (i EQ 0) THEN PRINT, ''
    PRINT, STRTRIM(((SYSTIME(1) - start_time_i)), 2), ' seconds, for date ', STRTRIM(i+1, 2), ' of ', STRTRIM(N_ELEMENTS(dates), 2)
  ENDFOR
  
  PRINT, ''
  PRINT, STRTRIM(((SYSTIME(1) - start_time) / 60), 2), ' minutes (', STRTRIM((((SYSTIME(1) - start_time) / 60) / 60), 2), ' hours)'
END


