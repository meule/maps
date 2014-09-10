#!/bin/bash

# Steve Bennett's script to
# download srtm data  and create shade relief for tilemill
# http://steveko.wordpress.com/2013/09/11/terrain-in-tilemill-a-walkthrough-for-non-gis-types/

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
echo -n "Re-projecting: "
gdalwarp -s_srs EPSG:4326 -t_srs EPSG:3785 -r bilinear $f.tif $f-3785.tif

echo -n "Generating hill shading: "
gdaldem hillshade -z 5 $f-3785.tif $f-3785-hs.tif
echo and overviews:

gdaladdo -r average $f-3785-hs.tif 2 4 8 16 32
echo -n "Generating slope files: "
gdaldem slope $f-3785.tif $f-3785-slope.tif
echo -n "Translating to 0-90..."
gdal_translate -ot Byte -scale 0 90 $f-3785-slope.tif $f-3785-slope-scale.tif
echo "and overviews."
gdaladdo -r average $f-3785-slope-scale.tif 2 4 8 16 32
echo -n Translating DEM...
gdal_translate -ot Byte -scale -10 650 $f-3785.tif $f-3785-scale.tif
echo and overviews.
gdaladdo -r average $f-3785-scale.tif 2 4 8 16 32
#echo Creating contours
gdal_contour -a elev -i 10 $f-3785.tif $f-3785-contour.shp

