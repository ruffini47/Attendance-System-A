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

ActiveRecord::Schema.define(version: 20191211114720) do

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "overtime_applying", default: false
    t.datetime "scheduled_end_time", default: "2019-12-12 09:00:00"
    t.string "business_processing"
    t.integer "to_superior_user_id"
    t.integer "instructor_confirmation", default: 0
    t.string "result"
    t.datetime "temp_scheduled_end_time"
    t.string "temp_business_processing"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "bases", force: :cascade do |t|
    t.integer "number"
    t.string "name"
    t.string "attendance_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "password_digest"
    t.string "remember_digest"
    t.boolean "admin", default: false
    t.boolean "superior", default: false
    t.integer "employee_number"
    t.string "uid"
    t.string "affiliation"
    t.datetime "basic_work_time", default: "2019-12-11 23:00:00"
    t.datetime "designated_work_start_time", default: "2019-12-12 00:00:00"
    t.datetime "designated_work_end_time", default: "2019-12-12 09:00:00"
    t.integer "number_of_overtime_applied", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
