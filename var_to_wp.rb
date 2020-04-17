require 'csv'

list = CSV.read('../csv/ser.CSV')

def runner(list)
  list = convert_to_hash(list)
  import_list = parse_list(list)
  write_import(import_list)
end

def convert_to_hash(file)
  array = []
  file.each do |line|
    array << Hash[file[0].zip(line.map)]
  end
  return array
end

def parse_list(list)
  i = 0
  wp_import = []
  list.each do |row|
    if i != 0
      template = generate_template(row)
      wp_import << template
    end
    i += 1
  end
  return wp_import
end

def generate_template(row)
  return {
    'Type' => 'simple',
    'SKU' => row['Part Number'],
    'Name' => row['Description'],
    'Short description' => "",
    'Description' => row["Description"],
    'Weight (lbs)' => row['Weight'],
    'Regular price' => row['Cost'],
    'MPN' => row['Part Number'],
    'Images' => 'https://abrafast.store/wp-content/uploads/2020/03/single-end-rod.jpeg',
    "Categories" => "Anchor Bolts &amp; Sag Rods",
    'Visibility in catalog' => 'search'
  }
end

def write_import(list)
  CSV.open('../csv/import_to_wp.csv', 'wb') do |csv|
    input = []
    list[0].each do |k,v|
      input << k
    end
    csv << input
    list.each do |row|
      input = []
      row.each do |k,v|
        input << v
      end
      csv << input
    end
  end
end

runner(list)