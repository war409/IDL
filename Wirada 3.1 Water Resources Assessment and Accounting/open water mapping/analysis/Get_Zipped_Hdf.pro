Function GET_Zipped_hdf, fname_input, fname_temp
	Compile_opt idl2

		ON_ERROR

		Input_file = fname_input
		;Output_file = MOD09A1_fname_output (day, month, year)
		Temp_file = fname_temp

			; UNZIP FILE to temp folder

			FileInfo = File_Info(Input_file)
			If FileInfo.Exists eq 1 then begin

				t= SysTime (1)
				SPAWN, 'gzip -d -c ' + Input_file + ' > ' + Temp_file	, Result, ErrResult, /HIDE  	; Unzip File
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

			EndIF ELSE Begin
				Print, 'File not found, returning -1'
				DATA = 	-1

			EndElse

		Return, DATA

END

