class JournalEntriesController < ApplicationController
  before_action :require_accounting_period!
  before_action :set_entry, only: [ :edit, :update ]

  def index
    @entries = entry_scope.recent
    @entry = entry_scope.new(entry_date: Date.current)
    @entry.journal_entry_lines.build if @entry.journal_entry_lines.empty?
  end

  def create
    @entry = entry_scope.new(entry_params)
    if @entry.save
      redirect_to journal_entries_path, notice: "仕訳を登録しました"
    else
      @entries = entry_scope.recent
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
    @entry = entry_scope.find(params[:id])
    @entry.destroy
    redirect_to journal_entries_path, notice: "仕訳を削除しました"
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
      journal_entry_lines_attributes: [ :id, :account_id, :dc, :amount, :memo, :_destroy ]
    )
  end
end
