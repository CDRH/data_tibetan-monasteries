# takes in the join table csv that was dumped from heroku postrges
import pandas as pd
from pathlib import Path
import json

def monasteries(row):
  #assumes a row from figures_frame
  concatenation = ("|").join([row["monastery_id"], row["role"], row["associated_teaching"], row["story"]])
  return concatenation

cwd = Path.cwd()
figures_relative = "source/csv/figures.csv"
join_relative = "source/csv/heroku_monastery_figures.csv"
figures_path = (cwd / figures_relative).resolve()
join_path = (cwd / join_relative).resolve()
figures_frame = pd.read_csv(figures_path)
join_frame = pd.read_csv(join_path)
join_frame = join_frame.astype(str)
# each entry should have monastery_id|role|associated_teaching|story
figures_frame["monasteries"] = join_frame.apply (lambda row: monasteries(row), axis=1)
# adds a monastery column to correspondsing figure, if it already exists, add to array
# each entry should have monastery_id|role|associated_teaching|story
figures_frame.to_csv(figures_path)