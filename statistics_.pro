;-------------------------------------------------------------------------------
; Name:       statistics_.pro
; 
; Purpose:    
;             
;             This routine calculates the ...
;             
;             
;             percent bias
;             pearsons product moment correlation coefficient
;             standard error of the mean
;             standard error of the estimate
;             
;             overestimation rate
;             Normalised root mean square error
;             
;             
; 
; Parameters: 
;             
;             year (as a single integer value; e.g., 2000) 
;             month (as a single integer value; e.g., 4) 
;             day (as a single integer value; e.g., 18) 
;             
;               - the routine will calculate eight-day ET for the specified date
;                 for example: setting the parameters as, 2009, 9, 30 respectively will 
;                 produce the file '.2009.273.tif'. NB. a single given date will 
;                 produce the ET product for the intersecting eight-day period. For 
;                 instance, the parameters 2009, 10, 1, will also produce the file 
;                 '.2009.273.tif' since the date 01/10/2009 falls within the 
;                 eight-day period 30/9/2009-07/10/2009
;             
; Optional Parameters:          
;             
;             (Optional) year2 (as a single integer value; 2000 - ...) 
;             (Optional) month2 (as a single integer value; 1 - 12) 
;             (Optional) day2 (as a single integer value; 1 - 31) 
;             
;               - the optional parameters specify an end date. For instance,
;                 the call 'statistics_, 2009, 9, 1, year2=2009, month2=11, day2=31' 
;                 will produce ET for each MODIS eight day period between the dates
;                 01/09/2009-31/11/2009; namely, 29/08/2009, 06/09/2009, 14/09/2009, 
;                 22/09/2009, 30/09/2009, 08/10/2009, 16/10/2009, 24/10/2009, 01/11/2009, 
;                 09/11/2009, 17/11/2009, and 25/11/2009.
; 
; Inputs:     
; 
; 
; Calling Sequence: 
; 
;             statistics_, year, month, day, year2=year2, month2=month2, day2=day2
; 
;             Examples:
; 
; 
; Author(s):  
; 
;             Garth Warren
;             
;             email: Garth.Warren@csiro.au
;               
; Created:    23/01/2017
; DLM:        
; Copyright:  (c) CSIR0 2017
; 
;-------------------------------------------------------------------------------


FUNCTION daycount, year, month
  IF month EQ 1 THEN days = [31, 31]
  IF month EQ 2 THEN days = [february(year), 31]
  IF month EQ 3 THEN days = [31, february(year)]
  IF month EQ 4 THEN days = [30, 31]
  IF month EQ 5 THEN days = [31, 30]
  IF month EQ 6 THEN days = [30, 31]
  IF month EQ 7 THEN days = [31, 30]
  IF month EQ 8 THEN days = [31, 31]
  IF month EQ 9 THEN days = [30, 31]
  IF month EQ 10 THEN days = [31, 30]
  IF month EQ 11 THEN days = [30, 31]
  IF month EQ 12 THEN days = [31, 30]
  RETURN, days
END


FUNCTION dates, year
  doy = MAKE_ARRAY(N_ELEMENTS(year) * 46, /LONG)
  FOR i=0, N_ELEMENTS(year)-1 DO BEGIN 
    doy[i*46:(1+i)*46-1] = INDGEN(46) * 8 + JULDAY(1, 1, year[i])
  ENDFOR
  RETURN, doy
END


FUNCTION dates_month, year
  dates_ = MAKE_ARRAY(N_ELEMENTS(year) * 12, /LONG)
  k = 0
  FOR i=0, N_ELEMENTS(year)-1 DO BEGIN
    FOR j=0, 12-1 DO BEGIN
      IF (i EQ 0) AND (j EQ 0) THEN dates_[k] = JULDAY(1, 1, year[i]) ELSE dates_[k] = dates_[k-1] + (daycount(year[i], j+1))[1]
      k = k + 1 
    ENDFOR
  ENDFOR
  RETURN, dates_
END


FUNCTION days_per_month, year
  days_ = MAKE_ARRAY(N_ELEMENTS(year) * 12, /LONG)
  k = 0
  FOR i=0, N_ELEMENTS(year)-1 DO BEGIN
    FOR j=0, 12-1 DO BEGIN
      days_[k] = (daycount(year[i], j+1))[0]
      k = k + 1 
    ENDFOR
  ENDFOR
  RETURN, days_
END


FUNCTION february, year
  IF (((399+(year MOD 400))/400-(3+(year MOD 4))/4) EQ 1) OR (year EQ 2000) THEN days = 29 ELSE days = 28
  RETURN, days
END


FUNCTION dayofyear, year, month, day
  dayofyear = JULDAY(month, day, year) - JULDAY(1, 1, year) + 1
  IF (dayofyear LE 9) THEN doy = '00' + STRTRIM(dayofyear, 2)
  IF ((dayofyear GT 9) AND (dayofyear LE 99)) THEN doy = '0' + STRTRIM(dayofyear, 2)
  IF (dayofyear GT 99) THEN doy = STRTRIM(dayofyear, 2) 
  RETURN, doy
END


FUNCTION output
  directory = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_EFM_data\MODIS\Products\Statistics'
  dir = FILE_TEST(directory, /DIRECTORY)
  IF dir[0] EQ 0 THEN FILE_MKDIR, directory
  filename_1 = directory + '\' + 'cmrset.RipIriAgETa' + '.monthly.percent.bias' + '.dat'
  filename_2 = directory + '\' + 'cmrset.RipIriAgETa' + '.monthly.pearsons' + '.dat'
  filename_3 = directory + '\' + 'cmrset.RipIriAgETa' + '.monthly.standard.difference' + '.dat'
  filename_4 = directory + '\' + 'cmrset.RipIriAgETa' + '.monthly.standard.error.of.the.estimate' + '.dat'
  filename_5 = directory + '\' + 'cmrset.RipIriAgETa' + '.monthly.overestimation.rate' + '.dat'
  filename_6 = directory + '\' + 'cmrset.RipIriAgETa' + '.monthly.nrmse' + '.dat'
  IF FILE_TEST(filename_1) EQ 1 THEN filename_1 = '-1'
  IF FILE_TEST(filename_2) EQ 1 THEN filename_2 = '-1'
  IF FILE_TEST(filename_3) EQ 1 THEN filename_2 = '-1'
  IF FILE_TEST(filename_4) EQ 1 THEN filename_2 = '-1'    
  IF FILE_TEST(filename_5) EQ 1 THEN filename_2 = '-1'
  IF FILE_TEST(filename_6) EQ 1 THEN filename_2 = '-1'
  RETURN, [[filename_1], [filename_2], [filename_3], [filename_4], [filename_5], [filename_6]]
END


FUNCTION input, year, month
  directory_1 = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_EFM_data\MODIS\Products\CMRSET\Month_'
  directory_2 = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_EFM_data\MODIS\Products\RipIriAgETa\Month_'
  IF (month LE 9) THEN monthstr = '0' + STRTRIM(month, 2) ELSE monthstr = STRTRIM(month, 2)
  filename_1 = directory_1 + '\' + 'cmrset' + '.' + STRTRIM(year, 2) + '.' + monthstr + '.mean' +  '.dat'
  filename_2 = directory_2 + '\' + 'RipIriAgETa' + '.' + STRTRIM(year, 2) + '.' + monthstr + '.mean' +  '.dat'
  IF FILE_TEST(filename_1) EQ 0 THEN filename_1 = '-1'
  IF FILE_TEST(filename_2) EQ 0 THEN filename_2 = '-1'
  RETURN, [[filename_1], [filename_2]]
END




PRO statistics_, year, year2=year2
  COMPILE_OPT idl2
  ON_ERROR, 2
  
  time = SYSTIME(1)
  
  IF KEYWORD_SET(year2) EQ 0 THEN year2 = year
  
  startdate = JULDAY(1, 1, year) 
  enddate = JULDAY(12, 31, year2) 
  datecount = (enddate - startdate) + 1
  dates = INDGEN(datecount) + startdate
  CALDAT, dates, months, days, years
  
  yearlist = years[UNIQ(years)]
  monthday = dates_month(yearlist)
  index = monthday[VALUE_LOCATE(monthday, dates)]
  dates = index[UNIQ(monthday[VALUE_LOCATE(monthday, dates)])]
  
  CALDAT, dates, month, day, year
  filecount = N_ELEMENTS(year)
  outputfn = output()
  dpf = days_per_month(yearlist)
  
  inputfn = MAKE_ARRAY(N_ELEMENTS(dpf), 2, /STRING)
  valid_x = MAKE_ARRAY(N_ELEMENTS(dpf), /FLOAT)
  valid_y = MAKE_ARRAY(N_ELEMENTS(dpf), /FLOAT)
  
  FOR k=0, N_ELEMENTS(dpf)-1 DO BEGIN
    inputfn[k,*] = input(year[k], month[k])
    IF (inputfn[k,1] NE '-1') THEN valid_x[k] = 1
    IF (inputfn[k,0] NE '-1') THEN valid_y[k] = 1
  ENDFOR
  
  valid_inputs = valid_x * valid_y
  file_n = TOTAL(valid_inputs)
  
  PRINT, '        ' + inputfn
  PRINT, '        ' + outputfn
  PRINT, ''
  PRINT, ''
  
  IF (file_n GT 2) THEN BEGIN
    
    ; Read data
    
    array_x = MAKE_ARRAY(N_ELEMENTS(dpf), 19160*14902, VALUE=-999.00, /FLOAT) 
    FOR k=0, N_ELEMENTS(dpf)-1 DO IF inputfn[k,1] NE '-1' THEN array_x[k,*] = READ_BINARY(inputfn[k,1], DATA_TYPE=4) 
    
    array_y = MAKE_ARRAY(N_ELEMENTS(dpf), 19160*14902, VALUE=-999.00, /FLOAT) 
    FOR k=0, N_ELEMENTS(dpf)-1 DO IF inputfn[k,1] NE '-1' THEN array_y[k,*] = READ_BINARY(inputfn[k,0], DATA_TYPE=4) 
    
    ; Calculate n
    
    nanindex_x = WHERE(array_x EQ -999.00)
    nanindex_y = WHERE(array_y EQ -999.00)
    nanindex = ([nanindex_x, nanindex_y])[(UNIQ([nanindex_x, nanindex_y]))] 
    
    n = array_x
    n[*] = 1
    n[nanindex] = 0
    n = TOTAL(n ,1)
    
    ; Set NAN
    
    array_x[nanindex] = !VALUES.F_NAN
    array_y[nanindex] = !VALUES.F_NAN
    
    ; --- --- --- ---
    
    ; Percent bias
    
    ysum = TOTAL(array_y, DIMENSION=1, /NAN)
    difference = TOTAL((array_x - array_y), DIMENSION=1, /NAN) 
    percentbias = (100 * ( difference / ysum ))
    
    nan_index = WHERE(FINITE(percentbias, /NAN), nan_count)
    IF (nan_count GT 0) THEN percentbias[nan_index] = -999.00    
    OPENW, lun, outputfn[0], /GET_LUN
    FREE_LUN, lun
    OPENU, lun, outputfn[0], /APPEND, /GET_LUN
    WRITEU, lun, percentbias
    FREE_LUN, lun
    
    minutes = (SYSTIME(1)-time) / 60
    PRINT, '        ', STRTRIM(minutes, 2), ' minutes for: file 1 of 6'
    PRINT, ''
    PRINT, ''
    
    ; --- --- --- ---
    
    ; Pearsons product moment correlation coefficient

    xbar = MEAN(array_x, DIMENSION=1, /NAN) 
    ybar = MEAN(array_y, DIMENSION=1, /NAN) 
    crossproduct = TOTAL(((array_x - xbar) * (array_y - ybar)), DIMENSION=1, /NAN) 
    xdeviation = TOTAL((array_x - xbar)^2, DIMENSION=1, /NAN) 
    ydeviation = TOTAL((array_y - ybar)^2, DIMENSION=1, /NAN) 
    pearsons = (crossproduct / (SQRT(xdeviation) * SQRT(ydeviation))) 
    
    IF (nan_count GT 0) THEN pearsons[nan_index] = -999.00    
    OPENW, lun, outputfn[1], /GET_LUN
    FREE_LUN, lun
    OPENU, lun, outputfn[1], /APPEND, /GET_LUN
    WRITEU, lun, pearsons
    FREE_LUN, lun
    
    minutes = (SYSTIME(1)-time) / 60
    PRINT, '        ', STRTRIM(minutes, 2), ' minutes for: file 2 of 6'
    PRINT, ''
    PRINT, ''    
    
    ; --- --- --- ---

    ; Standard difference
    
    SSe = TOTAL((array_y - array_x)^2, DIMENSION=1, /NAN)
    SD = SQRT((1. / n) * SSe) 
    
    IF (nan_count GT 0) THEN SD[nan_index] = -999.00    
    OPENW, lun, outputfn[2], /GET_LUN
    FREE_LUN, lun
    OPENU, lun, outputfn[2], /APPEND, /GET_LUN
    WRITEU, lun, SD
    FREE_LUN, lun
    
    minutes = (SYSTIME(1)-time) / 60
    PRINT, '        ', STRTRIM(minutes, 2), ' minutes for: file 3 of 6'
    PRINT, ''
    PRINT, ''    
    
    ; --- --- --- --- 
    
    ; Standard error of the estimate
    
    SEE = SQRT((SSe / n-2.))
    
    IF (nan_count GT 0) THEN SEE[nan_index] = -999.00    
    OPENW, lun, outputfn[3], /GET_LUN
    FREE_LUN, lun
    OPENU, lun, outputfn[3], /APPEND, /GET_LUN
    WRITEU, lun, SEE
    FREE_LUN, lun
    
    minutes = (SYSTIME(1)-time) / 60
    PRINT, '        ', STRTRIM(minutes, 2), ' minutes for: file 4 of 6'
    PRINT, ''
    PRINT, ''    
    
    ; --- --- --- --- 
    
    ; Overestimation rate
    
    overestimation_count = MAKE_ARRAY(19160*14902, VALUE=0, /FLOAT) 
    
    FOR i=0, N_ELEMENTS(dpf)-1 DO BEGIN
      ovr_index = WHERE(array_x[i] GT array_y[i], count)      
      IF count GT 0 THEN overestimation_count[ovr_index] += 1 
    ENDFOR
    
    overestimation_count = TOTAL(overestimation_count, DIMENSION=1, /NAN)
    overestimationrate = overestimation_count - ((1. / 2.) * n) 
    
    IF (nan_count GT 0) THEN overestimationrate[nan_index] = -999.00 
    OPENW, lun, outputfn[4], /GET_LUN
    FREE_LUN, lun
    OPENU, lun, outputfn[4], /APPEND, /GET_LUN
    WRITEU, lun, overestimationrate
    FREE_LUN, lun
    
    minutes = (SYSTIME(1)-time) / 60
    PRINT, '        ', STRTRIM(minutes, 2), ' minutes for: file 5 of 6'
    PRINT, ''
    PRINT, ''    
    
    ; --- --- --- ---
    
    ; Normalised root mean square error
    
    difference = TOTAL((x - y)^2, DIMENSION=1, /NAN) 
    RMSE = SQRT((1. / n) * difference) 
    NRMSE = 100. * (RMSE / (ymax - ymin)) 
    
    IF (nan_count GT 0) THEN NRMSE[nan_index] = -999.00    
    OPENW, lun, outputfn[5], /GET_LUN
    FREE_LUN, lun
    OPENU, lun, outputfn[5], /APPEND, /GET_LUN
    WRITEU, lun, NRMSE
    FREE_LUN, lun
    
    minutes = (SYSTIME(1)-time) / 60
    PRINT, '        ', STRTRIM(minutes, 2), ' minutes for: file 6 of 6'
    PRINT, ''
    PRINT, ''    
    
  ENDIF
  
END











