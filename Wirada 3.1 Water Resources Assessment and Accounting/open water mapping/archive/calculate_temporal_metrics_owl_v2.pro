pro calculate_temporal_metrics_OWL_V2

	t=SysTime(1)

    fname='\\file-wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\META\MOD09A1.2000.049.2010.257.aust.005.OWL.meta'
    envi_open_file, fname, r_fid=fid_OWL, /no_realize
    envi_file_query, fid_OWL, ns=ns, nl=nl, nb=nb
    dims = [-1, 0, ns-1, 0, nl-1]
    print, dims
    MAP_INFO = ENVI_GET_MAP_INFO  ( FID=fid_OWL)

     print, Systime(1)-t, ' seconds for opening files '

    pos= indgen(nb)

    ;define arrays for output
    ACUM_OWL_GT_01  =  LonArr(ns, nl)
    ACUM_OWL_GT_10  =  LonArr(ns, nl)
    ACUM_OWL_GT_30  =  LonArr(ns, nl)
    ACUM_OWL_GT_50  =  LonArr(ns, nl)
    ACUM_OWL_GT_70  =  LonArr(ns, nl)
    ACUM_OWL_GT_90  =  LonArr(ns, nl)
    ACUM_OWL_NE_255 =  LonArr(ns, nl)
    ACUM_OWL_EQ_255 =  LonArr(ns, nl)

	t_init = SysTime(1)

    for date=0, nb-1 do begin
;    for date=0, 3 do begin

      t= Systime(1)
      OWL = envi_get_data(fid=fid_OWL, pos=date, dims=dims)
      ;print, SysTime(1)-t, ' seconds for reading band  ', date

      ; mask "good" values" (where flag eq 0 or 1)
      ACUM_OWL_GT_01 += (OWL gt  1 AND OWL NE 255)
      ACUM_OWL_GT_10 += (OWL gt 10 AND OWL NE 255)
      ACUM_OWL_GT_30 += (OWL gt 30 AND OWL NE 255)
      ACUM_OWL_GT_50 += (OWL gt 50 AND OWL NE 255)
      ACUM_OWL_GT_70 += (OWL gt 70 AND OWL NE 255)
      ACUM_OWL_GT_90 += (OWL gt 90 AND OWL NE 255)
      ACUM_OWL_NE_255 += (OWL ne 255)
      ACUM_OWL_EQ_255 += (OWL eq 255)

      print, Systime(1)-t, ' seconds for getting and calculating date  ', date
      print, (Systime(1)-t_init)/(date+1), ' average per date  '


    endfor

stop
	  ACUM_OWL_NE_255 *= 1.0
      ACUM_ALL = (ACUM_OWL_EQ_255 + ACUM_OWL_NE_255) * 1.0

      OWL_GT_01 = Byte(((ACUM_OWL_GT_01 / ACUM_OWL_NE_255) * 100 + 0.5 ))
      OWL_GT_10 = Byte(((ACUM_OWL_GT_10 / ACUM_OWL_NE_255) * 100 + 0.5 ))
      OWL_GT_30 = Byte(((ACUM_OWL_GT_30 / ACUM_OWL_NE_255) * 100 + 0.5 ))
      OWL_GT_50 = Byte(((ACUM_OWL_GT_50 / ACUM_OWL_NE_255) * 100 + 0.5 ))
      OWL_GT_70 = Byte(((ACUM_OWL_GT_70 / ACUM_OWL_NE_255) * 100 + 0.5 ))
      OWL_GT_90 = Byte(((ACUM_OWL_GT_90 / ACUM_OWL_NE_255) * 100 + 0.5 ))
      OWL_EQ_255 = Byte(((ACUM_OWL_EQ_255 / ACUM_ALL) * 100 + 0.5 ))

     ; save outputs
    fname='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\temporal_metrics\OWL_GT_01.img'
    ENVI_WRITE_ENVI_FILE, OWL_GT_01, OUT_NAME=fname, MAP_INFO=MAP_INFO

    fname='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\temporal_metrics\OWL_GT_10.img'
    ENVI_WRITE_ENVI_FILE, OWL_GT_10, OUT_NAME=fname, MAP_INFO=MAP_INFO

    fname='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\temporal_metrics\OWL_GT_30.img'
    ENVI_WRITE_ENVI_FILE, OWL_GT_30, OUT_NAME=fname, MAP_INFO=MAP_INFO

    fname='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\temporal_metrics\OWL_GT_50.img'
    ENVI_WRITE_ENVI_FILE, OWL_GT_50, OUT_NAME=fname, MAP_INFO=MAP_INFO

    fname='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\temporal_metrics\OWL_GT_70.img'
    ENVI_WRITE_ENVI_FILE, OWL_GT_70, OUT_NAME=fname, MAP_INFO=MAP_INFO

    fname='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\temporal_metrics\OWL_GT_90.img'
    ENVI_WRITE_ENVI_FILE, OWL_GT_90, OUT_NAME=fname, MAP_INFO=MAP_INFO

    fname='\\wron\Working\work\Juan_Pablo\Open_Water_mapping\MOD09A1.005.AUST.OWL\temporal_metrics\OWL_EQ_255.img'
    ENVI_WRITE_ENVI_FILE, OWL_EQ_255, OUT_NAME=fname, MAP_INFO=MAP_INFO

end