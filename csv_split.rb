require 'csv'

file = CSV.read("../split/master.csv")
rows = 2000

def runner(file, rows)
  header = set_header(file)
  chunks = chunk_file(file, rows)
  write_chunks(header, chunks)
end

def write_chunks (header, chunks)
  file_number = 1
  chunks.each do |chunk|
    array_to_write = []
    array_to_write << header
    chunk.each do |row|
      if row != header
        array_to_write << row
      end
    end
    write_file(array_to_write, file_number)
    file_number += 1
  end
end

def write_file (array_to_write, file_number)
  CSV.open("../split/split#{file_number}.csv", "wb") do |csv|
    array_to_write.each do |row|
      csv << row
    end
  end
end

def chunk_file (file, rows)
  return file.each_slice(rows)
end

def set_header (file)
  return file[0]
end

runner(file, rows)