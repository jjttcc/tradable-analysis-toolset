require "test_helper"

class TradableAnalyzersTest < ActionDispatch::IntegrationTest
  include Capybara::DSL

  def setup
    @user = signed_in_user
  end

  def test_run_with_no_selections
    visit root_path
    click_button 'Run analysis'
    assert current_path == root_path, 'redirected to root'
  end

  def test_run_missing_analyzer
    visit root_path
    select('ibm', :from => 'symbols')
    click_button 'Run analysis'
    assert current_path == root_path, 'redirected to root'
  end

  def test_run_missing_symbol
    analyzer = 'MACD Crossover (Buy)'
    visit root_path
    select(analyzer, :from => 'analyzers')
    click_button 'Run analysis'
    assert current_path == root_path, 'redirected to root'
  end

  def test_run_with_selections
    analyzer_name = 'MACD Crossover (Buy)'
    analyzer_desc = analyzer_name.sub(/\s*\(.*\)/, '')
    visit root_path
    select('ibm', :from => 'symbols')
    select(analyzer_name, :from => 'analyzers')
    select('2012', :from => 'startdate_year')
    select('Sep', :from => 'startdate_month')
    select('24', :from => 'startdate_day')
    select('2014', :from => 'enddate_year')
    select('Sep', :from => 'enddate_month')
    select('25', :from => 'enddate_day')
    click_button 'Run analysis'
    assert page.has_content?(/1[0-9]\s+events/), 'has 10..19 events'
    assert page.has_content?(analyzer_desc), 'has analyzer'
    assert current_path == tradable_analyzers_index_path, 'ta index'
  end

  def test_run_with_multi_symbols
    analyzer_name = 'MACD Crossover (Buy)'
    analyzer_desc = analyzer_name.sub(/\s*\(.*\)/, '')
    visit root_path
    select('ibm', :from => 'symbols')
    select('aapl', :from => 'symbols')
    select(analyzer_name, :from => 'analyzers')
    select('2012', :from => 'startdate_year')
    select('Sep', :from => 'startdate_month')
    select('24', :from => 'startdate_day')
    select('2014', :from => 'enddate_year')
    select('Sep', :from => 'enddate_month')
    select('25', :from => 'enddate_day')
    click_button 'Run analysis'
    assert page.has_content?(/(1[0-9]|2[0-5])\s+events/), 'has 10..25 events'
    assert page.has_content?(analyzer_desc), 'has analyzer'
    assert current_path == tradable_analyzers_index_path, 'ta index'
  end

end
