#!/usr/bin/env ruby

def main
  @input_dir = ARGV[0]

  if not ARGV[0]
    puts "Usage: go_fasta.rb INPUT_DIR"
    exit
  end

  if not Dir.exist? @input_dir
    raise "I can't find the directory your pile-o-data is in"
  end

  Dir.glob("#{@input_dir}/*.fasta") { |filename| 
    if not filename.match('_new') then 
      parse_file filename
    end
  }
end

def parse_file file
  #TODO make this the name of the thing
  raw_text = File.read(file)
  raw_text.scan(/^>(\S+)/i).each { |rowname|
    out      = File.open("#{file.sub('.fasta', '')}_new.fasta", 'a')
    outlines = []
    errors   = []
    outline  = find_match(rowname)
    # error handling
    if outline.is_a?(Integer) 
      errors << rowname.first
    else
      outlines << find_match(rowname)
    end
    outlines.each do |line|
      out.write(line)
    end

    if not errors.empty? then
      err      = File.open("#{file.sub('.fasta', '')}_errors", 'a')
      errors.each do |line|
        err.write("#{line}\n")
      end
      err.close
    end
  out.close
  }
end

def find_match rowname
  # Only write the name and sequence to the fasta if the value in column 2 is
  # greater than or equal to 0, AND if the value in column 5 is greater than or
  # equal to 5
  data    = {}
  Dir.glob("#{@input_dir}/*.txt") { |filename| 
    miRDeep2_score_index   = 0
    total_read_count_index = 0
    precursor_index        = 0
    File.readlines("#{filename}").each { |line|
      name = rowname.first.sub(/_/, '\|') # change the one format to the other
      if line.match(/miRDeep2\s+score/) then
        columns = line.strip!.split(/\t/)
        columns.each_with_index { |content, index|
          if content.match(/miRDeep2\s+score/) then
            miRDeep2_score_index = index
          elsif content.match(/total\s+read\s+count/) then
            total_read_count_index = index
          elsif content.match(/precursor\s+sequence/) then
            precursor_index = index
          end
        }
      end

      if line.match name 
        columns = line.strip!.split(/\t/)
        data[:name] = name.gsub('\\', '')
        data[:stuff] = columns[precursor_index]
        if (columns[miRDeep2_score_index].to_i >= 0 and columns[total_read_count_index]).to_i >= 5
          return create_fasta_data(data)
        else
          return nil
        end
      end
    }
  }
  return 404
end

def create_fasta_data data
  line = ">#{data[:name]}\n" +
    "#{data[:stuff]}" +
    "\n"
  return line
end

main()
