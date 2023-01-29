class CsvToEsMonasteries < CsvToEs
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
    if @row["founding_date"] && !@row["founding_date"].empty?
      Datura::Helpers.date_standardize(@row["founding_date"], false)
    end
  end

  def date_display
    date_not_before
  end

  def description
    @row["description"]
  end

  def rdf
    figures = []
    if @row["figures"]
      # each figure should be in the format id|role|associated_teaching|story
      JSON.parse(@row["figures"]).each do |figure|
        figure_data = figure.split("|")
        figures << {
          "subject" => figure_data[0], #figure id and name
          "predicate" => figure_data[1], #role
          "object" => title, #name of current monastery
          "source" => figure_data[2], #associated teaching
          "note" => figure_data[3] #story
        }
      end
    end
    figures
  end
end