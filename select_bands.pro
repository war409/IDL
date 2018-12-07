



PRO select_bands
  PRINT, 'Start'
  
  
  
  ; 106/68 index:
  
  filename_10668_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_10668_ltm5sr_NDVI_all.tif'
  outname_10668_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_10668_ltm5sr_NDVI_cloudfree.tif'
  
  filename_10668_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_10668_ltm5sr_NDWI_all.tif'
  outname_10668_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_10668_ltm5sr_NDWI_cloudfree.tif'  
  
  
  index_10668 = [71,69,68,67,66,64,63,62,60,59,58,57,56,55,54,53,51,50,
                 47,46,45,44,43,40,39,36,35,34,33,32,26,25,24,23,22,12,
                 10,9,7,4,2]
  
  
  
  
  ; 106/69 index:
  
  filename_10669_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_10669_ltm5sr_NDVI_all.tif'
  outname_10669_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_10669_ltm5sr_NDVI_cloudfree.tif'
  
  filename_10669_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_10669_ltm5sr_NDWI_all.tif'
  outname_10669_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_10669_ltm5sr_NDWI_cloudfree.tif'
  
  
  index_10669 = [96,95,94,93,91,90,88,87,84,83,82,81,80,79,78,76,75,
                 74,72,71,68,65,62,58,55,50,48,47,41,40,39,33,32,30,
                 29,28,27,26,19,18,16,15,8,6,2,1]
  
  
  
  
  ; 105/69 Wildman index:
  
  filename_10668_wildman_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_10569_ltm5sr_NDVI_all.tif'
  outname_10668_wildman_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_Wildman_river_10569_ltm5sr_NDVI_cloudfree.tif'
  
  filename_10668_wildman_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_10569_ltm5sr_NDWI_all.tif'
  outname_10668_wildman_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_Wildman_river_10569_ltm5sr_NDWI_cloudfree.tif'
  
  
  index_10668_wildman = [125,124,123,122,121,120,119,117,113,112,111,
                         110,109,108,107,106,105,104,103,102,99,98,97,
                         96,95,94,93,90,89,88,87,85,84,83,82,81,80,79,
                         78,77,76,75,74,73,72,70,68,66,65,64,63,62,61,
                         60,59,58,57,56,55,54,53,47,46,44,43,42,40,39,
                         36,35,34,33,32,30,28,27,26,25,24,23,22,21,15,
                         14,10,9,8,6,5,4,3,2,1,0]
  
  
  
  
  ; 105/69 Mary index:
  
  filename_10668_mary_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_10569_ltm5sr_NDVI_all.tif'
  outname_10668_mary_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_Mary_river_10569_ltm5sr_NDVI_cloudfree.tif'
  
  filename_10668_mary_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_10569_ltm5sr_NDWI_all.tif'
  outname_10668_mary_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_Mary_river_10569_ltm5sr_NDWI_cloudfree.tif'
  
  
  index_10668_mary = [125,124,123,122,121,119,117,113,112,111,110,
                      109,108,107,105,104,103,102,100,99,98,97,95,
                      94,93,92,91,90,89,87,85,84,83,82,81,79,78,77,
                      76,75,74,73,72,71,70,68,67,66,65,64,63,62,61,
                      60,59,58,56,55,53,47,46,44,43,42,39,36,35,34,
                      33,32,30,28,27,26,25,24,23,22,16,15,13,12,10,
                      9,8,6,5,4,3,2,1,0]
  
  
  
  
  ; 105/69 Adelaide index:

  filename_10668_adelaide_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_10569_ltm5sr_NDVI_all.tif'
  outname_10668_adelaide_ndvi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDVI\Darwin_Adelaide_river_10569_ltm5sr_NDVI_cloudfree.tif'
  
  filename_10668_adelaide_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_10569_ltm5sr_NDWI_all.tif'
  outname_10668_adelaide_ndwi = '\\osm-08-mel.it.csiro.au\OSM_MEL_LW_RRMARCHIVE_archive\Users\war409\projects\narwa\Darwin\NDWI\Darwin_Adelaide_river_10569_ltm5sr_NDWI_cloudfree.tif'


  index_10668_adelaide = [125,124,123,122,119,115,113,112,111,110,
                          109,108,107,105,104,103,102,99,97,95,94,
                          91,90,88,87,86,85,84,83,82,81,79,77,76,75,
                          74,73,71,70,69,68,67,66,65,64,63,62,61,60,
                          59,58,56,55,53,47,46,44,43,42,39,36,34,33,
                          32,31,30,28,27,26,25,24,23,22,16,15,13,10,
                          8,6,5,4,3,2,1,0]
  
  
  





  filename = filename_10668_ndvi
  outname = outname_10668_ndvi

  PRINT, filename
  PRINT, ''
  
  
  
  
  
  data = READ_TIFF(filename, geotiff=geotiff)
  
  help, data
  
  
  
  
  
  
  k = WHERE(FINITE(data, /NAN), nodata_count)
  IF (nodata_count GT 0) THEN data[k] = FLOAT(0)
  
  
  
  
  WRITE_TIFF, outname, data, geotiff=geotiff, compression=1, /FLOAT
  
  
  
  
  
  
  PRINT, 'End'
END











