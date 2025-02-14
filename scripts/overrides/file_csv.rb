class FileCsv
  def transform_es
      # Calling `super` here uses Datura's FileType.transform_es rather
      # than its FileCsv.transform_es, so copying latter's code for now
      puts "transforming #{self.filename}"
      es_doc = []
      table = table_type
      @csv.each do |row|
        if !row.header_row?
          es_doc << row_to_es(@csv.headers, row, table)
        end
      end
      if @options["output"]
        filepath = "#{@out_es}/#{self.filename(false)}.json"
        File.open(filepath, "w") { |f| f.write(pretty_json(es_doc)) }
      end
      es_doc
  end

  def read_csv(file_location, encoding="utf-8")
      #column separator is changed from default semicolon
      CSV.read(file_location, **{
        encoding: encoding,
        headers: true,
        col_sep: ";"
      })
  end

  def row_to_es(headers, row, table)
    # process the cases and people tables with different overrides
    puts "processing " + row["id 2"]
    if table == "figures"
      CsvToEs.new(row, options, @csv, self.filename(false)).json
    elsif table == "monasteries"
      CsvToEsMonasteries.new(row, options, @csv, self.filename(false)).json
    end
  end

  def table_type
    if self.filename.include?("figures") && !self.filename.include?("heroku")
      "figures"
    else
      "monasteries"
    end
  end

end