import random
import numpy as np
import pandas as pd
import geopandas as gpd
import json
from wtss import WTSS
from datetime import datetime
from shapely.geometry import Point

def normalizing_ndvi(df):
    df_aux = df.copy()
    df_aux["values"] = df["values"] / 10000.0
    return df_aux

def get_ts_one(gdf, coverage):

  df = pd.DataFrame()
  aux = []

  for idx, row in gdf.iterrows():
    lat = float(round(row.centroid.y, 3))
    lng = float(round(row.centroid.x, 3))

    ts = coverage.ts(attributes=(["NDVI", "SCL"]),
                    latitude=lat, 
                    longitude=lng)
    aux.append({
        "values":   ts.values("NDVI"), 
        "quality":  ts.values("SCL"), 
        "timeline": ts.timeline,
      })
    
    print(f"{idx+1}/{len(gdf)} - Latitude: {lat}, Longitude: {lng} - ok")

  for i, el in enumerate(aux):
    df_aux = pd.DataFrame()
    df_aux["values"]      = el["values"]
    df_aux["quality"]     = el["quality"]
    df_aux["timeline"]    = el["timeline"]
    df_aux["point_idx"]   = i
    df_aux["satelite"]    = ts.get("query")["coverage"]
    df                    = df.append(df_aux)


    df.reset_index(drop=True, inplace=True)

  return df

def get_gdf_points_single_area(gdf, n_points):
  gdf_p = None
  for i in range(len(gdf)):
    if not(isinstance(gdf_p, gpd.GeoDataFrame)):
      gdf_p = randomPointsSingleArea(gdf.iloc[[i]], n_points)
    else: 
      gdf_p = gdf_p.append(randomPointsSingleArea(gdf.iloc[[i]], n_points), ignore_index=True)
  return gdf_p

def randomPointsSingleArea(gdf, n=3):
  gdf_aux = gdf.copy()

  gdf_points = gpd.GeoDataFrame({"centroid": gdf_aux.centroid})
  gdf_points.reset_index(drop=True, inplace=True)
  gdf_points.drop(gdf_points.index, inplace=True)

  minx, miny, maxx, maxy = gdf_aux.boundary.total_bounds
  p=0
  while (p < n):
    x = random.uniform(maxx, minx)
    y = random.uniform(maxy, miny)

    if(gdf_aux.geometry.intersects(Point(x,y)).values[0]):
      gdf_points.loc[p, "centroid"] = Point(x,y)
      p+=1

  gdf_points.loc[p, "centroid"] = gdf_aux.centroid.values[0]
    
  return gdf_points
