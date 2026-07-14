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

ActiveRecord::Schema[8.1].define(version: 2026_07_14_140346) do
  create_table "chapter_progresses", force: :cascade do |t|
    t.string "chapter_id", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "chapter_id"], name: "index_chapter_progresses_on_user_id_and_chapter_id", unique: true
    t.index ["user_id"], name: "index_chapter_progresses_on_user_id"
  end

  create_table "payment_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "KRW", null: false
    t.string "order_id", null: false
    t.string "provider", null: false
    t.json "provider_payload"
    t.string "provider_payment_id", null: false
    t.string "status", default: "pending", null: false
    t.integer "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payment_transactions_on_order_id", unique: true
    t.index ["provider", "provider_payment_id"], name: "index_payment_transactions_on_provider_and_provider_payment_id", unique: true
    t.index ["subscription_id"], name: "index_payment_transactions_on_subscription_id"
  end

  create_table "premium_waitlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "source", default: "landing_pricing", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_premium_waitlists_on_email", unique: true
  end

  create_table "service_desk_jobs", force: :cascade do |t|
    t.string "author", null: false
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "job_number", null: false
    t.datetime "performed_at", null: false
    t.integer "service_desk_request_id", null: false
    t.datetime "updated_at", null: false
    t.index ["service_desk_request_id", "job_number"], name: "idx_on_service_desk_request_id_job_number_b8b84ea463", unique: true
    t.index ["service_desk_request_id"], name: "index_service_desk_jobs_on_service_desk_request_id"
  end

  create_table "service_desk_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.text "description"
    t.integer "request_number", null: false
    t.string "requester", null: false
    t.integer "status", default: 0, null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.integer "visibility", default: 0, null: false
    t.index ["request_number"], name: "index_service_desk_requests_on_request_number", unique: true
  end

  create_table "subscriptions", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.string "billing_key"
    t.datetime "cancel_at"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.datetime "current_period_start"
    t.string "order_id"
    t.string "provider", null: false
    t.string "provider_customer_id", null: false
    t.string "status", default: "pending", null: false
    t.string "toss_billing_key"
    t.string "toss_customer_key"
    t.string "toss_payment_key"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["order_id"], name: "index_subscriptions_on_order_id", unique: true
    t.index ["provider", "provider_customer_id"], name: "index_subscriptions_on_provider_and_provider_customer_id", unique: true
    t.index ["toss_customer_key"], name: "index_subscriptions_on_toss_customer_key", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "chapter_progresses", "users"
  add_foreign_key "payment_transactions", "subscriptions"
  add_foreign_key "service_desk_jobs", "service_desk_requests"
  add_foreign_key "subscriptions", "users"
end
