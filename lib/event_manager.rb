# frozen_string_literal: false

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

# method that cleans the zipcode value in the CSV file
def clean_zipcode(zipcode)
  # reducing the conditional into a single line
  # method rjust does not change strings with length > 5
  # and vice versa with method slice ([b..e])
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone)
  numbers_only = /\d+/
  default_number = '5555555555'
  # filters out all the non-numerical characters
  phone = phone.scan(numbers_only).join('')

  if phone.length < 10 || phone.length > 11 || (phone.length == 11 && !phone.start_with?('1'))
    phone = default_number
  elsif phone.length == 11 && phone.start_with?('1')
    phone = phone[1..]
  end
  phone.insert(3, '-')
  phone.insert(7, '-')
end

def get_register_time(dates)
  dates.gsub!('/', '-').insert(dates.rindex('-') + 1, '20')
  Time.strptime(dates, '%m-%d-%Y %k:%M')
end

def display_target_times(hour_counts)
  puts %(Hours of the day to target:)
  hour_counts.each_key do |time|
    puts time.strftime('%I %p') if hour_counts[time] == hour_counts.values.max
  end
end

def display_target_day(day_counts)
  puts %(Day of the week to target:)
  day_counts.each_key { |day, _count| puts day if day_counts[day] == day_counts.values.max }
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  # actual file creation
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = %(output/thanks_#{id}.html)

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts %(Event Manager Initialized!)

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_counts = Hash.new(0)
day_counts = Hash.new(0)

contents.each do |row|
  # getting all the attributes needed for form_letter file creation from the CSV file
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  # Assignment: Clean phone numbers
  phone = clean_phone_number(row[:homephone])

  date = get_register_time(row[:regdate])

  # Assignment: Time targeting
  hour_counts[Time.strptime(date.hour.to_s, '%k')] += 1

  # Assignment: Day of the week targeting
  # find out which day of the week has the most registrations
  day_counts[date.strftime('%A')] += 1

  # getting the information of gov representatives from the CivicInfo API
  legislators = legislators_by_zipcode(zipcode)

  # ERB template to dynamically create forms for each attendee
  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

  # display the target hours and target day
  if contents.eof?
    display_target_times(hour_counts)
    display_target_day(day_counts)
  end
end

# TODO: RUBY STYLE GUIDE
# https://www.theodinproject.com/lessons/ruby-object-oriented-programming
