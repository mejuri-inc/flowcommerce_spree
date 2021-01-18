# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20201116193935) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"

  create_table "ab_results", force: true do |t|
    t.integer "order_id"
    t.boolean "new_checkout"
  end

  add_index "ab_results", ["order_id"], name: "index_ab_results_on_order_id", using: :btree

  create_table "ab_testings", force: true do |t|
    t.string   "name"
    t.boolean  "active"
    t.integer  "percentage"
    t.integer  "country_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_a"
    t.string   "url_b"
  end

  create_table "active_admin_comments", force: true do |t|
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id", using: :btree

  create_table "addresses", force: true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "zipcode"
    t.string   "phone"
    t.string   "state_name"
    t.string   "alternative_phone"
    t.integer  "state_id"
    t.integer  "country_id"
    t.string   "company"
    t.string   "email"
    t.integer  "user_profile_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  add_index "addresses", ["user_profile_id"], name: "index_addresses_on_user_profile_id", using: :btree

  create_table "ambassador_links", force: true do |t|
    t.string   "uid"
    t.string   "email"
    t.string   "internal_id"
    t.string   "active_share_url"
    t.string   "memorable_url"
    t.string   "first_name"
    t.string   "mejuri_url"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "campaigns", force: true do |t|
    t.integer  "spree_promotion_id"
    t.datetime "starts_at"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "campaigns", ["spree_promotion_id"], name: "index_campaigns_on_spree_promotion_id", using: :btree

  create_table "carrier_providers", force: true do |t|
    t.string   "narvar_code"
    t.string   "narvar_name"
    t.string   "fulfil_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chic_weeks_products", force: true do |t|
    t.integer "chic_week_id"
    t.integer "product_id"
  end

  create_table "collections", force: true do |t|
    t.string   "title1"
    t.string   "title2"
    t.text     "description"
    t.string   "banner_file_name"
    t.string   "banner_content_type"
    t.integer  "banner_file_size"
    t.datetime "banner_updated_at"
    t.string   "background_file_name"
    t.string   "background_content_type"
    t.integer  "background_file_size"
    t.datetime "background_updated_at"
    t.string   "picture1_file_name"
    t.string   "picture1_content_type"
    t.integer  "picture1_file_size"
    t.datetime "picture1_updated_at"
    t.string   "picture2_file_name"
    t.string   "picture2_content_type"
    t.integer  "picture2_file_size"
    t.datetime "picture2_updated_at"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "home_position"
    t.string   "home_image_file_name"
    t.string   "home_image_content_type"
    t.integer  "home_image_file_size"
    t.datetime "home_image_updated_at"
    t.string   "picture_1_link"
    t.string   "picture_2_link"
    t.string   "home_image_title"
    t.string   "home_image_tagline"
    t.string   "bottom_image_file_name"
    t.string   "bottom_image_content_type"
    t.integer  "bottom_image_file_size"
    t.datetime "bottom_image_updated_at"
    t.string   "pinterest_picture1"
    t.string   "pinterest_picture2"
    t.text     "seo_description"
    t.string   "seo_title"
    t.text     "seo_keywords"
    t.string   "alternative_link"
    t.string   "link_text"
    t.boolean  "black_background"
    t.boolean  "published"
    t.string   "menu_title"
    t.text     "short_description"
    t.integer  "holiday_order"
    t.string   "holiday_image_file_name"
    t.string   "holiday_image_content_type"
    t.integer  "holiday_image_file_size"
    t.datetime "holiday_image_updated_at"
    t.boolean  "happiness"
    t.string   "boutique"
    t.boolean  "category"
    t.string   "mobile_banner_file_name"
    t.string   "mobile_banner_content_type"
    t.integer  "mobile_banner_file_size"
    t.datetime "mobile_banner_updated_at"
    t.text     "picture1_text"
    t.text     "picture2_text"
    t.integer  "position"
    t.boolean  "new_arrival"
    t.boolean  "curation"
    t.string   "video_1_url"
    t.string   "video_2_url"
    t.string   "mobile_video_1_url"
    t.string   "mobile_video_2_url"
    t.boolean  "curation_video"
    t.string   "picture1_title"
    t.string   "picture2_title"
    t.string   "mobile_bottom_image_file_name"
    t.string   "mobile_bottom_image_content_type"
    t.integer  "mobile_bottom_image_file_size"
    t.datetime "mobile_bottom_image_updated_at"
    t.boolean  "curation_influencer"
    t.datetime "deleted_at"
  end

  add_index "collections", ["deleted_at"], name: "index_collections_on_deleted_at", using: :btree

  create_table "collections_products", force: true do |t|
    t.integer "collection_id"
    t.integer "product_id"
    t.integer "position"
  end

  create_table "countries_promotion_rules", id: false, force: true do |t|
    t.integer "country_id"
    t.integer "promotion_rule_id"
  end

  add_index "countries_promotion_rules", ["country_id"], name: "index_countries_promotion_rules_on_country_id", using: :btree
  add_index "countries_promotion_rules", ["promotion_rule_id"], name: "index_countries_promotion_rules_on_promotion_rule_id", using: :btree

  create_table "custom_configs", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.text     "config"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custom_configs", ["slug"], name: "index_custom_configs_on_slug", using: :btree

  create_table "delayed_jobs", force: true do |t|
    t.integer  "priority",   default: 0
    t.integer  "attempts",   default: 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "email_templates", force: true do |t|
    t.string   "name",       null: false
    t.string   "subject",    null: false
    t.string   "from",       null: false
    t.string   "cc"
    t.string   "bcc"
    t.text     "body",       null: false
    t.text     "template"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exception_reports", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "report_filename"
    t.integer  "no_exceptions"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.datetime "exception_time"
    t.boolean  "email_sent"
    t.hstore   "extra_data"
  end

  add_index "exception_reports", ["extra_data"], name: "index_exception_reports_on_extra_data", using: :gist

  create_table "faq_categories", force: true do |t|
    t.string   "slug"
    t.string   "name"
    t.text     "description"
    t.integer  "order"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "faq_categories", ["slug"], name: "index_faq_categories_on_slug", using: :btree

  create_table "faqs", force: true do |t|
    t.integer  "faq_category_id"
    t.string   "question"
    t.text     "answer"
    t.integer  "order"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "faqs", ["faq_category_id"], name: "index_faqs_on_faq_category_id", using: :btree

  create_table "gift_options", force: true do |t|
    t.integer  "line_item_id"
    t.string   "messages",     default: [], array: true
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "gift_options", ["line_item_id"], name: "index_gift_options_on_line_item_id", using: :btree

  create_table "gifts", force: true do |t|
    t.decimal  "amount"
    t.integer  "user_id"
    t.string   "from_name"
    t.string   "from_email"
    t.string   "to_name"
    t.string   "to_email"
    t.text     "message"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "used"
    t.string   "gift_code"
    t.integer  "line_item_id"
    t.boolean  "physical",     default: false
  end

  add_index "gifts", ["line_item_id"], name: "index_gifts_on_line_item_id", using: :btree

  create_table "giveaway_pages", force: true do |t|
    t.string   "top_description_1"
    t.string   "top_description_2"
    t.string   "disclaimer"
    t.string   "terms_and_conditions_link"
    t.string   "description_3"
    t.string   "middle_section_top_title"
    t.string   "middle_section_top_description"
    t.string   "middle_section_bottom_title"
    t.string   "middle_section_bottom_description"
    t.string   "bottom_form_title"
    t.string   "bottom_form_description"
    t.string   "zaius_campaign_name"
    t.string   "desktop_top_banner_img_file_name"
    t.string   "desktop_top_banner_img_content_type"
    t.integer  "desktop_top_banner_img_file_size"
    t.datetime "desktop_top_banner_img_updated_at"
    t.string   "middle_section_desktop_img_left_file_name"
    t.string   "middle_section_desktop_img_left_content_type"
    t.integer  "middle_section_desktop_img_left_file_size"
    t.datetime "middle_section_desktop_img_left_updated_at"
    t.string   "middle_section_desktop_img_right_file_name"
    t.string   "middle_section_desktop_img_right_content_type"
    t.integer  "middle_section_desktop_img_right_file_size"
    t.datetime "middle_section_desktop_img_right_updated_at"
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "bottom_banner_desktop_img_file_name"
    t.string   "bottom_banner_desktop_img_content_type"
    t.integer  "bottom_banner_desktop_img_file_size"
    t.datetime "bottom_banner_desktop_img_updated_at"
    t.string   "mobile_top_banner_img_file_name"
    t.string   "mobile_top_banner_img_content_type"
    t.integer  "mobile_top_banner_img_file_size"
    t.datetime "mobile_top_banner_img_updated_at"
    t.string   "middle_section_mobile_img_file_name"
    t.string   "middle_section_mobile_img_content_type"
    t.integer  "middle_section_mobile_img_file_size"
    t.datetime "middle_section_mobile_img_updated_at"
    t.string   "bottom_banner_mobile_img_file_name"
    t.string   "bottom_banner_mobile_img_content_type"
    t.integer  "bottom_banner_mobile_img_file_size"
    t.datetime "bottom_banner_mobile_img_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "url_path"
    t.string   "form_submitted_msg"
    t.string   "privacy_policy_link"
  end

  create_table "home_slides", force: true do |t|
    t.string   "title"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "button_text"
    t.string   "button_link"
    t.string   "button_inline_style"
    t.datetime "published_at"
    t.datetime "expired_at"
    t.boolean  "is_active",                  default: true
    t.integer  "order",                      default: 0
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "link"
    t.boolean  "designer_site"
    t.string   "tab_name"
    t.string   "mobile_image_file_name"
    t.string   "mobile_image_content_type"
    t.integer  "mobile_image_file_size"
    t.datetime "mobile_image_updated_at"
    t.string   "overlay_image_file_name"
    t.string   "overlay_image_content_type"
    t.integer  "overlay_image_file_size"
    t.datetime "overlay_image_updated_at"
    t.boolean  "instagram"
    t.string   "instagram_link"
    t.boolean  "designer_landing"
    t.boolean  "youtube"
  end

  create_table "influencers", force: true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.string   "name"
    t.text     "bio"
    t.string   "site"
    t.string   "youtube"
    t.string   "twitter"
    t.text     "notes"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  create_table "klarna_credit_payments", force: true do |t|
    t.integer  "spree_order_id"
    t.string   "klarna_order_id"
    t.string   "authorization_token"
    t.string   "fraud_status"
    t.datetime "expires_at"
    t.integer  "payment_method_id"
    t.integer  "user_id"
    t.string   "status"
    t.string   "purchase_currency"
    t.string   "locale"
    t.text     "response_body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "kpis", force: true do |t|
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "transactions"
    t.integer  "repeated_customers"
    t.integer  "new_repeated_customers"
    t.integer  "total_customers"
    t.decimal  "aov_repeated_customers"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "period_type"
  end

  create_table "landing_pages", force: true do |t|
    t.string   "name"
    t.string   "slug"
    t.string   "url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "landing_pages", ["url"], name: "index_landing_pages_on_url", using: :btree

  create_table "material_categories", force: true do |t|
    t.string   "name"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
  end

  create_table "material_descriptions", force: true do |t|
    t.string   "icon_name"
    t.string   "name"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "icon_url"
  end

  create_table "material_groups", force: true do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "notification_reads", force: true do |t|
    t.integer  "notification_id"
    t.integer  "user_id"
    t.datetime "read_at"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "notification_reads", ["notification_id"], name: "index_notification_reads_on_notification_id", using: :btree
  add_index "notification_reads", ["user_id"], name: "index_notification_reads_on_user_id", using: :btree

  create_table "notifications", force: true do |t|
    t.string   "title"
    t.text     "content"
    t.string   "url"
    t.string   "status"
    t.datetime "published_at"
    t.datetime "expires_at"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "pages", force: true do |t|
    t.string   "slug"
    t.string   "title"
    t.text     "content"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.boolean  "show_title",        default: true,            null: false
    t.string   "format",            default: "simple_format", null: false
    t.string   "seo_keyword_url"
    t.string   "seo_keyword_title"
    t.string   "short_title"
    t.string   "status"
    t.text     "seo_description"
    t.text     "seo_keywords"
    t.boolean  "indexable",         default: true
  end

  add_index "pages", ["slug"], name: "index_pages_on_slug", unique: true, using: :btree
  add_index "pages", ["status"], name: "index_pages_on_status", using: :btree

  create_table "payments_cash_credits", force: true do |t|
    t.integer  "spree_order_id"
    t.integer  "payment_method_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "amount_paid"
  end

  create_table "preorders", force: true do |t|
    t.string   "celery_order"
    t.string   "slug"
    t.string   "email"
    t.string   "name"
    t.decimal  "total"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "referral"
    t.string   "state"
  end

  create_table "product_engravings", force: true do |t|
    t.integer  "line_item_id"
    t.string   "engraving"
    t.integer  "quantity"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "product_engravings", ["line_item_id"], name: "index_product_engravings_on_line_item_id", using: :btree

  create_table "product_extensions", force: true do |t|
    t.integer  "product_id"
    t.integer  "original_price"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "seo_keyword_url"
    t.string   "seo_keyword_title"
    t.text     "shipping_notes"
    t.text     "product_care"
    t.text     "seo_description"
    t.text     "seo_keywords"
    t.boolean  "gift"
    t.boolean  "bundle"
    t.text     "bundle_description"
    t.text     "regular_shipping_wording"
    t.text     "fast_shipping_wording"
    t.text     "long_shipping_wording"
    t.text     "chicweek_shipping_wording"
    t.decimal  "retail_price"
    t.string   "display_name"
    t.text     "details"
    t.integer  "display_retail_price"
  end

  add_index "product_extensions", ["product_id"], name: "index_product_extensions_on_product_id", using: :btree

  create_table "product_material_descriptions", force: true do |t|
    t.integer  "product_id"
    t.integer  "material_description_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_material_descriptions", ["material_description_id"], name: "index_product_material_descriptions_on_material_description_id", using: :btree
  add_index "product_material_descriptions", ["product_id"], name: "index_product_material_descriptions_on_product_id", using: :btree

  create_table "product_sizes", force: true do |t|
    t.integer  "line_item_id"
    t.string   "description"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "profile_credit_cards", force: true do |t|
    t.string   "name"
    t.string   "number"
    t.string   "expiration_month"
    t.string   "expiration_year"
    t.integer  "user_profile_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
    t.string   "stripe_source_id"
    t.string   "brand"
    t.string   "stripe_customer_id"
    t.integer  "payment_method_id"
    t.datetime "deleted_at"
  end

  add_index "profile_credit_cards", ["payment_method_id"], name: "index_profile_credit_cards_on_payment_method_id", using: :btree

  create_table "profile_messages", force: true do |t|
    t.string   "name"
    t.boolean  "visible"
    t.integer  "user_profile_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "profile_messages", ["user_profile_id"], name: "index_profile_messages_on_user_profile_id", using: :btree

  create_table "public_ets", force: true do |t|
    t.date     "value"
    t.integer  "spree_variant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "public_ets", ["spree_variant_id"], name: "index_public_ets_on_spree_variant_id", using: :btree

  create_table "purchase_locations", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "method"
    t.string   "ip_address"
    t.string   "external_id"
    t.integer  "fulfil_channel_id"
    t.string   "setup_code"
    t.string   "setup_code_hash"
    t.string   "currency"
    t.boolean  "retail",            default: false
    t.json     "address_data"
    t.float    "lat"
    t.float    "lng"
    t.json     "open_hours",        default: {}
  end

  add_index "purchase_locations", ["external_id"], name: "index_purchase_locations_on_external_id", using: :btree
  add_index "purchase_locations", ["ip_address"], name: "index_purchase_locations_on_ip_address", using: :btree
  add_index "purchase_locations", ["lat", "lng"], name: "index_purchase_locations_on_lat_and_lng", using: :btree
  add_index "purchase_locations", ["method"], name: "index_purchase_locations_on_method", using: :btree
  add_index "purchase_locations", ["setup_code_hash"], name: "index_purchase_locations_on_setup_code_hash", unique: true, using: :btree

  create_table "purchase_locations_promotion_rules", id: false, force: true do |t|
    t.integer "purchase_location_id"
    t.integer "promotion_rule_id"
  end

  add_index "purchase_locations_promotion_rules", ["promotion_rule_id"], name: "index_purchase_locations_promotion_rules_on_promotion_rule_id", using: :btree
  add_index "purchase_locations_promotion_rules", ["purchase_location_id"], name: "index_pos_promotion_rules_on_purchase_location_id", using: :btree

  create_table "real_time_inventories", force: true do |t|
    t.string   "sku"
    t.integer  "product_id"
    t.integer  "warehouse_id"
    t.integer  "quantity_on_hand"
    t.integer  "quantity_available"
    t.string   "warehouse_code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "redeemed_gift_cards", force: true do |t|
    t.string   "number",           null: false
    t.decimal  "original_amount",  null: false
    t.decimal  "current_credit",   null: false
    t.string   "currency",         null: false
    t.datetime "locked_date_time"
    t.boolean  "locked"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "referral_codes", force: true do |t|
    t.string   "code"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "referral_programs", force: true do |t|
    t.string   "status"
    t.string   "recipient"
    t.string   "customer_id"
    t.string   "widget"
    t.decimal  "reward"
    t.string   "order_number"
    t.date     "order_date"
    t.decimal  "order_amount"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.string   "sender"
    t.boolean  "used"
    t.datetime "used_at"
  end

  create_table "referred_events", force: true do |t|
    t.integer  "referable_id"
    t.string   "referable_type"
    t.integer  "user_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "region_settings", force: true do |t|
    t.string   "name"
    t.string   "taxon_permalink"
    t.text     "available_currencies", default: [], array: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "sku_suffix",           default: ""
  end

  create_table "region_settings_resources", force: true do |t|
    t.integer  "resource_id"
    t.string   "resource_type"
    t.integer  "region_setting_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "registered_emails", force: true do |t|
    t.string   "email"
    t.boolean  "invited",       default: false, null: false
    t.datetime "invited_on"
    t.integer  "invited_by_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.string   "contest_name"
  end

  add_index "registered_emails", ["email"], name: "index_registered_emails_on_email", unique: true, using: :btree
  add_index "registered_emails", ["invited"], name: "index_registered_emails_on_invited", using: :btree

  create_table "relation_types", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "applies_to"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "relations", force: true do |t|
    t.integer  "relation_type_id"
    t.integer  "relatable_id"
    t.string   "relatable_type"
    t.integer  "related_to_id"
    t.string   "related_to_type"
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.decimal  "discount_amount",  precision: 8, scale: 2, default: 0.0
  end

  create_table "return_items", force: true do |t|
    t.integer  "line_item_id"
    t.integer  "quantity"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "reason"
    t.string   "description"
    t.string   "filename"
    t.string   "public_url"
    t.string   "commercial_invoice_url"
    t.string   "ff_shipment_id"
  end

  add_index "return_items", ["line_item_id"], name: "index_return_items_on_line_item_id", using: :btree

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "roles", ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", using: :btree
  add_index "roles", ["name"], name: "index_roles_on_name", using: :btree

  create_table "sales_report_orders", force: true do |t|
    t.datetime "date"
    t.string   "number"
    t.string   "email"
    t.string   "country"
    t.string   "order_state"
    t.string   "payment"
    t.string   "payment_state"
    t.string   "name"
    t.string   "sizes"
    t.float    "price"
    t.float    "price_w_adjustments"
    t.string   "coupon"
    t.float    "coupon_discount"
    t.float    "bundle_percentage"
    t.float    "user_credit"
    t.float    "cogs"
    t.float    "total_order"
    t.string   "currency"
    t.string   "tracking"
    t.integer  "cart_size"
    t.float    "tax"
    t.string   "shipping"
    t.boolean  "gift_used"
    t.float    "giftamount"
    t.string   "taxons"
    t.datetime "available_on"
    t.string   "engraving"
    t.string   "material"
    t.string   "category"
    t.string   "pos"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "order_id"
    t.integer  "line_item_id"
    t.datetime "shipped_date"
    t.string   "province"
  end

  add_index "sales_report_orders", ["order_id", "line_item_id"], name: "index_sales_report_orders_on_order_id_and_line_item_id", unique: true, using: :btree

  create_table "services", force: true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.string   "uname"
    t.string   "uemail"
    t.text     "raw"
    t.datetime "deauthorized_at"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "services", ["provider", "uid"], name: "provider_uid_index", unique: true, using: :btree
  add_index "services", ["user_id"], name: "index_services_on_user_id", using: :btree

  create_table "spree_addresses", force: true do |t|
    t.string   "firstname"
    t.string   "lastname"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "zipcode"
    t.string   "phone"
    t.string   "state_name"
    t.string   "alternative_phone"
    t.integer  "state_id"
    t.integer  "country_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "company"
    t.string   "email"
  end

  add_index "spree_addresses", ["country_id"], name: "index_spree_addresses_on_country_id", using: :btree
  add_index "spree_addresses", ["firstname"], name: "index_addresses_on_firstname", using: :btree
  add_index "spree_addresses", ["lastname"], name: "index_addresses_on_lastname", using: :btree
  add_index "spree_addresses", ["state_id"], name: "index_spree_addresses_on_state_id", using: :btree

  create_table "spree_adjustments", force: true do |t|
    t.integer  "source_id"
    t.decimal  "amount",          precision: 10, scale: 2
    t.string   "label"
    t.string   "source_type"
    t.integer  "adjustable_id"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.boolean  "mandatory"
    t.integer  "originator_id"
    t.string   "originator_type"
    t.boolean  "eligible",                                 default: true
    t.string   "adjustable_type"
    t.string   "state"
    t.integer  "order_id",                                 default: 0,     null: false
    t.boolean  "included",                                 default: false
    t.datetime "deleted_at"
  end

  add_index "spree_adjustments", ["adjustable_id", "adjustable_type"], name: "index_spree_adjustments_on_adjustable_id_and_adjustable_type", using: :btree
  add_index "spree_adjustments", ["adjustable_id"], name: "index_adjustments_on_order_id", using: :btree
  add_index "spree_adjustments", ["deleted_at"], name: "index_spree_adjustments_on_deleted_at", using: :btree
  add_index "spree_adjustments", ["eligible"], name: "index_spree_adjustments_on_eligible", using: :btree
  add_index "spree_adjustments", ["order_id"], name: "index_spree_adjustments_on_order_id", using: :btree
  add_index "spree_adjustments", ["source_id", "source_type"], name: "index_spree_adjustments_on_source_id_and_source_type", using: :btree

  create_table "spree_assets", force: true do |t|
    t.integer  "viewable_id"
    t.integer  "attachment_width"
    t.integer  "attachment_height"
    t.integer  "attachment_file_size"
    t.integer  "position"
    t.string   "viewable_type",           limit: 50
    t.string   "attachment_content_type"
    t.string   "attachment_file_name"
    t.string   "type",                    limit: 75
    t.datetime "attachment_updated_at"
    t.text     "alt"
    t.string   "place"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spree_assets", ["viewable_id"], name: "index_assets_on_viewable_id", using: :btree
  add_index "spree_assets", ["viewable_type", "type"], name: "index_assets_on_viewable_type_and_type", using: :btree

  create_table "spree_avalara_entity_use_codes", force: true do |t|
    t.string   "use_code"
    t.string   "use_code_description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "spree_avalara_transactions", force: true do |t|
    t.integer  "order_id"
    t.integer  "return_authorization_id"
    t.string   "message"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spree_avalara_transactions", ["order_id"], name: "index_spree_avalara_transactions_on_order_id", using: :btree
  add_index "spree_avalara_transactions", ["return_authorization_id"], name: "index_spree_avalara_transactions_on_return_authorization_id", using: :btree

  create_table "spree_calculators", force: true do |t|
    t.string   "type"
    t.integer  "calculable_id",   null: false
    t.string   "calculable_type", null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.text     "preferences"
  end

  add_index "spree_calculators", ["calculable_id", "calculable_type"], name: "index_spree_calculators_on_calculable_id_and_calculable_type", using: :btree
  add_index "spree_calculators", ["id", "type"], name: "index_spree_calculators_on_id_and_type", using: :btree

  create_table "spree_configurations", force: true do |t|
    t.string   "name"
    t.string   "type",       limit: 50
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "spree_configurations", ["name", "type"], name: "index_spree_configurations_on_name_and_type", using: :btree

  create_table "spree_countries", force: true do |t|
    t.string   "iso_name"
    t.string   "iso"
    t.string   "iso3"
    t.string   "name"
    t.integer  "numcode"
    t.boolean  "states_required", default: false
    t.datetime "updated_at"
    t.boolean  "shipping"
  end

  add_index "spree_countries", ["name"], name: "index_spree_countries_on_name", using: :btree

  create_table "spree_credit_cards", force: true do |t|
    t.string   "month"
    t.string   "year"
    t.string   "cc_type"
    t.string   "last_digits"
    t.integer  "address_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.string   "gateway_customer_profile_id"
    t.string   "gateway_payment_profile_id"
    t.string   "name"
    t.integer  "user_id"
    t.integer  "payment_method_id"
    t.jsonb    "meta",                        default: "{}"
  end

  add_index "spree_credit_cards", ["address_id"], name: "index_spree_credit_cards_on_address_id", using: :btree
  add_index "spree_credit_cards", ["payment_method_id"], name: "index_spree_credit_cards_on_payment_method_id", using: :btree
  add_index "spree_credit_cards", ["user_id"], name: "index_spree_credit_cards_on_user_id", using: :btree

  create_table "spree_gateways", force: true do |t|
    t.string   "type"
    t.string   "name"
    t.text     "description"
    t.boolean  "active",      default: true
    t.string   "environment", default: "development"
    t.string   "server",      default: "test"
    t.boolean  "test_mode",   default: true
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.text     "preferences"
  end

  add_index "spree_gateways", ["active"], name: "index_spree_gateways_on_active", using: :btree
  add_index "spree_gateways", ["test_mode"], name: "index_spree_gateways_on_test_mode", using: :btree

  create_table "spree_inventory_units", force: true do |t|
    t.string   "state"
    t.integer  "variant_id"
    t.integer  "order_id"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.integer  "shipment_id"
    t.integer  "return_authorization_id"
    t.boolean  "pending",                 default: true
    t.string   "return_reason"
    t.text     "return_description"
    t.integer  "line_item_id"
  end

  add_index "spree_inventory_units", ["line_item_id"], name: "index_spree_inventory_units_on_line_item_id", using: :btree
  add_index "spree_inventory_units", ["order_id"], name: "index_inventory_units_on_order_id", using: :btree
  add_index "spree_inventory_units", ["return_authorization_id"], name: "index_spree_inventory_units_on_return_authorization_id", using: :btree
  add_index "spree_inventory_units", ["shipment_id"], name: "index_inventory_units_on_shipment_id", using: :btree
  add_index "spree_inventory_units", ["variant_id"], name: "index_inventory_units_on_variant_id", using: :btree

  create_table "spree_likes", force: true do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer  "product_id"
    t.integer  "user_id"
  end

  create_table "spree_line_items", force: true do |t|
    t.integer  "order_id"
    t.integer  "variant_id"
    t.integer  "quantity",                                                          null: false
    t.decimal  "price",                    precision: 10, scale: 2,                 null: false
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.string   "currency"
    t.decimal  "cost_price",               precision: 10, scale: 2
    t.integer  "tax_category_id"
    t.string   "size"
    t.string   "fulfillment_status"
    t.text     "fulfillment_notes"
    t.integer  "fulfillment_priority"
    t.text     "fulfillment_return_notes"
    t.string   "manufacturing_location"
    t.integer  "ets"
    t.integer  "ets_backorder"
    t.integer  "processing_time"
    t.integer  "current_stock"
    t.decimal  "adjustment_total",         precision: 10, scale: 2, default: 0.0
    t.decimal  "additional_tax_total",     precision: 10, scale: 2, default: 0.0
    t.decimal  "promo_total",              precision: 10, scale: 2, default: 0.0
    t.decimal  "included_tax_total",       precision: 10, scale: 2, default: 0.0,   null: false
    t.decimal  "pre_tax_amount",           precision: 8,  scale: 2, default: 0.0
    t.datetime "exported_ets"
    t.datetime "fulfil_ets_date"
    t.integer  "fulfil_ets_days"
    t.datetime "deleted_at"
    t.integer  "stock_location_id"
    t.datetime "shipped_at"
    t.boolean  "available_for_walkout"
    t.boolean  "walkout",                                           default: false
  end

  add_index "spree_line_items", ["deleted_at"], name: "index_spree_line_items_on_deleted_at", using: :btree
  add_index "spree_line_items", ["order_id"], name: "index_spree_line_items_on_order_id", using: :btree
  add_index "spree_line_items", ["stock_location_id"], name: "index_spree_line_items_on_stock_location_id", using: :btree
  add_index "spree_line_items", ["tax_category_id"], name: "index_spree_line_items_on_tax_category_id", using: :btree
  add_index "spree_line_items", ["variant_id"], name: "index_spree_line_items_on_variant_id", using: :btree

  create_table "spree_log_entries", force: true do |t|
    t.integer  "source_id"
    t.string   "source_type"
    t.text     "details"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.string   "message"
  end

  add_index "spree_log_entries", ["source_id", "source_type"], name: "index_spree_log_entries_on_source_id_and_source_type", using: :btree

  create_table "spree_option_types", force: true do |t|
    t.string   "name",         limit: 100
    t.string   "presentation", limit: 100
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.integer  "position",                 default: 0, null: false
  end

  add_index "spree_option_types", ["position"], name: "index_spree_option_types_on_position", using: :btree

  create_table "spree_option_types_prototypes", id: false, force: true do |t|
    t.integer "prototype_id"
    t.integer "option_type_id"
  end

  create_table "spree_option_values", force: true do |t|
    t.integer  "position"
    t.string   "name"
    t.string   "presentation"
    t.integer  "option_type_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "spree_option_values", ["option_type_id"], name: "index_spree_option_values_on_option_type_id", using: :btree
  add_index "spree_option_values", ["position"], name: "index_spree_option_values_on_position", using: :btree

  create_table "spree_option_values_variants", id: false, force: true do |t|
    t.integer "variant_id"
    t.integer "option_value_id"
  end

  add_index "spree_option_values_variants", ["variant_id", "option_value_id"], name: "index_option_values_variants_on_variant_id_and_option_value_id", using: :btree
  add_index "spree_option_values_variants", ["variant_id"], name: "index_spree_option_values_variants_on_variant_id", using: :btree

  create_table "spree_order_properties", force: true do |t|
    t.integer  "order_id"
    t.string   "name"
    t.string   "presentation"
    t.string   "value"
    t.string   "class_name"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "spree_order_properties", ["order_id", "name"], name: "index_spree_order_properties_on_order_id_and_name", using: :btree
  add_index "spree_order_properties", ["order_id"], name: "index_spree_order_properties_on_order_id", using: :btree

  create_table "spree_orders", force: true do |t|
    t.string   "number",                  limit: 32
    t.decimal  "item_total",                         precision: 10, scale: 2, default: 0.0,     null: false
    t.decimal  "total",                              precision: 10, scale: 2, default: 0.0,     null: false
    t.string   "state"
    t.decimal  "adjustment_total",                   precision: 10, scale: 2, default: 0.0,     null: false
    t.integer  "user_id"
    t.datetime "created_at",                                                                    null: false
    t.datetime "updated_at",                                                                    null: false
    t.datetime "completed_at"
    t.integer  "bill_address_id"
    t.integer  "ship_address_id"
    t.decimal  "payment_total",                      precision: 10, scale: 2, default: 0.0
    t.integer  "shipping_method_id"
    t.string   "shipment_state"
    t.string   "payment_state"
    t.string   "email"
    t.text     "special_instructions"
    t.string   "currency"
    t.string   "last_ip_address"
    t.integer  "created_by_id"
    t.datetime "abandoned_email_sent_at"
    t.integer  "invoice_number"
    t.date     "invoice_date"
    t.string   "channel",                                                     default: "spree"
    t.text     "response"
    t.text     "commercial_invoice_url"
    t.string   "tryon"
    t.string   "ref_code"
    t.decimal  "additional_tax_total",               precision: 10, scale: 2, default: 0.0,     null: false
    t.decimal  "shipment_total",                     precision: 10, scale: 2, default: 0.0,     null: false
    t.decimal  "promo_total",                        precision: 10, scale: 2, default: 0.0
    t.decimal  "included_tax_total",                 precision: 10, scale: 2, default: 0.0,     null: false
    t.integer  "item_count",                                                  default: 0
    t.integer  "approver_id"
    t.datetime "approved_at"
    t.boolean  "confirmation_delivered",                                      default: false
    t.boolean  "considered_risky",                                            default: false
    t.integer  "state_lock_version",                                          default: 0,       null: false
    t.integer  "purchase_location_id"
    t.integer  "agent_id"
    t.integer  "redeemed_gift_card_id"
    t.boolean  "for_gift"
    t.string   "ambassador_source"
    t.datetime "deleted_at"
    t.integer  "packer_id"
    t.datetime "packed_at"
    t.string   "coupon_code"
    t.boolean  "subscribe"
    t.boolean  "fraudulent",                                                  default: false
    t.boolean  "has_walkout"
    t.string   "guest_token"
    t.jsonb    "meta",                                                        default: "{}"
  end

  add_index "spree_orders", ["approver_id"], name: "index_spree_orders_on_approver_id", using: :btree
  add_index "spree_orders", ["bill_address_id"], name: "index_spree_orders_on_bill_address_id", using: :btree
  add_index "spree_orders", ["completed_at"], name: "index_spree_orders_on_completed_at", using: :btree
  add_index "spree_orders", ["confirmation_delivered"], name: "index_spree_orders_on_confirmation_delivered", using: :btree
  add_index "spree_orders", ["considered_risky"], name: "index_spree_orders_on_considered_risky", using: :btree
  add_index "spree_orders", ["created_by_id"], name: "index_spree_orders_on_created_by_id", using: :btree
  add_index "spree_orders", ["created_by_id"], name: "spree_orders_created_by_id_index", using: :btree
  add_index "spree_orders", ["deleted_at"], name: "index_spree_orders_on_deleted_at", using: :btree
  add_index "spree_orders", ["email"], name: "index_spree_orders_on_email", using: :btree
  add_index "spree_orders", ["guest_token"], name: "index_spree_orders_on_guest_token", using: :btree
  add_index "spree_orders", ["number"], name: "index_spree_orders_on_number", using: :btree
  add_index "spree_orders", ["payment_state"], name: "index_spree_orders_on_payment_state", using: :btree
  add_index "spree_orders", ["purchase_location_id"], name: "index_spree_orders_on_purchase_location_id", using: :btree
  add_index "spree_orders", ["ship_address_id"], name: "index_spree_orders_on_ship_address_id", using: :btree
  add_index "spree_orders", ["shipping_method_id"], name: "index_spree_orders_on_shipping_method_id", using: :btree
  add_index "spree_orders", ["state"], name: "index_spree_orders_on_state", using: :btree
  add_index "spree_orders", ["user_id", "created_by_id"], name: "index_spree_orders_on_user_id_and_created_by_id", using: :btree
  add_index "spree_orders", ["user_id"], name: "index_spree_orders_on_user_id", using: :btree

  create_table "spree_orders_promotions", id: false, force: true do |t|
    t.integer "order_id"
    t.integer "promotion_id"
  end

  add_index "spree_orders_promotions", ["order_id", "promotion_id"], name: "index_spree_orders_promotions_on_order_id_and_promotion_id", using: :btree

  create_table "spree_payment_capture_events", force: true do |t|
    t.decimal  "amount",     precision: 10, scale: 2, default: 0.0
    t.integer  "payment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spree_payment_capture_events", ["payment_id"], name: "index_spree_payment_capture_events_on_payment_id", using: :btree

  create_table "spree_payment_methods", force: true do |t|
    t.string   "type"
    t.string   "name"
    t.text     "description"
    t.boolean  "active",          default: true
    t.string   "environment",     default: "development"
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
    t.datetime "deleted_at"
    t.string   "display_on"
    t.boolean  "auto_capture"
    t.string   "publishable_key"
    t.string   "private_key"
    t.text     "preferences"
  end

  add_index "spree_payment_methods", ["id", "type"], name: "index_spree_payment_methods_on_id_and_type", using: :btree

  create_table "spree_payments", force: true do |t|
    t.decimal  "amount",               precision: 10, scale: 2, default: 0.0, null: false
    t.integer  "order_id"
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "source_id"
    t.string   "source_type"
    t.integer  "payment_method_id"
    t.string   "state"
    t.string   "response_code"
    t.string   "avs_response"
    t.string   "identifier"
    t.string   "cvv_response_code"
    t.string   "cvv_response_message"
    t.datetime "deleted_at"
  end

  add_index "spree_payments", ["deleted_at"], name: "index_spree_payments_on_deleted_at", using: :btree
  add_index "spree_payments", ["order_id"], name: "index_spree_payments_on_order_id", using: :btree
  add_index "spree_payments", ["payment_method_id"], name: "index_spree_payments_on_payment_method_id", using: :btree
  add_index "spree_payments", ["source_id", "source_type"], name: "index_spree_payments_on_source_id_and_source_type", using: :btree

  create_table "spree_paypal_accounts", force: true do |t|
    t.string "email"
    t.string "payer_id"
    t.string "payer_country"
    t.string "payer_status"
  end

  create_table "spree_paypal_express_checkouts", force: true do |t|
    t.string   "token"
    t.string   "payer_id"
    t.string   "transaction_id"
    t.string   "state",                 default: "complete"
    t.string   "refund_transaction_id"
    t.datetime "refunded_at"
    t.string   "refund_type"
    t.datetime "created_at"
  end

  add_index "spree_paypal_express_checkouts", ["transaction_id"], name: "index_spree_paypal_express_checkouts_on_transaction_id", using: :btree

  create_table "spree_pending_promotions", force: true do |t|
    t.integer "user_id"
    t.integer "promotion_id"
  end

  add_index "spree_pending_promotions", ["promotion_id"], name: "index_spree_pending_promotions_on_promotion_id", using: :btree
  add_index "spree_pending_promotions", ["user_id"], name: "index_spree_pending_promotions_on_user_id", using: :btree

  create_table "spree_preferences", force: true do |t|
    t.text     "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "key"
  end

  add_index "spree_preferences", ["key"], name: "index_spree_preferences_on_key", unique: true, using: :btree

  create_table "spree_prices", force: true do |t|
    t.integer  "variant_id",                          null: false
    t.decimal  "amount",     precision: 10, scale: 2
    t.string   "currency"
    t.datetime "deleted_at"
  end

  add_index "spree_prices", ["deleted_at"], name: "index_spree_prices_on_deleted_at", using: :btree
  add_index "spree_prices", ["variant_id", "currency"], name: "index_spree_prices_on_variant_id_and_currency", using: :btree

  create_table "spree_product_option_types", force: true do |t|
    t.integer  "position"
    t.integer  "product_id"
    t.integer  "option_type_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "spree_product_option_types", ["option_type_id"], name: "index_spree_product_option_types_on_option_type_id", using: :btree
  add_index "spree_product_option_types", ["position"], name: "index_spree_product_option_types_on_position", using: :btree
  add_index "spree_product_option_types", ["product_id"], name: "index_spree_product_option_types_on_product_id", using: :btree

  create_table "spree_product_properties", force: true do |t|
    t.string   "value"
    t.integer  "product_id"
    t.integer  "property_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "position",    default: 0
  end

  add_index "spree_product_properties", ["position"], name: "index_spree_product_properties_on_position", using: :btree
  add_index "spree_product_properties", ["product_id"], name: "index_product_properties_on_product_id", using: :btree
  add_index "spree_product_properties", ["property_id"], name: "index_spree_product_properties_on_property_id", using: :btree

  create_table "spree_products", force: true do |t|
    t.string   "name",                 default: "",   null: false
    t.text     "description"
    t.datetime "available_on"
    t.datetime "deleted_at"
    t.string   "slug"
    t.text     "meta_description"
    t.string   "meta_keywords"
    t.integer  "tax_category_id"
    t.integer  "shipping_category_id"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "likes_count",          default: 0
    t.integer  "material_group_id"
    t.integer  "material_category_id"
    t.jsonb    "meta",                 default: "{}"
  end

  add_index "spree_products", ["available_on"], name: "index_spree_products_on_available_on", using: :btree
  add_index "spree_products", ["deleted_at"], name: "index_spree_products_on_deleted_at", using: :btree
  add_index "spree_products", ["material_category_id"], name: "index_spree_products_on_material_category_id", using: :btree
  add_index "spree_products", ["material_group_id"], name: "index_spree_products_on_material_group_id", using: :btree
  add_index "spree_products", ["meta"], name: "index_spree_products_on_meta", using: :gin
  add_index "spree_products", ["name"], name: "index_spree_products_on_name", using: :btree
  add_index "spree_products", ["shipping_category_id"], name: "index_spree_products_on_shipping_category_id", using: :btree
  add_index "spree_products", ["slug"], name: "index_spree_products_on_slug", using: :btree
  add_index "spree_products", ["slug"], name: "permalink_idx_unique", unique: true, using: :btree
  add_index "spree_products", ["tax_category_id"], name: "index_spree_products_on_tax_category_id", using: :btree

  create_table "spree_products_promotion_rules", id: false, force: true do |t|
    t.integer "product_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_products_promotion_rules", ["product_id"], name: "index_products_promotion_rules_on_product_id", using: :btree
  add_index "spree_products_promotion_rules", ["promotion_rule_id"], name: "index_products_promotion_rules_on_promotion_rule_id", using: :btree

  create_table "spree_products_taxons", force: true do |t|
    t.integer "product_id"
    t.integer "taxon_id"
    t.integer "position",   default: 0
  end

  add_index "spree_products_taxons", ["position"], name: "index_spree_products_taxons_on_position", using: :btree
  add_index "spree_products_taxons", ["product_id"], name: "index_spree_products_taxons_on_product_id", using: :btree
  add_index "spree_products_taxons", ["taxon_id"], name: "index_spree_products_taxons_on_taxon_id", using: :btree

  create_table "spree_promotion_action_line_items", force: true do |t|
    t.integer "promotion_action_id"
    t.integer "variant_id"
    t.integer "quantity",            default: 1
  end

  add_index "spree_promotion_action_line_items", ["promotion_action_id"], name: "index_spree_promotion_action_line_items_on_promotion_action_id", using: :btree
  add_index "spree_promotion_action_line_items", ["variant_id"], name: "index_spree_promotion_action_line_items_on_variant_id", using: :btree

  create_table "spree_promotion_actions", force: true do |t|
    t.integer  "promotion_id"
    t.integer  "position"
    t.string   "type"
    t.datetime "deleted_at"
    t.text     "preferences"
  end

  add_index "spree_promotion_actions", ["deleted_at"], name: "index_spree_promotion_actions_on_deleted_at", using: :btree
  add_index "spree_promotion_actions", ["id", "type"], name: "index_spree_promotion_actions_on_id_and_type", using: :btree
  add_index "spree_promotion_actions", ["promotion_id"], name: "index_spree_promotion_actions_on_promotion_id", using: :btree

  create_table "spree_promotion_rules", force: true do |t|
    t.integer  "promotion_id"
    t.integer  "user_id"
    t.integer  "product_group_id"
    t.string   "type"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "code"
    t.text     "preferences"
  end

  add_index "spree_promotion_rules", ["product_group_id"], name: "index_promotion_rules_on_product_group_id", using: :btree
  add_index "spree_promotion_rules", ["promotion_id"], name: "index_spree_promotion_rules_on_promotion_id", using: :btree
  add_index "spree_promotion_rules", ["user_id"], name: "index_promotion_rules_on_user_id", using: :btree

  create_table "spree_promotion_rules_users", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "promotion_rule_id"
  end

  add_index "spree_promotion_rules_users", ["promotion_rule_id"], name: "index_promotion_rules_users_on_promotion_rule_id", using: :btree
  add_index "spree_promotion_rules_users", ["user_id"], name: "index_promotion_rules_users_on_user_id", using: :btree

  create_table "spree_promotions", force: true do |t|
    t.string   "description"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "starts_at"
    t.string   "name"
    t.string   "type"
    t.integer  "usage_limit"
    t.string   "match_policy", default: "all"
    t.string   "code"
    t.boolean  "advertise",    default: false
    t.string   "path"
    t.datetime "deleted_at"
    t.text     "preferences"
    t.jsonb    "meta",         default: "{}"
  end

  add_index "spree_promotions", ["advertise"], name: "index_spree_promotions_on_advertise", using: :btree
  add_index "spree_promotions", ["code"], name: "index_spree_promotions_on_code", using: :btree
  add_index "spree_promotions", ["deleted_at"], name: "index_spree_promotions_on_deleted_at", using: :btree
  add_index "spree_promotions", ["expires_at", "starts_at", "code", "path"], name: "spree_promotions_expires_at_starts_at_code_path_idx", using: :btree
  add_index "spree_promotions", ["expires_at"], name: "index_spree_promotions_on_expires_at", using: :btree
  add_index "spree_promotions", ["id", "type"], name: "index_spree_promotions_on_id_and_type", using: :btree
  add_index "spree_promotions", ["path"], name: "index_spree_promotions_on_path", using: :btree
  add_index "spree_promotions", ["starts_at"], name: "index_spree_promotions_on_starts_at", using: :btree

  create_table "spree_properties", force: true do |t|
    t.string   "name"
    t.string   "presentation", null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "spree_properties_prototypes", id: false, force: true do |t|
    t.integer "prototype_id"
    t.integer "property_id"
  end

  create_table "spree_prototypes", force: true do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_relation_types", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "applies_to"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "spree_relations", force: true do |t|
    t.integer  "relation_type_id"
    t.integer  "relatable_id"
    t.string   "relatable_type"
    t.integer  "related_to_id"
    t.string   "related_to_type"
    t.decimal  "discount_amount",  precision: 8, scale: 2, default: 0.0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "position"
  end

  create_table "spree_return_authorizations", force: true do |t|
    t.string   "number"
    t.string   "state"
    t.decimal  "amount",                 precision: 10, scale: 2, default: 0.0,   null: false
    t.integer  "order_id"
    t.text     "reason"
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
    t.integer  "stock_location_id"
    t.string   "description"
    t.string   "fileurl"
    t.string   "internal_description"
    t.string   "commercial_invoice_url"
    t.string   "ff_shipment_id"
    t.string   "refund_option"
    t.string   "tracking_number"
    t.boolean  "refunded",                                        default: false
    t.text     "inventory_reasons",                               default: "{}"
    t.text     "preferences"
  end

  add_index "spree_return_authorizations", ["number"], name: "index_spree_return_authorizations_on_number", using: :btree
  add_index "spree_return_authorizations", ["order_id"], name: "index_spree_return_authorizations_on_order_id", using: :btree
  add_index "spree_return_authorizations", ["stock_location_id"], name: "index_spree_return_authorizations_on_stock_location_id", using: :btree

  create_table "spree_roles", force: true do |t|
    t.string "name"
  end

  create_table "spree_roles_users", id: false, force: true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "spree_roles_users", ["role_id"], name: "index_spree_roles_users_on_role_id", using: :btree
  add_index "spree_roles_users", ["user_id"], name: "index_spree_roles_users_on_user_id", using: :btree

  create_table "spree_shipments", force: true do |t|
    t.string   "tracking"
    t.string   "number"
    t.decimal  "cost",                   precision: 10, scale: 2, default: 0.0
    t.datetime "shipped_at"
    t.integer  "order_id"
    t.integer  "address_id"
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.string   "state"
    t.integer  "stock_location_id"
    t.string   "commercial_invoice_url"
    t.decimal  "adjustment_total",       precision: 10, scale: 2, default: 0.0
    t.decimal  "additional_tax_total",   precision: 10, scale: 2, default: 0.0
    t.decimal  "promo_total",            precision: 10, scale: 2, default: 0.0
    t.decimal  "included_tax_total",     precision: 10, scale: 2, default: 0.0, null: false
    t.decimal  "pre_tax_amount",         precision: 8,  scale: 2, default: 0.0
    t.datetime "deleted_at"
    t.string   "carrier"
  end

  add_index "spree_shipments", ["address_id"], name: "index_spree_shipments_on_address_id", using: :btree
  add_index "spree_shipments", ["deleted_at"], name: "index_spree_shipments_on_deleted_at", using: :btree
  add_index "spree_shipments", ["number"], name: "index_shipments_on_number", using: :btree
  add_index "spree_shipments", ["order_id"], name: "index_spree_shipments_on_order_id", using: :btree
  add_index "spree_shipments", ["stock_location_id"], name: "index_spree_shipments_on_stock_location_id", using: :btree

  create_table "spree_shipping_categories", force: true do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "spree_shipping_method_categories", force: true do |t|
    t.integer  "shipping_method_id",   null: false
    t.integer  "shipping_category_id", null: false
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "spree_shipping_method_categories", ["shipping_category_id", "shipping_method_id"], name: "unique_spree_shipping_method_categories", unique: true, using: :btree
  add_index "spree_shipping_method_categories", ["shipping_method_id"], name: "index_spree_shipping_method_categories_on_shipping_method_id", using: :btree

  create_table "spree_shipping_methods", force: true do |t|
    t.string   "name"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "display_on"
    t.datetime "deleted_at"
    t.string   "tracking_url"
    t.string   "admin_name"
    t.integer  "tax_category_id"
    t.string   "tax_code"
    t.integer  "min_transit_time", default: 1
    t.integer  "max_transit_time"
  end

  add_index "spree_shipping_methods", ["deleted_at"], name: "index_spree_shipping_methods_on_deleted_at", using: :btree
  add_index "spree_shipping_methods", ["tax_category_id"], name: "index_spree_shipping_methods_on_tax_category_id", using: :btree

  create_table "spree_shipping_methods_zones", id: false, force: true do |t|
    t.integer "shipping_method_id"
    t.integer "zone_id"
  end

  create_table "spree_shipping_rates", force: true do |t|
    t.integer  "shipment_id"
    t.integer  "shipping_method_id"
    t.boolean  "selected",                                      default: false
    t.decimal  "cost",                  precision: 8, scale: 2, default: 0.0
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.string   "name"
    t.string   "easy_post_shipment_id"
    t.string   "easy_post_rate_id"
    t.integer  "tax_rate_id"
  end

  add_index "spree_shipping_rates", ["selected"], name: "index_spree_shipping_rates_on_selected", using: :btree
  add_index "spree_shipping_rates", ["shipment_id", "shipping_method_id"], name: "spree_shipping_rates_join_index", unique: true, using: :btree
  add_index "spree_shipping_rates", ["tax_rate_id"], name: "index_spree_shipping_rates_on_tax_rate_id", using: :btree

  create_table "spree_skrill_transactions", force: true do |t|
    t.string   "email"
    t.float    "amount"
    t.string   "currency"
    t.integer  "transaction_id"
    t.integer  "customer_id"
    t.string   "payment_type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "spree_state_changes", force: true do |t|
    t.string   "name"
    t.string   "previous_state"
    t.integer  "stateful_id"
    t.integer  "user_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "stateful_type"
    t.string   "next_state"
  end

  add_index "spree_state_changes", ["stateful_id", "stateful_type"], name: "index_spree_state_changes_on_stateful_id_and_stateful_type", using: :btree
  add_index "spree_state_changes", ["user_id"], name: "index_spree_state_changes_on_user_id", using: :btree

  create_table "spree_states", force: true do |t|
    t.string   "name"
    t.string   "abbr"
    t.integer  "country_id"
    t.datetime "updated_at"
  end

  add_index "spree_states", ["country_id"], name: "index_spree_states_on_country_id", using: :btree

  create_table "spree_stock_items", force: true do |t|
    t.integer  "stock_location_id"
    t.integer  "variant_id"
    t.integer  "count_on_hand",      default: 0,     null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "backorderable",      default: false
    t.datetime "deleted_at"
    t.boolean  "reserve"
    t.boolean  "keep"
    t.string   "celery_code"
    t.text     "keep_wording"
    t.text     "reserve_wording"
    t.integer  "ets"
    t.integer  "ets_backorder"
    t.integer  "processing_time"
    t.integer  "quantity_available"
  end

  add_index "spree_stock_items", ["backorderable"], name: "index_spree_stock_items_on_backorderable", using: :btree
  add_index "spree_stock_items", ["deleted_at", "variant_id"], name: "spree_stock_items_deleted_at_variant_id_idx", using: :btree
  add_index "spree_stock_items", ["deleted_at"], name: "index_spree_stock_items_on_deleted_at", using: :btree
  add_index "spree_stock_items", ["stock_location_id", "variant_id"], name: "stock_item_by_loc_and_var_id", using: :btree
  add_index "spree_stock_items", ["stock_location_id"], name: "index_spree_stock_items_on_stock_location_id", using: :btree

  create_table "spree_stock_locations", force: true do |t|
    t.string   "name"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.integer  "state_id"
    t.string   "state_name"
    t.integer  "country_id"
    t.string   "zipcode"
    t.string   "phone"
    t.boolean  "active",                 default: true
    t.boolean  "backorderable_default",  default: false
    t.boolean  "propagate_all_variants", default: true
    t.string   "admin_name"
    t.integer  "purchase_location_id"
    t.integer  "fulfil_warehouse_id"
  end

  add_index "spree_stock_locations", ["active"], name: "index_spree_stock_locations_on_active", using: :btree
  add_index "spree_stock_locations", ["backorderable_default"], name: "index_spree_stock_locations_on_backorderable_default", using: :btree
  add_index "spree_stock_locations", ["country_id"], name: "index_spree_stock_locations_on_country_id", using: :btree
  add_index "spree_stock_locations", ["propagate_all_variants"], name: "index_spree_stock_locations_on_propagate_all_variants", using: :btree
  add_index "spree_stock_locations", ["purchase_location_id"], name: "index_spree_stock_locations_on_purchase_location_id", using: :btree
  add_index "spree_stock_locations", ["state_id"], name: "index_spree_stock_locations_on_state_id", using: :btree

  create_table "spree_stock_movements", force: true do |t|
    t.integer  "stock_item_id"
    t.integer  "quantity",        default: 0
    t.string   "action"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "originator_id"
    t.string   "originator_type"
  end

  add_index "spree_stock_movements", ["stock_item_id"], name: "index_spree_stock_movements_on_stock_item_id", using: :btree

  create_table "spree_stock_transfers", force: true do |t|
    t.string   "type"
    t.string   "reference"
    t.integer  "source_location_id"
    t.integer  "destination_location_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "number"
  end

  add_index "spree_stock_transfers", ["destination_location_id"], name: "index_spree_stock_transfers_on_destination_location_id", using: :btree
  add_index "spree_stock_transfers", ["number"], name: "index_spree_stock_transfers_on_number", using: :btree
  add_index "spree_stock_transfers", ["source_location_id"], name: "index_spree_stock_transfers_on_source_location_id", using: :btree

  create_table "spree_stores", force: true do |t|
    t.string   "name"
    t.string   "url"
    t.text     "meta_description"
    t.text     "meta_keywords"
    t.string   "seo_title"
    t.string   "mail_from_address"
    t.string   "default_currency"
    t.string   "code"
    t.boolean  "default",           default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "spree_stores", ["code"], name: "index_spree_stores_on_code", using: :btree
  add_index "spree_stores", ["default"], name: "index_spree_stores_on_default", using: :btree
  add_index "spree_stores", ["url"], name: "index_spree_stores_on_url", using: :btree

  create_table "spree_tax_categories", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.boolean  "is_default",  default: false
    t.datetime "deleted_at"
  end

  add_index "spree_tax_categories", ["deleted_at"], name: "index_spree_tax_categories_on_deleted_at", using: :btree
  add_index "spree_tax_categories", ["is_default"], name: "index_spree_tax_categories_on_is_default", using: :btree

  create_table "spree_tax_rates", force: true do |t|
    t.decimal  "amount",             precision: 8, scale: 5
    t.integer  "zone_id"
    t.integer  "tax_category_id"
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.boolean  "included_in_price",                          default: false
    t.string   "name"
    t.boolean  "show_rate_in_label",                         default: true
    t.datetime "deleted_at"
  end

  add_index "spree_tax_rates", ["deleted_at"], name: "index_spree_tax_rates_on_deleted_at", using: :btree
  add_index "spree_tax_rates", ["included_in_price"], name: "index_spree_tax_rates_on_included_in_price", using: :btree
  add_index "spree_tax_rates", ["show_rate_in_label"], name: "index_spree_tax_rates_on_show_rate_in_label", using: :btree
  add_index "spree_tax_rates", ["tax_category_id"], name: "index_spree_tax_rates_on_tax_category_id", using: :btree
  add_index "spree_tax_rates", ["zone_id"], name: "index_spree_tax_rates_on_zone_id", using: :btree

  create_table "spree_taxonomies", force: true do |t|
    t.string   "name",                   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "position",   default: 0
  end

  add_index "spree_taxonomies", ["position"], name: "index_spree_taxonomies_on_position", using: :btree

  create_table "spree_taxons", force: true do |t|
    t.integer  "parent_id"
    t.integer  "position",          default: 0
    t.string   "name",                          null: false
    t.string   "permalink"
    t.integer  "taxonomy_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "lft"
    t.integer  "rgt"
    t.string   "icon_file_name"
    t.string   "icon_content_type"
    t.integer  "icon_file_size"
    t.datetime "icon_updated_at"
    t.text     "description"
    t.string   "meta_title"
    t.string   "meta_description"
    t.string   "meta_keywords"
    t.integer  "depth"
  end

  add_index "spree_taxons", ["name"], name: "index_spree_taxons_on_name", using: :btree
  add_index "spree_taxons", ["parent_id"], name: "index_taxons_on_parent_id", using: :btree
  add_index "spree_taxons", ["permalink"], name: "index_taxons_on_permalink", using: :btree
  add_index "spree_taxons", ["position"], name: "index_spree_taxons_on_position", using: :btree
  add_index "spree_taxons", ["taxonomy_id"], name: "index_taxons_on_taxonomy_id", using: :btree

  create_table "spree_tokenized_permissions", force: true do |t|
    t.integer  "permissable_id"
    t.string   "permissable_type"
    t.string   "token"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "spree_tokenized_permissions", ["permissable_id", "permissable_type"], name: "index_tokenized_name_and_type", using: :btree

  create_table "spree_trackers", force: true do |t|
    t.string   "environment"
    t.string   "analytics_id"
    t.boolean  "active",       default: true
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "spree_trackers", ["active"], name: "index_spree_trackers_on_active", using: :btree

  create_table "spree_variants", force: true do |t|
    t.string   "sku",                                      default: "",    null: false
    t.decimal  "weight",          precision: 8,  scale: 2, default: 0.0
    t.decimal  "height",          precision: 8,  scale: 2
    t.decimal  "width",           precision: 8,  scale: 2
    t.decimal  "depth",           precision: 8,  scale: 2
    t.datetime "deleted_at"
    t.boolean  "is_master",                                default: false
    t.integer  "product_id"
    t.decimal  "cost_price",      precision: 10, scale: 2
    t.integer  "position"
    t.string   "cost_currency"
    t.boolean  "track_inventory",                          default: true
    t.datetime "updated_at"
    t.integer  "tax_category_id"
    t.integer  "ff_variant_id"
    t.jsonb    "meta",                                     default: "{}"
  end

  add_index "spree_variants", ["deleted_at"], name: "index_spree_variants_on_deleted_at", using: :btree
  add_index "spree_variants", ["is_master"], name: "index_spree_variants_on_is_master", using: :btree
  add_index "spree_variants", ["position"], name: "index_spree_variants_on_position", using: :btree
  add_index "spree_variants", ["product_id"], name: "index_spree_variants_on_product_id", using: :btree
  add_index "spree_variants", ["sku"], name: "unique_index_on_spree_variants_sku", unique: true, where: "(deleted_at IS NULL)", using: :btree
  add_index "spree_variants", ["tax_category_id"], name: "index_spree_variants_on_tax_category_id", using: :btree
  add_index "spree_variants", ["track_inventory"], name: "index_spree_variants_on_track_inventory", using: :btree

  create_table "spree_zone_members", force: true do |t|
    t.integer  "zoneable_id"
    t.string   "zoneable_type"
    t.integer  "zone_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.text     "zone_type"
  end

  add_index "spree_zone_members", ["zone_id", "zone_type"], name: "index_spree_zone_members_on_zone_id_and_zone_type", using: :btree
  add_index "spree_zone_members", ["zoneable_id", "zoneable_type"], name: "index_spree_zone_members_on_zoneable_id_and_zoneable_type", using: :btree

  create_table "spree_zones", force: true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "default_tax",        default: false
    t.integer  "zone_members_count", default: 0
    t.text     "klass"
    t.text     "status"
    t.jsonb    "meta",               default: "{}"
    t.string   "kind"
  end

  add_index "spree_zones", ["default_tax"], name: "index_spree_zones_on_default_tax", using: :btree
  add_index "spree_zones", ["id", "klass"], name: "index_spree_zones_on_id_and_klass", using: :btree
  add_index "spree_zones", ["kind"], name: "index_spree_zones_on_kind", using: :btree
  add_index "spree_zones", ["klass", "name"], name: "index_spree_zones_on_klass_and_name", unique: true, using: :btree
  add_index "spree_zones", ["meta"], name: "index_spree_zones_on_meta", using: :gin
  add_index "spree_zones", ["status"], name: "index_spree_zones_on_status", using: :btree

  create_table "stores", force: true do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "taggings", force: true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       limit: 128
    t.datetime "created_at"
  end

  add_index "taggings", ["context"], name: "index_taggings_on_context", using: :btree
  add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true, using: :btree
  add_index "taggings", ["tag_id"], name: "index_taggings_on_tag_id", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context", using: :btree
  add_index "taggings", ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy", using: :btree
  add_index "taggings", ["taggable_id"], name: "index_taggings_on_taggable_id", using: :btree
  add_index "taggings", ["taggable_type"], name: "index_taggings_on_taggable_type", using: :btree
  add_index "taggings", ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type", using: :btree
  add_index "taggings", ["tagger_id"], name: "index_taggings_on_tagger_id", using: :btree

  create_table "tags", force: true do |t|
    t.string  "name"
    t.integer "taggings_count", default: 0
  end

  add_index "tags", ["name"], name: "index_tags_on_name", unique: true, using: :btree

  create_table "tax_audits", force: true do |t|
    t.decimal  "rate"
    t.string   "calculator"
    t.integer  "auditable_id"
    t.string   "auditable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tax_audits", ["auditable_id", "auditable_type"], name: "index_tax_audits_on_auditable_id_and_auditable_type", using: :btree

  create_table "taxon_extensions", force: true do |t|
    t.integer  "taxon_id"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.string   "seo_keyword_url"
    t.string   "seo_keyword_title"
  end

  add_index "taxon_extensions", ["taxon_id"], name: "index_taxon_extensions_on_taxon_id", using: :btree

  create_table "taxons_promotion_rules", id: false, force: true do |t|
    t.integer "taxon_id"
    t.integer "promotion_rule_id"
  end

  add_index "taxons_promotion_rules", ["promotion_rule_id"], name: "index_taxons_promotion_rules_on_promotion_rule_id", using: :btree
  add_index "taxons_promotion_rules", ["taxon_id"], name: "index_pos_promotion_rules_on_taxon_id", using: :btree

  create_table "tulip_relations", force: true do |t|
    t.integer  "model_id"
    t.string   "model_type"
    t.integer  "tulip_id"
    t.integer  "ghost_tulip_id"
    t.datetime "last_sync"
    t.datetime "last_ghost_sync"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tulip_relations", ["model_type", "model_id"], name: "index_tulip_relations_on_model_type_and_model_id", using: :btree

  create_table "user_addresses", force: true do |t|
    t.integer  "addressable_id"
    t.string   "addressable_type"
    t.string   "address_line_1"
    t.string   "address_line_2"
    t.string   "city"
    t.string   "state_province"
    t.string   "postal_code"
    t.string   "country"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  create_table "user_credits", force: true do |t|
    t.integer  "user_id"
    t.datetime "date"
    t.decimal  "amount",      precision: 8, scale: 2,                 null: false
    t.string   "credit_type"
    t.text     "description"
    t.boolean  "used",                                default: false
    t.datetime "used_at"
    t.integer  "order_id"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.boolean  "pending"
    t.string   "currency",                            default: "USD", null: false
  end

  add_index "user_credits", ["user_id"], name: "index_user_credits_on_user_id", using: :btree

  create_table "user_order_referrals", force: true do |t|
    t.integer "user_id",  null: false
    t.integer "order_id", null: false
  end

  add_index "user_order_referrals", ["user_id", "order_id"], name: "index_user_order_referrals_on_user_id_and_order_id", unique: true, using: :btree

  create_table "user_profiles", force: true do |t|
    t.integer  "user_id"
    t.string   "first_name"
    t.string   "last_name"
    t.date     "birthday"
    t.string   "gender"
    t.string   "hometown"
    t.string   "current_city"
    t.string   "country"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.string   "referral_code"
    t.hstore   "extra_data"
    t.string   "stripe_customer_id"
    t.integer  "default_credit_card_id"
  end

  add_index "user_profiles", ["extra_data"], name: "index_user_profiles_on_extra_data", using: :gist
  add_index "user_profiles", ["referral_code"], name: "index_user_profiles_on_referral_code", unique: true, using: :btree
  add_index "user_profiles", ["user_id"], name: "index_user_profiles_on_user_id", using: :btree

  create_table "user_subscriptions", force: true do |t|
    t.integer  "user_id"
    t.boolean  "newsletter",          default: true,  null: false
    t.boolean  "designer_newsletter", default: false, null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "user_subscriptions", ["user_id"], name: "index_user_subscriptions_on_user_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                                 default: "",                  null: false
    t.string   "encrypted_password",                    default: ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at",                                                          null: false
    t.datetime "updated_at",                                                          null: false
    t.string   "username"
    t.string   "spree_api_key",              limit: 48
    t.integer  "ship_address_id"
    t.integer  "bill_address_id"
    t.string   "exemption_number"
    t.integer  "avalara_entity_use_code_id"
    t.datetime "deleted_at"
    t.uuid     "uuid",                                  default: "gen_random_uuid()"
    t.string   "permalink"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["deleted_at"], name: "index_users_on_deleted_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["permalink"], name: "index_users_on_permalink", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["spree_api_key"], name: "index_users_on_spree_api_key", using: :btree
  add_index "users", ["username"], name: "index_users_on_username", using: :btree
  add_index "users", ["uuid"], name: "index_users_on_uuid", using: :btree

  create_table "users_roles", id: false, force: true do |t|
    t.integer "user_id"
    t.integer "role_id"
  end

  add_index "users_roles", ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",  null: false
    t.integer  "item_id",    null: false
    t.string   "event",      null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

  create_table "videos", force: true do |t|
    t.string   "video_url"
    t.integer  "variant_id"
    t.string   "thumbnail_file_name"
    t.string   "thumbnail_content_type"
    t.integer  "thumbnail_file_size"
    t.datetime "thumbnail_updated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "zipcode_ranges", force: true do |t|
    t.string  "name"
    t.string  "min_zipcode"
    t.string  "max_zipcode"
    t.integer "country_id"
  end

  add_index "zipcode_ranges", ["country_id"], name: "index_zipcode_ranges_on_country_id", using: :btree
  add_index "zipcode_ranges", ["min_zipcode", "max_zipcode"], name: "index_zipcode_ranges_on_min_zipcode_and_max_zipcode", using: :btree

end
