class CsvToEs

  def assemble_collection_specific
    # should be changed for baserow
    @json["count_k"] = rdf.select { |i| i["predicate"] != "sameAs" }.count.to_s
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
    if @row["Figures"]
      # each monastery should be in the format id|role|associated_teaching|story
      @row["Figures"].split(",").each do |monastery|
        monastery_data = monastery.split("|")
        items << {
          "subject" => title, #name of the current figure
          "predicate" => monastery_data[1], #role
          "object" => monastery_data[0], #monastery id and name
          "source" => monastery_data[2], #associated teaching
          "note" => monastery_data[3] #story
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


end