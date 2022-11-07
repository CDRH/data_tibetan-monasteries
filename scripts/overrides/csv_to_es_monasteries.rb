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
    
  end
end