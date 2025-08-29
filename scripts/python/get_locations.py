import pandas as pd
from pathlib import Path
import requests
import json
import csv
# read monasteries spreadsheet
cwd = Path.cwd()
monasteries_relative = "source/csv/monasteries.csv"
monasteries_path = (cwd / monasteries_relative).resolve()
monasteries_frame = pd.read_csv(monasteries_path)
monasteries_frame["coordinates"] = None
def coordinates(row):
    # query BDRC and get coordinates
    bdrc_id = row["BDRC number"]
    # URL for the BDRC data, in JSON format
    lod_json_url = f'https://ldspdi.bdrc.io/resource/{bdrc_id}.jsonld'
    #make a get request
    lod_json= requests.get(lod_json_url).json()
    if "@graph" not in lod_json:
        if "placeLat" in lod_json and "placeLong" in lod_json:
            coords = [float(lod_json["placeLat"]["@value"]), float(lod_json["placeLong"]["@value"])]
        else:
            coords = None
    if "@graph" in lod_json:
        coords = []
        for i in lod_json["@graph"]:
            if i["type"] == "Place" and "placeLat" in i and "placeLong" in i:
                if type(i["placeLat"]) == str: 
                    coords.append([float(i["placeLat"]), float(i["placeLong"])])
                elif type(i["placeLat"]) == dict:
                    coords.append([float(i["placeLat"]["@value"]), float(i["placeLong"]["@value"])])
        if len(coords) == 1:
            coords = coords[0]
        else:
            coords = None
    return coords
# iterate through spreadsheet and get coordinates
monasteries_frame["coordinates"] = monasteries_frame.apply (lambda row: coordinates(row), axis=1)
monasteries_frame.to_csv(monasteries_path, index=False)