class Ser < Hash
  def initialize(type,grade,finish,diameter,length,thread_length)
    new_part = {'type' => type ,"grade" => grade, 'finish' => finish,'diameter' => diameter, 'length' => length, "thread_length" => thread_length}
    # item = {'Part Number' => "", 'Description' => "", "Cost" => "", "Weight" => ""} 
    self['Part Number'] = create_part_number(new_part)
    self['Description'] = create_description(new_part)
    self['Cost'] = create_cost(new_part)
    self['Weight'] = create_weight(new_part)
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
    string += "-"
    string += new_part['thread_length'].to_s
    return string
  end

  def create_description(new_part)
    length = notate(new_part['length'])
    thread_length = notate(new_part['thread_length'])
    string = ""
    string += 'ASTM ' + new_part['grade']['grade'] + " - "
    string += new_part['finish']['finish'].capitalize + " "
    string += new_part['type']['type'].split.map(&:capitalize)*' ' + " "
    string += "- #{new_part['diameter']['diameter']}" + " "
    string += "x #{length}"
    string += " - "
    string += "#{thread_length} Thread"
    return string
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
    if quarter > 0 && quarter != 2
      string += "-" if feet != 0 || inches != 0
      string += "#{quarter}/4"
    end
    if quarter == 2
      string += "-" if feet != 0 || inches != 0
      string += "1/2"
    end
    string += '"' if inches > 0 || quarter > 0
    return string
  end
end 