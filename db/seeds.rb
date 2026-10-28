# rubocop:disable Metrics/BlockLength

# db/seeds.rb
#
# Development-only demo data.
# Running bin/rails db:seed intentionally clears existing
# development records and recreates the sample dataset.
#
# All deletion and creation happens in one transaction.
# If any operation fails, the database is rolled back.

raise 'Destructive seeds are only allowed in development.' unless Rails.env.development?

ActiveRecord::Base.transaction do
  # --------------------------------------------------
  # Clear existing data
  # --------------------------------------------------

  AvailabilityBlock.delete_all
  UserWorkingHour.delete_all
  WorkingHour.delete_all

  AppointmentService.delete_all
  Appointment.delete_all
  Note.delete_all
  UserService.delete_all
  Service.delete_all
  Client.delete_all
  Resource.delete_all
  UserInvitation.delete_all
  PasswordReset.delete_all
  User.delete_all
  Account.delete_all

  # --------------------------------------------------
  # Accounts
  # --------------------------------------------------

  account_one = Account.create!(
    business_name: "Jane Stuff's Stuff and Things",
    timezone: 'America/Chicago'
  )

  account_two = Account.create!(
    business_name: "John Denver's Sing Songs and Stuff",
    timezone: 'America/Denver'
  )

  # --------------------------------------------------
  # Users
  # --------------------------------------------------

  development_password = '12'

  jane = User.create!(
    account: account_one,
    first_name: 'Jane',
    last_name: 'Stuff',
    email: 'js@example.com',
    role: 'owner',
    password: development_password,
    password_confirmation: development_password
  )

  susan = User.create!(
    account: account_one,
    first_name: 'Susan',
    last_name: 'Staff',
    email: 'susanstaff@example.com',
    role: 'staff',
    password: development_password,
    password_confirmation: development_password
  )

  User.create!(
    account: account_one,
    first_name: 'Susette',
    last_name: 'StaffReader',
    email: 'susettestaffreader@example.com',
    role: 'read_only',
    password: development_password,
    password_confirmation: development_password
  )

  john = User.create!(
    account: account_two,
    first_name: 'John',
    last_name: 'Denver',
    email: 'jd@example.com',
    role: 'owner',
    password: development_password,
    password_confirmation: development_password
  )

  # --------------------------------------------------
  # Resources
  # --------------------------------------------------

  chair_one = Resource.create!(
    account: account_one,
    name: 'Chair 1'
  )

  chair_two = Resource.create!(
    account: account_one,
    name: 'Chair 2'
  )

  massage_room = Resource.create!(
    account: account_one,
    name: 'Massage Room'
  )

  john_chair = Resource.create!(
    account: account_two,
    name: 'Chair 1'
  )

  # --------------------------------------------------
  # Clients
  # --------------------------------------------------

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
    account: account_one,
    user: susan,
    first_name: 'Avery',
    last_name: 'Morgan',
    email: 'avery.morgan@example.com',
    phone: '(504) 555-0104'
  )

  client_four = Client.create!(
    account: account_two,
    user: john,
    first_name: 'Nina',
    last_name: 'Patel',
    email: 'nina.patel@example.com',
    phone: '(504) 555-0103'
  )

  # --------------------------------------------------
  # Services
  # --------------------------------------------------

  deep_tissue = Service.create!(
    account: account_one,
    title: 'Deep Tissue Massage',
    description: 'Focused deep tissue session for shoulder and back tension.',
    duration_minutes: 60,
    price: 95.00
  )

  custom_rug = Service.create!(
    account: account_one,
    title: 'Custom Rug Consultation',
    description: 'Initial consultation for a custom tufted rug design.',
    duration_minutes: 45,
    price: 50.00
  )

  quick_consult = Service.create!(
    account: account_one,
    title: 'Quick Consultation',
    description: 'Short consultation for scheduling and service planning.',
    duration_minutes: 20,
    price: 25.00
  )

  follow_up = Service.create!(
    account: account_two,
    title: 'Follow-up Appointment',
    description: 'Follow-up service appointment and client check-in.',
    duration_minutes: 30,
    price: 40.00
  )

  # --------------------------------------------------
  # UserServices
  # Provider-specific offerings and prices
  # --------------------------------------------------

  UserService.create!(
    user: jane,
    service: deep_tissue,
    price: 95.00
  )

  UserService.create!(
    user: jane,
    service: custom_rug,
    price: 50.00
  )

  UserService.create!(
    user: jane,
    service: quick_consult,
    price: 25.00
  )

  UserService.create!(
    user: susan,
    service: quick_consult,
    price: 25.00
  )

  UserService.create!(
    user: susan,
    service: deep_tissue,
    price: 110.00
  )

  UserService.create!(
    user: john,
    service: follow_up,
    price: 40.00
  )

  # --------------------------------------------------
  # Business working hours
  # --------------------------------------------------

  # Jane's business: Monday-Friday, 9 AM-5 PM.
  # John's business: Monday-Friday, 10 AM-6 PM.

  (1..5).each do |weekday|
    WorkingHour.create!(
      account: account_one,
      day_of_week: weekday,
      opens_at: '09:00',
      closes_at: '17:00'
    )

    WorkingHour.create!(
      account: account_two,
      day_of_week: weekday,
      opens_at: '10:00',
      closes_at: '18:00'
    )
  end

  # --------------------------------------------------
  # Provider working hours
  # --------------------------------------------------

  # Jane inherits her business's working hours.
  # Susan overrides business hours on Tuesday and Thursday.

  [2, 4].each do |weekday|
    UserWorkingHour.create!(
      user: susan,
      day_of_week: weekday,
      opens_at: '11:00',
      closes_at: '19:00'
    )
  end

  # --------------------------------------------------
  # Availability blocks
  # --------------------------------------------------

  chicago = Time.find_zone!(account_one.timezone)

  next_wednesday = chicago.today.next_occurring(:wednesday)
  next_tuesday = chicago.today.next_occurring(:tuesday)
  next_saturday = chicago.today.next_occurring(:saturday)

  # Jane's lunch break next Wednesday: noon-1 PM.

  AvailabilityBlock.create!(
    account: account_one,
    user: jane,
    is_available: false,
    starts_at: chicago.local(
      next_wednesday.year,
      next_wednesday.month,
      next_wednesday.day,
      12
    ),
    ends_at: chicago.local(
      next_wednesday.year,
      next_wednesday.month,
      next_wednesday.day,
      13
    )
  )

  # Business closure next Tuesday: 9 AM-5 PM.
  # This removes inherited business hours.
  # Provider-specific overrides can still apply.

  AvailabilityBlock.create!(
    account: account_one,
    is_available: false,
    starts_at: chicago.local(
      next_tuesday.year,
      next_tuesday.month,
      next_tuesday.day,
      9
    ),
    ends_at: chicago.local(
      next_tuesday.year,
      next_tuesday.month,
      next_tuesday.day,
      17
    )
  )

  # Jane opens extra availability next Saturday: 10 AM-2 PM.

  AvailabilityBlock.create!(
    account: account_one,
    user: jane,
    is_available: true,
    starts_at: chicago.local(
      next_saturday.year,
      next_saturday.month,
      next_saturday.day,
      10
    ),
    ends_at: chicago.local(
      next_saturday.year,
      next_saturday.month,
      next_saturday.day,
      14
    )
  )

  # --------------------------------------------------
  # Appointment timezone helper
  # --------------------------------------------------

  # Interpret appointment times in the business's timezone.
  # ActiveRecord stores the resulting timestamps in UTC.

  business_time = lambda do |account, day_offset, hour, minute|
    zone = Time.find_zone!(account.timezone)
    day = zone.today + day_offset

    zone.local(day.year, day.month, day.day, hour, minute)
  end

  # --------------------------------------------------
  # Appointments
  # --------------------------------------------------

  Appointment.create!(
    account: account_one,
    user: jane,
    resource: chair_one,
    client: client_one,
    scheduled_at: business_time.call(account_one, 2, 14, 0),
    status: 'scheduled',
    duration_minutes: deep_tissue.duration_minutes + custom_rug.duration_minutes,
    duration_overridden: false,
    service_ids: [
      deep_tissue.id,
      custom_rug.id,
    ]
  )

  Appointment.create!(
    account: account_one,
    user: jane,
    resource: chair_two,
    client: client_two,
    scheduled_at: business_time.call(account_one, 4, 11, 30),
    status: 'scheduled',
    duration_minutes: custom_rug.duration_minutes,
    duration_overridden: false,
    service_ids: [
      custom_rug.id,
    ]
  )

  Appointment.create!(
    account: account_one,
    user: susan,
    resource: massage_room,
    client: client_three,
    scheduled_at: business_time.call(account_one, 1, 16, 0),
    status: 'scheduled',
    duration_minutes: 30,
    duration_overridden: true,
    service_ids: [
      quick_consult.id,
    ]
  )

  Appointment.create!(
    account: account_one,
    user: jane,
    resource: chair_one,
    client: client_one,
    scheduled_at: business_time.call(account_one, -10, 13, 0),
    status: 'completed',
    duration_minutes: deep_tissue.duration_minutes,
    duration_overridden: false,
    service_ids: [
      deep_tissue.id,
    ]
  )

  Appointment.create!(
    account: account_one,
    user: jane,
    resource: chair_two,
    client: client_two,
    scheduled_at: business_time.call(account_one, -5, 15, 30),
    status: 'completed',
    duration_minutes: custom_rug.duration_minutes,
    duration_overridden: false,
    service_ids: [
      custom_rug.id,
    ]
  )

  Appointment.create!(
    account: account_one,
    user: susan,
    resource: massage_room,
    client: client_three,
    scheduled_at: business_time.call(account_one, -3, 10, 0),
    status: 'canceled',
    duration_minutes: quick_consult.duration_minutes,
    duration_overridden: false,
    service_ids: [
      quick_consult.id,
    ]
  )

  Appointment.create!(
    account: account_two,
    user: john,
    resource: john_chair,
    client: client_four,
    scheduled_at: business_time.call(account_two, 7, 12, 0),
    status: 'scheduled',
    duration_minutes: follow_up.duration_minutes,
    duration_overridden: false,
    service_ids: [
      follow_up.id,
    ]
  )

  Appointment.create!(
    account: account_two,
    user: john,
    resource: john_chair,
    client: client_four,
    scheduled_at: business_time.call(account_two, -14, 12, 0),
    status: 'completed',
    duration_minutes: follow_up.duration_minutes,
    duration_overridden: false,
    service_ids: [
      follow_up.id,
    ]
  )

  # --------------------------------------------------
  # Notes
  # --------------------------------------------------

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
    user: susan,
    body: 'Prefers shorter appointments when possible.'
  )

  Note.create!(
    client: client_four,
    user: john,
    body: 'Follow up about scheduling and preferred service length.'
  )

  # --------------------------------------------------
  # Seed summary
  # --------------------------------------------------

  Rails.logger.debug
  Rails.logger.debug 'Calrizzler development seed complete!'
  Rails.logger.debug '-------------------------------------'
  Rails.logger.debug "Accounts:             #{Account.count}"
  Rails.logger.debug "Users:                #{User.count}"
  Rails.logger.debug "Resources:            #{Resource.count}"
  Rails.logger.debug "Clients:              #{Client.count}"
  Rails.logger.debug "Services:             #{Service.count}"
  Rails.logger.debug "UserServices:         #{UserService.count}"
  Rails.logger.debug "WorkingHours:         #{WorkingHour.count}"
  Rails.logger.debug "UserWorkingHours:     #{UserWorkingHour.count}"
  Rails.logger.debug "AvailabilityBlocks:   #{AvailabilityBlock.count}"
  Rails.logger.debug "Appointments:         #{Appointment.count}"
  Rails.logger.debug "AppointmentServices:  #{AppointmentService.count}"
  Rails.logger.debug "Notes:                #{Note.count}"
end

# rubocop:enable Metrics/BlockLength
