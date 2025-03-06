class CreateReceipts < ActiveRecord::Migration[7.1]
  def change
    create_table :receipts do |t|
      t.string :retailer
      t.date :purchaseDate
      t.string :purchaseTime
      t.float :total

      t.timestamps
    end
  end
end
