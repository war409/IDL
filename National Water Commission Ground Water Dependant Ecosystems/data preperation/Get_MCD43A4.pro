; ##############################################################################################
; NAME: Get_MCD43A4.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; DATE: 14/02/2010
; DLM: 16/02/2013
; 
; DESCRIPTION: This tool retrieves MCD43A4 data.
;
; ##############################################################################################


;---------------------------------------------------------------------------------------------
FUNCTION dates

  COMPILE_OPT idl2
  dates_2000 = INDGEN(46) * 8 +  JULDAY(1,1,2000)
  dates_2001 = INDGEN(46) * 8 +  JULDAY(1,1,2001)
  dates_2002 = INDGEN(46) * 8 +  JULDAY(1,1,2002)
  dates_2003 = INDGEN(46) * 8 +  JULDAY(1,1,2003)
  dates_2004 = INDGEN(46) * 8 +  JULDAY(1,1,2004)
  dates_2005 = INDGEN(46) * 8 +  JULDAY(1,1,2005)
  dates_2006 = INDGEN(46) * 8 +  JULDAY(1,1,2006)
  dates_2007 = INDGEN(46) * 8 +  JULDAY(1,1,2007)
  dates_2008 = INDGEN(46) * 8 +  JULDAY(1,1,2008)
  dates_2009 = INDGEN(46) * 8 +  JULDAY(1,1,2009)
  dates_2010 = INDGEN(46) * 8 +  JULDAY(1,1,2010)
  dates_2011 = INDGEN(46) * 8 +  JULDAY(1,1,2011)
  dates_2012 = INDGEN(46) * 8 +  JULDAY(1,1,2012)
  dates_2013 = INDGEN(46) * 8 +  JULDAY(1,1,2013)  
  dates_2014 = INDGEN(46) * 8 +  JULDAY(1,1,2014)
  dates_2015 = INDGEN(46) * 8 +  JULDAY(1,1,2015)  
  
  dates = [dates_2000, dates_2001, dates_2002, dates_2003, dates_2004, dates_2005, dates_2006, $
    dates_2007, dates_2008, dates_2009, dates_2010, dates_2011, dates_2012, dates_2013, dates_2014, $
    dates_2015]
  
  RETURN, dates ; Return a full list of all possible 8-day [julian day] dates for the years 2000 to 2011.
END
;---------------------------------------------------------------------------------------------


;---------------------------------------------------------------------------------------------
FUNCTION MCD43A4_fname, Day, Month, Year ; Get the full file name and path of each MOD09A1 file for the selected date.
  COMPILE_OPT idl2
  Path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MCD43A4.005\' ; Set MODIS parent directory.
  IF Month LE 9 THEN Prefix_Month = '0' ELSE Prefix_Month = ' ' ; Add leading zero to month.
  IF Day LE 9 THEN Prefix_Day = '0' ELSE Prefix_Day = ' ' ; Add leading zero to day.
  DOY = JULDAY(Month, Day, Year)  -  JULDAY(1, 1, Year) + 1 ; Get date as DOY.
  IF DOY GT 9 and DOY LE 99 THEN Prefix_DOY = '0' ; Add leading zero to DOY.
  IF DOY LE 9 THEN Prefix_DOY = '00' ; Add leading zero to DOY.
  IF DOY GT 99 THEN Prefix_DOY = ' '
  fname = STRARR(10) ; Create array to hold file names.
  
  FOR i=0, 3 DO BEGIN ; Band loop:
    CASE i OF
      0: Band_text= 'aust.005.b01.500m_0620_0670nm_nbar.hdf.gz'
      1: Band_text= 'aust.005.b02.500m_0841_0876nm_nbar.hdf.gz'
      2: Band_text= 'aust.005.b03.500m_0459_0479nm_nbar.hdf.gz'
      3: Band_text= 'aust.005.b06.500m_1628_1652nm_nbar.hdf.gz'
    ENDCASE

    fname_i = STRCOMPRESS(Path + STRING(Year) + '.' + $
      Prefix_Month + STRING(Month) +  '.' + $
      Prefix_Day + STRING(Day) +  '\' + $
      'MCD43A4.' + STRING(Year) + '.' + $
      Prefix_DOY + STRING(DOY) + '.' + $
      Band_text , /REMOVE_ALL) ; Set the full file name and path for the selected date and the i-th band.

    fname[i] = fname_i ; Add the new file name to the file name array.
  ENDFOR
  RETURN, fname ; Return the file name array to the main procedure.
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
PRO Get_MCD43A4
  COMPILE_OPT idl2
  time = SYSTIME(1) ; Set procedure start time.
  ;-------------------------------------------------------------------------------------------
  output_directory = 'G:\data\modis\MCD43A4.005\' ; Set the output directory.
  ;-------------------------------------------------------------------------------------------
  ; Open an existing image and extract the header information:
  template = '\\wron\Working\work\Juan_Pablo\MOD09A1.005\header_issue\MOD09A1.2009.001.aust.005.b01.500m_0620_0670nm_refl.img'
  ENVI_OPEN_FILE , template, R_FID=FID_template, /NO_REALIZE 
  map = ENVI_GET_MAP_INFO(FID=FID_template) 
  ;-------------------------------------------------------------------------------------------
  ; Get all valid 8-day dates for the selected time period:
  All_Dates = dates()
  Date_Start = JULDAY(1, 1, 2000)
  Date_End = JULDAY(3, 1, 2011)
  Get_Dates = Where((All_Dates GE Date_Start) AND (All_Dates LE Date_End), Date_Count)
  ;-------------------------------------------------------------------------------------------
  ; Date loop:
  ;-------------------------------------------------------------------------------------------
  FOR i=0, Date_Count-1 DO BEGIN
    iTime = SYSTIME(1) ; Get loop start time.
    ;-----------------------------------------------------------------------------------------
    ; Get Data:
    ;-----------------------------------------------------------------------------------------
    iDates = Get_Dates[i] ; Get the i-th date.
    CALDAT, All_Dates[iDates], Month, Day, Year ; Get the i-th month, day, and year.
    Input_file = MCD43A4_fname(Day, Month, Year) ; Get the i-th date file list.
    IF Month LE 9 THEN Month_String = '0' + STRTRIM(Month, 2) ELSE Month_String = STRTRIM(Month, 2)
    IF Day LE 9 THEN Day_String = '0' + STRTRIM(Day, 2) ELSE Day_String = STRTRIM(Day, 2)
    Temp_file  = 'G:\data\modis\MCD43A4.005\Temp.hdf' ; Set the temporary file name and path. 
    
    ;-------------- ; Get RED data:
    fname_Red = Input_file[0]
    RED = gzhdf(fname_Red, Temp_file) ; Get data.
    SIZE_DATA = SIZE(RED)
    ;-------------- ; Get NIR data:
    fname_NIR = Input_file[1]
    NIR = gzhdf(fname_NIR, Temp_file) ; Get data.
    ;-------------- ; Get BLUE data:
    fname_Blue = Input_file[2]
    BLUE = gzhdf(fname_Blue, Temp_file) ; Get data.
    SIZE_DATA = SIZE(BLUE)
    ;-------------- ; Get SWIR2 data:
    fname_SWIR2 = Input_file[3]
    SWIR2 = gzhdf(fname_SWIR2, Temp_file) ; Get data.

    ;-------------- ; Check if any of the selected input files are missing or corrupt:
    IF N_ELEMENTS(RED) EQ 1 OR $
      N_ELEMENTS(NIR) EQ 1 OR $
      N_ELEMENTS(BLUE) EQ 1 OR $
      N_ELEMENTS(SWIR2) EQ 1 $
    THEN Corrupted=1 ELSE Corrupted=0
    ;-----------------------------------------------------------------------------------------
    ; Write Data:
    ;-----------------------------------------------------------------------------------------
    IF Corrupted EQ 0 THEN BEGIN ; Continue to the next loop if one or more of the input files are missing or corrupt:

      ;-------------- ; Write RED data:
      fname_Red = STRMID(fname_Red, STRPOS(fname_Red, '\', /REVERSE_SEARCH)+1, 29) ; Get file name short.
      fname_Red = output_directory + fname_Red + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, RED, OUT_NAME=fname_Red, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, RED ; Remove variable from memory.
      UNDEFINE, fname_Red ; Remove variable from memory.
      ;-------------- ; Write NIR data:
      fname_NIR = STRMID(fname_NIR, STRPOS(fname_NIR, '\', /REVERSE_SEARCH)+1, 29) ; Get file name short.
      fname_NIR = output_directory + fname_NIR + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, NIR, OUT_NAME=fname_NIR, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, NIR ; Remove variable from memory.
      UNDEFINE, fname_NIR ; Remove variable from memory.    
      ;-------------- ; Write BLUE data:
      fname_Blue = STRMID(fname_Blue, STRPOS(fname_Blue, '\', /REVERSE_SEARCH)+1, 29) ; Get file name short.
      fname_Blue = output_directory + fname_Blue + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, BLUE, OUT_NAME=fname_Blue, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, BLUE ; Remove variable from memory.
      UNDEFINE, fname_Blue ; Remove variable from memory.
      ;-------------- ; Write SWIR2 data:
      fname_SWIR2 = STRMID(fname_SWIR2, STRPOS(fname_SWIR2, '\', /REVERSE_SEARCH)+1, 29) ; Get file name short.
      fname_SWIR2 = output_directory + fname_SWIR2 + '.img' ; Set the output file name.
      ENVI_WRITE_ENVI_FILE, SWIR2, OUT_NAME=fname_SWIR2, MAP_INFO=map, /NO_OPEN ; Write the file to disk.
      UNDEFINE, SWIR2 ; Remove variable from memory.
      UNDEFINE, fname_SWIR2 ; Remove variable from memory.
        
      ;-----------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-iTime), 2), ' Seconds for date: ', $
      STRTRIM(i+1, 2), ' of ', STRTRIM(Date_Count, 2), ' (', $
      Day_String, '/', Month_String, '/', STRTRIM(Year, 2), ') ', '- One or more of the input files are missing or invalid.'
    ENDELSE
    IF Corrupted EQ 0 THEN BEGIN
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-iTime), 2), ' Seconds for date: ', $
      STRTRIM(i+1, 2), ' of ', STRTRIM(Date_Count, 2), ' (', $
      Day_String, '/', Month_String, '/', STRTRIM(Year, 2), ')'
    ENDIF
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  ; PRINT SCRIPT INFORMATION:
  ;-----------------------------------
  ; GET END TIME
  MINUTES = (SYSTIME(1)-time)/60
  HOURS = MINUTES/60
  ;--------------
  PRINT,''
  PRINT,'Total processing time: ', STRTRIM(MINUTES, 2), ' minutes (', STRTRIM(HOURS, 2),   ' hours)'
  PRINT,''
  PRINT,'Finished processing: Get_MOD09A1.pro'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

