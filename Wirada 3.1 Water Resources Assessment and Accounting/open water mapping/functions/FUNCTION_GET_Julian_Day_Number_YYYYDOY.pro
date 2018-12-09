; ##############################################################################################
; NAME: FUNCTION_GET_Julian_Day_Number_YYYYDOY.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 11/11/2010
;
; DESCRIPTION:  This function can be used to extract date as a Julian day number from the input
;               string. The input date should be in the form of a four character year (YYYY) and 
;               a three character day-of-year (DOY). 
;               
;               For example, say the input is: 
;               
;               STRINGS=['MOD09A1.005.OWL.5VariableModel.2004353.img', $
;                 'MOD09A1.005.OWL.5VariableModel.2004361.img']
;               
;               The function calling sequence is: 
;               
;               JULIAN_DATE = FUNCTION_GET_Julian_Day_Number_YYYYDOY(STRINGS, 31, 35)
;               
;               The output is:
;               
;               2453358
;               2453366
;
; INPUT:        STRING: A string that contains the year as YYYY, and day-of-year. The string may  
;               be a scalar or an array of strings. If an array of strings is used the date 
;               positions must be consistent.
; 
;               YEAR_POS: The starting character position of the YYYY in the input string.
;               
;               DOY_POS: The starting character position of the DOY in the input string.
;
; OUTPUT:       A long integer array containing the Julian day number for each input string is
;               returned to the program that called the function.
;               
; NOTES:        
;
; ##############################################################################################


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_GET_Julian_Day_Number_YYYYDOY, STRING, YEAR_POS, DOY_POS
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE STRING TO GET YEAR    
  YYYY = STRMID(STRING, YEAR_POS, 4)
  ;--------------
  ; MANIPULATE STRING TO GET DAY OF YEAR
  DOY = STRMID(STRING, DOY_POS, 3)
  ;--------------
  ; GET 'DAY' AND 'MONTH' FROM 'DAY OF YEAR' 
  CALDAT, JULDAY(1, DOY, YYYY), MONTH, DAY
  ;--------------
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  JULIAN_DATE = JULDAY(MONTH, DAY, YYYY)
  ;--------------------------------------------------------------------------------------------- 
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, JULIAN_DATE
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

