class CreateCommerceCatalogAndLicenses < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.boolean :sale_enabled, null: false, default: false

      t.timestamps
    end
    add_index :products, :code, unique: true

    create_table :product_offers do |t|
      t.references :product, null: false, foreign_key: true
      t.string :code, null: false
      t.integer :version, null: false
      t.integer :duration_months, null: false
      t.integer :supply_amount, null: false
      t.integer :vat_amount, null: false
      t.integer :total_amount, null: false
      t.integer :discount_bps, null: false, default: 0
      t.string :currency, null: false, default: "KRW"
      t.boolean :active, null: false, default: true
      t.datetime :available_from
      t.datetime :available_until

      t.timestamps
    end
    add_index :product_offers, :code, unique: true
    add_index :product_offers, %i[product_id duration_months version], unique: true,
      name: "index_product_offers_on_product_duration_version"

    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :public_id, null: false
      t.string :provider, null: false
      t.string :status, null: false, default: "pending"
      t.date :requested_start_on, null: false
      t.integer :supply_amount, null: false
      t.integer :vat_amount, null: false
      t.integer :total_amount, null: false
      t.string :currency, null: false, default: "KRW"
      t.datetime :payment_requested_at, null: false
      t.datetime :paid_at
      t.datetime :finalized_at

      t.timestamps
    end
    add_index :orders, :public_id, unique: true
    add_index :orders, %i[user_id status]

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :product_offer, null: false, foreign_key: true
      t.string :product_code, null: false
      t.string :product_name, null: false
      t.string :offer_code, null: false
      t.integer :offer_version, null: false
      t.integer :duration_months, null: false
      t.integer :supply_amount, null: false
      t.integer :vat_amount, null: false
      t.integer :total_amount, null: false
      t.integer :discount_bps, null: false, default: 0
      t.string :currency, null: false, default: "KRW"

      t.timestamps
    end
    add_index :order_items, %i[order_id product_id], unique: true

    create_table :licenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :order_item, null: true, foreign_key: true, index: false
      t.string :source, null: false, default: "paid"
      t.string :status, null: false, default: "scheduled"
      t.date :starts_on, null: false
      t.date :last_usable_on, null: false
      t.datetime :access_ends_at, null: false

      t.timestamps
    end
    add_index :licenses, :order_item_id, unique: true
    add_index :licenses, %i[user_id product_id starts_on], unique: true,
      name: "index_licenses_on_user_product_start"
    add_index :licenses, %i[user_id product_id access_ends_at],
      name: "index_licenses_on_user_product_access_end"

    add_reference :payment_transactions, :purchase_order,
      null: true, foreign_key: { to_table: :orders }, index: { unique: true }
    change_column_null :payment_transactions, :subscription_id, true
  end
end
