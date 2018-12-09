

FUNCTION get_zipped_hdf, fname_input, fname_temp
  COMPILE_OPT idl2
	ON_ERROR
	
  input_file = fname_input
	Temp_file = fname_temp
	
  ; Unzip file to temp folder
  
	FileInfo = FILE_INFO(input_file)
  IF FileInfo.Exists EQ 1 THEN BEGIN
    t = SYSTIME(1)
		SPAWN, 'gzip -d -c ' + input_file + ' > ' + Temp_file	, Result, ErrResult, /HIDE ; Unzip File
		PRINT, SYSTIME(1) - t, ' Seconds for unzipping file'
		
		Err_violated = TOTAL(STRMATCH(ErrResult, '*violated*'))
		Err_invalid  = TOTAL(STRMATCH(ErrResult, '*invalid*'))
		
		IF Err_violated EQ 0 AND Err_invalid EQ 0 THEN BEGIN ; if not it means spawn returned some error
		  ; READ HDF
			sdFileID = HDF_SD_START(Temp_file, /READ)
			sdsID = HDF_SD_SELECT(sdFileID, 0)
			
			HDF_SD_FILEINFO, sdFileID, datasets, attributes
			HDF_SD_GETINFO, sdsID, NAME=thisSDSName
			
			t = SYSTIME(1)
			HDF_SD_GETDATA, sdsID, DATA
			PRINT, SYSTIME(1) - t, ' Seconds for reading HDF dataset'
			HDF_SD_END, sdFileID
		  FILE_DELETE, Temp_file
	  ENDIF Else BEGIN
		  PRINT, 'File corrupt, returning -1'
			DATA = -1
		ENDELSE	
	ENDIF ELSE BEGIN
	  PRINT, 'File not found, returning -1'
	  DATA = -1
	ENDELSE
	
	RETURN, DATA
END


