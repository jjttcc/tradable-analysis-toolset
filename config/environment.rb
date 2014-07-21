# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
TradableAnalysisToolset::Application.initialize!

# Make the application name globally available.
Rails.configuration.application_name = 'Tradable Analysis Toolset'

