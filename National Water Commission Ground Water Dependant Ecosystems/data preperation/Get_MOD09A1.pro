; ##############################################################################################
; NAME: Get_MOD09A1.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; DATE: 14/02/2010
; DLM: 22/02/2013
; 
; DESCRIPTION: This tool retrieves 500 meter resolution MOD09A1 band 3 (blue), band 6 (SWIR2), 
;              and band 12 (state).
;
; ##############################################################################################


;---------------------------------------------------------------------------------------------
FUNCTION dates
  
  COMPILE_OPT idl2
  dates_2000 = INDGEN(46) * 8 +  JULday(1,1,2000)
  dates_2001 = INDGEN(46) * 8 +  JULday(1,1,2001)
  dates_2002 = INDGEN(46) * 8 +  JULday(1,1,2002)
  dates_2003 = INDGEN(46) * 8 +  JULday(1,1,2003)
  dates_2004 = INDGEN(46) * 8 +  JULday(1,1,2004)
  dates_2005 = INDGEN(46) * 8 +  JULday(1,1,2005)
  dates_2006 = INDGEN(46) * 8 +  JULday(1,1,2006)
  dates_2007 = INDGEN(46) * 8 +  JULday(1,1,2007)
  dates_2008 = INDGEN(46) * 8 +  JULday(1,1,2008)
  dates_2009 = INDGEN(46) * 8 +  JULday(1,1,2009)
  dates_2010 = INDGEN(46) * 8 +  JULday(1,1,2010)
  dates_2011 = INDGEN(46) * 8 +  JULday(1,1,2011)
  dates_2012 = INDGEN(46) * 8 +  JULday(1,1,2012)
  dates_2013 = INDGEN(46) * 8 +  JULday(1,1,2013)  
  dates_2014 = INDGEN(46) * 8 +  JULday(1,1,2014)
  dates_2015 = INDGEN(46) * 8 +  JULday(1,1,2015)  
  
  dates = [dates_2000, dates_2001, dates_2002, dates_2003, dates_2004, dates_2005, dates_2006, $
    dates_2007, dates_2008, dates_2009, dates_2010, dates_2011, dates_2012, dates_2013, dates_2014, $
    dates_2015]
  
  RETURN, dates ; Return a full list of all possible 8-day [julian day] dates for the years 2000 to 2011.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION MOD09A1, day, day, year ; Get the full file name and path of each MOD09A1 file for the selected date.
  COMPILE_OPT idl2
  
  path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MOD09A1.005\' ; Set MODIS parent directory.
  IF month LE 9 THEN month_prefix = '0' ELSE month_prefix = ' ' ; Add leading zero to month.
  IF day LE 9 THEN day_prefix = '0' ELSE day_prefix = ' ' ; Add leading zero to day.
  DOY = JULDAY(month, day, year)  -  JULDAY(1, 1, Year) + 1 ; Get date as DOY.
  IF DOY GT 9 and DOY LE 99 THEN DOY_prefix = '0' ; Add leading zero to DOY.
  IF DOY LE 9 THEN DOY_prefix = '00' ; Add leading zero to DOY.
  IF DOY GT 99 THEN DOY_prefix = ' '
  
  filenames = STRARR(10) ; Create array to hold file names.
  
  FOR i=0, 9 DO BEGIN ; Band loop:
    CASE i OF
      0: band= 'aust.005.b01.500m_0620_0670nm_refl.hdf.gz'
      1: band= 'aust.005.b02.500m_0841_0876nm_refl.hdf.gz'
      2: band= 'aust.005.b03.500m_0459_0479nm_refl.hdf.gz'
      3: band= 'aust.005.b04.500m_0545_0565nm_refl.hdf.gz'
      4: band= 'aust.005.b05.500m_1230_1250nm_refl.hdf.gz'
      5: band= 'aust.005.b06.500m_1628_1652nm_refl.hdf.gz'
      6: band= 'aust.005.b07.500m_2105_2155nm_refl.hdf.gz'
      7: band= 'aust.005.b08.500m_quality.hdf.gz'
      8: band= 'aust.005.b12.500m_state_flags.hdf.gz'
      9: band= 'aust.005.b13.500m_day_of_year.hdf.gz'
    ENDCASE

    filename = STRCOMPRESS(path + STRING(year) + '.' + day_prefix + STRING(day) +  '.' + month_prefix + STRING(month) +  '\' + $
      'MOD09A1.' + STRING(year) + '.' + Prefix_DOY + STRING(DOY) + '.' + band , /REMOVE_ALL) 
    filenames[i] = filename ; Add the new file name to the file name array.
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
PRO Get_MOD09A1
  COMPILE_OPT idl2
  time = SYSTIME(1) ; Set procedure start time.
  
  output_directory = 'H:\war409\MOD09A1.005.2\' ; Set the output directory.
  
  ; Open an existing image and extract the header information...
  template = '\\wron\Working\work\Juan_Pablo\MOD09A1.005\header_issue\MOD09A1.2009.001.aust.005.b01.500m_0620_0670nm_refl.img'
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
  
  FOR i=0, count-1 DO BEGIN
    itime = SYSTIME(1) ; Get loop start time.
    
    ; Get Data...
    
    idates = selectdates[i] ; Get the i-th date.
    CALDAT, dates[idates], day, day, year ; Get the i-th day, day, and year.
    filenames = MOD09A1(day, day, year) ; Get the i-th date file list.
    IF day LE 9 THEN day_String = '0' + STRTRIM(day, 2) ELSE day_String = STRTRIM(day, 2) 
    IF month LE 9 THEN month_string = '0' + STRTRIM(Month, 2) ELSE month_string = STRTRIM(month, 2) 
    temp  = 'C:\temp.hdf' ; Set the temporary file name and path.
    
    ; Get the NIR band...
    filename_NIR = filenames[1]
    NIR = gzhdf(filename_NIR, temp) ; Get data.
    size = SIZE(NIR)
    
    ; Get the blue band...
    filename_blue = filenames[2]
    blue = gzhdf(filename_blue, temp) ; Get data.
    
    ; Get the green band...
    filename_green = filenames[3]
    green = gzhdf(filename_green, temp) ; Get data.
    
    ; Get the SWIR 1 band...
    filename_SWIR1 = filenames[4]
    SWIR1 = gzhdf(filename_SWIR1, temp) ; Get data.
    
    ; Get the SWIR 2 band...
    filename_SWIR2 = filenames[5]
    SWIR2 = gzhdf(filename_SWIR2, temp) ; Get data.
    
    ; Get the state band...
    filename_state = filenames[8]
    state = gzhdf(filename_state, temp) ; Get data.
    
    ; Check if any of the selected input files are missing or corrupt...
    IF ((N_ELEMENTS(NIR) EQ 1) OR (N_ELEMENTS(blue) EQ 1) OR $ 
        (N_ELEMENTS(green) EQ 1) OR (N_ELEMENTS(SWIR1) EQ 1) OR $
        (N_ELEMENTS(SWIR2) EQ 1) OR (N_ELEMENTS(state) EQ 1)) THEN corrupt = 1 ELSE corrupt = 0 
      
    ;-----------------------------------------------------------------------------------------
    ; Write data to file.
    ;-----------------------------------------------------------------------------------------
    
    IF corrupt EQ 0 THEN BEGIN ; Continue to the next loop if one or more of the input files are missing or corrupt:
      
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
      
      ; Write the green band to file...
      filename_green = STRMID(filename_green, STRPOS(filename_green, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_green = output_directory + filename_green + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, green, OUT_NAME=filename_green, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, green ; Remove the variable from memory.
      UNDEFINE, filename_green ; Remove the variable from memory.
      
      ; Write the SWIR 1 band to file...
      filename_SWIR1 = STRMID(filename_SWIR1, STRPOS(filename_SWIR1, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_SWIR1 = output_directory + filename_SWIR1 + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, SWIR1, OUT_NAME=filename_SWIR1, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, SWIR1 ; Remove the variable from memory.
      UNDEFINE, filename_SWIR1 ; Remove the variable from memory.
      
      ; Write the SWIR 2 band to file...
      filename_SWIR2 = STRMID(filename_SWIR2, STRPOS(filename_SWIR2, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_SWIR2 = output_directory + filename_SWIR2 + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, SWIR2, OUT_NAME=filename_SWIR2, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, SWIR2 ; Remove the variable from memory.
      UNDEFINE, filename_SWIR2 ; Remove the variable from memory.
      
      ; Write the state band to file...
      filename_state = STRMID(filename_state, STRPOS(filename_state, '\', /REVERSE_SEARCH)+1, 29) ; Trim the file name.
      filename_state = output_directory + filename_state + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, state, OUT_NAME=filename_state, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, state ; Remove the variable from memory.
      UNDEFINE, filename_state ; Remove the variable from memory.
      
    ENDIF ELSE BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', STRTRIM(i+1, 2), ' of ', STRTRIM(count, 2), ' (', $
        day_String, '/', day_String, '/', STRTRIM(year, 2), ') ', '- One or more of the input files are missing or invalid.'
    ENDELSE 
    IF corrupt EQ 0 THEN BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', $
        STRTRIM(i+1, 2), ' of ', STRTRIM(count, 2), ' (', day_String, '/', day_String, '/', STRTRIM(year, 2), ')'
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

