require 'coveralls'
Coveralls.wear!('rails') if ENV['CIRCLE_CI']

# figure out where we are being loaded from
if $LOADED_FEATURES.grep(/spec\/spec_helper\.rb/).any?
  begin
    fail 'foo'
  rescue => e
    puts <<-MSG
  ===================================================
  It looks like spec_helper.rb has been loaded
  multiple times. Normalize the require to:

    require "spec/spec_helper"

  Things like File.join and File.expand_path will
  cause it to be loaded multiple times.

  Loaded this time from:

    #{e.backtrace.join("\n    ")}
  ===================================================
    MSG
  end
end

require 'rubygems'

# Avoid database cleaning
raise ArgumentError.new 'Use RAILS_ENV=test for running rspec tests' unless ENV['RAILS_ENV'] == 'test'
require 'database_cleaner'

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara'
require 'factory_girl_rails'
require 'capybara/dsl'
require 'rspec/core'
require 'capybara/rspec/matchers'
require 'capybara/rspec/features'
require 'capybara/rspec'
require 'capybara/rails'
require 'paperclip/matchers'
require 'capybara/poltergeist'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  # Ensure that if we are running js tests, we are using latest webpack assets
  # This will use the defaults of :js and :server_rendering meta tags
  ReactOnRails::TestHelper.configure_rspec_to_compile_assets(config)

  config.include FactoryGirl::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Paperclip::Shoulda::Matchers
  config.include ExpectationsHelper
  config.include ElasticsearchHelper
  config.include FormsHelper
  config.include FormsEngineHelper
  config.include HL7FixtureHelper
  config.include AsyncHelper
  config.include ApiHelper
  config.include Waiters
  config.include CaredoxSpecFinderHelper
  config.include ChosenSelect
  config.include Select2Select
  config.include ResponsiveHelper
  config.include Capybara::DSL
  config.include Capybara::RSpecMatchers
  config.include DownloadHelper
  config.include TogglerHelper
  config.include MedicalCenterTestHelper
  config.include TimezoneHelper
  config.include TestReportHelper

  Capybara.register_driver :chrome do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end
  Capybara.javascript_driver = :chrome
  Capybara.register_driver :iphone do |app|
    Capybara::Selenium::Driver.new(app,
                                   :browser => :chrome,
                                   :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.chrome(
                                     'chromeOptions' => {
                                       'mobileEmulation' => {
                                         'deviceMetrics' => { 'width' => 480, 'height' => 640, 'pixelRatio' => 3.0 },
                                         'userAgent' => "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"
                                       }
                                     }
                                   )
                                  )
  end

  # to enable siging in a devise user
  config.extend ControllerMacros, type: :controller

  Capybara.default_max_wait_time = 15

  # config.mock_with :rspec

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:suite) do
    Role.sync_all_default_role_permissions

    # uncommnet to precompile asset on each spec run
    #%x[bundle exec rake assets:clobber]
    #%x[bundle exec rake assets:precompile]
  end

  unless ENV['DO_NOT_DEFER_GC']
    config.before(:all) do
      DeferredGarbageCollection.start
    end
  end

  # rspec-retry gem config
  # show retry status in spec process
  config.verbose_retry = true
  # show exception that triggers a retry if verbose_retry is set to true
  config.display_try_failure_messages = true

  # run retry only on features
  retries = ENV['CIRCLE_CI'].present? ? 3 : 1
  config.around :each, :js do |ex|
    ex.run_with_retry retry: retries
  end

  # Maximize browser window for feature tests
  config.before(:each, js: true) do
    Capybara.page.driver.browser.manage.window.maximize
  end

  config.before(:each) do |example|
    Rails.cache.clear
    DatabaseCleaner.strategy = :truncation , {:except => %w[
        vaccines vaccine_groups vaccine_groups_vaccines vaccine_aggregations
        vaccine_aggregations_vaccine_groups master_allergen_types master_allergy_sources
        master_diet_restrictions screening_types physical_examination_screening_check_types roles
        role_permission_selections master_medical_event_skip_reasons master_potential_asthma_triggers
        bmi_age_lms_values
    ], pre_count: true, reset_ids: false}
    DatabaseCleaner.start
    #Lifesaver.suppress_indexing

    # handle elastic search indexes
    # ActiveRecord::Base.send(:descendants).each do |model|
    #   if model.respond_to? :tire
    #     # delete the index for the current model
    #     model.tire.index.delete
    #     model.tire.create_elasticsearch_index
    #     # the mapping definition must get executed again. for that, we reload the model class.
    #     load File.expand_path("../../app/models/#{model.name.underscore.downcase}.rb", __FILE__)
    #   end
    # end

    # getting cancan ability class into play
    load File.expand_path('../../app/models/ability.rb', __FILE__)

  end

  config.after(:each) do |example|
    Capybara.reset_sessions!
    if example.metadata[:js]
      RackRequestBlocker.wait_for_requests_complete
    end
    Rails.logger.info "Current locale: #{I18n.locale}"
    if example.exception && ENV['CIRCLE_CI'].present?
      Rails.logger.error "Failed test #{example.metadata[:location]}"
      path = ENV.fetch('CIRCLE_ARTIFACTS', Rails.root.join('log'))
      file_name = "dump_for_#{example.metadata[:location].parameterize}_#{Time.current.to_s(:db).gsub(/[:,' ']/,'-')}.sql"
      `mysqldump -u ubuntu --skip-compact circle_test > #{path}/#{file_name}`
      Rails.logger.info "MySQL dump created: #{file_name}"
    end
    DatabaseCleaner.clean
    Capybara.use_default_driver
    ::PaperTrail.whodunnit = nil
    Vaccine.reset_cache
    VaccineGroup.reset_cache
    VaccineAggregation.reset_cache
    Sidekiq::Worker.clear_all

    # if example.metadata[:js]
    #   save_timestamped_screenshot(Capybara.page, example.metadata) if example.exception
    # end

  end

  config.after(:each, js: true) do |example|
    if example.exception && ENV['CIRCLE_CI'].present?
      path = ENV.fetch('CIRCLE_ARTIFACTS', Rails.root.join('log'))
      file_name = "screenshot_for_#{example.metadata[:location].parameterize}_#{Time.current.to_s(:db).gsub(/[:,' ']/,'-')}.png"
      screenshot_path = "#{path}/#{file_name}"
      Capybara.page.save_screenshot(screenshot_path)
      Rails.logger.error "Screenshot: #{screenshot_path}"
    end
  end

  unless ENV['DO_NOT_DEFER_GC']
    config.after(:all) do
      DeferredGarbageCollection.reconsider
    end
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # rspec-rails 3 will no longer automatically infer an example group's spec type
  # from the file location. You can explicitly opt-in to the feature using this
  # config option.
  # To explicitly tag specs without using automatic inference, set the `:type`
  # metadata manually:
  #
  #     describe ThingsController, :type => :controller do
  #       # Equivalent to being in spec/controllers
  #     end
  config.infer_spec_type_from_file_location!
end

FactoryGirl.reload
