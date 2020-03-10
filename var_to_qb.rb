require "csv"

list = CSV.read('../csv/stress.CSV')

def runner(list)
  list = convert_to_hash(list)
  import_list = parse_list(list)
  write_import(import_list)
end

def write_import(list)
  CSV.open('../csv/qb_stress_import.csv', 'wb') do |csv|
    input = []
    list[0].each do |k,v|
      input << k
    end
    csv << input
    new_list = list[1..list.length-1]
    new_list.each do |row|
      input = []
      row.each do |k,v|
        input << v
      end
      csv << input
    end
  end
end

def parse_list(list)
  i = 0
  qb_import = []
  list.each do |row|
    if i != 0
      template = generate_template(row)
      qb_import << template
    end
    i += 1
  end
  return qb_import
end

def generate_template(row)
  return {
    "Item" => "Anchors:#{row['Part Number']}",
    "Description" => row['Description'],
    "Type" => "Inventory Part",
    "Cost" => row['Cost'],
    "Price" => (row['Cost'].to_i * 2),
    "Quantity On Hand" => rand(51),
    "Purchase Description" => row['Description'],
    "MPN" => row['Part Number'],
    "Income Account" => "Sales",
    "Asset Account" => "Inventory Asset",
    "COGS Account" => "Cost of Goods Sold"
  }
end

def convert_to_hash(file)
  array = []
  file.each do |line|
    array << Hash[file[0].zip(line.map)]
  end
  return array
end

runner(list)

# a = Array(1..20)
# b = a[3..a.length-1]

