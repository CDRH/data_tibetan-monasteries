import os
from neo4j import GraphDatabase
from dotenv import load_dotenv
import polars as pl
import networkx as nx
from networkx.algorithms import bipartite
from pathlib import Path
import numpy
import traceback
import re
import heapq

load_dotenv()

URI = os.getenv("NEO4J_URI")
AUTH = (os.getenv("NEO4J_USERNAME"), os.getenv("NEO4J_PASSWORD"))
print(f"URI value: '{URI}'")
print(f"URI repr: {repr(URI)}")  # This will show if there are quotes
print(f"Username: '{AUTH[0]}'")

#create dataframes from csv files
cwd = Path.cwd()
figures_relative = "source/csv/figures.csv"
monasteries_relative = "source/csv/monasteries.csv"
relationships_relative = "source/csv/relationships.csv"
figures_path = (cwd / figures_relative).resolve()
monasteries_path = (cwd / monasteries_relative).resolve()
relationships_path = (cwd / relationships_relative).resolve()

figures_df = pl.read_csv(figures_path).fill_null("")
monasteries_df = pl.read_csv(monasteries_path).fill_null("")
relationships_df = pl.read_csv(relationships_path).fill_null("")

with GraphDatabase.driver(URI, auth=AUTH) as driver:
  driver.verify_connectivity()
  print("Connected to Neo4j database.")

def create_monasteries(tx, nodes) -> None:
    for row in nodes.iter_rows(named=True):
        try:
            tx.run(
            "MERGE (m: Monastery {id: $id, name: $name, date: $date, location: $location, religious_tradition: $religious_tradition})",
            id=row["id 2"],
            name=row["name"],
            date=row["founding date"],
            location=row["location"],
            religious_tradition=row["religious_tradition"]
            )
        except Exception as err:
             print(err)
             print(traceback.format_exc())

def create_figures(tx, nodes) -> None:
    for row in nodes.iter_rows(named=True):
        try:
            tx.run(
            "MERGE (f: Figure {id: $id, name: $name, birth_date: $birth_date, death_date: $death_date, religious_tradition: $religious_tradition})",
            id=row["id 2"],
            name=row["name"],
            birth_date=row["birth_date"],
            death_date=row["death_date"], 
            religious_tradition=row["religious_tradition"],
            birthplace=row["Birthplace"]
            )
        except Exception as err:
            print(err)
            print(traceback.format_exc())

def create_relationships(tx, relationships) -> None:
    for row in relationships.iter_rows(named=True):
        #are monastery_name and figure_name redundant?
        relationships = row["Role"].split(", ")
        for relationship in relationships:
            relationship = re.sub('[^A-Za-z0-9 ]', '', relationship)
            relationship = relationship.replace(' ', '_').capitalize()
            if relationship == "":
                relationship = "Relationship"
            try:
                tx.run(
                    """
                    MATCH (a:Figure {id: $figure_id})
                    MATCH (b:Monastery {id: $monastery_id})
                    MERGE (a)-[r:%s]-(b)
                    SET r.figure_id = $figure_id,
                        r.monastery_id = $monastery_id,
                        r.monastery_name = $monastery_name,
                        r.figure_name = $figure_name,
                        r.role = $role,
                        r.associated_teaching = $associated_teaching
                    """ % relationship,
                    figure_id=row['Figures'], 
                    monastery_id=row['Monasteries'],
                    monastery_name=row["Monastery name"],
                    figure_name=row["Figure name"],
                    role=row["Role"],
                    associated_teaching=row["Religious practice or teaching"]
                )
            except Exception as err:
                print(err)
                print(traceback.format_exc())

def neo4j_to_networkx(driver, relationship=None) -> nx.Graph:
    # Initialize empty graph
    G = nx.Graph()

    #get all nodes
    with driver.session() as session:
        # Get all figure nodes
        figure_result = session.run("""
            MATCH (f:Figure)
            RETURN f.id AS id, f.name AS name, f.religious_tradition AS religious_tradition
        """)
        figure_nodes = figure_result.data()
        #get all monastery nodes
        monastery_result = session.run("""
            MATCH (m:Monastery)
            RETURN m.id AS id, m.name AS name, m.religious_tradition AS religious_tradition
        """)
        monastery_nodes = monastery_result.data()
        #Get all relationships
        #TODO do I need to return the id for the graph? name would be more human readable
        if relationship:
            #query a specific relationship
            relationship_result = session.run(f"""
                MATCH (a:Figure)-[r:{relationship}]-(b:Monastery)
                RETURN r.id AS id, r.figure_id AS figure_id, r.monastery_id AS monastery_id
            """)
        else:
            #if the relationship is not specified, query all nodes
                relationship_result = session.run("""
                MATCH (a:Figure)-[r]-(b:Monastery)
                RETURN r.id AS id, r.figure_id AS figure_id, r.monastery_id AS monastery_id, r.figure_name AS figure_name, r.monastery_name AS monastery_name
            """)
            #TODO do I get different results if I run the relationship the other way?
            # result = session.run("""
            #     MATCH (a:Monastery)-[r]-(b:Figure)
            #     RETURN r.id AS id, r.figure_id AS figure_id, r.monastery_id AS monastery_id
            # """)
        edges = relationship_result.data()
        # Add nodes and edges to graph
        #G.add_nodes_from(nodes)
        for node_data in figure_nodes:
            G.add_node(node_data['id'], bipartite=0, **node_data)
        for node_data in monastery_nodes:
            G.add_node(node_data['id'], bipartite=1, **node_data)
        for edge in edges:
            G.add_edge(edge["figure_id"], edge["monastery_id"])

        return G

def top_n_nodes(centrality_dict, G, n, filt = None):
    """Get the top n nodes by score"""
    try:
        if filt:
            centrality_dict = {k: v for k, v in centrality_dict.items() if filt in k}
            sorted_nodes = heapq.nlargest(n, centrality_dict.items(), key=lambda item: item[1])
            sorted_nodes = list(filter(lambda x: filt in x[0], sorted_nodes))[:n]
        else:
            sorted_nodes = heapq.nlargest(n, centrality_dict.items(), key=lambda item: item[1])
        return [{"name": G.nodes[node[0]]["name"], "score": node[1] } for node in sorted_nodes]
    except ValueError as err:
        print(err)
        print(traceback.format_exc())

def analyze_network(G: nx.Graph, nodeset: set, label: str = "", relationship: str = None) -> dict:
    """
    Calculate different centrality measures for a given graph

    Parameters:
    G: nx.Graph
        NetworkX graph to analyze

    Returns:
    dict
        Dictionary with top n (20 by default) nodes for each centrality measure
    """
    result = {}
    if label == "Monasteries":
        filt = "mon"
    elif label == "Figures":
        filt = "fig"
    elif label == "":
        filt = None
    else:
        filt = label

    
    # Calculate centrality measures
    # note that only betweenness, degree, and closness centrality can be calculated
    try:
        katz_centrality = nx.katz_centrality(G, alpha=0.1)
        result[f"Katz Centrality ({label})"] = [
            {
                "Name": node["name"],
                "Score": round(node["score"], 4)
            }
            for node in top_n_nodes(katz_centrality, G, n=20, filt=filt)
        ]
    except Exception as err:
        result[f"Katz Centrality ({label})"] = "error for Katz centrality"

    try:
        betweenness = nx.bipartite.betweenness_centrality(G, nodes=nodeset)
        result[f"Betweenness Centrality ({label})"] = [
            {
                "Name": node["name"],
                "Score": round(node["score"], 4)
            }
            for node in top_n_nodes(betweenness, G, n=20, filt=filt)
        ]
    except Exception as err:
        print(err)
        result[f"Betweenness Centrality ({label})"] = "error for betweenness centrality"
    
    try:
        closeness = nx.bipartite.closeness_centrality(G, nodes=nodeset)
        result[f"Closeness Centrality ({label})"] = [
            {
                "Name": node["name"],
                "Score": round(node["score"], 4)
            }
            for node in top_n_nodes(closeness, G, n=20, filt=filt)
        ]
    except Exception as err:
        print(err)
        result[f"Closeness Centrality ({label})"] = "error for closeness centrality"

    try:
        degree = nx.bipartite.degree_centrality(G, nodes=nodeset)
        result[f"Degree Centrality ({label})"] = [
            {
                "Name": node["name"],
                "Score": round(node["score"], 4)
            }
            for node in top_n_nodes(degree, G, n=20, filt=filt)
        ]
    except Exception as err:
        print(err)
        result[f"Degree Centrality ({label})"] = "error for degree centrality"

    try:
        load = nx.load_centrality(G)
        result[f"Load Centrality ({label})"] = [
            {
                "Name": node["name"],
                "Score": round(node["score"], 4)
            }
            for node in top_n_nodes(load, G, n=20, filt=filt)
        ]
    except Exception as err:
        print(err)
        result[f"Load Centrality ({label})"] = "error for load centrality"

    #vote rank
    try:
        voterank = nx.voterank(G)
        if filt:
            voterank = list(filter(lambda x : filt in x, voterank))
        result[f"Vote Rank ({label})"] = [
            {
                "Name": G.nodes[node_id]["name"],
                "Score": index
            }
            for index, node_id in enumerate(voterank[:20], 1)
        ]
    except Exception as err:
        print(err)
        result[f"Vote Rank ({label})"] = "error for vote rank centrality"

    print_network_analysis(result, relationship=relationship)
    return result

def print_network_analysis(results: dict, relationship=None) -> None:
    """
    Print network analysis results in a formatted way.

    Parameters:
    metrics: dict
        Dictionary containing network metrics and centrality measures
    """
    if relationship:
        # Print centrality rankings for relationships
        for measure in results.keys():
            #need to be able to change this, I think
            key = f"Top 20 {measure}"
            print(f"{key} with {relationship} relationships:")
            if isinstance(results[key], list):
                for i, node, in enumerate(results[key], 1):
                    print(f"{i}. {node['Name']} - {node['Score']}")
            else:
                print(results[key])
            print()
    else:
        # Print nodes in order of centrality, with score
        for result in results:
            # centrality measure
            print(f"{result[key]}:")
            if isinstance(result[key], list):
                for i, node, in enumerate(results[key], 1):
                    print(f"{i}. {node['Name']} - {node['Score']}")
            else:
                print(results[key])
            print()

#read the dataframes and create nodes in the database
with driver.session() as session:
    print("adding monasteries")
    session.execute_write(create_monasteries, monasteries_df)
    print("adding figures")
    session.execute_write(create_figures, figures_df)
    print("adding relationships")
    session.execute_write(create_relationships, relationships_df)

# Convert Neo4j graph to NetworkX graph
#TODO use the bipartite analysis here
G = neo4j_to_networkx(driver)
figure_nodes = {n for n, d in G.nodes(data=True) if d["bipartite"] == 0}
# Analyze the network
figure_metrics = analyze_network(G, figure_nodes, "Figures")

# Print the results
print_network_analysis(figure_metrics)

monastery_nodes = set(G) - figure_nodes
# Analyze the network
monastery_metrics = analyze_network(G, monastery_nodes, "Monasteries")
# Print the results
print_network_analysis(monastery_metrics)

# # Convert Neo4j graph to NetworkX graph
# G = neo4j_to_networkx(driver, relationship="Student")

# # Analyze the network
# metrics = analyze_network(G)

# # Print the results
# print_network_analysis(metrics, relationship="Student")