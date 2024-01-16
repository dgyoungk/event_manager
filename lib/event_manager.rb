require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'



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

  case
  when phone.length < 10 || phone.length > 11
    phone = default_number
  when phone.length == 11 && phone.start_with?('1')
    phone = phone[1..]
  when phone.length == 11 && !phone.start_with('1')
    phone = default_number
  end

  phone.insert(3, '-')
  phone.insert(7, '-')
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
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

contents.each do |row|
  # getting all the attributes needed for form_letter file creation from the CSV file
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  # Assignment: Clean phone numbers
  phone = clean_phone_number(row[:homephone])

  # Assignment: Time targeting
  # note: the date in the CSV file is in the format of MM/DD/YY
  # TODO:
  # - use the registration date and time to find out what the peak registration hours are
  # https://www.theodinproject.com/lessons/ruby-event-manager#assignment-time-targeting

  # getting the information of gov representatives from the CivicInfo API
  legislators = legislators_by_zipcode(zipcode)

  # ERB template to dynamically create forms for each attendee
  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

end
