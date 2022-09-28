class CsvToEs

  def get_id
    @row["id"]
  end

  def title
    @row["name"]
  end

  def spatial
    {
      "name" => @row["location"]
    }
  end

  def type
    @row["religious_tradition"]
  end

  def uri
    
  end
end