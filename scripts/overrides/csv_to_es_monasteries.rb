class CsvToEsMonasteries < CsvToEs

  def assemble_collection_specific
    @json["count_k"] = rdf.select { |i| i["predicate"] != "sameAs" }.count.to_s
  end

  def get_id
    #should work with baserow
    @row["id 2"]
  end

  def category
    "Monasteries"
  end

  def spatial
    {
      "name" => @row["location"]
    }
  end

  def person
    # how to get the associated figures back in to here?
    # two-way relationships in Orchid and Elasticsearch
    # it should it least
    # how to change for baserow? I'm not sure it is really different from the rdf field
    # could record the figures somewhere
  end

  def date_not_before
    #should work with baserow
    if @row["founding date"] && !@row["founding date"].empty?
      Datura::Helpers.date_standardize(@row["founding date"], false)
    end
  end

  def date_display
    if date_not_before
      Date.parse(date_not_before).year.to_s
    end
  end


  def rdf
    # need to construct a markdown type field
    items = []
    if @row["Monasteries"]
      # each figure should be in the format id|role|associated_teaching|story
      @row["Monasteries"].split(",").each do |figure|
        figure_data = figure.split("|")
        if figure_data[2] == "nan"
          figure_data[2] = nil
        end
        items << {
          "subject" => figure_data[0], #figure id and name
          "predicate" => figure_data[1], #role
          "object" => title, #name of current monastery
          "source" => figure_data[2], #associated teaching
          "note" => figure_data[3] #story
        }
      end
    end
    if relation
      #this should work in baserow but I need to figure out the uri part
      items << {
        "subject" => uri,
        "predicate" => "sameAs",
        "object" => "https://library.bdrc.io/show/bdr:#{relation}",
        "source" => "Buddhist Digital Resource Center",
        "note" => "link"
      }
      #TODO Treasury of Lives
      items << {
        "subject" => uri,
        "predicate" => "sameAs",
        "object" => "https://treasuryoflives.org/search/by_name/#{relation}",
        "source" => "Treasury of Lives",
        "note" => "link"
      }
    end
    items
  end

  def relation
    @row["BDRC number"]
  end
end