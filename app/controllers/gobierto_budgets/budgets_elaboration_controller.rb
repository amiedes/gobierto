class GobiertoBudgets::BudgetsElaborationController < GobiertoBudgets::ApplicationController
  before_action :check_setting_enabled, :load_place, :load_year

  def index
    @site_stats = GobiertoBudgets::SiteStats.new(site: current_site, year: @year)
    @top_income_budget_lines = GobiertoBudgets::TopBudgetLine.limit(5).where(site: current_site, year: @year, place: @place, kind: GobiertoBudgets::BudgetLine::INCOME).all
    @top_expense_budget_lines = GobiertoBudgets::TopBudgetLine.limit(5).where(site: current_site, year: @year, place: @place, kind: GobiertoBudgets::BudgetLine::EXPENSE).all
    @sample_budget_lines = (@top_income_budget_lines + @top_expense_budget_lines).sample(3)
    @budgets_data_updated_at = current_site.budgets_data_updated_at('forecast')

    @kind = params[:kind] || GobiertoBudgets::BudgetLine::EXPENSE
    @area_name = params[:area_name] || (@kind == GobiertoBudgets::BudgetLine::EXPENSE ? GobiertoBudgets::FunctionalArea.area_name : GobiertoBudgets::EconomicArea.area_name)

    @interesting_expenses = GobiertoBudgets::BudgetLine.all(where: { site: current_site, place: @place, level: 2, year: @year, kind: @kind, area_name: @area_name })
    @interesting_expenses_previous_year = GobiertoBudgets::BudgetLine.all(where: { site: current_site, place: @place, level: 2, year: @year - 1, kind: @kind, area_name: @area_name })
    @place_budget_lines = GobiertoBudgets::BudgetLine.all(where: { site: current_site, place: @place, level: 1, year: @year, kind: @kind, area_name: @area_name })

    respond_to do |format|
      format.html
      format.js
    end
  end

  private

  def check_setting_enabled
    render_404 unless budgets_elaboration_active?
  end

  def load_place
    @place = current_site.place
    render_404 and return if @place.nil?
  end

  def load_year
    @year = Date.today.year + 1
  end

end
