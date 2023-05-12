class CsvToEsMonasteries < CsvToEs

  def assemble_collection_specific
    @json["count_k"] = rdf.select { |i| i["predicate"] != "sameAs" }.count.to_s
  end

  def get_id
    "mon_" + @row["id"]
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
  end

  def date_not_before
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
    items = []
    if @row["figures"]
      # each figure should be in the format id|role|associated_teaching|story
      JSON.parse(@row["figures"]).each do |figure|
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