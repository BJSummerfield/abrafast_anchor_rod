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

import_file = CSV.read('./import.csv')

def runner(import_file)
  csv_hash = convert_to_hash(import_file)
  port = ssh_into_server
  client = mysql_connection(port)
  write_products(csv_hash, client)
  client.close
end

def write_products(csv_hash, client)
  i = 0
  csv_hash.each do |item|
    write_wp_posts(item, client)
    product_id = query_ID(client, 'wp_posts', 'product', 'post_title', item['Name'].gsub("'","\\\\'"))
    p 'starting postmeta'
    write_wp_postmeta(item, product_id, client)
    p 'starting term_relationships'
    write_wp_term_relationships(item, product_id, client)
    p "starting meta lookup"
    write_wp_wc_product_meta_lookup(item, product_id, client)
    i += 1
    p i 
  end
end

def write_wp_wc_product_meta_lookup(item, product_id, client)
  lookup_hash = generate_wp_wc_product_meta_lookup_hash(item, product_id)
  string = generate_wp_wc_product_meta_lookup_string(lookup_hash, product_id)
  client.query(string)
end

def generate_wp_wc_product_meta_lookup_string(lookup_hash, product_id)
  return "REPLACE INTO `wp_wc_product_meta_lookup` (`product_id`, `sku`, `virtual`, `downloadable`, `min_price`, `max_price`, `onsale`, `stock_quantity`, `stock_status`, `rating_count`, `average_rating`, `total_sales`, `tax_status`, `tax_class`) VALUES ('#{lookup_hash["product_id"]}', '#{lookup_hash["sku"]}', '#{lookup_hash["virtual"]}', '#{lookup_hash["downloadable"]}', '#{lookup_hash["min_price"]}', '#{lookup_hash["max_price"]}', '#{lookup_hash["onsale"]}', '#{lookup_hash["stock_quantity"]}', '#{lookup_hash["stock_status"]}', '#{lookup_hash["rating_count"]}', '#{lookup_hash["average_rating"]}', '#{lookup_hash["total_sales"]}', '#{lookup_hash["tax_status"]}', '#{lookup_hash["tax_clas"]}')"   
end

def generate_wp_wc_product_meta_lookup_hash(item, product_id)
  hash = {}
  hash['product_id'] = product_id 
  hash['sku'] = item['SKU']
  hash['virtual'] = '0'
  hash['downloadable'] = '0' 
  hash['min_price'] = item['Regular price']
  hash['max_price'] = item['Regular price']
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

def write_wp_term_relationships(item, product_id, client)
  array = [63, 7, 2]
  string = "INSERT INTO `wp_term_relationships` (`object_id`, `term_taxonomy_id`) VALUES "
  i = 1 
  array.each do |v|
    string += "(#{product_id}, #{v})"
    string += ", " if i != array.length
    i += 1
  end
  string += ";"
  client.query(string)
end

def write_wp_postmeta(item, product_id, client)
  item_hash = generate_wp_postmeta_hash(item, client)
  string = "INSERT INTO `wp_postmeta`(`post_id`, `meta_key`, `meta_value`) VALUES "
  i = 1
  item_hash.each do |k,v|
    string += "(#{product_id}, '#{k}', '#{v}')"
    string += ", " if i != item_hash.length
    i += 1
  end
  string += ";"
  client.query(string)
end

def generate_wp_postmeta_hash(item, client)
  hash = {}
  hash['_sku'] = item['SKU']
  hash['_regular_price'] = item["Regular price"]
  hash['total_sales'] = "0"
  hash['_tax_status'] = 'taxable'
  hash['_tax_class'] = "''"
  hash['_manage_stock'] = "no"
  hash['_backorders'] = 'no'
  hash['_sold_individually'] = 'no'
  hash['_weight'] = item['Weight (lbs)']
  hash['_virtual'] = 'no'
  hash['_downloadable'] = 'no'
  hash['_download_limit'] = '-1'
  hash['_download_expiry'] = '-1'
  hash['_thumbnail_id'] = '6910' #'query_ID(client, 'wp_posts', 'attachment', 'guid', item['Images']).to_s'
  hash['_stock'] = 'NULL'
  hash['_stock_status'] = 'instock' 
  hash['_wc_average_rating'] = '0'
  hash['_wc_review_count'] = '0'
  hash['_product_version'] = '4.0.1'
  hash['_price'] = item['Regular price']
  hash['_wpm_gtin_code'] = item['MPN']
  return hash
end

def write_wp_posts(item, client)
  item_hash = generate_wp_posts_hash(item)
  mysql_string = generate_wp_posts_string(item_hash)
  p mysql_string
  # client.query(mysql_string)
end

def generate_wp_posts_string(item_hash)
  return "insert into `wp_posts`(`post_content`,`post_title`,`ping_status`,`post_name`,`guid`,`post_type`,`post_date`,`post_date_gmt`, `post_modified`, `post_modified_gmt`,`post_excerpt`,`to_ping`,`pinged`, `post_content_filtered`) VALUES ('#{item_hash['post_content']}', '#{item_hash['post_title']}', '#{item_hash['ping_status']}', '#{item_hash['post_name']}', '#{item_hash['guid']}', '#{item_hash['post_type']}', #{item_hash['post_date']}, #{item_hash['post_date_gmt']} , #{item_hash['post_modified']}, #{item_hash['post_modified_gmt']}, #{item_hash['post_excerpt']}, #{item_hash['to_ping']}, #{item_hash['pinged']}, #{item_hash['post_content_filtered']});"
end

def generate_wp_posts_hash(item)
  hash = {}
  hash['post_content'] = item["Description"].gsub("'","\\\\'")
  hash['post_title'] = item["Name"].gsub("'","\\\\'")
  hash['ping_status'] = 'closed'
  hash['post_name'] = item['Name'].gsub(' - ', '-').gsub("'","").gsub('"',"").gsub('/','-').gsub(" ", "-").downcase
  hash['guid'] = "https://abrafast.store/product/#{hash['post_name']}/"
  hash['post_type'] = 'product'
  hash['post_date'] = 'NOW()'
  hash['post_date_gmt'] = 'NOW()'
  hash['post_modified'] = 'NOW()'
  hash['post_modified_gmt'] = 'NOW()'
  hash['post_excerpt'] = "''"
  hash['to_ping'] = "''"
  hash['pinged'] = "''"
  hash['post_content_filtered'] = "''"  
  return hash
end

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
    port: port
  )
  return client
end

def query_ID(client, table, post_type, search_field, search_value)
  query = client.query("Select ID from #{table} where post_type = '#{post_type}' and #{search_field} = '#{search_value}';")
  query.each do |row|
    return row["ID"]
  end
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

start(import_file)

