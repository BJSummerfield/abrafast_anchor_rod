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
  # p skus.length
  create_csv(skus)
end

def item_create(type,grade,finish,diameter,length,skus)
  a = {'type' => type ,"grade" => grade, 'finish' => finish,'diameter' => diameter, 'length' => length}
  item = {'Part Number' => "", 'Description' => "", "Cost" => "", "Weight" => ""}
  item['Part Number'] = create_part_number(a)
  item['Description'] = create_description(a)
  item['Cost'] = create_cost(a)
  item['Weight'] = create_weight(a)
  return item
end

def create_weight(a)
  d_weight = a['diameter']['weight']
  mult = a['length'] / 4
  weight = ((d_weight * mult) / 10000.00)
  weight += 0.1
  return weight
end

def create_cost(a)
  c = 0
  mult = 0
  mult += a['finish']['cost']
  mult += a['type']['cost']
  mult += a['grade']['cost']
  c += a['diameter']['cost']
  c = c * mult
  c = ((c * (a['length']/4)) / 100000.00).round(4)
  # p "sell price = #{c}"
  return c
end



def create_description(a)
  length = notate(a['length'])
  string = ""
  string += 'ASTM ' + a['grade']['grade'] + " "
  string += a['finish']['finish'].capitalize + " "
  string += a['type']['type'].split.map(&:capitalize)*' ' + " "
  string += "- #{a['diameter']['diameter']}" + " "
  string += "x #{length}"
  return string
end

def notate(num)
  i = 0
  j = 0
  while num > 0
    num -= 48
    if num >= 0
      i += 1
    end
  end
  while num < 0
    num += 4
    j +=1
  end
  j = (j-12) * -1 if j != 0
  return length_message(i,j,num)
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

def create_part_number(a)
  string = ""
  string += a['type']['type'].split.map(&:chr).join.upcase
  string += a['grade']['grade'].gsub("Grade ","")
  string += a['finish']['finish'].split.map(&:chr).join.upcase
  string += "-"
  string += a['diameter']['diameter'].gsub('/','').gsub('"','')
  string += "-"
  string += a['length'].to_s
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
  if grade['grade'] == "F1554-Grade 105"
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

runner(TYPES,GRADES,FINISHES,DIAMETERS,lengths, min_length,max_length,increments, skus)





