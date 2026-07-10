class CreatePaymentTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_transactions do |t|
      t.references :subscription, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :provider_payment_id, null: false
      t.string :order_id, null: false
      t.string :status, null: false, default: "pending"
      t.integer :amount, null: false
      t.string :currency, null: false, default: "KRW"
      t.json :provider_payload

      t.timestamps
    end

    add_index :payment_transactions, %i[provider provider_payment_id], unique: true
    add_index :payment_transactions, :order_id, unique: true
  end
end
