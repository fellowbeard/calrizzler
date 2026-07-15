# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 20_260_618_191_706) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_catalog.plpgsql'

  create_table 'accounts', force: :cascade do |t|
    t.string 'business_name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'appointment_services', force: :cascade do |t|
    t.bigint 'appointment_id', null: false
    t.datetime 'created_at', null: false
    t.bigint 'service_id', null: false
    t.datetime 'updated_at', null: false
    t.index ['appointment_id'], name: 'index_appointment_services_on_appointment_id'
    t.index ['service_id'], name: 'index_appointment_services_on_service_id'
  end

  create_table 'appointments', force: :cascade do |t|
    t.bigint 'account_id'
    t.bigint 'client_id', null: false
    t.datetime 'created_at', null: false
    t.integer 'duration_minutes'
    t.bigint 'resource_id'
    t.datetime 'scheduled_at', null: false
    t.string 'status', default: 'scheduled', null: false
    t.datetime 'updated_at', null: false
    t.bigint 'user_id'
    t.index ['account_id'], name: 'index_appointments_on_account_id'
    t.index ['client_id'], name: 'index_appointments_on_client_id'
    t.index ['resource_id'], name: 'index_appointments_on_resource_id'
    t.index ['user_id'], name: 'index_appointments_on_user_id'
  end

  create_table 'clients', force: :cascade do |t|
    t.bigint 'account_id'
    t.datetime 'created_at', null: false
    t.string 'email'
    t.string 'first_name'
    t.string 'last_name'
    t.string 'phone'
    t.datetime 'updated_at', null: false
    t.bigint 'user_id'
    t.index ['account_id'], name: 'index_clients_on_account_id'
    t.index ['user_id'], name: 'index_clients_on_user_id'
  end

  create_table 'notes', force: :cascade do |t|
    t.text 'body'
    t.bigint 'client_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index ['client_id'], name: 'index_notes_on_client_id'
    t.index ['user_id'], name: 'index_notes_on_user_id'
  end

  create_table 'resources', force: :cascade do |t|
    t.bigint 'account_id'
    t.datetime 'created_at', null: false
    t.string 'name'
    t.datetime 'updated_at', null: false
    t.index ['account_id'], name: 'index_resources_on_account_id'
    t.index ['name', 'account_id'], name: 'index_resources_on_name_and_account_id', unique: true
  end

  create_table 'services', force: :cascade do |t|
    t.bigint 'account_id', null: false
    t.datetime 'created_at', null: false
    t.text 'description'
    t.integer 'duration_minutes'
    t.decimal 'price'
    t.string 'title'
    t.datetime 'updated_at', null: false
    t.bigint 'user_id', null: false
    t.index ['account_id'], name: 'index_services_on_account_id'
    t.index ['user_id'], name: 'index_services_on_user_id'
  end

  create_table 'users', force: :cascade do |t|
    t.bigint 'account_id'
    t.datetime 'created_at', null: false
    t.string 'email'
    t.string 'first_name'
    t.string 'last_name'
    t.string 'password_digest'
    t.string 'role', default: 'owner', null: false
    t.datetime 'updated_at', null: false
    t.index ['account_id'], name: 'index_users_on_account_id'
    t.index ['email'], name: 'index_users_on_email', unique: true
  end

  add_foreign_key 'appointment_services', 'appointments'
  add_foreign_key 'appointment_services', 'services'
  add_foreign_key 'appointments', 'accounts'
  add_foreign_key 'appointments', 'clients'
  add_foreign_key 'appointments', 'resources'
  add_foreign_key 'appointments', 'users'
  add_foreign_key 'clients', 'accounts'
  add_foreign_key 'clients', 'users'
  add_foreign_key 'notes', 'clients'
  add_foreign_key 'notes', 'users'
  add_foreign_key 'resources', 'accounts'
  add_foreign_key 'services', 'accounts'
  add_foreign_key 'services', 'users'
  add_foreign_key 'users', 'accounts'
end
