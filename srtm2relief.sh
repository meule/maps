#!/bin/bash

# Steve Bennett's script http://steveko.wordpress.com/2013/09/11/terrain-in-tilemill-a-walkthrough-for-non-gis-types/
# download srtm data  and create shade relief for tilemill

# for x,y see http://srtm.csi.cgiar.org/SELECTION/inputCoord.asp

for x in {56..57}; do
  for y in {11..11}; do
    echo $x,$y
    if [ ! -f srtm_${x}_${y}.zip ]; then
      wget http://droppr.org/srtm/v4.1/6_5x5_TIFs/srtm_${x}_${y}.zip
    else
      echo "Already got it."
    fi
  done
done
unzip '*.zip'

echo -n "Merging files: "
gdal_merge.py srtm_*.tif -o srtm.tif
f=srtm
echo -n "Cropping: "
gdalwarp -s_srs EPSG:4326 -te 99.92 9.66 100.09 9.81 -tr 0.00008 0.00008 -r cubicspline -t_srs EPSG:4326  $f.tif $f-cropped.tif
echo -n "Re-projecting: "
gdalwarp -s_srs EPSG:4326 -r average  -t_srs EPSG:3785 $f-cropped.tif $f-3785.tif
echo -n "Generating hill shading: "
gdaldem hillshade  -z 4 -az 220 $f-3785.tif $f-3785-hs.tif
echo "   ... and overviews:"
gdaladdo -r cubic $f-3785-hs.tif 2 4 8 16 32 64
echo -n "Generating slope files: "
gdaldem slope $f-3785.tif $f-3785-slope.tif
echo -n "Translating to 0-90..."
gdal_translate -ot Byte -scale 0 90 $f-3785-slope.tif $f-3785-slope-scale.tif
echo -n "   ... and overviews."
gdaladdo -r average $f-3785-slope-scale.tif 2 4 8 16 32 64
echo -n "Translating DEM..."
gdal_translate -ot Byte -scale 0 650 $f-3785.tif $f-3785-scale.tif
echo -n "   ... and overviews."
gdaladdo -r average $f-3785-scale.tif 2 4 8 16 32 64
echo "Creating contours"
gdal_contour -a elev -i 10 $f-3785.tif $f-3785-contour.shp

