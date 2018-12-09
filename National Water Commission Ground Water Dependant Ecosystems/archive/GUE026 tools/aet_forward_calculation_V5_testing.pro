

;----------------------------------------------------------------------------------------------------
FUNCTION EVI_MCD43, BLUE_, RED_, NIR_
  BLUE_ *= 0.0001
  RED_  *= 0.0001
  NIR_  *= 0.0001
  RESULT = (2.5* ((NIR_ - RED_) / (NIR_ + 6 * RED_ - 7.5 * BLUE_ + 1) ))
RETURN, RESULT
END
;----------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------
FUNCTION GVMI_MCD43, NIR_, SWIR2_
  NIR_    *= 0.0001
  SWIR2_  *= 0.0001
  RESULT = ((NIR_ + 0.1)-(SWIR2_ + 0.02)) / ((NIR_ + 0.1) + (SWIR2_ + 0.02))
  RETURN, RESULT
END
;----------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------
function AET_model1, EVI, GVMI, PET, RAIN, k_max, a, alpha, b, beta, k_Ei_max, k_CMI, C_CMI, CMI_max, EVI_min, EVI_max, FLUX_SITE
	compile_opt idl2
	t= systime(1)
		; CALCULATES CMI
		k_CMI=	k_CMI
		C_CMI=	C_CMI
		CMI = GVMI - (k_CMI * EVI + C_CMI)						; This is the original CMI calculation invented by Albert and Guillaume
		EVI_min=  EVI_min
		EVI_max=  EVI_max
		EVI_r = (((EVI-EVI_min)/(EVI_max-EVI_min)) > 0) < 1
		; CALCULATES CMI_r
		CMI_min = 0.					; from Excel Spreadsheet
		CMI_max = CMI_max
		CMI_r = (  ((CMI-CMI_min)/(CMI_max-CMI_min)) > 0) < 1
		;CALCULATES kc
		k_max=		k_max
		a=			a
		alpha=		alpha
		b=		    b
		beta=		beta
		kc = k_max * (1-EXP(-a*EVI_r^alpha-b*CMI_r^beta))
		; CALCULATES k_Ei
		k_Ei_max=	k_Ei_max
		k_Ei = k_Ei_max * EVI_r
		;calculates AET_model1
		AET_1 = kc * PET + k_Ei * RAIN
	return, AET_1
end
;----------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------
; MAIN PROCEDURE:
;----------------------------------------------------------------------------------------------------
PRO aet_forward_calculation_V5_testing
	  compile_opt idl2
    ;---------------------------------------------------
    ; defines model parameters. These come from the paper
    x1=[0.911293,10.221437,2.381496,0,1,0,0.665331,-0.247571,1,0,0.9]
    x2=[0.755762,13.999496,2.457595,0,1,0.207007,0.5,0.05,1,0,0.9]
    x3=[0.868261,14.41953,2.70145,2.086299,0.953363,0,1.777835,-0.35,1,0,0.9]
    x4=[0.679704,14.118289,2.481207,7.991423,0.889975,0.229422,0.774739,-0.075699,1,0,0.9]
	  x=x4
    ; gets parameters from x
    k_max	= x[0]
    a	= x[1]
    alpha	= x[2]
    b	= x[3]
    beta = x[4]
    k_Ei_max	= x[5]
    k_CMI	= x[6]
    C_CMI	= x[7]
    CMI_max	= x[8]
    EVI_min	= x[9]
    EVI_max	= x[10]
    ;---------------------------------------------------
    In_Mask_250 = '\\File-wron\Working\work\NWC_Groundwater_Dependent_Ecosystems\Data\Raster\SILO\MODIS.Land.Mask.aust.005.250m.img'
		envi_open_file, In_Mask_250, r_fid=fid_LAND, /No_Realize
		if (fid_LAND eq -1) then return
		envi_file_query, fid_LAND, ns=ns, nl=nl, nb=nb
		MAP_INFO = ENVI_GET_MAP_INFO(FID=fid_LAND)
		dims_LAND = [-1, 0, ns-1, 0, nl-1]
 		LAND = envi_get_data(fid=fid_LAND, dims=DIMS_LAND, pos=0)
    ;--------------------------------------------------- ; OPEN and read FILES
    ; reads band1
    fname = 'G:\Data\MODIS\MOD09Q1.005\MOD09Q1.2001.001.aust.005.b01.img'
    envi_open_file, fname, r_fid=fid_band1, /No_Realize
    envi_file_query, fid_band1, ns=ns, nl=nl, nb=nb
    dims_band1 = [-1, 0, ns-1, 0, nl-1]
 
    ; reads band2
    fname = 'G:\Data\MODIS\MOD09Q1.005\MOD09Q1.2001.001.aust.005.b02.img'
    envi_open_file, fname, r_fid=fid_band2, /No_Realize
    envi_file_query, fid_band2, ns=ns, nl=nl, nb=nb
    dims_band2 = [-1, 0, ns-1, 0, nl-1]
        
    ; reads band3
    fname = 'G:\Data\MODIS\MOD09A1.005.250m\MOD09A1.2001.001.aust.005.b03.250m.img'    
    envi_open_file, fname, r_fid=fid_band3, /No_Realize
    envi_file_query, fid_band3, ns=ns, nl=nl, nb=nb
    dims_band3 = [-1, 0, ns-1, 0, nl-1]
        
    ; reads band6
    fname = 'G:\Data\MODIS\MOD09A1.005.250m\MOD09A1.2001.001.aust.005.b06.250m.img'
    envi_open_file, fname, r_fid=fid_band6, /No_Realize
    envi_file_query, fid_band6, ns=ns, nl=nl, nb=nb
    dims_band6 = [-1, 0, ns-1, 0, nl-1]
    ;--------------------------------------------------- ; READS DATA
    RED =  envi_get_data(fid=fid_band1, dims=dims_band1, pos=0)
    NIR =  envi_get_data(fid=fid_band2, dims=dims_band2, pos=0)
    BLUE = envi_get_data(fid=fid_band3, dims=dims_band3, pos=0)
    SWIR2 = envi_get_data(fid=fid_band6, dims=dims_band6, pos=0)
    ;selects pixels with values OK. From now on makes operations with only those pixs and goes faster
    where_OK = where(LAND eq 1 AND $
      RED gt -32000 AND  $
      NIR gt -32000 AND  $
      BLUE gt -32000 AND  $
      SWIR2 gt -32000, complement=where_NO_OK)
    ;---------------------------------------------------
    EVI = EVI_MCD43(BLUE[where_OK], RED[where_OK], NIR[where_OK])
    GVMI = GVMI_MCD43(NIR[where_OK], SWIR2[where_OK])
    undefine, RED, NIR, BLUE, SWIR2    ; don't need these any more

		; reads PET (SILO)
    fname = 'H:\Projects\NWC_Groundwater_Dependent_Ecosystems\Gamma\PET_s1102_2001001.Sum.img' 
    PET= read_binary(fname , DATA_TYPE=2, DATA_DIMS=[19160, 14902])

    ; reads RAIN (SILO)
    fname = 'H:\Projects\NWC_Groundwater_Dependent_Ecosystems\Gamma\rain_s1102_2001001.Sum.img'
    RAIN= read_binary(fname , DATA_TYPE=2, DATA_DIMS=[19160, 14902])

    PET= (temporary(PET[where_ok])) * 0.1
    RAIN= (temporary(RAIN[where_ok])) * 0.1
		;--------------------------------------------------- ; calculates AET_model1
    AET_1 = AET_model1(EVI, GVMI, PET, RAIN, k_max, a, alpha, b, beta, k_Ei_max, k_CMI, C_CMI, CMI_max, EVI_min, EVI_max)
    AET_1 = (AET_1 * 10)
    AET_1 = FIX(Temporary(AET_1) + 0.5)
		;reconstructs arrays
    AET = FIX(LAND) & AET[*] = 0
		AET[where_ok] = AET_1
    AET[where_no_ok] = -999
    undefine, AET_1
		; WRITES OUTPUTS
		out_name = 'H:\Projects\NWC_Groundwater_Dependent_Ecosystems\Gamma\CMRSET_JP_250m.img'
    ENVI_WRITE_ENVI_FILE, AET, out_name=out_name, /NO_OPEN, MAP_INFO=MAP_INFO
END

