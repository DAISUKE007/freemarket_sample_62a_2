class CreateCategoryBrands < ActiveRecord::Migration[5.0]
  def change
    create_table :category_brands do |t|
      t.references :category,  null: false, foreign_key: true    #カテゴリーID
      t.references :brand,     foreign_key: true                 #ブランドID
      t.timestamps
    end
  end
end
