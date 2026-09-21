class JournalEntriesController < ApplicationController
  before_action :require_accounting_period!
  before_action :set_entry, only: [ :edit, :update ]
  before_action :set_autocomplete_candidates, only: [ :index, :edit ]

  def index
    @entries = entry_scope.recent
    @entry = entry_scope.new(entry_date: Date.current)
    @entry.journal_entry_lines.build if @entry.journal_entry_lines.empty?
  end

  # 摘要から勘定科目を提案する。AI が無効なとき (OLLAMA_URL 未設定) は
  # そもそも画面にボタンが出ないが、直接叩かれた場合に備えて 404 を返す。
  def suggest
    return head :not_found unless OllamaClient.enabled?

    suggester = JournalEntrySuggester.new(user: current_user, accounting_period: current_period)
    result = suggester.call(
      description: params[:description].to_s,
      amount: params[:amount].presence
    )

    render json: {
      debit_account_id: result.debit_account.id,
      debit_account_name: result.debit_account.name,
      credit_account_id: result.credit_account.id,
      credit_account_name: result.credit_account.name,
      confidence: result.confidence,
      differs_from_standard: result.differs_from_standard?,
      warning: result.warning
    }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_content
  rescue OllamaClient::Unavailable => e
    render json: { error: e.message }, status: :service_unavailable
  rescue OllamaClient::Error => e
    Rails.logger.warn("[JournalEntrySuggester] #{e.class}: #{e.message}")
    render json: { error: "提案を取得できませんでした" }, status: :bad_gateway
  end

  def create
    @entry = entry_scope.new(entry_params)
    if @entry.save
      redirect_to journal_entries_path, notice: "仕訳を登録しました"
    else
      @entries = entry_scope.recent
      set_autocomplete_candidates
      flash.now[:alert] = @entry.errors.full_messages.join(" / ")
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @entry.update(entry_params)
      redirect_to journal_entries_path, notice: "仕訳を更新しました"
    else
      set_autocomplete_candidates
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry = entry_scope.find(params[:id])
    @entry.destroy
    redirect_to journal_entries_path, notice: "仕訳を削除しました", status: :see_other
  end

  private

  def entry_scope
    JournalEntry.where(accounting_period_id: current_period.id)
  end

  def set_entry
    @entry = entry_scope.find(params[:id])
    @entry.journal_entry_lines.build if @entry.journal_entry_lines.empty?
  end

  def entry_params
    params.require(:journal_entry).permit(
      :entry_date,
      :description,
      journal_entry_lines_attributes: [ :id, :account_id, :dc, :amount, :memo, :_destroy ]
    )
  end

  def set_autocomplete_candidates
    @description_suggestions =
      JournalEntry
        .joins(:accounting_period)
        .where(accounting_periods: { user_id: current_user.id })
        .where.not(description: [ nil, "" ])
        .order(updated_at: :desc)
        .limit(200)
        .pluck(:description)
        .map(&:strip)
        .reject(&:blank?)
        .uniq
        .first(20)

    @memo_suggestions =
      JournalEntryLine
        .joins(journal_entry: :accounting_period)
        .where(accounting_periods: { user_id: current_user.id })
        .where.not(memo: [ nil, "" ])
        .order(updated_at: :desc)
        .limit(300)
        .pluck(:memo)
        .map(&:strip)
        .reject(&:blank?)
        .uniq
        .first(30)
  end
end
