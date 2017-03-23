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

ActiveRecord::Schema.define(version: 20170322142317) do

  create_table "mas_sessions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "mas_session_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "data"
  end

  create_table "parameter_groups", force: :cascade do |t|
    t.string   "name"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_parameter_groups_on_name"
    t.index ["user_id"], name: "index_parameter_groups_on_user_id"
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
    t.integer  "mas_session_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["mas_session_id"], name: "index_tradable_analyzers_on_mas_session_id"
  end

  create_table "tradable_processor_parameters", force: :cascade do |t|
    t.string   "name"
    t.string   "value"
    t.string   "data_type"
    t.integer  "parameter_group_id"
    t.integer  "tradable_processor_id"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.index ["parameter_group_id"], name: "index_tradable_processor_parameters_on_parameter_group_id"
    t.index ["tradable_processor_id"], name: "index_tradable_processor_parameters_on_tradable_processor_id"
  end

  create_table "tradable_processors", force: :cascade do |t|
    t.string   "name"
    t.string   "tp_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tradable_processors_on_name", unique: true
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
