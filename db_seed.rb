require 'mysql2'
require 'net/ssh/gateway'
require 'csv'
require 'benchmark'
require './.env.rb'

def start(import_file)
  time = Benchmark.measure {
    runner(import_file)
  }
  puts time.real
end

def runner(import_file)
  csv_hash = convert_to_hash(import_file)
  puts "CSV Formated"
  port = ssh_into_server
  puts "Connected to Server"
  client = mysql_connection(port)
  puts "Connected to Database"
  write_products(csv_hash, client)
  client.close
end

def write_products(csv_hash, client)
  create_wp_posts_csv(csv_hash)
  puts "WP_POSTS CSV Created"
  write_table('wp_posts.csv', 'wp_posts', client)
  puts "WP_POSTS Loaded To Database"
  wp_posts_ids = client.query("Select * from wp_posts where post_author = '2' and post_type = 'product' and post_date >= NOW() - interval 5.5 hour order by id;")
  puts "WP_POST ID's Selected"
  match_ids(csv_hash, wp_posts_ids)
  puts "PRODUCT ID's MATCHED"
  create_wp_postmeta_csv(csv_hash,wp_posts_ids)
  puts "WP_POSTMETA CSV Created"
  write_table('wp_postmeta.csv', 'wp_postmeta', client)
  puts "WP_POSTMETA Loaded To Database"
  create_wp_wc_product_meta_lookup_csv(csv_hash)
  puts "WP_WC_PRODUCT_META_LOOKUP CSV CREATED"
  write_table('wp_wc_product_meta_lookup.csv', 'wp_wc_product_meta_lookup', client)
  puts "WP_WC_PRODUCT_META_LOOKUP Loaded To Database"
  create_wp_term_relationships_csv(csv_hash)
  puts "WP_TERM_RELATIONSHIPS CSV CREATED"
  write_table('wp_term_relationships.csv', 'wp_term_relationships', client)
  puts "WP_TERM_RELATIONSHIPS Loaded To Database"
end

# ------ wp_posts_code ------ #

def create_wp_posts_csv(csv_hash)
  CSV.open("./csv/wp_posts.csv", "wb") do |csv|
    i = 0
    csv_hash.each do |product|
      wp_posts_hash = generate_wp_posts_hash(product)
      if i == 0
        input = []
        wp_posts_hash.each do |k,v|
          input << k
        end
        csv << input
      end
      input = []
      wp_posts_hash.each do |k,v|
        input << v
      end
      i += 1
      csv << input
    end
  end
end

def generate_wp_posts_hash(product)
  hash = {}
  hash['ID'] = nil
  hash['post_author'] = '2'
  hash['post_date'] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  hash['post_date_gmt'] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  hash['post_content'] = product['Description'].gsub("'","\\\\'")
  hash['post_title'] = product['Name'].gsub("'","\\\\'")
  hash['post_excerpt'] = nil
  hash['post_status'] = "publish"
  hash['comment_status'] = 'open'
  hash['ping_status'] = 'closed'
  hash['post_password'] = nil
  hash['post_name'] = product['Name'].gsub(' - ', '-').gsub("'","").gsub('"',"").gsub('/','-').gsub(" ", "-").downcase
  hash['to_ping'] = nil
  hash['pinged'] = nil
  hash['post_modified'] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  hash['post_modified_gmt'] = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  hash['post_content_filtered'] = nil
  hash['post_parent'] = '0'
  hash['guid'] = "https://abrafast.store/product/#{hash['post_name']}/"
  hash['menu_order'] = "0"
  hash['post_type'] = "product"
  hash['post_mime_type'] = nil
  hash['comment_count'] = '0'
  return hash
end

# ------ wp_postmeta_code ------ #

def create_wp_postmeta_csv(csv_hash, wp_posts_ids)
  headers = wp_postmeta_headers
  CSV.open('./csv/wp_postmeta.csv', 'wb') do |csv|
    csv << headers
    csv_hash.each do |product|
      product_array = format_wp_postmeta(product, wp_posts_ids)
      product_array.each do |row|
        csv << row
      end
    end
  end
end

def wp_postmeta_headers
  array = [
    'meta_id',
    'post_id',
    'meta_key',
    'meta_value'
  ]
end

def format_wp_postmeta(product, wp_posts_ids)
  array = []
  wp_postmeta_hash = generate_wp_postmeta_hash(product)
  wp_postmeta_hash.each do |k,v|
    array << [
      nil,
      product["ID"],
      k,
      v
    ]
  end
  return array
end

def generate_wp_postmeta_hash(product)
  hash = {}
  hash['_sku'] = product['SKU']
  hash['_regular_price'] = product["Regular price"]
  hash['total_sales'] = "0"
  hash['_tax_status'] = 'taxable'
  hash['_tax_class'] = "''"
  hash['_manage_stock'] = "no"
  hash['_backorders'] = 'no'
  hash['_sold_individually'] = 'no'
  hash['_weight'] = product['Weight (lbs)']
  hash['_virtual'] = 'no'
  hash['_downloadable'] = 'no'
  hash['_download_limit'] = '-1'
  hash['_download_expiry'] = '-1'
  hash['_thumbnail_id'] = '5096'
  hash['_stock'] = 'NULL'
  hash['_stock_status'] = 'instock' 
  hash['_wc_average_rating'] = '0'
  hash['_wc_review_count'] = '0'
  hash['_product_version'] = '4.0.1'
  hash['_price'] = product['Regular price']
  hash['_wpm_gtin_code'] = product['MPN']
  return hash
end

# ------ wp_wc_product_meta_lookup_code ------ #

def create_wp_wc_product_meta_lookup_csv(csv_hash)
  CSV.open('./csv/wp_wc_product_meta_lookup.csv', 'wb') do |csv|
    i = 0
    csv_hash.each do |product|
      wp_wc_product_meta_lookup_hash = generate_wp_wc_product_meta_lookup_hash(product)
      if i == 0
        input = []
        wp_wc_product_meta_lookup_hash.each do |k,v|
          input << k
        end
        csv << input
      end
      input = []
      wp_wc_product_meta_lookup_hash.each do |k,v|
        input << v
      end
      i += 1
      csv << input
    end
  end
end

def generate_wp_wc_product_meta_lookup_hash(product)
  hash = {}
  hash['product_id'] = product["ID"]
  hash['sku'] = product['SKU']
  hash['virtual'] = '0'
  hash['downloadable'] = '0' 
  hash['min_price'] = product['Regular price']
  hash['max_price'] = product['Regular price']
  hash['onsale'] = '0'
  hash['stock_quantity'] = '0'
  hash['stock_status'] = 'instock'
  hash['rating_count'] = '0'
  hash['average_rating'] = '0'
  hash['total_sales'] = '0'
  hash['tax_status'] = 'taxable'
  hash['tax_class'] = "''"
  return hash
end

# ------ wp_term_relationships_code ------ #

def create_wp_term_relationships_csv(csv_hash)
  headers = wp_term_relationships_headers
  CSV.open('./csv/wp_term_relationships.csv', 'wb') do |csv|
    csv << headers
    csv_hash.each do |product|
      product_array = format_wp_term_relationships(product)
      product_array.each do |row|
        csv << row
      end
    end
  end 
end

def wp_term_relationships_headers
  array = [
    'object_id',
    'term_taxonomy_id',
    'term_order'
  ]
end

def format_wp_term_relationships(product)
  array = []
  values = [63, 7, 2]
  values.each do |v|
    array << [
      product["ID"],
      v,
      "0"
    ]
  end
  return array
end

# ------ Utility Code ------ #

def ssh_into_server
  gateway = Net::SSH::Gateway.new(
    URL,
    'root'
  )
  port = gateway.open('127.0.0.1', 3306)
  return port
end

def mysql_connection(port)
  ## found in /etc/mysql/debian.cnf
  client = Mysql2::Client.new(
    host: "127.0.0.1",
    username: USERNAME,
    password: PASSWORD,
    database: "wordpress",
    local_infile: true,
    port: port
  )
  return client
end

def match_ids(csv_hash, wp_posts_ids)
  wp_posts_ids_total = 0
  wp_posts_ids.each do |entry|
    wp_posts_ids_total += 1
  end
  p wp_posts_ids_total
  p csv_hash.length
  start = wp_posts_ids_total - csv_hash.length
  p start
  i = 0
  wp_posts_ids.each do |row|
    if i >= start
      csv_hash[i - start]["ID"] = row['ID']
    end
    i += 1
  end
end

def write_table(file_path, table, client)
  string = "LOAD DATA LOCAL INFILE \'#{Dir.pwd}/csv/#{file_path}\' INTO TABLE #{table} FIELDS TERMINATED BY \',\' ENCLOSED BY '\"' LINES TERMINATED BY '\\n' IGNORE 1 ROWS;"
  client.query(string)
end

def convert_to_hash(file)
  array = []
  i = 0
  file.each do |line|
    if i != 0
      array << Hash[file[0].zip(line.map)]
    end
    i += 1
  end
  return array
end



import_file = CSV.read("./csv/split3.csv")

start(import_file)
  