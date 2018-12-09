; ##############################################################################################
; NAME: MOD15A2_mask.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren
; DATE: 19/04/2010
; DLM: 19/04/2010
;
;
; DESCRIPTION:  This tool
; 
; 
; INPUT:        
;
;
; OUTPUT:       One single-band flat binary raster per input 
;
;               
; PARAMETERS:   Define the parameters via in-program pop-up dialog widgets...
; 
; 
; NOTES:        For more information contact Garth.Warren@csiro.au
; 
;               
; ##############################################################################################



; **********************************************************************************************
PRO MOD15A2_mask
  time = SYSTIME(1) ; Get the procedure start time.

  ;---------------------------------------------------------------------------------------------
  ; Set the input arguments: 
  ;---------------------------------------------------------------------------------------------  
  
  infolder = 'C:\Documents and Settings\war409\MOD15A2.005\' ; Set the input directory.
  outfolder = 'C:\Documents and Settings\war409\MOD15A2.005.Mask2\' ; Set the output directory.
  
  startdate = JULDAY(1, 1, 2000)
  enddate = JULDAY(4, 31, 2012)
  
  ;---------------------------------------------------------------------------------------------
  ; Mask Data: 
  ;---------------------------------------------------------------------------------------------
  
  ; Get all valid 8-day day-of-year dates for the selected time period.
  dateindex = WHERE((modisdates()  GE startdate) AND (modisdates()  LE enddate), datecount) 
  dates = modisdates() 
  
  PRINT, ''
  
  FOR i=0, datecount-1 DO BEGIN
    itime = SYSTIME(1) ; Get the loop start time.
    
    idate = dateindex[i] ; Get the current date.
    CALDAT, dates[idate], month, day, year ; Get the current month, day, and year.
    IF month LE 9 THEN monthstring = '0' + STRTRIM(month, 2) ELSE monthstring = STRTRIM(month, 2)
    IF day LE 9 THEN daystring = '0' + STRTRIM(day, 2) ELSE daystring = STRTRIM(day, 2)
    
    filenames = mod15a2(day, month, year, infolder, 'img') ; Get the current dates filename list.
    
    ; Get the lai band.
    filename_lai = filenames[0]
    IF (FILE_TEST(filename_lai) EQ 1) THEN lai = READ_BINARY(filename_lai, DATA_TYPE=1) ELSE lai = -1 ; Get data.
    
    ; Get the quality band.
    filename_quality = filenames[1]
    IF (FILE_TEST(filename_quality) EQ 1) THEN quality = READ_BINARY(filename_quality, DATA_TYPE=1) ELSE quality = -1 ; Get data.
    
    ; Get the extra quality band.
    filename_extra = filenames[2]
    IF (FILE_TEST(filename_extra) EQ 1) THEN extra = READ_BINARY(filename_extra, DATA_TYPE=1) ELSE extra = -1 ; Get data.
    
    ; Check if any of the files are missing or invalid.corrupted
    IF (N_ELEMENTS(lai) EQ 1) OR (N_ELEMENTS(quality) EQ 1) OR (N_ELEMENTS(extra) EQ 1) THEN corrupted = 1 ELSE Corrupted = 0
    
    ; Skip this date if one or more input is missing or invalid.
    IF corrupted EQ 0 THEN BEGIN
      
      outfiles = mod15a2(day, month, year, outfolder, 'img')
      outfilename = outfiles[0]   
      OPENW, UNIT, outfilename, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT ; Close the output file.
      
      ;-------------------------------------------------------------------------------------------
      ; Apply mask: 
      ;------------------------------------------------------------------------------------------- 
      
      maskarray = MAKE_ARRAY(N_ELEMENTS(lai), VALUE=1, /INTEGER) 
      output = MAKE_ARRAY(N_ELEMENTS(lai), VALUE=-999.00, /FLOAT) 
            
      ; Mask lai fill cells.
      fill = WHERE(lai GE 249, fillcount) 
      IF (N_ELEMENTS(fill) GT 1) THEN maskarray[fill] = 0 
      
      ; quality
      ; 00001000 ; cloud (00001000 AND 8)  - 4
      ; 00010000 ; mixed (00010000 AND 16) - 5
            
      ; Find and replace cloud pixels.
      cloud = BITWISE_OPERATOR(quality, 8, 8, 1) 
      IF (N_ELEMENTS(cloud) GT 1) THEN maskarray[cloud] = 0 
      
      ; extra
      ; 00000011 ; ocean     (00000011 AND 3) 
      ; 00100000 ; internal  (00100000 AND 32) internal cloud - 6
      
      ; Find and replace ocean pixels.
      ocean = BITWISE_OPERATOR(extra, 3, 3, 1) 
      IF (N_ELEMENTS(ocean) GT 1) THEN maskarray[ocean] = 0 
      
      ; Find and replace internal cloud pixels.
      internal = BITWISE_OPERATOR(extra, 32, 32, 1) 
      IF (N_ELEMENTS(internal) GT 1) THEN maskarray[internal] = 0 
      
      ; Invert the mask (create an index of 'good' cells).
      mask = WHERE(maskarray EQ 1, maskcount) 
      
      ; Apply the LAI scale factor.
      lai = FLOAT(lai[mask] * 0.1) 
      
      ; Use the mask to build the output array.
      output[mask] = FLOAT(lai)
      
      OPENU, UNIT, outfilename, /GET_LUN, /APPEND ; Open the output file for editing.
      WRITEU, UNIT, output ; Write the output data.
      FREE_LUN, UNIT ; Close the output file.
      
      ;-----------------------------------------------------------------------------------------
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', $
              STRTRIM(i+1, 2), ' of ', STRTRIM(datecount, 2), ' (', daystring, '/', $
              monthstring, '/', STRTRIM(Year, 2), '). '
      ;-----------------------------------------------------------------------------------------
    ENDIF ELSE BEGIN
      ;-----------------------------------------------------------------------------------------
      PRINT, '  ', STRTRIM(ROUND(SYSTIME(1)-itime), 2), ' Seconds for date: ', $ 
             STRTRIM(i+1, 2), ' of ', STRTRIM(datecount, 2), ' (', daystring, '/', $ 
             monthstring, '/', STRTRIM(Year, 2), '). ', 'One or more input is missing or invalid.'
      ;-----------------------------------------------------------------------------------------
    ENDELSE
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  minutes = (SYSTIME(1)-time) / 60 
  hours = minutes / 60 
  PRINT, ''
  PRINT, 'Total processing time: ', STRTRIM(minutes, 2), ' minutes (', STRTRIM(hours, 2),   ' hours)'
  PRINT, ''
  ;---------------------------------------------------------------------------------------------
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
FUNCTION mod15a2, day, month, year, path, extension
  COMPILE_OPT idl2
  
  dayofyear = JULDAY(month, day, year)  -  JULDAY(1, 1, year) + 1 ; Get the date in day of year format.
  filenames = STRARR(10) ; Create an array to hold the filenames.
  
  IF dayofyear GT 9 and dayofyear LE 99 THEN dayofyearprefix = '0' 
  IF dayofyear LE 9 THEN dayofyearprefix = '00' 
  IF dayofyear GT 99 THEN dayofyearprefix = ' ' 
  
  IF month LE 9 THEN monthprefix = '0' ELSE monthprefix = ' ' 
  IF day LE 9 THEN dayprefix = '0' ELSE dayprefix = ' ' 
  
  FOR i=0, 2 DO BEGIN 
    CASE i OF
      0: band = 'aust.005.b02.1000m_lai'
      1: band = 'aust.005.b03.1000m_quality'
      2: band = 'aust.005.b04.1000m_extra_quality'
    ENDCASE
    
    ; Set the full file name and path for the selected date and band.
    filename = STRCOMPRESS('MOD15A2.' + STRING(year) + '.' + $
                           dayofyearprefix + STRING(dayofyear) + '.' + $
                           band + '.' + extension, /REMOVE_ALL) 

    filenames[i] = path + filename ; Add the filename to the filename array.
  ENDFOR
  
  RETURN, filenames ; Return the file name array to the main procedure.
END
;-----------------------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------------------
FUNCTION BITWISE_OPERATOR, Data, Binary1, Match1, WhereValue
  
  State = ((Data AND Binary1) EQ Match1) ; Apply bit statement.
  Index = WHERE(State EQ WhereValue, Count) ; Get the count of cells that conform to the statement.
  
  RETURN, [Index] ; Return index.
END
;-----------------------------------------------------------------------------------------------



;-----------------------------------------------------------------------------------------------
FUNCTION BITWISE_OPERATOR_AND, Data, Binary1, Match1, Binary2, Match2, WhereValue
  
  State = ((Data AND Binary1) EQ Match1) AND ((Data AND Binary2) EQ Match2) ; Apply bit statement.
  Index = WHERE(State EQ WhereValue, Count) ; Get the count of cells that conform to the statement.
  
  RETURN, [Index] ; Return index.
END
;-----------------------------------------------------------------------------------------------



