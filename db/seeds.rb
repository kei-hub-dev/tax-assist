# 勘定科目の初期値。
#
# guidance は「どういう支出をこの科目に入れるか」の判定基準で、
# 勘定科目の説明として画面に表示されるほか、AI による仕訳提案の判断材料になる。
# 利用者が /accounts で編集できるため、seed では未設定のものだけを埋める。
default_accounts = [
  { name: "現金",       category: "asset",
    guidance: "手元の現金。事業用の財布や金庫から支払ったもの。" },
  { name: "普通預金",   category: "asset",
    guidance: "事業用の銀行口座。口座振替・振込・デビットカードでの支払いを含む。" },
  { name: "売掛金",     category: "asset",
    guidance: "商品やサービスを提供済みで、まだ入金されていない代金。" },
  { name: "立替金",     category: "asset",
    guidance: "取引先や従業員のために一時的に立て替えた金銭。後で回収する。" },
  { name: "前払費用",   category: "asset",
    guidance: "翌期以降のサービスに対して先に支払った費用。年払いの保険料や家賃など。" },
  { name: "備品",       category: "asset",
    guidance: "取得価額10万円以上で1年を超えて使用する物品。10万円未満は消耗品費にする。" },

  { name: "買掛金",     category: "liability",
    guidance: "仕入れた商品の代金で、まだ支払っていないもの。" },
  { name: "未払金",     category: "liability",
    guidance: "仕入以外で発生した未払いの代金。備品購入やサービス利用の請求など。" },
  { name: "未払費用",   category: "liability",
    guidance: "継続的なサービスのうち、期末時点で未払いの部分。" },
  { name: "預り金",     category: "liability",
    guidance: "源泉所得税や社会保険料など、他者に代わって一時的に預かった金銭。" },

  { name: "資本金",     category: "equity",
    guidance: "法人の元手。個人事業では通常使わず元入金を用いる。" },
  { name: "元入金",     category: "equity",
    guidance: "個人事業の元手。期首に前年の残高から繰り越される。" },

  { name: "売上高",     category: "revenue", sub_category: "sales",
    guidance: "本業による収入。商品の販売代金やサービスの提供料。" },
  { name: "受取利息",   category: "revenue", sub_category: "non_op_income",
    guidance: "預金利息など本業以外の収入。" },

  { name: "仕入高",     category: "expense", sub_category: "cogs",
    guidance: "販売する商品や、製品の材料の購入代金。" },
  { name: "旅費交通費", category: "expense", sub_category: "sganda",
    guidance: "電車・バス・タクシー・航空券・宿泊費など、移動そのものに伴う費用。" \
              "取引先を訪問するための移動費もここに含め、接待交際費にはしない。" },
  { name: "通信費",     category: "expense", sub_category: "sganda",
    guidance: "インターネット回線、サーバやドメインの利用料、電話代、切手・はがき代。" },
  { name: "消耗品費",   category: "expense", sub_category: "sganda",
    guidance: "取得価額10万円未満の物品、事務用品、ソフトウェアのライセンス。" \
              "10万円以上で1年を超えて使うものは備品にする。" },
  { name: "支払手数料", category: "expense", sub_category: "sganda",
    guidance: "振込手数料、決済サービスの利用料、専門家への報酬。" },
  { name: "水道光熱費", category: "expense", sub_category: "sganda",
    guidance: "電気・ガス・水道代。自宅兼事務所の場合は事業使用分のみを按分して計上する。" },
  { name: "地代家賃",   category: "expense", sub_category: "sganda",
    guidance: "事務所や駐車場の賃料。自宅兼事務所の場合は事業使用分のみを按分して計上する。" }
]

User.find_each do |user|
  now = Time.current

  rows = default_accounts.map do |h|
    { user_id: user.id, name: h[:name], category: h[:category], sub_category: h[:sub_category],
      created_at: now, updated_at: now }
  end
  Account.upsert_all(rows, unique_by: :index_accounts_on_user_id_and_name)

  default_accounts.each do |h|
    next unless h[:sub_category]
    Account.where(user_id: user.id, name: h[:name], sub_category: nil)
           .update_all(sub_category: h[:sub_category], updated_at: now)
  end

  # guidance は利用者が編集できるので、まだ設定されていないものだけを埋める。
  # デプロイのたびに db:seed が走る (fly.toml の release_command) ため、
  # ここで無条件に上書きすると利用者の編集内容が消える。
  default_accounts.each do |h|
    next if h[:guidance].blank?
    Account.where(user_id: user.id, name: h[:name], guidance: [ nil, "" ])
           .update_all(guidance: h[:guidance], updated_at: now)
  end
end
