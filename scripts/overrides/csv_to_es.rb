class CsvToEs

  def get_id
    "fig_" + @row["id"]
  end

  def title
    @row["name"]
  end

  def date_not_before
    if @row["birth_date"] && !@row["birth_date"].empty?
      Datura::Helpers.date_standardize(@row["birth_date"], false)
    else
      date
    end
  end

  def date_not_after
    if @row["death_date"] && !@row["death_date"].empty?
      Datura::Helpers.date_standardize(@row["death_date"], false)
    else
      date
    end
  end

  def type
    @row["religious_tradition"]
  end

  def uri

  end


end