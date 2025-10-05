# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
DEFAULT_ACCOUNTS = [
  # 資産
  { name: "現金",       category: "asset" },
  { name: "普通預金",   category: "asset" },
  { name: "売掛金",     category: "asset" },
  { name: "立替金",     category: "asset" },
  { name: "前払費用",   category: "asset" },
  { name: "備品",       category: "asset" },

  # 負債
  { name: "買掛金",     category: "liability" },
  { name: "未払金",     category: "liability" },
  { name: "未払費用",   category: "liability" },
  { name: "預り金",     category: "liability" },

  # 純資産（法人は「資本金」、個人は「元入金」を主に使用）
  { name: "資本金",     category: "equity" },
  { name: "元入金",     category: "equity" },

  # 収益
  { name: "売上高",     category: "revenue" },
  { name: "受取利息",   category: "revenue" },

  # 費用
  { name: "仕入高",     category: "expense" },
  { name: "旅費交通費", category: "expense" },
  { name: "通信費",     category: "expense" },
  { name: "消耗品費",   category: "expense" },
  { name: "支払手数料", category: "expense" },
  { name: "水道光熱費", category: "expense" },
  { name: "地代家賃",   category: "expense" }
]

User.find_each do |u|
  DEFAULT_ACCOUNTS.each do |attrs|
    Account.find_or_create_by!(user: u, name: attrs[:name]) { |a| a.category = attrs[:category] }
  end
end
