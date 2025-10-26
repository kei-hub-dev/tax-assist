DEFAULT_ACCOUNTS = [
  { name: "現金",       category: "asset" },
  { name: "普通預金",   category: "asset" },
  { name: "売掛金",     category: "asset" },
  { name: "立替金",     category: "asset" },
  { name: "前払費用",   category: "asset" },
  { name: "備品",       category: "asset" },

  { name: "買掛金",     category: "liability" },
  { name: "未払金",     category: "liability" },
  { name: "未払費用",   category: "liability" },
  { name: "預り金",     category: "liability" },

  { name: "資本金",     category: "equity" },
  { name: "元入金",     category: "equity" },

  { name: "売上高",     category: "revenue", sub_category: "sales" },
  { name: "受取利息",   category: "revenue", sub_category: "non_op_income" },

  { name: "仕入高",     category: "expense", sub_category: "cogs" },
  { name: "旅費交通費", category: "expense", sub_category: "sganda" },
  { name: "通信費",     category: "expense", sub_category: "sganda" },
  { name: "消耗品費",   category: "expense", sub_category: "sganda" },
  { name: "支払手数料", category: "expense", sub_category: "sganda" },
  { name: "水道光熱費", category: "expense", sub_category: "sganda" },
  { name: "地代家賃",   category: "expense", sub_category: "sganda" }
]

User.find_each do |user|
  now = Time.current
  rows = DEFAULT_ACCOUNTS.map do |h|
    { user_id: user.id, name: h[:name], category: h[:category], sub_category: h[:sub_category], created_at: now, updated_at: now }
  end
  Account.upsert_all(rows, unique_by: :index_accounts_on_user_id_and_name)

  DEFAULT_ACCOUNTS.each do |h|
    next unless h[:sub_category]
    Account.where(user_id: user.id, name: h[:name], sub_category: nil).update_all(sub_category: h[:sub_category], updated_at: now)
  end
end
