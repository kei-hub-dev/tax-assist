class JournalEntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_accounting_period!
  before_action :set_entry, only: [ :edit, :update ]

  def index
    @entries = JournalEntry.where(accounting_period_id: current_period.id).recent
    @entry = JournalEntry.new(
      accounting_period_id: current_period.id,
      entry_date: Date.current
    )
    @entry.journal_entry_lines.build if @entry.journal_entry_lines.empty?
  end

  def create
    @entry = JournalEntry.new(entry_params.merge(accounting_period_id: current_period.id))
    if @entry.save
      redirect_to journal_entries_path, notice: "仕訳を登録しました"
    else
      @entries = JournalEntry.where(accounting_period_id: current_period.id).recent
      flash.now[:alert] = @entry.errors.full_messages.join(" / ")
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @entry.update(entry_params)
      redirect_to journal_entries_path, notice: "仕訳を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entry = JournalEntry.where(accounting_period_id: current_period.id).find(params[:id])
    @entry.destroy
    redirect_to journal_entries_path, notice: "仕訳を削除しました"
  end

  private

  def set_entry
    @entry = JournalEntry.where(accounting_period_id: current_period.id).find(params[:id])
  end

  def entry_params
    params.require(:journal_entry).permit(
      :entry_date,
      journal_entry_lines_attributes: [ :id, :account_id, :dc, :amount, :memo, :_destroy ]
    )
  end

  def next_entry_no
    last_no = JournalEntry.where(accounting_period_id: current_period.id).maximum(:entry_no)
    (last_no || 0) + 1
  end
end
