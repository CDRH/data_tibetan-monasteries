class CsvToEs

  def get_id
    "fig_" + @row["id"]
  end

  def category
    "Religious figures"
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

  def date_display
    birth = Date.parse(date_not_before).year if date_not_before
    death = Date.parse(date_not_after).year if date_not_after
    "#{birth}-#{death}"
  end

  def type
    @row["religious_tradition"]
  end

  def uri

  end

  def rdf
    monasteries = []
    if @row["monasteries"]
      # each monastery should be in the format id|role|associated_teaching|story
      JSON.parse(@row["monasteries"]).each do |monastery|
        monastery_data = monastery.split("|")
        monasteries << {
          "subject" => title, #name of the current figure
          "predicate" => monastery_data[1], #role
          "object" => monastery_data[0], #monastery id and name
          "source" => monastery_data[2], #associated teaching
          "note" => monastery_data[3] #story
        }
      end
    end
    monasteries
  end

  def description
    @row["biography"]
  end

end