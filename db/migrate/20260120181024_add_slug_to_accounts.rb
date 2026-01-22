class AddSlugToAccounts < ActiveRecord::Migration[7.2]
  def up
    add_column :accounts, :slug, :string
    add_index :accounts, :slug, unique: true

    # Popula slugs para contas existentes
    Account.reset_column_information
    Account.find_each do |account|
      slug = account.name.parameterize
      # Garante unicidade em caso de nomes duplicados
      counter = 1
      original_slug = slug
      while Account.exists?(slug: slug)
        slug = "#{original_slug}-#{counter}"
        counter += 1
      end
      account.update_column(:slug, slug)
    end

    # Torna obrigatório após popular
    change_column_null :accounts, :slug, false
  end

  def down
    remove_index :accounts, :slug
    remove_column :accounts, :slug
  end
end
