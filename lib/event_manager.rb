# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

#########################
# api fetching legislator info from googles civic api
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

# creates a file and writes a letter to it
def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

# phone number formatting, when number is NIL nothing
# will be printed to the thank you letter.
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
  number
end

#########################
## user statistics ##

# adds stats of users into hashes
def format_reg_time(raw_str)
  day_month = raw_str.split('/')
  year_time = day_month[2].split(' ')
  time = year_time[1].split(':')
  @regtime = Time.new("20#{year_time[0]}",
                      day_month[0], day_month[1],
                      time[0], time[1])
end

def hours_per_day
  hour = @regtime.strftime('%k').to_i
  day = @regtime.strftime('%A')
  if @user_stats_time.key?(day)
    @user_stats_time[day].push(hour)
  else
    @user_stats_time[day] = [].push(hour)
  end
end

def reg_per_day
  day = @regtime.strftime('%A')
  if @user_stats_day.key?(day)
    @user_stats_day[day] += 1
  else
    @user_stats_day[day] = 1
  end
end

def most_common_string(array)
  array.group_by do |string|
    string
  end.values.max_by(&:size).first
end

def top_day
  day = most_common_string(@user_stats_day)[0]
  times = @user_stats_time[day]
  time = times.sum(0) / times.size
  count = @user_stats_day[day]
  puts " most trafficked day: #{day}"
  clean_time(time)
  puts " #{count} people regestered "
  @user_stats_time.delete(day)
end

def visualize_stats
  puts '###################'
  puts '   User stats:     '
  puts ''
  top_day
  puts ''
  puts '    Other days:'

  weekly_stats(@user_stats_time)
end

def clean_time(time)
  if time > 12
    time -= 12
    ma = 'pm'
  else
    ma = 'am'
  end
  puts " peak time: #{time}#{ma}"
  puts ''
end

def weekly_stats(days)
  days.each do |day, times|
    time = times.sum(0) / times.size
    puts "#{day} ~"
    clean_time(time)
  end
end

#########################

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

@user_stats_time = {}
@user_stats_day = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name].capitalize
  phone_number = valid_phone_number(row[:homephone])
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  #########################
  ## user stat logging ##
  format_reg_time(row[:regdate])

  # saves statistics per regestration 
  hours_per_day
  reg_per_day
end

visualize_stats
