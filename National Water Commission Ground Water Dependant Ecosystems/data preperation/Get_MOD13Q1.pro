; ##############################################################################################
; NAME: Get_MOD13Q1.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au) 
; DATE: 14/02/2010
; DLM: 22/02/2013
; 
; DESCRIPTION: This tool retrieves 250 meter resolution MOD13Q1 bands.
;
; ##############################################################################################


;---------------------------------------------------------------------------------------------
FUNCTION dates
  
  COMPILE_OPT idl2
  dates_2000 = INDGEN(46) * 16 +  JULDAY(1,1,2000)
  dates_2001 = INDGEN(46) * 16 +  JULDAY(1,1,2001)
  dates_2002 = INDGEN(46) * 16 +  JULDAY(1,1,2002)
  dates_2003 = INDGEN(46) * 16 +  JULDAY(1,1,2003)
  dates_2004 = INDGEN(46) * 16 +  JULDAY(1,1,2004)
  dates_2005 = INDGEN(46) * 16 +  JULDAY(1,1,2005)
  dates_2006 = INDGEN(46) * 16 +  JULDAY(1,1,2006)
  dates_2007 = INDGEN(46) * 16 +  JULDAY(1,1,2007)
  dates_2008 = INDGEN(46) * 16 +  JULDAY(1,1,2008)
  dates_2009 = INDGEN(46) * 16 +  JULDAY(1,1,2009)
  dates_2010 = INDGEN(46) * 16 +  JULDAY(1,1,2010)
  dates_2011 = INDGEN(46) * 16 +  JULDAY(1,1,2011)
  dates_2012 = INDGEN(46) * 16 +  JULDAY(1,1,2012)
  dates_2013 = INDGEN(46) * 16 +  JULDAY(1,1,2013)  
  dates_2014 = INDGEN(46) * 16 +  JULDAY(1,1,2014)
  dates_2015 = INDGEN(46) * 16 +  JULDAY(1,1,2015)  
  
  dates = [dates_2000, dates_2001, dates_2002, dates_2003, dates_2004, dates_2005, dates_2006, $
    dates_2007, dates_2008, dates_2009, dates_2010, dates_2011, dates_2012, dates_2013, dates_2014, $
    dates_2015]
  
  RETURN, dates ; Return a full list of all possible 8-day [julian day] dates for the years 2000 to 2011.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION MOD13Q1, day, month, year ; Get the full file name and path of each MOD09A1 file for the selected date.
  COMPILE_OPT idl2
  
  path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MOD13Q1.005\' ; Set MODIS parent directory.
  IF month LE 9 THEN month_prefix = '0' ELSE month_prefix = ' ' ; Add leading zero to month.
  IF day LE 9 THEN day_prefix = '0' ELSE day_prefix = ' ' ; Add leading zero to day.
  DOY = JULDAY(month, day, year)  -  JULDAY(1, 1, Year) + 1 ; Get date as DOY.
  IF DOY GT 9 and DOY LE 99 THEN DOY_prefix = '0' ; Add leading zero to DOY.
  IF DOY LE 9 THEN DOY_prefix = '00' ; Add leading zero to DOY.
  IF DOY GT 99 THEN DOY_prefix = ' '
  
  filenames = STRARR(10) ; Create array to hold file names.
  
  FOR i=0, 10 DO BEGIN 
    CASE i OF
      0: band = 'MOD13Q1.2000.049.aust.005.b01.250m_ndvi.hdf.gz' 
      1: band = 'MOD13Q1.2000.049.aust.005.b02.250m_evi.hdf.gz' 
      2: band = 'MOD13Q1.2000.049.aust.005.b03.250m_vi_quality' 
      3: band = 'MOD13Q1.2000.049.aust.005.b04.250m_0620_0670nm_refl' 
      4: band = 'MOD13Q1.2000.049.aust.005.b05.250m_0841_0876nm_refl' 
      5: band = 'MOD13Q1.2000.049.aust.005.b06.250m_0459_0479nm_refl' 
      6: band = 'MOD13Q1.2000.049.aust.005.b07.250m_2105_2155nm_refl' 
      7: band = 'MOD13Q1.2000.049.aust.005.b08.250m_view_zenith' 
      8: band = 'MOD13Q1.2000.049.aust.005.b09.250m_sun_zenith' 
      9: band = 'MOD13Q1.2000.049.aust.005.b10.250m_relative_azimuth' 
      10: band = 'MOD13Q1.2000.049.aust.005.b11.250m_day_of_year' 
      11: band = 'MOD13Q1.2000.049.aust.005.b12.250m_pixel_reliability' 
    ENDCASE
    
    filename = STRCOMPRESS(path + STRING(year) + '.' + month_prefix + STRING(month) +  '.' + day_prefix + STRING(day) +  '\' + $
      'MOD13Q1.' + STRING(year) + '.' + DOY_prefix + STRING(DOY) + '.' + band , /REMOVE_ALL) 
    filenames[i] = filename 
  ENDFOR
  
  RETURN, filenames ; Return the file name array to the main procedure.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION gzhdf, filename, temp ; Unzip the input file to the temp folder and get data:
  COMPILE_OPT idl2
  ON_ERROR
  
  file_information = File_Info(filename)
  
  IF file_information.Exists EQ 1 THEN BEGIN
    SPAWN, 'gzip -d -c ' + filename + ' > ' + temp , ResuLT, ErrResuLT, /HIDE ; Unzip File.
    sdFileID = HDF_SD_Start(temp, /Read) ; Read the uncompressed HDF file.
    sdsID = HDF_SD_Select(sdFileID, 0) ; Set the HDF ID.
    HDF_SD_GetData, sdsID, data ; Get the HDF data.
    HDF_SD_END, sdFileID ; Close the HDF.
    FILE_DELETE, temp ; Delete the temporary file (unzipped HDF).
  ENDIF ELSE Begin
      data =  -1 ; Return -1 if the file or filename is invalid. 
  ENDELSE
  
  RETURN, data ; Retrun the HDF file data to the main procedure.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
PRO Get_MOD13Q1
  COMPILE_OPT idl2 
  time = SYSTIME(1) 
  
  ; Set the output directory...
  output_directory = 'H:\war409\gamma\modis\' 
  
  ; Open an existing image and extract the header information...
  template = '\\wron\Working\work\war409\work\imagery\modis\template\MOD13Q1.2000.049.aust.005.b02.250m_evi.img'
  ENVI_OPEN_FILE , template, R_FID=FID_template, /NO_REALIZE 
  map = ENVI_GET_MAP_INFO(FID=FID_template) 
  
  ; Get all valid 8-day dates for the selected time period...
  dates = dates() 
  startdate = JULDAY(1, 1, 2000)
  enddate = JULDAY(12, 31, 2000)
  selectdates = Where((dates GE startdate) AND (dates LE enddate), datecount)
  
  ;-------------------------------------------------------------------------------------------
  ; Date loop.
  ;-------------------------------------------------------------------------------------------
  
  FOR i=0, datecount-1 DO BEGIN
    itime = SYSTIME(1) ; Get loop start time.
    
    ; Get MODIS data...
    
    idates = selectdates[i] ; Get the i-th date.
    CALDAT, dates[idates], month, day, year ; Get the i-th month, day, and year.
    filenames = MOD13Q1(day, month, year) ; Get the i-th date file list.
    IF month LE 9 THEN month_string = '0' + STRTRIM(Month, 2) ELSE month_string = STRTRIM(month, 2)
    IF day LE 9 THEN day_string = '0' + STRTRIM(day, 2) ELSE day_string = STRTRIM(day, 2)
    temp  = 'C:\temp.hdf' ; Set the temporary file name and path. 
    
    ; Get the NDVI band...
    filename_NDVI = filenames[0] 
    NDVI = gzhdf(filename_NDVI, temp) 
    size = SIZE(NDVI) 
    
    ; Get the EVI band...
    filename_EVI = filenames[1] 
    EVI = gzhdf(filename_EVI, temp) 
    
    ; Get the quality band... 
    filename_quality = filenames[2] 
    quality = gzhdf(filename_quality, temp) 
    
    ; Get the red band... 
    filename_red = filenames[3] 
    red = gzhdf(filename_red, temp) 
    
    ; Get the NIR band... 
    filename_NIR = filenames[4] 
    NIR = gzhdf(filename_NIR, temp) 
    
    ; Get the blue band... 
    filename_blue = filenames[5] 
    blue = gzhdf(filename_blue, temp) 
    
    ; Get the MIR band... 
    filename_MIR = filenames[6] 
    MIR = gzhdf(filename_MIR, temp) 
    
    ; Get the view (zenith) band... 
    filename_view = filenames[7] 
    view = gzhdf(filename_view, temp) 
    
    ; Get the sun (zenith) band... 
    filename_sun = filenames[8] 
    sun = gzhdf(filename_sun, temp) 
    
    ; Get the azimuth band... 
    filename_azimuth = filenames[9] 
    azimuth = gzhdf(filename_azimuth, temp) 
    
    ; Get the day of year band... 
    filename_dayofyear = filenames[10] 
    dayofyear = gzhdf(filename_dayofyear, temp) 
    
    ; Get the (pixel) reliability band... 
    filename_reliability = filenames[11] 
    reliability = gzhdf(filename_reliability, temp) 
    
    ; Check whether any of the selected files are missing or corrupt... 
    IF ((N_ELEMENTS(NDVI) EQ 1) OR $ 
        (N_ELEMENTS(EVI) EQ 1) OR $ 
        (N_ELEMENTS(quality) EQ 1) OR $ 
        (N_ELEMENTS(red) EQ 1) OR $ 
        (N_ELEMENTS(NIR) EQ 1) OR $ 
        (N_ELEMENTS(blue) EQ 1) OR $ 
        (N_ELEMENTS(MIR) EQ 1) OR $ 
        (N_ELEMENTS(view) EQ 1) OR $ 
        (N_ELEMENTS(sun) EQ 1) OR $ 
        (N_ELEMENTS(azimuth) EQ 1) OR $ 
        (N_ELEMENTS(dayofyear) EQ 1) OR $ 
        (N_ELEMENTS(reliability) EQ 1)) $ 
    THEN corrupt = 1 ELSE corrupt = 0 
    
    ;-----------------------------------------------------------------------------------------
    ; Write Data.
    ;-----------------------------------------------------------------------------------------
    
    IF corrupt EQ 0 THEN BEGIN ; Continue to the next loop if one or more of the input files are missing or corrupt.
      
      ; Write the NDVI band to file...
      filename_NDVI = STRMID(filename_NDVI, STRPOS(filename_NDVI, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_NDVI = output_directory + filename_NDVI + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, NDVI, OUT_NAME=filename_NDVI, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, NDVI ; Remove the variable from memory.
      UNDEFINE, filename_NDVI ; Remove the variable from memory.
      
      ; Write the EVI band to file...
      filename_EVI = STRMID(filename_EVI, STRPOS(filename_EVI, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_EVI = output_directory + filename_EVI + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, EVI, OUT_NAME=filename_EVI, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, EVI ; Remove the variable from memory.
      UNDEFINE, filename_EVI ; Remove the variable from memory.
      
      ; Write the quality band to file...
      filename_quality = STRMID(filename_quality, STRPOS(filename_quality, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_quality = output_directory + filename_quality + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, quality, OUT_NAME=filename_quality, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, quality ; Remove the variable from memory.
      UNDEFINE, filename_quality ; Remove the variable from memory.
      
      ; Write the red band to file...
      filename_red = STRMID(filename_red, STRPOS(filename_red, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_red = output_directory + filename_red + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, red, OUT_NAME=filename_red, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, red ; Remove the variable from memory.
      UNDEFINE, filename_red ; Remove the variable from memory.
      
      ; Write the NIR band to file... 
      filename_NIR = STRMID(filename_NIR, STRPOS(filename_NIR, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_NIR = output_directory + filename_NIR + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, NIR, OUT_NAME=filename_NIR, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, NIR ; Remove the variable from memory.
      UNDEFINE, filename_NIR ; Remove the variable from memory.                   
      
      ; Write the blue band to file...
      filename_blue = STRMID(filename_blue, STRPOS(filename_blue, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_blue = output_directory + filename_blue + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, blue, OUT_NAME=filename_blue, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, blue ; Remove the variable from memory.
      UNDEFINE, filename_blue ; Remove the variable from memory.
      
      ; Write the MIR band to file...
      filename_MIR = STRMID(filename_MIR, STRPOS(filename_MIR, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_MIR = output_directory + filename_MIR + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, MIR, OUT_NAME=filename_MIR, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, MIR ; Remove the variable from memory.
      UNDEFINE, filename_MIR ; Remove the variable from memory.
      
      ; Write the view band to file...
      filename_view = STRMID(filename_view, STRPOS(filename_view, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_view = output_directory + filename_view + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, view, OUT_NAME=filename_view, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, view ; Remove the variable from memory.
      UNDEFINE, filename_view ; Remove the variable from memory.
      
      ; Write the sun band to file...
      filename_sun = STRMID(filename_sun, STRPOS(filename_sun, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_sun = output_directory + filename_sun + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, sun, OUT_NAME=filename_sun, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, sun ; Remove the variable from memory.
      UNDEFINE, filename_sun ; Remove the variable from memory.
      
      ; Write the azimuth band to file...
      filename_azimuth = STRMID(filename_azimuth, STRPOS(filename_azimuth, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_azimuth = output_directory + filename_azimuth + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, azimuth, OUT_NAME=filename_azimuth, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, azimuth ; Remove the variable from memory.
      UNDEFINE, filename_azimuth ; Remove the variable from memory.
      
      ; Write the dayofyear band to file...
      filename_dayofyear = STRMID(filename_dayofyear, STRPOS(filename_dayofyear, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_dayofyear = output_directory + filename_dayofyear + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, dayofyear, OUT_NAME=filename_dayofyear, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, dayofyear ; Remove the variable from memory.
      UNDEFINE, filename_dayofyear ; Remove the variable from memory.
      
      ; Write the reliability band to file...
      filename_reliability = STRMID(filename_reliability, STRPOS(filename_reliability, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_reliability = output_directory + filename_reliability + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, reliability, OUT_NAME=filename_reliability, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, reliability ; Remove the variable from memory.
      UNDEFINE, filename_reliability ; Remove the variable from memory. 
      
    ENDIF ELSE BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', STRTRIM(i+1, 2), ' of ', STRTRIM(datecount, 2), ' (', $ 
      day_string, '/', month_string, '/', STRTRIM(year, 2), ') ', '- One or more of the input files are missing or invalid.'
    ENDELSE
    IF corrupt EQ 0 THEN BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', $ 
      STRTRIM(i+1, 2), ' of ', STRTRIM(datecount, 2), ' (', day_string, '/', month_string, '/', STRTRIM(year, 2), ')'
    ENDIF
  ENDFOR
  
  ; Print the elapsed processing time to the console... 
  
  minutes = (SYSTIME(1) - time) / 60 
  hours = minutes / 60 
  
  PRINT,''
  PRINT,'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)'
  PRINT,''
END
;--------------------------------------------------------------------------------------------- 

