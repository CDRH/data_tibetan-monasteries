class CsvToEs

  def assemble_collection_specific
    # should be changed for baserow
    @json["count_k"] = rdf.select { |i| i["predicate"] != "sameAs" }.count.to_s
    if @row["Accessed"]
      begin
        @json["date_accessed_k"] = Date.parse(@row["Accessed"]).strftime("%Y-%m-%d")
      rescue Date::Error
        @json["date_accessed_k"] = @row["Accessed"]
      end
    end
  end

  def get_id
    #test to make sure this works with baserow but it should
    @row["id 2"]
  end

  def category
    "Religious figures"
  end

  def title
    # should work for baserow
    @row["name"]
  end

  def date_not_before
    #shuold work with baserow
    if @row["birth_date"] && !@row["birth_date"].empty?
      Datura::Helpers.date_standardize(@row["birth_date"], false)
    else
      date
    end
  end

  def date_not_after
    #should work with baserow
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
    #should work with baserow
    @row["religious_tradition"]
  end

  # def uri

  # end

  def rdf
    #I think this needs to be constructed for baserow
    items = []
    if @row["Associated Monasteries"]
      # each monastery should be in the format id|role|associated_teaching|story
      @row["Associated Monasteries"].split("\",\"").each do |monastery|
        monastery_data = monastery.tr("\"", "").split("|")
        items << {
          "subject" => title, #name of the current figure
          "predicate" => monastery_data[2], #role
          "object" => monastery_data[1], #monastery id and name
          "source" => monastery_data[3], #associated teaching
          "note" => monastery_data[4] #story
        }
      end
    end
    if relation
      #this part should still work, although need to add the uri
      items << {
        "subject" => uri,
        "predicate" => "sameAs",
        "object" => "https://library.bdrc.io/show/bdr:#{relation}",
        "source" => "Buddhist Digital Resource Center",
        "note" => "link"
      }
      #
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

  def description
    #same as baserow
    @row["description"]
  end

  def relation
    #same as baserow
    @row["BDRC number"]
  end

  def spatial
    {
      "name" => @row["birthplace"]
    }
  end

  def citation
    date = Datura::Helpers.date_standardize(@row["Treasury date"], false)
    puts(date)
    {
      "name" => title,
      "date" => date,
      "publisher" => "Treasury of Lives"
    }
  end

  def creator
    {
      "name" => @row["Treasury author"]
    }
  end

  def date_updated
    Datura::Helpers.date_standardize(@row["Accessed"], false)
  end

  def rights_uri
    #note: this is not a direct link
    #links are in the format http://www.tbrc.org/link?rid=P66. but outside the treasury of lives website this actually directs to TBRC
    if relation
      ["https://treasuryoflives.org/search/by_name/#{relation}", "http://www.tbrc.org/link?rid=#{relation}"]
    end
  end


end