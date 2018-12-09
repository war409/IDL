; ##############################################################################################
; NAME: MOD15A2_get.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren
; DATE: 18/04/2010
; DLM: 18/04/2010
; 
; 
; DESCRIPTION: This tool unpacks compressed MODIS data on WRON.
;
;
; ##############################################################################################



; **********************************************************************************************
PRO MOD15A2_get
  COMPILE_OPT idl2
  time = SYSTIME(1) ; Get the procedure start time.
  
  ;---------------------------------------------------------------------------------------------
  ; Set the input arguments: 
  ;---------------------------------------------------------------------------------------------
  
  outfolder = 'C:\Documents and Settings\war409\modis\' ; Set the output directory.
  template = '\\wron\Working\work\war409\work\imagery\modis\template\MOD15A2.2000.049.aust.005.b02.1000m_lai.img'
  tempfile  = 'C:\WorkSpace\temp.hdf' ; Set a temporary filename.
  
  startdate = JULDAY(1, 1, 2000)
  enddate = JULDAY(4, 31, 2012)
  
  ;---------------------------------------------------------------------------------------------
  ; Get Data: 
  ;---------------------------------------------------------------------------------------------
  
  PRINT, ''
  
  ; Open an existing image and extract the header information.
  ENVI_OPEN_FILE , template, R_FID = FID, /NO_REALIZE 
  mapinfo = ENVI_GET_MAP_INFO(FID = FID) 
  
  ; Get all valid 8-day day-of-year dates for the selected time period.
  dateindex = WHERE((modisdates()  GE startdate) AND (modisdates()  LE enddate), datecount) 
  dates = modisdates() 
  
  FOR i=0, datecount-1 DO BEGIN
    itime = SYSTIME(1) ; Get the loop start time.
    
    idate = dateindex[i] ; Get the current date.
    CALDAT, dates[idate], month, day, year ; Get the current month, day, and year.
    IF month LE 9 THEN monthstring = '0' + STRTRIM(month, 2) ELSE monthstring = STRTRIM(month, 2)
    IF day LE 9 THEN daystring = '0' + STRTRIM(day, 2) ELSE daystring = STRTRIM(day, 2)
    
    filenames = mod15a2(day, month, year) ; Get the current dates filename list.
    
    ; Get the lai band.
    filename_lai = filenames[0]
    lai = gzhdf(filename_lai, tempfile) 
    size = SIZE(lai)
    
    ; Get the quality band.
    filename_quality = filenames[1]
    quality = gzhdf(filename_quality, tempfile) 
    
    ; Get the extra quality band.
    filename_extra = filenames[2]
    extra = gzhdf(filename_extra, tempfile) 
    
    ; Check if any of the selected input files are missing or invalid.
    IF (N_ELEMENTS(lai) EQ 1) OR (N_ELEMENTS(quality) EQ 1) OR (N_ELEMENTS(extra) EQ 1) THEN Corrupted = 1 ELSE Corrupted = 0
    
    ;-------------------------------------------------------------------------------------------
    ; Write Data: 
    ;-------------------------------------------------------------------------------------------
    
    IF Corrupted EQ 0 THEN BEGIN 
    
      ; Write the lai data to disk.
      filename_lai = STRMID(filename_lai, STRPOS(filename_lai, '\', /REVERSE_SEARCH)+1, 39) ; Get file name short.
      filename_lai = outfolder + filename_lai + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, lai, OUT_NAME=filename_lai, MAP_INFO=mapinfo, /NO_OPEN ; Write the file to disk.
      UNDEFINE, lai ; Remove the variable from memory.
      UNDEFINE, filename_lai ; Remove the variable from memory.
      
      ; Write the quality data to disk.
      filename_quality = STRMID(filename_quality, STRPOS(filename_quality, '\', /REVERSE_SEARCH)+1, 43) ; Get file name short.
      filename_quality = outfolder + filename_quality + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, quality, OUT_NAME=filename_quality, MAP_INFO=mapinfo, /NO_OPEN ; Write the file to disk.
      UNDEFINE, quality ; Remove the variable from memory.
      UNDEFINE, filename_quality ; Remove the variable from memory.
      
      ; Write the extra quality data to disk.
      filename_extra = STRMID(filename_extra, STRPOS(filename_extra, '\', /REVERSE_SEARCH)+1, 49) ; Get file name short.
      filename_extra = outfolder + filename_extra + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, extra, OUT_NAME=filename_extra, MAP_INFO=mapinfo, /NO_OPEN ; Write the file to disk.
      UNDEFINE, extra ; Remove the variable from memory.
      UNDEFINE, filename_extra ; Remove the variable from memory.
      
      
    ENDIF ELSE BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', $ 
             STRTRIM(i+1, 2), ' of ', STRTRIM(datecount, 2), ' (', daystring, '/', $ 
             monthstring, '/', STRTRIM(Year, 2), '). ', 'One or more input is missing or invalid.'
    ENDELSE
    
    IF Corrupted EQ 0 THEN BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', $
              STRTRIM(i+1, 2), ' of ', STRTRIM(datecount, 2), ' (', daystring, '/', $
              monthstring, '/', STRTRIM(Year, 2), '). '
    ENDIF
    
  ENDFOR
  
  minutes = (SYSTIME(1)-time) / 60 
  hours = minutes / 60 
  PRINT, ''
  PRINT, 'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)'
  PRINT, ''
END
; **********************************************************************************************



;-----------------------------------------------------------------------------------------------
FUNCTION modisdates
  COMPILE_OPT idl2
  
  dates2000 = INDGEN(46) * 8 +  JULDAY(1, 1, 2000)
  dates2001 = INDGEN(46) * 8 +  JULDAY(1, 1, 2001)
  dates2002 = INDGEN(46) * 8 +  JULDAY(1, 1, 2002)
  dates2003 = INDGEN(46) * 8 +  JULDAY(1, 1, 2003)
  dates2004 = INDGEN(46) * 8 +  JULDAY(1, 1, 2004)
  dates2005 = INDGEN(46) * 8 +  JULDAY(1, 1, 2005)
  dates2006 = INDGEN(46) * 8 +  JULDAY(1, 1, 2006)
  dates2007 = INDGEN(46) * 8 +  JULDAY(1, 1, 2007)
  dates2008 = INDGEN(46) * 8 +  JULDAY(1, 1, 2008)
  dates2009 = INDGEN(46) * 8 +  JULDAY(1, 1, 2009)
  dates2010 = INDGEN(46) * 8 +  JULDAY(1, 1, 2010)
  dates2011 = INDGEN(46) * 8 +  JULDAY(1, 1, 2011)
  dates2012 = INDGEN(46) * 8 +  JULDAY(1, 1, 2012)
  dates2013 = INDGEN(46) * 8 +  JULDAY(1, 1, 2013)
  dates2014 = INDGEN(46) * 8 +  JULDAY(1, 1, 2014)
  dates2015 = INDGEN(46) * 8 +  JULDAY(1, 1, 2015)
  
  dates = [dates2000, $
           dates2001, $
           dates2002, $
           dates2003, $
           dates2004, $
           dates2005, $
           dates2006, $
           dates2007, $
           dates2008, $
           dates2009, $
           dates2010, $
           dates2011, $
           dates2012, $
           dates2013, $
           dates2014, $
           dates2015]
  
  RETURN, dates ; Return a list of all possible 8-day [julian day] dates for the years 2000 to 2015.
END
;-----------------------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------------------
FUNCTION mod15a2, day, month, year
  COMPILE_OPT idl2
  
  dayofyear = JULDAY(month, day, year)  -  JULDAY(1, 1, year) + 1 ; Get the date in day of year format.
  path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MOD15A2.005\' ; Set the MODIS parent directory.
  filenames = STRARR(10) ; Create an array to hold the filenames.
  
  IF dayofyear GT 9 and dayofyear LE 99 THEN dayofyearprefix = '0' 
  IF dayofyear LE 9 THEN dayofyearprefix = '00' 
  IF dayofyear GT 99 THEN dayofyearprefix = ' ' 
  
  IF month LE 9 THEN monthprefix = '0' ELSE monthprefix = ' ' 
  IF day LE 9 THEN dayprefix = '0' ELSE dayprefix = ' ' 
  
  FOR i=0, 2 DO BEGIN 
    CASE i OF
      0: band = 'aust.005.b02.1000m_lai.hdf.gz'
      1: band = 'aust.005.b03.1000m_quality.hdf.gz'
      2: band = 'aust.005.b04.1000m_extra_quality.hdf.gz'
    ENDCASE
    
    ; Set the full file name and path for the selected date and band.
    filename = STRCOMPRESS(path + $
                           STRING(year) + '.' + $
                           monthprefix + STRING(month) +  '.' + $
                           dayprefix + STRING(day) +  '\' + $
                           'MOD15A2.' + STRING(year) + '.' + $
                           dayofyearprefix + STRING(dayofyear) + '.' + $
                           band , /REMOVE_ALL) 

    filenames[i] = filename ; Add the filename to the filename array.
  ENDFOR
  
  RETURN, filenames ; Return the file name array to the main procedure.
END
;-----------------------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------------------
FUNCTION gzhdf, filename, temp
  COMPILE_OPT idl2
  
  fileinfo = File_Info(filename) ; Get file information.
  
  IF fileinfo.Exists EQ 1 THEN BEGIN 
    SPAWN, 'gzip -d -c ' + filename + ' > ' + temp, result, ErrResult, /HIDE ; Unzip File.
    tempinfo = File_Info(temp) ; Get file information.
    
    IF tempinfo.Exists EQ 1 THEN BEGIN 
      fileID = HDF_SD_Start(temp, /Read) ; Read the uncompressed hdf file.
      sdsID = HDF_SD_Select(fileID, 0) ; Set the hdf ID.
      HDF_SD_GetData, sdsID, data ; Get the hdf data.
      HDF_SD_END, fileID ; Close the hdf file.
      FILE_DELETE, temp ; Delete the temp file.
    ENDIF ELSE data = -1 
     
  ENDIF ELSE data = -1 
  
  RETURN, data ; Return the hdf data to the main procedure.
END
;-----------------------------------------------------------------------------------------------


