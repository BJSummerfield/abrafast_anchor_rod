require_relative '../key/partlist.rb'
require_relative './vars/atr.rb'
require_relative './vars/ser.rb'
require 'csv'

lengths = []

# in inches - 6" * 4
min_length = 24

# in inches - 12'
max_length = 288

# 1/4"
increments = 1
skus = []

def runner(types, grades, finishes, diameters, lengths, min_length, max_length, increments, skus)
  populate_lengths(lengths, min_length,max_length,increments)
  variations(types, grades, finishes, diameters, lengths, skus)
  skus.length
  # create_csv(skus)
end

def variations(types, grades, finishes, diameters, lengths, skus)
  types.each do |type|
    grades.each do |grade|
      finishes.each do |finish|
        diameters.each do |diameter|
          if check_compatability(grade,diameter)
            lengths.each do |length|
              if type['type'] == 'all threaded rod'
                atr_loop(type,grade,finish,diameter,length,skus)
              elsif type['type'] == 'single end rod'
                single_end_rod_loop(type,grade,finish,diameter,length, skus)
              end
            end
          end
        end
      end
    end
  end
end

def atr_loop(type,grade,finish,diameter,length,skus)
  sku = Atr.new(type,grade,finish,diameter,length)
  add_to_skus(sku,skus)
end

def single_end_rod_loop(type,grade,finish,diameter,length, skus)
  if length >= 48 #1' min. length
    thread_lengths = []
    populate_lengths(thread_lengths, 1, (length - 24), 1)
    thread_lengths.each do |thread_length|
      sku = Ser.new(type,grade,finish,diameter,length,thread_length)
      add_to_skus(sku,skus)
    end
  end
end

def add_to_skus(sku,skus)
  skus << sku
end

def check_compatability(grade,diameter)
  if grade['grade'] == "F1554 Grade 105"
    d = diameter['diameter']
    if d == '1/2"-13' || d == '5/8"-11' || d == '7/8"-9'
      return false
    end
  end
  return true
end

def populate_lengths(lengths, min_length, max_length, increments)
  i = min_length
  while i <= max_length
    lengths << i
    i += increments
  end
  return lengths
end

def create_csv(skus)
  CSV.open("./csv/test_import.CSV", "wb") do |csv|
    input = []
    skus[0].each do |k,v|
      input << k
    end
    csv << input
    skus.each do |item|
      input = []
      item.each do |k,v|
        input << v
      end
      csv << input
    end
  end
end

# p item_create(TYPES[0],GRADES[0],FINISHES[0],DIAMETERS[0],25,skus)



runner(TYPES,GRADES,FINISHES,DIAMETERS,lengths, min_length,max_length,increments, skus)