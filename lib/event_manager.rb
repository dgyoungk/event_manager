require 'csv'
require 'google/apis/civicinfo_v2'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'


# method that cleans the zipcode value in the CSV file
def clean_zipcode(zipcode)
  # case
  # when zipcode.nil?
  #   zipcode = '00000'
  # when zipcode.length < 5
  #   zipcode = zipcode.rjust(5, '0')
  # when zipcode.length > 5
  #   zipcode = zipcode[0..4]
  # end
  # zipcode

  # reducing the switch statement into a single line
  # method rjust does not change strings with length > 5
  # and vice versa with method slice ([b..e])
  zipcode.to_s.rjust(5, '0')[0..4]
end

puts %(Event Manager Initialized!)

# loading a CSV file using the File class

# contents = File.read('event_attendees.csv')

# if File.exist? 'event_attendees.csv'
#   lines = File.readlines('event_attendees.csv')
#   lines.each_with_index do |line, idx|
#     next if idx == 0
#     columns = line.split(',')
#     puts columns[2]
#   end
# else
#   puts "event_attendees.csv: No such file or directory"
# end

# loading a CSV file using the CSV library

# contents = CSV.open('event_attendees.csv', headers: true)
# contents.each do |row|
#   name = row[2]
#   puts name
# end

# using column names to access their values


contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    )

    legislators = legislators.officials

    legislator_names = legislators.map(&:name)

    legislator_string = legislator_names.join(', ')
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end


  puts %(#{name} #{zipcode} #{legislator_string})
end
