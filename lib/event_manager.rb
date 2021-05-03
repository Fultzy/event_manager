require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exists?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def valid_phone_number(raw_str)
  phone_number = raw_str.delete ' -.,()'
  case phone_number.length
  when 11
    if phone_number.start_with?('1')
      phone_number.slice!(0)
      format_phone_number(phone_number)
    end
  when 10
    format_phone_number(phone_number)
  end
end

def format_phone_number(number)
  number.insert(0, '(')
  number.insert(4, ')')
  number.insert(8, '-')
  return number
end

def reg_time(raw_str)
  p array = raw_str.split("/")
  year = "20#{array[2]}"
  month = array[0]
  day = array[1]
  p "month: #{month}, day: #{day}, year: #{year}"

end

def clean_time(time)
  p "time: #{time}"

end

def clean_day(time)
  p "day: #{time}"
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

days_reg = []
times_reg = []

contents.each do |row|
  puts id = row[0]
  reg_time(row[:regdate])
  name = row[:first_name].capitalize
  phone_number = valid_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  ## user stats ##

  ## time of day peak
  # times_reg.push(clean_time(time))

  ## day of the week peak
  # days_reg.push(clean_day(time))

end
