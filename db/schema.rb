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

ActiveRecord::Schema.define(version: 20190227044711) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "address_assignments", force: :cascade do |t|
    t.string   "address_user_type",       null: false
    t.integer  "address_user_id",         null: false
    t.integer  "notification_address_id", null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["address_user_type", "address_user_id"], name: "index_address_assignments_on_address_user_type_and_id", using: :btree
    t.index ["notification_address_id"], name: "index_address_assignments_on_notification_address_id", using: :btree
  end

  create_table "analysis_events", force: :cascade do |t|
    t.integer  "tradable_event_set_id", null: false
    t.datetime "date_time",             null: false
    t.string   "signal_type",           null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["tradable_event_set_id"], name: "index_analysis_events_on_tradable_event_set_id", using: :btree
  end

  create_table "analysis_profile_runs", force: :cascade do |t|
    t.integer  "user_id",                             null: false
    t.integer  "analysis_profile_id"
    t.string   "analysis_profile_name",               null: false
    t.string   "analysis_profile_client",             null: false
    t.datetime "run_start_time",                      null: false
    t.datetime "expiration_date",                     null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "notification_status",     default: 1, null: false
    t.integer  "lock_version"
    t.index ["analysis_profile_id"], name: "index_analysis_profile_runs_on_analysis_profile_id", using: :btree
    t.index ["user_id"], name: "index_analysis_profile_runs_on_user_id", using: :btree
  end

  create_table "analysis_profiles", force: :cascade do |t|
    t.string   "name",                                 null: false
    t.string   "analysis_client_type",                 null: false
    t.integer  "analysis_client_id",                   null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.boolean  "save_results",         default: false, null: false
    t.index ["analysis_client_type", "analysis_client_id"], name: "index_analysis_profiles_on_analysis_client_type_and_id", using: :btree
    t.index ["name", "analysis_client_id"], name: "index_analysis_profiles_on_name_and_analysis_client_id", unique: true, using: :btree
  end

  create_table "analysis_runs", force: :cascade do |t|
    t.integer  "status",                  null: false
    t.datetime "start_date",              null: false
    t.datetime "end_date",                null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "analysis_profile_run_id", null: false
    t.index ["analysis_profile_run_id"], name: "index_analysis_runs_on_analysis_profile_run_id", using: :btree
  end

  create_table "analysis_schedules", force: :cascade do |t|
    t.string   "name",         null: false
    t.boolean  "active",       null: false
    t.string   "trigger_type"
    t.integer  "trigger_id"
    t.integer  "user_id",      null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["name", "user_id"], name: "index_analysis_schedules_on_name_and_user_id", unique: true, using: :btree
    t.index ["trigger_type", "trigger_id"], name: "index_analysis_schedules_on_trigger_type_and_id", using: :btree
    t.index ["user_id"], name: "index_analysis_schedules_on_user_id", using: :btree
  end

  create_table "close_date_links", force: :cascade do |t|
    t.string   "market_type",          null: false
    t.integer  "market_id",            null: false
    t.integer  "market_close_date_id", null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.index ["market_close_date_id"], name: "index_close_date_links_on_market_close_date_id", using: :btree
    t.index ["market_type", "market_id"], name: "index_close_date_links_on_market_type_and_market_id", using: :btree
  end

  create_table "event_based_triggers", force: :cascade do |t|
    t.integer  "triggered_event_type"
    t.boolean  "activated",            default: false, null: false
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "status",               default: 1,     null: false
    t.integer  "lock_version",         default: 0,     null: false
  end

  create_table "event_generation_profiles", force: :cascade do |t|
    t.integer  "analysis_profile_id"
    t.datetime "end_date"
    t.integer  "analysis_period_length_seconds", null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.index ["analysis_profile_id"], name: "index_event_generation_profiles_on_analysis_profile_id", using: :btree
  end

  create_table "event_statuses", force: :cascade do |t|
    t.string   "name",                   null: false
    t.integer  "status",     default: 0, null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  create_table "exchanges", force: :cascade do |t|
    t.string   "name",                   null: false
    t.integer  "type",       default: 1, null: false
    t.string   "timezone",               null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "full_name"
    t.index ["name"], name: "index_exchanges_on_name", unique: true, using: :btree
  end

  create_table "market_close_dates", force: :cascade do |t|
    t.integer  "year",       null: false
    t.integer  "month",      null: false
    t.integer  "day",        null: false
    t.string   "reason",     null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year", "reason"], name: "index_market_close_dates_on_year_and_reason", unique: true, using: :btree
  end

  create_table "market_schedules", force: :cascade do |t|
    t.string   "market_type"
    t.integer  "market_id"
    t.integer  "schedule_type",          default: 1, null: false
    t.string   "date"
    t.string   "pre_market_start_time"
    t.string   "pre_market_end_time"
    t.string   "post_market_start_time"
    t.string   "post_market_end_time"
    t.string   "core_start_time",                    null: false
    t.string   "core_end_time",                      null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.index ["market_type", "market_id"], name: "index_market_schedules_on_market_type_and_market_id", using: :btree
  end

  create_table "mas_sessions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mas_session_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "data"
  end

  create_table "mas_socket_addresses", force: :cascade do |t|
    t.string   "name"
    t.string   "fqdn",       default: "", null: false
    t.integer  "port",                    null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "notification_addresses", force: :cascade do |t|
    t.integer  "user_id",            null: false
    t.string   "label",              null: false
    t.integer  "medium_type",        null: false
    t.string   "contact_identifier", null: false
    t.string   "extra_data"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.index ["label"], name: "index_notification_addresses_on_label", unique: true, using: :btree
    t.index ["user_id"], name: "index_notification_addresses_on_user_id", using: :btree
  end

  create_table "notifications", force: :cascade do |t|
    t.string   "notification_source_type", null: false
    t.integer  "notification_source_id",   null: false
    t.integer  "status",                   null: false
    t.string   "error_message"
    t.string   "contact_identifier",       null: false
    t.string   "synopsis"
    t.integer  "medium_type",              null: false
    t.integer  "user_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.index ["notification_source_type", "notification_source_id"], name: "index_notifications_on_notification_source_type_and_id", using: :btree
    t.index ["user_id"], name: "index_notifications_on_user_id", using: :btree
  end

  create_table "period_type_specs", force: :cascade do |t|
    t.integer  "period_type_id", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "category"
    t.index ["user_id"], name: "index_period_type_specs_on_user_id", using: :btree
  end

  create_table "periodic_triggers", force: :cascade do |t|
    t.integer  "interval_seconds"
    t.time     "time_window_start"
    t.time     "time_window_end"
    t.integer  "schedule_type"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "status",            default: 1, null: false
    t.integer  "lock_version",      default: 0, null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["session_id"], name: "index_sessions_on_session_id", using: :btree
    t.index ["updated_at"], name: "index_sessions_on_updated_at", using: :btree
  end

  create_table "symbol_list_assignments", force: :cascade do |t|
    t.string   "symbol_list_user_type", null: false
    t.integer  "symbol_list_user_id",   null: false
    t.integer  "symbol_list_id",        null: false
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["symbol_list_id"], name: "index_symbol_list_assignments_on_symbol_list_id", using: :btree
    t.index ["symbol_list_user_type", "symbol_list_user_id"], name: "index_symbol_list_assignments_on_list_user_type_and_id", using: :btree
  end

  create_table "symbol_lists", force: :cascade do |t|
    t.string   "name",        null: false
    t.string   "description"
    t.integer  "symbols",                  array: true
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["name"], name: "index_symbol_lists_on_name", using: :btree
  end

  create_table "tradable_analyzers", force: :cascade do |t|
    t.text     "name",        null: false
    t.integer  "event_id",    null: false
    t.boolean  "is_intraday", null: false
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "tradable_entities", id: false, force: :cascade do |t|
    t.string   "symbol",     null: false
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["symbol"], name: "index_tradable_entities_on_symbol", unique: true, using: :btree
  end

  create_table "tradable_event_sets", force: :cascade do |t|
    t.integer  "tradable_processor_run_id", null: false
    t.string   "symbol",                    null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["tradable_processor_run_id"], name: "index_tradable_event_sets_on_tradable_processor_run_id", using: :btree
  end

  create_table "tradable_processor_parameter_settings", force: :cascade do |t|
    t.integer  "tradable_processor_run_id", null: false
    t.string   "name",                      null: false
    t.string   "value",                     null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["tradable_processor_run_id"], name: "index_tradable_proc_param_settings_on_tradable_proc_run_id", using: :btree
  end

  create_table "tradable_processor_parameters", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.string   "data_type"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "sequence_number"
    t.integer  "tradable_processor_specification_id"
    t.index ["tradable_processor_specification_id"], name: "index_trad_proc_params_on_tradable_processor_specification_id", using: :btree
  end

  create_table "tradable_processor_runs", force: :cascade do |t|
    t.integer  "analysis_run_id", null: false
    t.integer  "processor_id",    null: false
    t.integer  "period_type",     null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["analysis_run_id"], name: "index_tradable_processor_runs_on_analysis_run_id", using: :btree
  end

  create_table "tradable_processor_specifications", force: :cascade do |t|
    t.integer  "event_generation_profile_id"
    t.integer  "processor_id",                null: false
    t.integer  "period_type",                 null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.index ["event_generation_profile_id"], name: "index_tradable_processor_specs_on_event_generation_profile_id", using: :btree
  end

  create_table "tradable_symbols", force: :cascade do |t|
    t.string   "symbol",                      null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "exchange_id"
    t.boolean  "tracked",     default: false, null: false
    t.index ["exchange_id"], name: "index_tradable_symbols_on_exchange_id", using: :btree
    t.index ["symbol"], name: "index_tradable_symbols_on_symbol", unique: true, using: :btree
    t.index ["tracked"], name: "index_tradable_symbols_on_tracked", using: :btree
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
    t.boolean  "admin",              default: false, null: false
    t.index ["email_addr"], name: "index_users_on_email_addr", unique: true, using: :btree
  end

  add_foreign_key "close_date_links", "market_close_dates"
  add_foreign_key "symbol_list_assignments", "symbol_lists"
  add_foreign_key "tradable_symbols", "exchanges"
  add_foreign_key "tradable_symbols", "tradable_entities", column: "symbol", primary_key: "symbol"
end
