; ##############################################################################################
; NAME: Batch_Normalised_Ratio.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 12/12/2010
; DLM: 30/05/2011
;
; DESCRIPTION:  This program calculates normalised ratios of the form:
; 
;               (BAND - BAND) / (BAND + BAND)
;               
;               The user may choose to calculate one or more of the following indices:
;               
;               NDVI = (NIR - R) / (NIR + R)
;               
;               NDWI 1 = (NIR - MIR) / (NIR + MIR)
;               
;               NDWI 2 = (G - NIR) / (G + NIR)
;               
;               mNDWI = (G - MIR) / (G + MIR)
;               
;               The user must define each input band in the selected index. 
;               
;               This program operates in batch mode by date. For each unique date the selected
;               indices are calculated and saved to file.
;
; INPUT:        One or more single-band date-sets.
;
; OUTPUT:       One single-band flat binary raster per input date-set.
;               
; PARAMETERS:   Define the parameters via in-program pop-up dialog widgets...
;               
;               1.  Select The Input Data.
;               
;               2.  Define Dates.
;               
;                   A multi-part widget; select a filename from the list and set the position of the first 
;                   character in the DOY and Year; or the Day, Month and Year strings. The selected date parts 
;                   are printed at the bottom of the widget. An invalid selection will cause the program to 
;                   quit. For more information see FUNCTION_WIDGET_Date.pro
;               
;               3.  Select the input data type.
;               
;                   A multi-part widget; select the input data type from the droplist. An incorrect data type
;                   selection will result in invalid results.
;               
;               4.  Select the output data type.
;               
;                   A multi-part widget; select an output data type. A non-valid data type selection will
;                   cause the program to quit.
;                   
;               4b. Set an output scaling factor (optional).
;               
;                   A multi-part widget; if the user selected a byte or integer output data type this
;                   widget will allow the user to set a scaling factor to preserve some or all decimal precision.
;                   
;               5.  Provide Input: No Data (optional).
;               
;                   A multi-part widget; if the input data has a no-data (fill) value that you want ignored in 
;                   the ratio calculation select 'Set a Grid Value to NaN' and define the value in the text box.
;               
;               6.  Select Indices.
;               
;                   A multi-part widget; select one or more indices. The program will calculate and write the
;                   selected ratios. You must select at least one index.
;               
;               7.  Define Bands.
;               
;                   A multi-part widget; you must assign the correct input files to the correct band for the
;                   program to calculate the selected indices correctly. Select an input file from the file list,
;                   select the reflectance band associated with the input file. Using the sliders set the string
;                   in the selected filename that defines the band. For example:
;                   
;                   The input file 'L5105069_06920060730_B30' contains landsat 5 reflectance data for band 3
;                   which is the Red band. Select 'Red Band' from the bandlist. Change the 'Length: Red' slider to 3,
;                   and move the 'Position: Red' to 21. The red string displayed at the bottom of the widget should
;                   display 'B30'. With this information the program can search and extract all of the red band data 
;                   files from the input file list.
;               
;               8.  Select The Output Folder.
;               
;                   The selected indices are written to this location.
;                     
; NOTES:        This program calls one or more external functions. You will need to compile the  
;               necessary functions in IDL, or save the functions to the current IDL workspace  
;               prior to running this tool.
;               
;               To identify your IDL workspace run the following from the IDL command line:
;               
;               CD, CURRENT=CWD & PRINT, CWD
;               
;               Functions used in this program include:
;               
;               FUNCTION_WIDGET_Date.pro
;               FUNCTION_WIDGET_Droplist.pro
;               FUNCTION_WIDGET_Set_Value_Conditional
;               FUNCTION_WIDGET_No_Data.pro
;               FUNCTION_WIDGET_Select_Ratio.pro
;               FUNCTION_WIDGET_Set_Bands.pro
;               
;               For more information contact Garth.Warren@csiro.au
;
; ##############################################################################################


PRO Batch_Normalised_Ratio
  ;---------------------------------------------------------------------------------------------
  StartTime = SYSTIME(1) ; Get the current system time.
  PRINT,''
  PRINT,'Begin Processing: Batch_Normalised_Ratio'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
  ; Input/Output:
  ;---------------------------------------------------------------------------------------------
  ; Select the input data:
  Path='G:\data\modis\temp\' ; '\\file-wron\Working\work\hod083\imagery\toac\landsat\toac_results\'
  Filter=['*.tif','*.img','*.flt','*.bin']
  In_Files = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Input Data', FILTER=Filter, /MUST_EXIST, /MULTIPLE_FILES)
  IF In_Files[0] EQ '' THEN RETURN ; Error check.
  In_Files = In_Files[SORT(In_Files)] ; Sort the input file list.
  ;-------------- ; Remove the file path from the input file names:
  fname_Start = STRPOS(In_Files, '\', /REVERSE_SEARCH)+1 ; Get the position of the first file name character (after the file path).
  fname_Length = (STRLEN(In_Files)-fname_Start)-4 ; Get the length of each path-less file name.
  FNS = MAKE_ARRAY(N_ELEMENTS(In_Files), /STRING) ; Create an array to store the input file names.
  FOR a=0, N_ELEMENTS(In_Files)-1 DO BEGIN ; Fill the file name array:
    FNS[a] += STRMID(In_Files[a], fname_Start[a], fname_Length[a]) ; Get the a-the file name (trim away the file path).
  ENDFOR
  ;-------------- ; Get the input dates:
  In_Dates = FUNCTION_WIDGET_Date(IN_FILES=FNS, /JULIAN) ; Get the input file name dates.
  IF In_Dates[0] NE -1 THEN BEGIN ; Check for valid dates.
    In_Files = In_Files[SORT(In_Dates)] ; Sort file name by date.
    FNS = FNS[SORT(In_Dates)] ; Sort file name by date.
    Unique_Dates = In_Dates[UNIQ(In_Dates)] ; Get unique input dates.
    Unique_Dates = Unique_Dates[SORT(Unique_Dates)] ; Sort the unique dates.   
    Unique_Dates = Unique_Dates[UNIQ(Unique_Dates)] ; Get unique input dates.
  ENDIF ELSE BEGIN
    PRINT,'** Invalid Date Selection **'
    RETURN ; Quit program
  ENDELSE
  ;---------------------------------------------------------------------------------------------
  ; Select the input data type:
  In_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Input Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (In_DataType EQ 7) OR (In_DataType EQ 8) OR (In_DataType EQ 9) OR (In_DataType EQ 10) OR (In_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Select the output data type:
  Out_DataType = FUNCTION_WIDGET_Droplist(TITLE='Select Output Datatype:', VALUE=['0 : UNDEFINED : Undefined', '1 : BYTE : Byte', $
    '2 : INT : Integer', '3 : LONG : Longword integer', '4 : FLOAT : Floating point', $
    '5 : DOUBLE : Double-precision floating', '6 : COMPLEX : Complex floating', $
    '7 : STRING : String', '8 : STRUCT : Structure', '9 : DCOMPLEX : Double-precision complex', $
    '10 : POINTER : Pointer', '11 : OBJREF : Object reference', '12 : UINT : Unsigned Integer', $
    '13 : ULONG : Unsigned Longword Integer', '14 : LONG64 : 64-bit Integer', $
    '15 : ULONG64 : Unsigned 64-bit Integer'])
  IF (Out_DataType EQ 0) OR (Out_DataType EQ 1) OR (Out_DataType EQ 7) OR (Out_DataType EQ 8) OR (Out_DataType EQ 9) OR (Out_DataType EQ 10) OR (Out_DataType EQ 11) THEN BEGIN
    PRINT,'** Invalid Data Type **'
    RETURN ; Quit program.
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set an output scaling factor:
  IF (Out_DataType EQ 1) OR (Out_DataType EQ 2) OR (Out_DataType EQ 3) THEN BEGIN
    Scaling = FUNCTION_WIDGET_Set_Value_Conditional(TITLE='Provide Input: Scaling', ACCEPT_STRING='Set a Scaling Value', $
      DECLINE_STRING='Do Not Set a Scaling Value', DEFAULT='10.00', /FLOAT)
  ENDIF ELSE Scaling = -1
  ;---------------------------------------------------------------------------------------------
  ; Set No Data:
  No_DATA = -1
  IF (In_DataType EQ 1) OR (In_DataType EQ 2) OR (In_DataType EQ 12) THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999', /INTEGER)
  IF (In_DataType EQ 3) OR (In_DataType GE 13) THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999', /LONG)
  IF In_DataType EQ 4 THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999.00', /FLOAT)
  IF (In_DataType EQ 5) OR (In_DataType EQ 6) THEN No_DATA = FUNCTION_WIDGET_No_Data(TITLE='Provide Input: No Data', DEFAULT='-999.00', /DOUBLE) 
  IF (No_DATA[0] NE -1) THEN NaN = No_DATA[1] ; Set NaN value.
  ;---------------------------------------------------------------------------------------------
  ; Set the normalised ratio:
  In_Ratio = FUNCTION_WIDGET_Select_Ratio()
  IF (In_Ratio[0] EQ -1) OR (MAX(In_Ratio) LT 1) THEN BEGIN ; Selection check.
    PRINT,'** You Must Select At Least One Index **'
    RETURN ; Quit program
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set input bands:
  In_Bands = FUNCTION_WIDGET_Set_Bands(TITLE='Define Bands', IN_FILES=FNS)
  IF (In_Bands[0] EQ -1) THEN BEGIN ; Selection check.
    PRINT,'** Invalid Band Selection **'
    RETURN ; Quit program
  ENDIF
  ;---------------------------------------------------------------------------------------------
  ; Set the output folder:
  Path='\\file-wron\Working\work\hod083\imagery\toac\landsat\toac_results\'
  Out_Directory = DIALOG_PICKFILE(PATH=Path, TITLE='Select The Output Folder', /DIRECTORY, /OVERWRITE_PROMPT)
  IF Out_Directory EQ '' THEN RETURN ; Error check.
  ;--------------------------------------------------------------------------------------------- 
  ; Date loop:
  ;---------------------------------------------------------------------------------------------
  FOR i=0, N_ELEMENTS(Unique_Dates)-1 DO BEGIN ; Loop through each input year:
    LoopStartTime_Date = SYSTIME(1) ; Get the loop start time.
    ;-------------- ; Manipulate dates and get files:
    CALDAT, Unique_Dates[i], iM, iD, iY ; Convert the i-th julian number to calender date.
    DOY = JULDAY(iM, iD, iY) - JULDAY(1, 0, iY) ; Convert the calender date to day of year.
    IF (DOY LE 9) THEN DOY = '00' + STRING(STRTRIM(DOY,2)) ; Add leading zero
    IF (DOY LE 99) AND (DOY GT 9) THEN DOY = '0' + STRING(STRTRIM(DOY,2)) ; Add leading zero
    Index = WHERE(In_Dates EQ Unique_Dates[i], COUNT) ; Get an index of file-dates that belong to the current date.
    Files_In = In_Files[Index] ; Get the list of files that belong to the current date.
    FNS_In = FNS[Index] ; Get the list of short filenames.
    ;-------------- ; Get data:
    IF (In_Ratio[2] EQ 1) OR (In_Ratio[3] EQ 1) THEN BEGIN ; Get the green band:
      Green_String = STRMID(FNS_In[(In_Bands[5])], In_Bands[3], In_Bands[4]) ; Get the green band string identifier.
      Green_In = Files_In[WHERE(STRMATCH(Files_In, '*' + Green_String + '*') EQ 1)] ; Get the green band file for the current date.
      Green = READ_BINARY(Green_In, DATA_TYPE=In_DataType) ; Get data.
      IF (No_DATA[0] NE -1) THEN Green_OK = WHERE(Green NE NaN, Count_Green) ELSE Count_Green = 0 ; Find all NaN cells.
    ENDIF ELSE Count_Green = 0
    IF (In_Ratio[0] EQ 1) THEN BEGIN ; Get the Red band:
      Red_String = STRMID(FNS_In[(In_Bands[8])], In_Bands[6], In_Bands[7]) ; Get the red band string identifier.
      Red_In = Files_In[WHERE(STRMATCH(Files_In, '*' +  Red_String + '*') EQ 1)] ; Get the red band file for the current date.
      Red = READ_BINARY(Red_In, DATA_TYPE=In_DataType) ; Get data.
      IF (No_DATA[0] NE -1) THEN Red_OK = WHERE(Red NE NaN, Count_Red) ELSE Count_Red = 0 ; Find all NaN cells.
    ENDIF ELSE Count_Red = 0    
    IF (In_Ratio[0] EQ 1) OR (In_Ratio[1] EQ 1) OR (In_Ratio[2] EQ 1) THEN BEGIN ; Get the NIR band:
      NIR_String = STRMID(FNS_In[(In_Bands[11])], In_Bands[9], In_Bands[10]) ; Get the NIR band string identifier.
      NIR_In = Files_In[WHERE(STRMATCH(Files_In, '*' +  NIR_String + '*') EQ 1)] ; Get the NIR band file for the current date.
      NIR = READ_BINARY(NIR_In, DATA_TYPE=In_DataType) ; Get data.
      IF (No_DATA[0] NE -1) THEN NIR_OK = WHERE(NIR NE NaN, Count_NIR) ELSE Count_NIR = 0 ; Find all NaN cells.
    ENDIF ELSE Count_NIR = 0
    IF (In_Ratio[1] EQ 1) OR (In_Ratio[3] EQ 1) THEN BEGIN ; GET the MIR band:
      MIR_String = STRMID(FNS_In[(In_Bands[14])], In_Bands[12], In_Bands[13]) ; Get the MIR band string identifier.
      MIR_In = Files_In[WHERE(STRMATCH(Files_In, '*' +  MIR_String + '*') EQ 1)] ; Get the MIR band file for the current date.
      MIR = READ_BINARY(MIR_In, DATA_TYPE=In_DataType) ; Get data.
      IF (No_DATA[0] NE -1) THEN MIR_OK = WHERE(MIR NE NaN, Count_MIR) ELSE Count_MIR = 0 ; Find all NaN cells.
    ENDIF ELSE Count_MIR = 0
    ;-------------- ; Remove NaN cells from the analysis:
    IF (In_Ratio[2] EQ 1) OR (In_Ratio[3] EQ 1) THEN Size = N_ELEMENTS(Green) ; Set the input raster size.
    IF (In_Ratio[0] EQ 1) THEN Size = N_ELEMENTS(Red) ; Set the input raster size.
    IF (In_Ratio[0] EQ 1) OR (In_Ratio[1] EQ 1) OR (In_Ratio[2] EQ 1) THEN Size = N_ELEMENTS(NIR) ; Set the input raster size.
    IF (Count_Green GT 0) THEN Green = TEMPORARY(Green[Green_OK]) ; Get valid data only.
    IF (Count_Red GT 0) THEN Red = TEMPORARY(Red[Red_OK]) ; Get valid data only.
    IF (Count_NIR GT 0) THEN NIR = TEMPORARY(NIR[NIR_OK]) ; Get valid data only.
    IF (Count_MIR GT 0) THEN MIR = TEMPORARY(MIR[MIR_OK]) ; Get valid data only.
    ;-------------------------------------------------------------------------------------------
    ; Calculate NDVI:
    ;-------------------------------------------------------------------------------------------
    IF (In_Ratio[0] EQ 1) THEN BEGIN
      NDVI = (NIR - Red) / (NIR + Red * 1.0)
      ;-------------- ; Reconstruct data to the original dimensions (fill missing locations):
      IF (No_DATA[0] NE -1) THEN BEGIN
        NDVI_Out = FLTARR(Size) & NDVI_Out[*] =  NaN
        NDVI_Out[Red_OK] = NDVI
      ENDIF ELSE NDVI_Out = NDVI
      ;-------------- ; Set the output datatype:
      IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
        IF (Scaling[0] NE -1) THEN NDVI_Out = FIX((NDVI_Out * Scaling[1]) + 0.5) ELSE NDVI_Out = FIX(NDVI_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
        IF (Scaling[0] NE -1) THEN NDVI_Out = LONG((NDVI_Out * Scaling[1]) + 0.5) ELSE NDVI_Out = LONG(NDVI_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 4) THEN BEGIN ; Float:
        NDVI_Out = NDVI_Out
      ENDIF
      IF (Out_DataType EQ 5) THEN BEGIN ; Double:
        NDVI_Out = DOUBLE(NDVI_Out)
      ENDIF
      IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
        IF (Scaling[0] NE -1) THEN NDVI_Out = UINT((NDVI_Out * Scaling[1]) + 0.5) ELSE NDVI_Out = UINT(NDVI_Out + 0.5)
      ENDIF
      ;-------------- ; Write:
      File_NDVI = Out_Directory + FNS_In[0] + '_NDVI.img' ; Set the output filename.
      OPENW, UNIT, File_NDVI, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT ; Close the output file.
      OPENU, UNIT, File_NDVI, /GET_LUN, /APPEND ; Open the output file for editing.
      WRITEU, UNIT, NDVI_Out ; Write output data.
      FREE_LUN, UNIT ; Close the output file.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Calculate NDWI 1:
    ;-------------------------------------------------------------------------------------------
    IF (In_Ratio[1] EQ 1) THEN BEGIN
      NDWI1 = (NIR - MIR) / (NIR + MIR * 1.0)
      ;-------------- ; Reconstruct data to the original dimensions (fill missing locations):
      IF (No_DATA[0] NE -1) THEN BEGIN
        NDWI1_Out = FLTARR(Size) & NDWI1_Out[*] =  NaN
        NDWI1_Out[NIR_OK] = NDWI1
      ENDIF ELSE NDWI1_Out = NDWI1
      ;-------------- ; Set the output datatype:
      IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
        IF (Scaling[0] NE -1) THEN NDWI1_Out = FIX((NDWI1_Out * Scaling[1]) + 0.5) ELSE NDWI1_Out = FIX(NDWI1_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
        IF (Scaling[0] NE -1) THEN NDWI1_Out = LONG((NDWI1_Out * Scaling[1]) + 0.5) ELSE NDWI1_Out = LONG(NDWI1_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 4) THEN BEGIN ; Float:
        NDWI1_Out = NDWI1_Out
      ENDIF
      IF (Out_DataType EQ 5) THEN BEGIN ; Double:
        NDWI1_Out = DOUBLE(NDWI1_Out)
      ENDIF
      IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
        IF (Scaling[0] NE -1) THEN NDWI1_Out = UINT((NDWI1_Out * Scaling[1]) + 0.5) ELSE NDWI1_Out = UINT(NDWI1_Out + 0.5)
      ENDIF
      ;-------------- ; Write:
      File_NDWI1 = Out_Directory + FNS_In[0] + '_NDWI1.img' ; Set the output file name.
      OPENW, UNIT, File_NDWI1, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT ; Close the output file.
      OPENU, UNIT, File_NDWI1, /GET_LUN, /APPEND ; Open the output file for editing.
      WRITEU, UNIT, NDWI1_Out ; Write output data.
      FREE_LUN, UNIT ; Close the output file.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Calculate NDWI 2:
    ;-------------------------------------------------------------------------------------------
    IF (In_Ratio[2] EQ 1) THEN BEGIN ; Calculate NDWI 2:
      NDWI2 = (Green - NIR) / (Green + NIR * 1.0)
      ;-------------- ; Reconstruct data to the original dimensions (fill missing locations):
      IF (No_DATA[0] NE -1) THEN BEGIN
        NDWI2_Out = FLTARR(Size) & NDWI2_Out[*] =  NaN
        NDWI2_Out[NIR_OK] = NDWI2
      ENDIF ELSE NDWI2_Out = NDWI2
      ;-------------- ; Set the output datatype:
      IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
        IF (Scaling[0] NE -1) THEN NDWI2_Out = FIX((NDWI2_Out * Scaling[1]) + 0.5) ELSE NDWI2_Out = FIX(NDWI2_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
        IF (Scaling[0] NE -1) THEN NDWI2_Out = LONG((NDWI2_Out * Scaling[1]) + 0.5) ELSE NDWI2_Out = LONG(NDWI2_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 4) THEN BEGIN ; Float:
        NDWI2_Out = NDWI2_Out
      ENDIF
      IF (Out_DataType EQ 5) THEN BEGIN ; Double:
        NDWI2_Out = DOUBLE(NDWI2_Out)
      ENDIF
      IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
        IF (Scaling[0] NE -1) THEN NDWI2_Out = UINT((NDWI2_Out * Scaling[1]) + 0.5) ELSE NDWI2_Out = UINT(NDWI2_Out + 0.5)
      ENDIF
      ;-------------- ; Write:
      File_NDWI2 = Out_Directory + FNS_In[0] + '_NDWI2.img' ; Set the output file name.
      OPENW, UNIT, File_NDWI2, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT ; Close the output file.
      OPENU, UNIT, File_NDWI2, /GET_LUN, /APPEND ; Open the output file for editing.
      WRITEU, UNIT, NDWI2_Out ; Write output data.
      FREE_LUN, UNIT ; Close the output file.
    ENDIF
    ;-------------------------------------------------------------------------------------------
    ; Calculate mNDWI:
    ;-------------------------------------------------------------------------------------------
    IF (In_Ratio[3] EQ 1) THEN BEGIN ; Calculate mNDWI:
      mNDWI = (Green - MIR) / (Green + MIR * 1.0)
      ;-------------- ; Reconstruct data to the original dimensions (fill missing locations):
      IF (No_DATA[0] NE -1) THEN BEGIN
        mNDWI_Out = FLTARR(Size) & mNDWI_Out[*] =  NaN
        mNDWI_Out[MIR_OK] = mNDWI
      ENDIF ELSE mNDWI_Out = mNDWI
      ;-------------- ; Set the output datatype:
      IF (Out_DataType EQ 2) THEN BEGIN ; Signed Integer:
        IF (Scaling[0] NE -1) THEN mNDWI_Out = FIX((mNDWI_Out * Scaling[1]) + 0.5) ELSE mNDWI_Out = FIX(mNDWI_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 3) THEN BEGIN ; Long Integer:
        IF (Scaling[0] NE -1) THEN mNDWI_Out = LONG((mNDWI_Out * Scaling[1]) + 0.5) ELSE mNDWI_Out = LONG(mNDWI_Out + 0.5)
      ENDIF
      IF (Out_DataType EQ 4) THEN BEGIN ; Float:
        mNDWI_Out = mNDWI_Out
      ENDIF
      IF (Out_DataType EQ 5) THEN BEGIN ; Double:
        mNDWI_Out = DOUBLE(mNDWI_Out)
      ENDIF
      IF (Out_DataType EQ 12) THEN BEGIN ; Unsigned Integer:
        IF (Scaling[0] NE -1) THEN mNDWI_Out = UINT((mNDWI_Out * Scaling[1]) + 0.5) ELSE mNDWI_Out = UINT(mNDWI_Out + 0.5)
      ENDIF
      ;-------------- ; Write:
      File_mNDWI = Out_Directory + FNS_In[0] + '_mNDWI.img' ; Set the output file name.
      OPENW, UNIT, File_mNDWI, /GET_LUN ; Create the output file.
      FREE_LUN, UNIT ; Close the output file.
      OPENU, UNIT, File_mNDWI, /GET_LUN, /APPEND ; Open the output file for editing.
      WRITEU, UNIT, mNDWI_Out ; Write output data.
      FREE_LUN, UNIT ; Close the output file.
    ENDIF
    ;-------------------------------------------------------------------------------------------   
    Minutes = (SYSTIME(1)-LoopStartTime_Date)/60 ; Get the file loop end time
    PRINT, '  Processing Time: ', STRTRIM(Minutes, 2), ' minutes, for year ', STRTRIM(i+1, 2), $
      ' of ', STRTRIM(N_ELEMENTS(Unique_Dates), 2)
    ;-------------------------------------------------------------------------------------------      
  ENDFOR
  ;---------------------------------------------------------------------------------------------
  Minutes = (SYSTIME(1)-StartTime)/60 ; Subtract the program End-Time from the program Start-Time.
  Hours = Minutes/60 ; Convert minutes to hours.
  PRINT,''
  PRINT,'Total Processing Time: ', STRTRIM(Minutes, 2), ' minutes (', STRTRIM(Hours, 2), ' hours).'
  PRINT,''
  ;---------------------------------------------------------------------------------------------
END

