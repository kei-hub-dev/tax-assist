require "rails_helper"

# fly.toml の release_command でデプロイのたびに db:seed が走るため、
# 再実行しても利用者の編集内容を壊さないことが重要になる。
RSpec.describe "db/seeds.rb", type: :model do
  let!(:user) { User.create!(email: "seed@example.com", password: "password1") }

  def run_seed
    Rails.application.load_seed
  end

  it "既定の勘定科目を作成し、判定基準を設定する" do
    run_seed

    travel = user.accounts.find_by!(name: "旅費交通費")
    expect(travel.category).to eq("expense")
    expect(travel.sub_category).to eq("sganda")
    expect(travel.guidance).to include("移動")
    expect(travel.guidance).to include("接待交際費にはしない")
  end

  it "何度実行しても勘定科目が重複しない" do
    run_seed
    count_after_first = user.accounts.count

    run_seed

    expect(user.accounts.count).to eq(count_after_first)
  end

  it "利用者が編集した判定基準を上書きしない" do
    run_seed
    travel = user.accounts.find_by!(name: "旅費交通費")
    travel.update!(guidance: "当事務所では出張の宿泊費は別科目にする")

    run_seed

    expect(travel.reload.guidance).to eq("当事務所では出張の宿泊費は別科目にする")
  end

  it "判定基準が空のものだけを埋める" do
    run_seed
    travel = user.accounts.find_by!(name: "旅費交通費")
    travel.update_column(:guidance, nil)

    run_seed

    expect(travel.reload.guidance).to be_present
  end
end
