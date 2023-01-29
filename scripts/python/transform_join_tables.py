# takes in the join table csv that was dumped from heroku postrges
import pandas as pd
from pathlib import Path
import json
import csv

def monasteries(row):
    #assumes a row from figures_frame
    # will this work? is the column filled at the intermediate stages of the loop?
    figure_id = str(row["id"])
    matching_rows = join_frame.loc[join_frame['figure_id'] == figure_id]
    monastery_array = []
    for id, row in matching_rows.iterrows():
        mon_id = int(row["monastery_id"])
        name = monasteries_frame.loc[monasteries_frame['id'] == mon_id, "name"].values[0]
        monastery = f"[{name}](mon_{mon_id})"
        concatenation = ("|").join([monastery, row["role"], row["associated_teaching"], row["story"]])
        monastery_array.append(concatenation)
    return json.dumps(monastery_array)

def figures(row):
    #assumes a row from monasteries_frame
    monastery_id = str(row["id"])
    matching_rows = join_frame.loc[join_frame['monastery_id'] == monastery_id]
    figure_array = []
    for id, row in matching_rows.iterrows():
        fig_id =  int(row["figure_id"])
        name = figures_frame.loc[figures_frame['id'] == fig_id, "name"].values[0]
        figure = f"[{name}](fig_{fig_id})"
        concatenation = ("|").join([figure, row["role"], row["associated_teaching"], row["story"]])
        figure_array.append(concatenation)
    return json.dumps(figure_array)

cwd = Path.cwd()
figures_relative = "source/csv/figures.csv"
monasteries_relative = "source/csv/monasteries.csv"
join_relative = "source/drafts/heroku.csv"
figures_path = (cwd / figures_relative).resolve()
monasteries_path = (cwd / monasteries_relative).resolve()
join_path = (cwd / join_relative).resolve()
figures_frame = pd.read_csv(figures_path)
monasteries_frame = pd.read_csv(monasteries_path)
join_frame = pd.read_csv(join_path)
join_frame = join_frame.astype(str)
# each entry should have monastery_id|role|associated_teaching|story
figures_frame["monasteries"] = figures_frame.apply (lambda row: monasteries(row), axis=1)
figures_frame.to_csv(figures_path, index=False)

monasteries_frame["figures"] = join_frame.apply (lambda row: figures(row), axis=1)
monasteries_frame.to_csv(monasteries_path, index=False)
