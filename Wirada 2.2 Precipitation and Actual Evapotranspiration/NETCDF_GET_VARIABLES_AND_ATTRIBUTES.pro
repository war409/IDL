; GET VARIABLE AND ATTRIBUTE INFORMATION
PRO NETCDF_GET_VARIABLES_AND_ATTRIBUTES
    ;---------------------------------------------------------------
    ;FILEOPEN = FILEPATH('20100101_rad.nc', ROOT_DIR='Z:\', SUBDIRECTORY='work\war409\PP\TESTING\OUT')
    ;---------------------------------------------------------------
    ; DEFINE NETCDF FILE
    ; CREATE THE 'IN' IDL VARIABLE TO CONTAIN THE INPUT NETCDF FILE ID
    FILEOPEN = '\\Wron\TimeSeries\Climate\gridded_aust\SiloUpdate201102\radNC\2010\20100101_rad.nc'
    NETID = NCDF_OPEN(FILEOPEN ,/NOWRITE)
    FILE_INFO = NCDF_INQUIRE(NETID)
    PRINT, 'NUMBER OF VARIABLES = ', FILE_INFO.nvars
    PRINT, 'NUMBER OF GLOBAL ATTRIBUTES = ', FILE_INFO.ngatts
    ;
    ; GET GLOBAL ATTRIBUTES
    GLO_ATT = FILE_INFO.ngatts
    IF GLO_ATT GT 0 THEN BEGIN
      ARRNAMEGLO = STRARR(GLO_ATT)
      ARRGLO = STRARR(GLO_ATT)
      FOR k=0, GLO_ATT-1 DO BEGIN
        NAME = NCDF_ATTNAME(NETID, k, /GLOBAL)
        ARRNAMEGLO[k] = NAME
        ATT_INFO = NCDF_ATTINQ(NETID, NAME, /GLOBAL)
        NCDF_ATTGET, NETID, NAME, ATTVALUE, /GLOBAL
        IF ATT_INFO.datatype EQ 'CHAR' THEN (VALUE = STRING(ATTVALUE)) ELSE (VALUE = ATTVALUE)
        ARRGLO[k] = VALUE
      ENDFOR
    ENDIF
    ;---------------------------------------------------------------
    PRINT, GLO_ATT
    PRINT, ARRNAMEGLO[5]
    PRINT, ARRGLO[5]
    PRINT, ''
    ;---------------------------------------------------------------
    ;
    ; GET VARIABLE ATTRIBUTES
    VAR_INFO = NCDF_VARINQ(NETID, 2)
    VAR_NAME = VAR_INFO.name
    PRINT, VAR_NAME
    VAR_TYPE = VAR_INFO.datatype
    VAR_ATT = VAR_INFO.natts
    VID = NCDF_VARID(NETID, VAR_NAME)
    IF VAR_ATT GT 0 THEN BEGIN
      ARRNAME = STRARR(VAR_ATT)
      ARRVAL = STRARR(VAR_ATT)
      FOR j=0, VAR_ATT-1 DO BEGIN
        NAME = NCDF_ATTNAME(NETID, VID, j)
        ; NAME = NCDF_ATTNAME(NETID, 0, /GLOBAL)
        ARRNAME[j] = NAME
        ATT_INFO = NCDF_ATTINQ(NETID, VID, NAME)
        NCDF_ATTGET, NETID, VID, NAME, ATTVALUE
        IF ATT_INFO.datatype EQ 'CHAR' THEN (VALUE = STRING(ATTVALUE)) ELSE (VALUE = ATTVALUE)
        ARRVAL[j] = VALUE
      ENDFOR
    ENDIF
    ;---------------------------------------------------------------
    PRINT, VAR_ATT
    PRINT, VAR_NAME
    PRINT, ARRNAME[3]
    PRINT, ARRVAL[3]
    PRINT, ''
    ;---------------------------------------------------------------
END