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

ActiveRecord::Schema[8.1].define(version: 2026_10_23_175217) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "business_name"
    t.datetime "created_at", null: false
    t.string "timezone", default: "America/Denver", null: false
    t.datetime "updated_at", null: false
  end

  create_table "appointment_services", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.datetime "created_at", null: false
    t.decimal "price_at_booking", precision: 10, scale: 2
    t.bigint "service_id", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id", "service_id"], name: "index_appointment_services_on_appointment_id_and_service_id", unique: true
    t.index ["appointment_id"], name: "index_appointment_services_on_appointment_id"
    t.index ["service_id"], name: "index_appointment_services_on_service_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration_minutes", null: false
    t.boolean "duration_overridden", default: false, null: false
    t.bigint "resource_id", null: false
    t.datetime "scheduled_at", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id", "resource_id", "scheduled_at"], name: "index_appointments_on_account_resource_time"
    t.index ["account_id", "scheduled_at"], name: "index_appointments_on_account_and_scheduled_at"
    t.index ["account_id"], name: "index_appointments_on_account_id"
    t.index ["client_id"], name: "index_appointments_on_client_id"
    t.index ["resource_id"], name: "index_appointments_on_resource_id"
    t.index ["user_id"], name: "index_appointments_on_user_id"
  end

  create_table "availability_blocks", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.boolean "is_available", default: false, null: false
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id"], name: "index_availability_blocks_on_account_id"
    t.index ["user_id", "starts_at", "ends_at"], name: "index_availability_blocks_on_user_and_times"
    t.index ["user_id"], name: "index_availability_blocks_on_user_id"
    t.check_constraint "ends_at > starts_at", name: "availability_blocks_valid_times"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_clients_on_account_id"
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "body"
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["client_id"], name: "index_notes_on_client_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "password_resets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["token_digest"], name: "index_password_resets_on_token_digest", unique: true
    t.index ["user_id"], name: "index_password_resets_on_user_id"
  end

  create_table "resources", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_resources_on_account_id"
    t.index ["name", "account_id"], name: "index_resources_on_name_and_account_id", unique: true
  end

  create_table "services", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes"
    t.decimal "price"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["account_id", "title"], name: "index_services_on_account_id_and_title", unique: true
    t.index ["account_id"], name: "index_services_on_account_id"
  end

  create_table "user_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.bigint "invited_by_id", null: false
    t.string "role", null: false
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_user_invitations_on_account_id"
    t.index ["invited_by_id"], name: "index_user_invitations_on_invited_by_id"
    t.index ["token_digest"], name: "index_user_invitations_on_token_digest", unique: true
  end

  create_table "user_services", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.bigint "service_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["service_id"], name: "index_user_services_on_service_id"
    t.index ["user_id", "service_id"], name: "index_user_services_on_user_id_and_service_id", unique: true
    t.index ["user_id"], name: "index_user_services_on_user_id"
  end

  create_table "user_working_hours", force: :cascade do |t|
    t.time "closes_at"
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.boolean "is_closed", default: false, null: false
    t.time "opens_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "day_of_week"], name: "index_user_working_hours_on_user_id_and_day_of_week"
    t.index ["user_id", "day_of_week"], name: "index_user_working_hours_unique_closed_day", unique: true, where: "(is_closed = true)"
    t.index ["user_id"], name: "index_user_working_hours_on_user_id"
    t.check_constraint "day_of_week >= 0 AND day_of_week <= 6", name: "user_working_hours_valid_day"
    t.check_constraint "is_closed = true AND opens_at IS NULL AND closes_at IS NULL OR is_closed = false AND opens_at IS NOT NULL AND closes_at IS NOT NULL AND closes_at > opens_at", name: "user_working_hours_valid_times"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest"
    t.string "role", default: "owner", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "working_hours", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.time "closes_at", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "opens_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "day_of_week"], name: "index_working_hours_on_account_id_and_day_of_week"
    t.index ["account_id"], name: "index_working_hours_on_account_id"
    t.check_constraint "closes_at > opens_at", name: "working_hours_valid_times"
    t.check_constraint "day_of_week >= 0 AND day_of_week <= 6", name: "working_hours_valid_day"
  end

  add_foreign_key "appointment_services", "appointments"
  add_foreign_key "appointment_services", "services"
  add_foreign_key "appointments", "accounts"
  add_foreign_key "appointments", "clients"
  add_foreign_key "appointments", "resources"
  add_foreign_key "appointments", "users"
  add_foreign_key "availability_blocks", "accounts"
  add_foreign_key "availability_blocks", "users"
  add_foreign_key "clients", "accounts"
  add_foreign_key "clients", "users"
  add_foreign_key "notes", "clients"
  add_foreign_key "notes", "users"
  add_foreign_key "password_resets", "users"
  add_foreign_key "resources", "accounts"
  add_foreign_key "services", "accounts"
  add_foreign_key "user_invitations", "accounts"
  add_foreign_key "user_invitations", "users", column: "invited_by_id"
  add_foreign_key "user_services", "services"
  add_foreign_key "user_services", "users"
  add_foreign_key "user_working_hours", "users"
  add_foreign_key "users", "accounts"
  add_foreign_key "working_hours", "accounts"
end
