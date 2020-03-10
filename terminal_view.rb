require_relative '../key/partlist.rb'

def runner(types,grades,finishes,diameters)
  a = []
  welcome_msg
  a << pick_type(types)
  puts "**************************************************"
  a << pick_grade(grades)
  puts "**************************************************"
  a << pick_finish(finishes)
  a << "-"
  puts "**************************************************"
  a << pick_diameter(diameters)
  a << "-"
  puts "**************************************************"
  a << pick_length
  system("open", "http://localhost:8000/product/#{a.join("")}/")
end

def pick_length
  a = false
  length = 0
  puts "** Please Select Your Length"
  puts "****************************"
  length += select_feet
  if length != 576
    length += select_inches
  end
  return length
end

def select_inches
  a = false
  puts ""
  puts "How many inches? (Max 12)"
  puts "************************"
  puts ""
  while a == false
    inches = gets.chomp.to_i
    if inches < 0 || inches > 12
      puts "Invalid entry"
    else
      a = true
      return inches * 4
    end
  end
end

def select_feet
  a = false
  puts ""
  puts "How many Feet? (Max 12)"
  puts "************************"
  puts ""
  while a == false
  feet = gets.chomp.to_i
    if feet < 0 || feet > 12
      puts "Invalid entry"
    else
      a = true
      return feet * 4 * 12
    end
  end
end

def pick_finish(finishes)
  a = false
  puts "** Please Select Your Finish **"
  (finishes.length).times do |i|
    puts "#{i+1}.) #{finishes[i]}"
  end
  puts ""
  puts "Input your choice #"
  while a == false
  options = [*1..finishes.length]
  i = gets.chomp.to_i
  options = [*1..(finishes.length)]
  if options.include?(i)
    a = true
    return finishes[i - 1].split.map(&:chr).join.upcase
  else
    puts "Invalid Choice"
    end
  end
end

def pick_diameter(diameters)
  a = false
  puts "** Please Select Your finish **"
  (diameters.length).times do |i|
    puts "#{i+1}.) #{diameters[i]}"
  end
  puts ""
  puts "Input your choice #"
  while a == false
    options = [*1..diameters.length]
    i = gets.chomp.to_i
    options = [*1..(diameters.length)]
    if options.include?(i)
      a = true
      return diameters[i - 1].gsub('/','').gsub('"','')
    else
      puts "Invalid Choice"
    end
  end
end

def pick_grade(grades)
  a = false
  puts "** Please Select Your Grade **"
  (grades.length).times do |i|
    puts "#{i+1}.) #{grades[i]}"
  end
  puts ""
  puts "Input your choice #"
  while a == false
    options = [*1..grades.length]
    i = gets.chomp.to_i
    options = [*1..(grades.length)]
    if options.include?(i)
      a = true
      return grades[i - 1].gsub("Grade ","")
    else
      puts "Invalid Choice"
    end
  end
end

def pick_type(types)
  a = false
    puts "** Please Select Your Type **"
  (types.length).times do |i|
    puts "#{i+1}.) #{types[i]}"
  end
  puts ""
  puts "Input your choice #"
  while a == false
    options = [*1..types.length]
    i = gets.chomp.to_i
    options = [*1..(types.length)]
    if options.include?(i)
      a = true
      return types[i - 1].split.map(&:chr).join.upcase
    else
      puts "Invalid Choice"
    end
  end
end

def welcome_msg
  puts "**************************************************"
  puts "Welcome To Abrafast's Custom Anchor Bolt Creator"
  puts "**************************************************"
end

types = [
  "single end rod",
  "double end rod",
  "all threaded rod"
]

grades = [
  'F1554-Grade 55',
  'F1554-Grade 105'
]


finishes = [
  'plain',
  'galvanized'
]

diameters = [
  '1/2"-13',
  '5/8"-11',
  '3/4"-10',
  '7/8"-9',
  '1"-8',
  '1-1/8"-7',
  '1-1/4"-7',
  '1-3/8"-6',
  '1-1/2"-6'
]

runner(types,grades,finishes,diameters)
