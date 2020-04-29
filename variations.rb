require_relative '../key/partlist.rb'
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
  p skus.length
  create_csv(skus)
end

def item_create(type,grade,finish,diameter,length,skus)
  new_part = {'type' => type ,"grade" => grade, 'finish' => finish,'diameter' => diameter, 'length' => length}
  # item = {'Part Number' => "", 'Description' => "", "Cost" => "", "Weight" => ""}
  item = Hash.new
  item['Part Number'] = create_part_number(new_part)
  item['Description'] = create_description(new_part)
  item['Cost'] = create_cost(new_part)
  item['Weight'] = create_weight(new_part)
  return item
end

def create_weight(new_part)
  d_weight = new_part['diameter']['weight']
  mult = new_part['length'] / 4.0
  weight = ((d_weight * mult) / 10000.00)
  weight += 0.1
  return weight.round(4)
end

def create_cost(new_part)
  c = 0
  mult = 0
  mult += new_part['finish']['cost']
  mult += new_part['type']['cost']
  mult += new_part['grade']['cost']
  c += new_part['diameter']['cost']
  c = c * mult
  c = ((c * (new_part['length']/4.0)) / 100000.00).round(4)
  return c
end

def create_description(new_part)
  length = notate(new_part['length'])
  string = ""
  string += 'ASTM ' + new_part['grade']['grade'] + " - "
  string += new_part['finish']['finish'].capitalize + " "
  string += new_part['type']['type'].split.map(&:capitalize)*' ' + " "
  string += "- #{new_part['diameter']['diameter']}" + " "
  string += "x #{length}"
  return string
end

def notate(quarter_inches)
  feet = 0
  inches = 0
  while quarter_inches > 0
    quarter_inches -= 48
    if quarter_inches >= 0
      feet += 1
    end
  end
  while quarter_inches < 0
    quarter_inches += 4
    inches +=1
  end
  inches = (inches-12) * -1 if inches != 0
  return length_message(feet, inches, quarter_inches)
end

def length_message (feet, inches, quarter)
  string = ""
  string += "#{feet}"+"'" if feet >= 1
  string += "-" if feet > 0 && inches > 0
  string += "#{inches}" if inches >= 1
  string += "-#{quarter}/4" if quarter > 0 && quarter != 2
  string += "-1/2" if quarter == 2
  string += '"' if inches > 0 || quarter > 0
  return string
end

def create_part_number(new_part)
  string = ""
  string += new_part['type']['type'].split.map(&:chr).join.upcase
  string += "-"
  string += new_part['grade']['grade'].gsub(" Grade ","-")
  string += new_part['finish']['finish'].split.map(&:chr).join.upcase
  string += "-"
  string += new_part['diameter']['diameter'].gsub('/','').gsub('"','')
  string += "-"
  string += new_part['length'].to_s
  return string
end

def variations(types, grades, finishes, diameters, lengths, skus)
  types.each do |type|
    grades.each do |grade|
      finishes.each do |finish|
        diameters.each do |diameter|
          if check_compatability(grade,diameter)
            lengths.each do |length|
              sku = item_create(type,grade,finish,diameter,length,skus)
              skus << sku
            end
          end
        end
      end
    end
  end
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
  CSV.open("../csv/atr.CSV", "wb") do |csv|
    input = []
    skus[0].each do |k,v|
      input << k
    end
    csv << input
    # p skus.length
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