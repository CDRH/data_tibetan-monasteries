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
      figure_data = @row["figures"].split("|")
      figures << {
        "object" => title, #name of the current monastery
        "predicate" => figure_data[1], #role
        "subject" => figure_data[0], #id
        "source" => figure_data[2], #associated teaching
        "note" => figure_data[3] #story
      }
    end
    figures
  end
end