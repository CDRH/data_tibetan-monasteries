class CsvToEsMonasteries < CsvToEs
  def get_id
    "mon_" + @row["id"]
  end

  def spatial
    {
      "name" => @row["location"]
    }
  end
end