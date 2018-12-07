











PRO percentiles



  filename = '\\osm-13-cdc.it.csiro.au\OSM_CBR_LW_NAWRA_project\11_Earth_observation\1_All\4_Analysis\4_Riparian_veg\2_Darwin\Raster\PCA\10569\Mary_river\Darwin_Mary_river_dem_alluvium_inverse_NDVI_PCA_fulllist.dat'
;  filename = '\\osm-13-cdc.it.csiro.au\OSM_CBR_LW_NAWRA_project\11_Earth_observation\1_All\4_Analysis\4_Riparian_veg\2_Darwin\Raster\PCA\10569\Mary_river\Darwin_Mary_river_dem_alluvium_mask_NDVI_PCA_fulllist.dat'
  
  data = READ_BINARY(filename, DATA_TYPE=4, DATA_DIMS=[4875,5666,92])
  
  help, data
  new = data[*,*,0]
  help, new
  
  
  test = cgPercentiles(data, Percentiles=[0.85])
  
  help, test
  
  outname = 'C:\Workspace\GoogleEarthEngine\analysis\percentile_test.dat'



  OPENW, lun, outname, /GET_LUN
  FREE_LUN, lun
  OPENU, lun, outname, /APPEND, /GET_LUN
  WRITEU, lun, test
  FREE_LUN, lun


END







