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

ActiveRecord::Schema.define(version: 20200119112654) do

  create_table "attendances", force: :cascade do |t|
    t.date "worked_on"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "note"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "overtime_applying", default: false
    t.datetime "scheduled_end_time"
    t.string "business_processing"
    t.integer "to_superior_user_id"
    t.integer "instructor_confirmation", default: 0
    t.string "result"
    t.datetime "temp_scheduled_end_time"
    t.string "temp_business_processing"
    t.integer "tomorrow"
    t.datetime "cl_scheduled_end_time"
    t.datetime "cr_scheduled_end_time"
    t.string "cl_business_processing"
    t.string "cr_business_processing"
    t.integer "attendance_hour"
    t.integer "attendance_min"
    t.integer "departure_hour"
    t.integer "departure_min"
    t.boolean "attendance_change_applying", default: false
    t.integer "temp_attendance_change_to_superior_user_id"
    t.datetime "after_change_start_time"
    t.datetime "after_change_end_time"
    t.string "attendance_change_note"
    t.datetime "cr_after_change_end_time"
    t.string "cr_attendance_change_note"
    t.datetime "temp_after_change_start_time"
    t.datetime "temp_after_change_end_time"
    t.string "temp_attendance_change_note"
    t.string "last_attendance_change_note"
    t.datetime "cr_after_change_start_time"
    t.integer "attendance_change_tomorrow"
    t.integer "attendance_change_instructor_confirmation", default: 0
    t.boolean "manager_approval_applying", default: false
    t.integer "manager_approval_to_superior_user_id"
    t.string "manager_approval", default: "所属長承認　未"
    t.integer "saved_attendance_change_to_superior_user_id"
    t.datetime "attendance_change_approved_datetime"
    t.datetime "before_change_start_time"
    t.datetime "before_change_end_time"
    t.integer "time_log_count", default: 0
    t.boolean "time_log_attendance_change_approved", default: false
    t.integer "attendance_change_to_superior_user_id"
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
    t.datetime "basic_work_time", default: "2020-01-18 23:00:00"
    t.datetime "designated_work_start_time", default: "2020-01-19 00:00:00"
    t.datetime "designated_work_end_time", default: "2020-01-19 09:00:00"
    t.integer "number_of_overtime_applied", default: 0
    t.integer "number_of_attendance_change_applied", default: 0
    t.integer "number_of_manager_approval_applied", default: 0
    t.index ["email"], name: "index_users_on_email", unique: true
  end

end
