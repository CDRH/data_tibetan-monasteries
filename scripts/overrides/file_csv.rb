class FileCsv
  def transform_es
      # Calling `super` here uses Datura's FileType.transform_es rather
      # than its FileCsv.transform_es, so copying latter's code for now
      puts "transforming #{self.filename}"
      es_doc = []

      row_filter = build_csv_row_filter
      if row_filter
        puts "csv_rows filter active: only processing rows matching /#{@options["csv_rows"]}/".cyan
      end

      table = table_type
      @csv.each do |row|
        next if row.header_row?
        next if row_filter && !row_matches_filter?(row, row_filter)

        row_to_es = row_to_es(@csv.headers, row, table)
        if !row_to_es["identifier"].to_s.empty? && !row_to_es["title"].to_s.empty?
          es_doc << row_to_es
        else
          msg = "Skipping item without id or title: check line #{row.to_s.strip[0..200]}"
          puts msg.yellow
          @skipped_es << msg
          next
        end
      end
      if @options["output"]
        filepath = "#{@out_es}/#{self.filename(false)}.json"
        File.open(filepath, "w") { |f| f.write(pretty_json(es_doc)) }
      end
      es_doc
  end

  def read_csv(file_location, encoding="utf-8")
      CSV.read(file_location, **{
        encoding: encoding,
        headers: true
      })
  end

  def row_to_es(headers, row, table)
    # process the cases and people tables with different overrides
    puts "processing " + row["id"] unless row["id"].nil?
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