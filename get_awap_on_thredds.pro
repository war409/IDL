


;-----------------------------------------------------------------------------------------------


FUNCTION awap_name, band, day, month, year
  COMPILE_OPT IDL2
  
  directory = 'http://opendap.bom.gov.au:8080/thredds/fileServer/'
  IF month LE 9 THEN month_suffix = '0' ELSE month_suffix = ' '
  IF day LE 9 THEN day_suffix = '0' ELSE day_suffix = ' '
  doy = JULDAY(month, day, year)  -  JULDAY(1, 1, year) + 1
  
  CASE band OF
      1: file = ['daily_rain_5km', 'rainfall-day_awap_daily_0deg05_aust_']
      2: file = ['rain_5km_monthly', 'rainfall-month_awap_monthly_0deg05_aust_']
      3: file = ['daily_maximum_temperature_5km', 'temperature-maximum-day_awap_daily_0deg05_aust_']
      4: file = ['daily_minimum_temperature_5km', 'temperature-minimum-day_awap_daily_0deg05_aust_']
      5: file = ['daily_solar_radiation_5km', 'solar-global-exposure-day_awap_daily_0deg05_aust_']
   ENDCASE

   filename = STRCOMPRESS(directory + $
                          STRING(file[0]) + '/' + $
                          STRING(year) + '/' + $
                          STRING(file[1]) + $
                          STRING(year) + $
                          month_suffix + STRING(month) + $
                          day_suffix + STRING(day) +  '.nc', $
                          /REMOVE_ALL)
                          
  shortfilename = STRCOMPRESS(STRING(file[1]) + $
                              STRING(year) + $
                              month_suffix + STRING(month) + $
                              day_suffix + STRING(day) +  '.nc', $
                              /REMOVE_ALL)
  
  RETURN, [filename, shortfilename]
END


;-----------------------------------------------------------------------------------------------


FUNCTION get_data, URL, output, log
  time = SYSTIME(1)
  CATCH, error 

  IF (error NE 0) THEN BEGIN
    CATCH, /CANCEL
    PRINT, 'file not found: ' + URL
    OBJ_DESTROY, netObject
    OPENU, lun, log, /APPEND, /GET_LUN
    PRINTF, FORMAT='(10000(A,:,","))', lun, URL
    FREE_LUN, lun
    RETURN, -1
  ENDIF
  
  netObject = OBJ_NEW('IDLnetURL')
  void = netObject->Get(URL=URL, FILENAME=output)
  OBJ_DESTROY, netObject
  PRINT, STRTRIM(SYSTIME(1) - time, 2) + ' seconds to download: ' + URL
END


;-----------------------------------------------------------------------------------------------


PRO get_awap_on_thredds
  time = SYSTIME(1)
  PRINT, ''
  
  output_directory = '\\wron\Working\work\RVR_CC\ClimateC\data\awap\tmax\daily\'
  band = 3
  start_date = JULDAY(1, 1, 1970)
  end_date =  JULDAY(12, 31, 2013)
  interval = 1
  date_count = (end_date + 1 - start_date)
  dates = INDGEN(date_count) * interval + start_date
  
  ; Create a log to record any failed downloads.
  log = 'C:\workspace\error_log_tmax.txt'
  OPENW, lun, log, /GET_LUN ; Create the output file.
  FREE_LUN, lun ; Close the output file. 
      
  ; File loop.
  FOR i=0, N_ELEMENTS(dates)-1 DO BEGIN
    CALDAT, dates[i], month, day, year 
    file = awap_name(band, day, month, year)
    output = output_directory + STRTRIM(year, 2) + '\' + file[1]
    data = get_data(file[0], output, log)
  ENDFOR
  
  PRINT, ''
  PRINT, STRTRIM(((SYSTIME(1) - time) / 60), 2) + ' minutes to download all files'
END








