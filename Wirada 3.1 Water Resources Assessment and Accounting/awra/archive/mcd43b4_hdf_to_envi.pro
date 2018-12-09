function NBAR_fname, day, month, year
	compile_opt idl2

	If year ge 2007 then ModisProductName = 'MCD43B4' Else ModisProductName = 'MOD43B4'
	If year ge 2007 then Version = '005' Else Version = '004'

	path = '\\data-wron\RemoteSensing\MODIS\L2\LPDAAC\'+ModisProductName+'.'+Version+'\'

	if month le 9 then app_month = '0' else app_month = ' '
	if day le 9 then app_day = '0' else app_day = ' '

	doy = JULDAY (month, day, year)  -  JULDAY (1,1,year) + 1
	if doy le 9 then app_doy = '00'
	if doy gt 9 and doy le 99 then app_doy = '0'
	if doy gt 99 then app_doy = ' '


	fname = strarr(7)


	for i=0, 6 do begin

		Case i of
			0: Band_text= 'aust.'+Version+'.b01.1000m_0620_0670nm_nbar.hdf.gz'
			1: Band_text= 'aust.'+Version+'.b02.1000m_0841_0876nm_nbar.hdf.gz'
			2: Band_text= 'aust.'+Version+'.b03.1000m_0459_0479nm_nbar.hdf.gz'
			3: Band_text= 'aust.'+Version+'.b04.1000m_0545_0565nm_nbar.hdf.gz'
			4: Band_text= 'aust.'+Version+'.b05.1000m_1230_1250nm_nbar.hdf.gz'
			5: Band_text= 'aust.'+Version+'.b06.1000m_1628_1652nm_nbar.hdf.gz'
			6: Band_text= 'aust.'+Version+'.b07.1000m_2105_2155nm_nbar.hdf.gz'

		EndCase

		fname_i = strcompress( $
			path + $
			String (year) + '.' +	$
			app_month + String(month) +  '.' + $
			app_day + String(day) +  '\' + $
			ModisProductName + '.' + $
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


function NBAR_fname_output, day, month, year
	compile_opt idl2

	If year ge 2007 then ModisProductName = 'MCD43B4.005' Else ModisProductName = 'MCD43B4.004'

	path = '\\powerapp1-wron\data\work\Juan_Pablo\Temp\'+ModisProductName+'\Condamine\721\'

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
			'MCD43B4.' + $
			String (year) + '.' +	$
			app_doy + String(doy) + '.' + $
			'721_Condamine.png' , $
			/REMOVE_ALL )

		;fname_search = FILE_SEARCH(fname_case)

		;if n_elements(Fname_search) ne 1 then stop else $
		;	fname[i*2+j] = Fname_case

	return, fname
end



pro MCD43B4_HDF_to_ENVI
	compile_opt idl2

	; prompt user for date

	YEAR = 0
	MONTH = 0
	DAY = 0

		WHILE Year lt 2000 OR Year gt 2009 do Begin
			READ, YEAR, PROMPT='Enter Year '
			IF Year lt 2000 OR Year gt 2009 Then Begin
				result = DIALOG_MESSAGE( 'Year must be between 2000 and 2009' )
			EndIf
		EndWhile

		WHILE Month lt 1 OR Month gt 12 do Begin
			READ, Month, PROMPT='Enter Month '
			IF Month lt 1 OR Month gt 12 Then Begin
				result = DIALOG_MESSAGE( 'Month must be between 1 and 12' )
			EndIf
		EndWhile

		WHILE Day lt 1 OR Day gt 31 do Begin
			READ, Day, PROMPT='Enter Day '
			IF Day lt 1 OR Day gt 31 Then Begin
				result = DIALOG_MESSAGE( 'Day must be between 1 and 31' )
			EndIf
		EndWhile

 		filename = NBAR_fname (day, month, year)
		;print, filename

		File_Info_Band = FILE_INFO(filename[0])
		IF File_Info_Band.EXISTS eq 0 then begin
			result = DIALOG_MESSAGE( 'Files do not exist   ' )
			stop
		endif



	; Unzip and read files
		Output_file = '\\File-wron\Working\work\war409\Work\Imagery\MODIS\TEMP2.hdf'

		for i=0,6 do begin

			File_Info_Band = FILE_INFO(filename[i])
			IF File_Info_Band.EXISTS eq 1 then begin

				; UNZIP FILE to temp folder
				t= SysTime (1)
				SPAWN, 'gzip -d -c ' + filename[i] + ' > ' + Output_file			; Unzip File
				Print, SysTime (1) - t, ' Seconds for unzipping file'

				; READ HDF
				sdFileID = HDF_SD_Start (Output_file, /Read)
				sdsID = HDF_SD_Select (sdFileID, 0)

				HDF_SD_FileInfo, sdFileID, datasets, attributes
				HDF_SD_GetInfo, sdsID, Name = thisSDSName

				t= SysTime (1)
				HDF_SD_GetData, sdsID, DATA
				Print, SysTime (1) - t, ' Seconds for reading HDF dataset'

				HDF_SD_End, sdFileID
				FILE_DELETE, Output_file

			ENDIF ELSE Begin

				DATA = IntArr(9580, 7451) & DATA[*] = -32000

			ENDELSE
stop
			;DATA = ConGrid (Temporary(DATA), DIMS_output[0], DIMS_output[1], 3)

			IMG[i,*,*] = Temporary(DATA)

		EndFor

		Print, SysTime (1) - t_elapsed, ' Seconds for reading 3 HDF datasets'




end


