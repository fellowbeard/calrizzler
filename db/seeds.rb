require 'faker'

# Destroy existing records
AppointmentService.destroy_all
Appointment.destroy_all
Note.destroy_all
Service.destroy_all
Client.destroy_all
Resource.destroy_all
User.destroy_all
Account.destroy_all

# Accounts
account_one = Account.create!(
  business_name: "Jane Stuff's Stuff and Things"
)

account_two = Account.create!(
  business_name: "John Denver's Sing Songs and Stuff"
)

# Resources
chair_one = Resource.create!(
  account: account_one,
  name: 'Chair 1'
)

chair_two = Resource.create!(
  account: account_one,
  name: 'Chair 2'
)

john_chair = Resource.create!(
  account: account_two,
  name: 'Chair 1'
)

# Users
jane = User.create!(
  account: account_one,
  first_name: 'Jane',
  last_name: 'Stuff',
  email: 'js@example.com',
  role: 'owner',
  password: '12',
  password_confirmation: '12'
)

john = User.create!(
  account: account_two,
  first_name: 'John',
  last_name: 'Denver',
  email: 'jd@example.com',
  role: 'owner',
  password: '12',
  password_confirmation: '12'
)

User.create!(
  account: account_one,
  first_name: 'Susette',
  last_name: 'StaffReader',
  email: 'susettestaffreader@example.com',
  role: 'read_only',
  password: '12',
  password_confirmation: '12'
)

# Clients
client_one = Client.create!(
  account: account_one,
  user: jane,
  first_name: 'Maya',
  last_name: 'Rivera',
  email: 'maya.rivera@example.com',
  phone: '(504) 555-0101'
)

client_two = Client.create!(
  account: account_one,
  user: jane,
  first_name: 'Caleb',
  last_name: 'Brooks',
  email: 'caleb.brooks@example.com',
  phone: '(504) 555-0102'
)

client_three = Client.create!(
  account: account_two,
  user: john,
  first_name: 'Nina',
  last_name: 'Patel',
  email: 'nina.patel@example.com',
  phone: '(504) 555-0103'
)

# Services
deep_tissue = Service.create!(
  account: account_one,
  user: jane,
  title: 'Deep Tissue Massage',
  description: 'Focused deep tissue session for shoulder and back tension.',
  duration_minutes: 60,
  price: 95.00
)

custom_rug = Service.create!(
  account: account_one,
  user: jane,
  title: 'Custom Rug Consultation',
  description: 'Initial consultation for a custom tufted rug design.',
  duration_minutes: 45,
  price: 50.00
)

follow_up = Service.create!(
  account: account_two,
  user: john,
  title: 'Follow-up Appointment',
  description: 'Follow-up service appointment and client check-in.',
  duration_minutes: 30,
  price: 40.00
)

# Appointments
Appointment.create!(
  account: account_one,
  user: jane,
  resource: chair_one,
  client: client_one,
  scheduled_at: 2.days.from_now,
  status: 'scheduled',
  service_ids: [deep_tissue.id, custom_rug.id]
)

Appointment.create!(
  account: account_one,
  user: jane,
  resource: chair_two,
  client: client_two,
  scheduled_at: 4.days.from_now,
  status: 'scheduled',
  service_ids: [custom_rug.id]
)

Appointment.create!(
  account: account_two,
  user: john,
  resource: john_chair,
  client: client_three,
  scheduled_at: 1.week.from_now,
  status: 'scheduled',
  service_ids: [follow_up.id]
)

# Notes
Note.create!(
  client: client_one,
  user: jane,
  body: 'Client prefers afternoon appointments and firm pressure.'
)

Note.create!(
  client: client_two,
  user: jane,
  body: 'Interested in earth tones and a bold geometric design.'
)

Note.create!(
  client: client_three,
  user: john,
  body: 'Follow up about scheduling and preferred service length.'
)

Rails.logger.debug 'Seeded:'
Rails.logger.debug "- #{Account.count} accounts"
Rails.logger.debug "- #{User.count} users"
Rails.logger.debug "- #{Resource.count} resources"
Rails.logger.debug "- #{Client.count} clients"
Rails.logger.debug "- #{Service.count} services"
Rails.logger.debug "- #{Appointment.count} appointments"
Rails.logger.debug "- #{AppointmentService.count} appointment services"
Rails.logger.debug "- #{Note.count} notes"
