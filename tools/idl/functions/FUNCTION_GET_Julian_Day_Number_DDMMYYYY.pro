; ##############################################################################################
; NAME: FUNCTION_GET_Julian_Day_Number_DDMMYYYY.pro
; LANGUAGE: IDL
; AUTHOR: Garth Warren (Email: Garth.Warren@csiro.au)
; PROJECT: NA
; DATE: 11/11/2010
; DLM: 11/11/2010
;
; DESCRIPTION:  This function can be used to extract date as a Julian day number from the input
;               string. The input date should be in the form of a four character year (YYYY), a 
;               a two character day (DD), and a two character month (MM).
;               
;               For example, say the input is: 
;               
;               STRINGS=['MOD09A1.005.OWL.5VariableModel.20041116.img', $
;                 'MOD09A1.005.OWL.5VariableModel.20041124.img']
;               
;               The function calling sequence is: 
;               
;               JULIAN_DATE = FUNCTION_GET_Julian_Day_Number_DDMMYYYY(STRINGS, 31, 35, 37)
;               
;               The output is:
;               
;               2453326
;               2453334
;
; INPUT:        STRING: A string that contains the year as YYYY, month as MM, and day as DD.  
;               The string may be a scalar or an array of strings. If an array of strings is 
;               used the date positions must be consistent.
; 
;               YEAR_POS: The starting character position of the YYYY in the input string.
;               
;               MONTH_POS: The starting character position of the MM in the input string.
;               
;               DAY_POS: The starting character position of the DD in the input string.
;
; OUTPUT:       A long integer array containing the Julian day number for each input string is
;               returned to the program that called the function.
;               
; NOTES:        
;
; ##############################################################################################


;***********************************************************************************************
; ##############################################################################################
FUNCTION FUNCTION_GET_Julian_Day_Number_DDMMYYYY, STRING, YEAR_POS, MONTH_POS, DAY_POS
  COMPILE_OPT IDL2, HIDDEN
  ON_ERROR, 2
  ;---------------------------------------------------------------------------------------------
  ; MANIPULATE STRING TO GET YEAR                            
  YYYY = STRMID(STRING, YEAR_POS, 4)
  ;--------------
  ; MANIPULATE STRING TO GET MONTH
  MM = STRMID(STRING, MONTH_POS, 2)
  ;--------------
  ; MANIPULATE STRING TO GET DAY
  DD = STRMID(STRING, DAY_POS, 2)
  ;--------------
  ; CONVERT FILE DATES TO 'JULDAY' FORMAT
  DMY = JULDAY(MM, DD, YYYY)
  ;--------------------------------------------------------------------------------------------- 
  ; RETURN TO MAIN PROGRAM LEVEL
  RETURN, JULIAN_DATE
  ;---------------------------------------------------------------------------------------------
END
; ##############################################################################################
;***********************************************************************************************

