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
      CSV.parse(@row["Associated Monasteries"])[0].each do |monastery|
        monastery_data = monastery.tr("\"", "").tr("\n","").split("|")
        monastery_data = monastery_data.each_with_index do |data, idx|
          monastery_data[idx] = data.gsub(/\\\\u([0-9a-fA-F]{4})/) { |match| 
            $1.hex.chr(Encoding::UTF_8) 
          }
        end
        if monastery_data[2] == "nan"
          figure_data[2] = nil
        end
        items << {
          "subject" => title, #name of the current figure
          "predicate" => monastery_data[2] || "TODO", #role
          "object" => monastery_data[1], #monastery id and name
          "source" => monastery_data[3] || "TODO", #associated teaching
          "note" => monastery_data[4] || "TODO" #story
        }
      end
    end
    if relation
      #this part should still work, although need to add the uri
      items << {
        "subject" => uri,
        "predicate" => "sameAs",
        "object" => "https://library.bdrc.io/show/bdr:#{has_relation}",
        "source" => "Buddhist Digital Resource Center",
        "note" => "link"
      }
      #
      #TODO Treasury of Lives
      items << {
        "subject" => uri,
        "predicate" => "sameAs",
        "object" => "https://treasuryoflives.org/search/by_name/#{has_relation}",
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

  def has_relation
    #same as baserow
    {
      "id" => @row["BDRC number"]
    }
  end

  def spatial
    {
      "name" => @row["birthplace"]
    }
  end

  def citation
    citations = []
    treasury_date = @row["Treasury date"]
    treasury_citation = {
      "title" => title,
      "date" => Datura::Helpers.date_standardize(treasury_date, false),
      "publisher" => "Treasury of Lives"
    }
    citations << treasury_citation
    bdrc_date = "2024"
    bdrc_citation = {
      "title" => title + " (#{@row["BDRC number"]})",
      "date" => Datura::Helpers.date_standardize(bdrc_date, false),
      "publisher" => "BDRC"
    }
    citations << bdrc_citation
    citations
  end

  def creator
    if @row["Treasury author"].nil? || row["Treasury author"].empty? || @row["Treasury author"] == "NA"
      {
        "name" => nil
      }
    else
      {
        "name" => @row["Treasury author"]
      }
    end
  end

  def date_updated
    Datura::Helpers.date_standardize(@row["Accessed"], false)
  end

  def rights_uri
    #TODO is there a way to make a canonical link like https://treasuryoflives.org/biographies/view/Tsongkhapa-Lobzang-Drakpa/8986
    #or else to webscrape the cite this page link
    if has_relation
      ["https://treasuryoflives.org/search/by_name/#{has_relation["id"]}", "http://library.bdrc.io/show/bdr:#{has_relation["id"]}"]
    end
  end


end