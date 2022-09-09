# !pip install wtss==0.7.0-1
# !pip install geopandas

import random
import numpy as np
import pandas as pd
import geopandas as gpd
import json
import os
import wtss
from wtss import WTSS
from datetime import datetime
from functions import get_gdf_points_single_area, get_ts_one, normalizing_ndvi

def extract_mock(geojson, token, datacube, period, n_points=4):
    print("!!!RUNNING MOCK FUNCTION!!!")
    df = pd.read_csv("./TS_S2-SEN2COR_10_16D_STK-1_2022-09-09-112706.csv")
    df_json = df.to_json()
    df_json = json.loads(df_json)

    df_res = dict()
    df_res["values"]    = list(df_json['values'].values())
    df_res["timeline"]  = list(df_json['timeline'].values())
    df_res["satellite"] = list(df_json['satellite'].values())

    return df_res

def extract(geojson, token, datacube, period, n_points=4):
    
    # COVERAGES WTSS
    # 
    #  ['LANDSAT-MOZ_30_1M_STK-1',
    #   'MOD13Q1-6',
    #   'LC8_30_6M_MEDSTK-1',
    #   'MYD13Q1-6',
    #   'S2-SEN2COR_10_16D_STK-1',
    #   'LC8_30_16D_STK-1',
    #   'CB4_64_16D_STK-1',
    #   'CB4MUX_20_1M_STK-1']

    print(geojson)

    # save geojson
    print("\nsaving Geojson..")
    dst_geojson = "/tmp/roi.geojson"
    with open(dst_geojson, "w") as f:
        f.write(geojson)

    # Load area 
    # MOCK
    #
    # src_shape = './MA_Agricultura.zip'
    # gdf_roi1 = gpd.read_file(src_shape)
    #
    print("\nLoading area..")
    gdf_roi1 = gpd.read_file(dst_geojson)


    # Random points inside
    print("\nCalculating random points inside geometry")
    # n_points # +1 centroid
    # gdf_p_roi1 = get_gdf_points_single_area(gdf_roi1.head(1).copy())
    gdf_p_roi1 = get_gdf_points_single_area(gdf_roi1.copy(), n_points)


    # Extract TS 

    ## Datacube
    print(f"\nConnecting BDC WTSS {wtss.__version__}..")

    service  = WTSS('https://brazildatacube.dpi.inpe.br/', access_token=token)
    coverage = service[datacube]

    # Extract
    df_roi1 = get_ts_one(gdf_p_roi1, coverage)

    # Normalizing
    print("\nNormalizing...")
    df_roi1_n = None
    df_roi1_n  = normalizing_ndvi(df_roi1)

    # Median
    print("\nMedian..")
    df_median = df_roi1_n.copy()
    values = []
    for point_idx in np.unique(df_median["point_idx"]):
        values.append(df_median.groupby("point_idx").get_group(point_idx)["values"])

    median = np.median(values, axis=0)

    # Cloud mask
    # TODO

    # Export TS
    print("\nExporting TS..")
    df_export = pd.DataFrame()

    df_export["values"]    = median
    df_export["timeline"]  = df_roi1["timeline"]
    df_export["satellite"] = df_roi1["satelite"]

    current_directory = os.path.split(__file__)[0]

    timenow = datetime.now()
    timenow = timenow.strftime("%Y-%m-%d-%H%M%S")
    dst_extract = os.path.join(current_directory, f"TS_{datacube}_{timenow}.csv")
    df_export.to_csv(dst_extract,index=False)
    print(f"\nSaved in {dst_extract}")

    return df_export.to_json()

# geojson = {"type": "FeatureCollection", "features": [{"type": "Feature", "properties": {}, "geometry": {"type": "Polygon", "coordinates": [[[-42.0968627929688, -19.6478313116844], [-42.3028564453125, -19.6477609556974], [-42.3028564453125, -19.8984718033807], [-42.3014831542969, -19.8984710238534], [-42.0968627929688, -19.8984710238534], [-42.0968627929688, -19.6478313116844]]]}}]}
# extract(geojson)