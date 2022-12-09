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

  def description
    @row["description"]
  end
end