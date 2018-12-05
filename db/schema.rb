# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181205111333) do

  create_table "analysis_profiles", force: :cascade do |t|
    t.string   "name"
    t.string   "analysis_client_type"
    t.integer  "analysis_client_id"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "save_results",         default: false, null: false
    t.index ["analysis_client_type", "analysis_client_id"], name: "index_analysis_profiles_on_analysis_client_type_and_id"
  end

  create_table "analysis_schedules", force: :cascade do |t|
    t.string   "name"
    t.boolean  "active"
    t.string   "trigger_type"
    t.integer  "trigger_id"
    t.integer  "user_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["trigger_type", "trigger_id"], name: "index_analysis_schedules_on_trigger_type_and_id"
    t.index ["user_id"], name: "index_analysis_schedules_on_user_id"
  end

  create_table "event_based_triggers", force: :cascade do |t|
    t.integer  "triggered_event_type"
    t.boolean  "activated",            default: false, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
  end

  create_table "event_generation_profiles", force: :cascade do |t|
    t.integer  "analysis_profile_id"
    t.datetime "end_date"
    t.integer  "analysis_period_length_seconds"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["analysis_profile_id"], name: "index_event_generation_profiles_on_analysis_profile_id"
  end

  create_table "mas_sessions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mas_session_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "data"
  end

  create_table "period_type_specs", force: :cascade do |t|
    t.integer  "period_type_id", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
    t.index ["user_id"], name: "index_period_type_specs_on_user_id"
  end

  create_table "periodic_triggers", force: :cascade do |t|
    t.integer  "interval_seconds"
    t.time     "time_window_start"
    t.time     "time_window_end"
    t.integer  "schedule_type"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id"
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "tradable_analyzers", force: :cascade do |t|
    t.text     "name"
    t.integer  "event_id"
    t.boolean  "is_intraday"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "tradable_entities", id: false, force: :cascade do |t|
    t.string   "symbol",     null: false
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["symbol"], name: "index_tradable_entities_on_symbol", unique: true
  end

  create_table "tradable_processor_parameters", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.string   "data_type"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "sequence_number"
    t.integer  "tradable_processor_specification_id"
    t.index ["tradable_processor_specification_id"], name: "index_trad_proc_params_on_tradable_processor_specification_id"
  end

  create_table "tradable_processor_specifications", force: :cascade do |t|
    t.integer  "event_generation_profile_id"
    t.integer  "processor_id"
    t.integer  "period_type"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["event_generation_profile_id"], name: "index_tradable_processor_specs_on_event_generation_profile_id"
  end

  create_table "tradables", force: :cascade do |t|
    t.text     "name",       null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "symbol",     null: false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email_addr"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "encrypted_password"
    t.string   "salt"
    t.boolean  "admin",              default: false
    t.index ["email_addr"], name: "index_users_on_email_addr", unique: true
  end

end
