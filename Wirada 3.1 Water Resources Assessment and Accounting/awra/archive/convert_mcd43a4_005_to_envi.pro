function MCD43A4_fname, day, month, year
	compile_opt idl2

	path = '\\wron\RemoteSensing\MODIS\L2\LPDAAC\data\aust\MCD43A4.005\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '


	fname = strarr(7)


	for i=0, 6 do begin

		Case i of
			0: Band_text= 'aust.005.b01.500m_0620_0670nm_nbar.hdf.gz'
			1: Band_text= 'aust.005.b02.500m_0841_0876nm_nbar.hdf.gz'
			2: Band_text= 'aust.005.b03.500m_0459_0479nm_nbar.hdf.gz'
			3: Band_text= 'aust.005.b04.500m_0545_0565nm_nbar.hdf.gz'
			4: Band_text= 'aust.005.b05.500m_1230_1250nm_nbar.hdf.gz'
			5: Band_text= 'aust.005.b06.500m_1628_1652nm_nbar.hdf.gz'
			6: Band_text= 'aust.005.b07.500m_2105_2155nm_nbar.hdf.gz'

		EndCase

		fname_i = strcompress( $
			path + $
			String (year) + '.' +	$
			app_month + String(month) +  '.' + $
			app_day + String(day) +  '\' + $
			'MCD43A4.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			Band_text , $
			/REMOVE_ALL )

		fname[i] = fname_i

	EndFor

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

	return, fname
end


function MCD43A4_fname_output, day, month, year
	compile_opt idl2

	path = '\\wron\Working\work\Juan_Pablo\MCD43A4.005\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '


	fname = strarr(7)


	for i=0, 6 do begin

		Case i of
			0: Band_text= 'aust.005.b01.500m_0620_0670nm_nbar.img'
			1: Band_text= 'aust.005.b02.500m_0841_0876nm_nbar.img'
			2: Band_text= 'aust.005.b03.500m_0459_0479nm_nbar.img'
			3: Band_text= 'aust.005.b04.500m_0545_0565nm_nbar.img'
			4: Band_text= 'aust.005.b05.500m_1230_1250nm_nbar.img'
			5: Band_text= 'aust.005.b06.500m_1628_1652nm_nbar.img'
			6: Band_text= 'aust.005.b07.500m_2105_2155nm_nbar.img'

		EndCase

		fname_i = strcompress( $
			path + $
		;	String (year) + '.' +	$
		;	app_month + String(month) +  '.' + $
		;	app_day + String(day) +  '\' + $
			'MCD43A4.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			Band_text , $
			/REMOVE_ALL )

		fname[i] = fname_i

	EndFor

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

	return, fname
end



function MCD43A4_fname_output_png, day, month, year
	compile_opt idl2

	path = '\\wron\Working\work\Juan_Pablo\MCD43A4.005\png_reduced_10\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '

	;fname = strarr(1)

		fname = strcompress( $
			path + $
			;String (year) + '.' +	$
			;app_month + String(month) +  '.' + $
			;app_day + String(day) +  '\' + $
			'MCD43A4.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			'RealColor.png' , $
			/REMOVE_ALL )

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

	return, fname
end



function MODIS_8d_dates
	compile_opt idl2

	  dates_2000 = IndGen(46) * 8 +  JULDAY (1,1,2000)
	  dates_2001 = IndGen(46) * 8 +  JULDAY (1,1,2001)
	  dates_2002 = IndGen(46) * 8 +  JULDAY (1,1,2002)
	  dates_2003 = IndGen(46) * 8 +  JULDAY (1,1,2003)
	  dates_2004 = IndGen(46) * 8 +  JULDAY (1,1,2004)
	  dates_2005 = IndGen(46) * 8 +  JULDAY (1,1,2005)
	  dates_2006 = IndGen(46) * 8 +  JULDAY (1,1,2006)
	  dates_2007 = IndGen(46) * 8 +  JULDAY (1,1,2007)
	  dates_2008 = IndGen(46) * 8 +  JULDAY (1,1,2008)
	  dates_2009 = IndGen(46) * 8 +  JULDAY (1,1,2009)

	dates = [dates_2000, dates_2001, dates_2002, dates_2003, dates_2004, dates_2005, dates_2006, dates_2007, dates_2008, dates_2009]
	;dates = [dates_2007, dates_2008]

	return, dates

end



pro convert_mcd43a4_005_to_envi
	compile_opt idl2

	t_elapsed = SysTime (1)


	;open the following image and extract header info (particularly MAP_INFO )
	fname = '\\wron\Working\work\Juan_Pablo\MCD43A4.005\MCD43A4.2000.049.aust.005.b01.500m_0620_0670nm_nbar.img'
	ENVI_OPEN_DATA_FILE , fname , R_FID = FID
	projection = ENVI_GET_PROJECTION (FID= FID)
	MAP_INFO = ENVI_GET_MAP_INFO  ( FID=FID)

  ; only images modified later than thresh_date will be processed
  thresh_date = JulDay(6, 1, 2009)


	Dates = MODIS_8d_dates ()
	For dates_n = 0, n_elements(Dates)-1 do begin		; Starts in 6 because composites 0 to 5  don't exist
;	For dates_n = 418, n_elements(Dates)-1 do begin		; Starts in 418 to update data (5 August 2009)
	;dates_n=3

		t_loop = SysTime (1)


		CALDAT, Dates[dates_n], Month, Day, Year

		Input_file = MCD43A4_fname (day, month, year)
		Output_file = MCD43A4_fname_output (day, month, year)
		Temp_file = 'C:\temp\MCD43A4_temp.hdf'


		;for i=0, 3 do begin

		bands_processed = 0      ; this will count the number of bands processed

		for i=0, 6 do begin

			;Case i of
			;	0: band= 0			;first band (RED)
			;	1: band= 1			;second band (NIR)
			;	2: band= 5			;sixth band (SWIR2)
			;	3: band= 6			;seventh band (SWIR3)
			;EndCase
				Band = i


      ; Check if hdf (zipped) is newer than a given date
      file_info_band = File_Info(Input_file[band])           ; get date of last modification
      exists = file_info_band.exists
      mtime = Bin_Date(Systime(0, file_info_band.mtime))                ; convert to array
      JulDay_mtime = JulDay(mtime[1], mtime[2], mtime[0])    ; convert to julday


      IF exists eq 1 AND JulDay_mtime gt thresh_date THEN BEGIN        ; only start processing if file exists and is older than the threshold
        bands_processed += 1

  			; UNZIP FILE to temp folder
  			t= SysTime (1)
  			SPAWN, 'gzip -d -c ' + Input_file[band] + ' > ' + Temp_file			; Unzip File
  			Print, SysTime (1) - t, ' Seconds for unzipping file'


  			; READ HDF
  			sdFileID = HDF_SD_Start (Temp_file, /Read)
  			sdsID = HDF_SD_Select (sdFileID, 0)

  			HDF_SD_FileInfo, sdFileID, datasets, attributes
  			HDF_SD_GetInfo, sdsID, Name = thisSDSName

  			t= SysTime (1)
  			HDF_SD_GetData, sdsID, DATA
  			Print, SysTime (1) - t, ' Seconds for reading HDF dataset'

  			HDF_SD_End, sdFileID
  			FILE_DELETE, Temp_file


  			; Create subset Condamine
  			;DATA = DATA[7677:9045, 3167:4281]
  			SIZE_DATA = Size (Data)

  			REDUCE_FACTOR = 10

  			NEW_SIZE_DATA = SIZE_DATA / REDUCE_FACTOR

  			; Saves as ENVI
  			t= SysTime (1)
  			ENVI_WRITE_ENVI_FILE, DATA, OUT_NAME = Output_file[band], MAP_INFO = MAP_INFO, /No_Open
  			Print, SysTime (1) - t, ' Seconds for saving ENVI file'

  			; retains bands 7,2,1 for making png
  			t= SysTime (1)
  			IF band eq 0 then RED = CONGRID(Temporary(DATA), NEW_SIZE_DATA[1], NEW_SIZE_DATA[2])
  			IF band eq 1 then NIR = CONGRID(Temporary(DATA), NEW_SIZE_DATA[1], NEW_SIZE_DATA[2])
  			;IF band eq 2 then BLUE = Temporary(DATA)
  			;IF band eq 3 then GREEN = Temporary(DATA)
  			;IF band eq 4 then SWIR1 = Temporary(DATA)
  			;IF band eq 5 then SWIR2 = Temporary(DATA)
  			IF band eq 6 then SWIR3 = CONGRID(Temporary(DATA), NEW_SIZE_DATA[1], NEW_SIZE_DATA[2])
  			Print, SysTime (1) - t, ' Seconds for retaining and CONGRIDing band'

      ENDIF ELSE BEGIN
         print, 'file ',Input_file[band], 'does not exist or older than threshold date'
      ENDELSE

  		endfor

      if bands_processed eq 7 THEN BEGIN      ; only create png's if all nbar bands have been done

    		t_png = SysTime (1)

    		;Decides enhancement
    		max_enhancement = 5000
    		division_factor = 255. / max_enhancement
    		noDataColor = 200

    		; Rescale data to 0-max_enhancement
    		where_nodata = Where(RED le -10000 or NIR le -10000 or SWIR3 le -10000, count)

    		RED >= 0
    		RED <= max_enhancement
    		RED = byte (temporary(RED) * division_factor)
    		if count ge 1 then RED[where_nodata] = noDataColor

    		NIR >= 0
    		NIR <= max_enhancement
    		NIR = byte (temporary(NIR) * division_factor)
    		if count ge 1 then NIR[where_nodata] = noDataColor

    		SWIR3 >= 0
    		SWIR3 <= max_enhancement
    		SWIR3 = byte (temporary(SWIR3) * division_factor)
    		if count ge 1 then SWIR3[where_nodata] = noDataColor

    		;make png
    		array_png = bytarr (3, NEW_SIZE_DATA[1], NEW_SIZE_DATA[2])
    		array_png [0,*,*] = temporary(SWIR3)
    		array_png [1,*,*] = temporary(NIR)
    		array_png [2,*,*] = temporary(RED)


    		WRITE_PNG, MCD43A4_fname_output_png(day, month, year), array_png, red,green,blue, /order;, transparent=transparent

    		Print, SysTime (1) - t_png, ' Seconds for saving png '

    ENDIF

		Print, SysTime (1) - t_loop, ' Seconds for composite ', dates_n, ' of ', n_elements(Dates)-1

		print



	endfor

end

