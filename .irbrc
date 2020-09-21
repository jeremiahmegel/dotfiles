IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb_history"
IRB.conf[:SAVE_HISTORY] = 1000

if ENV['FORCE_PRY'] == '1'
  old_stubs = Gem::Specification.class_variable_get(:@@stubs)
  gem_load_error =
    if defined?(Gem::MissingSpecError)
      Gem::MissingSpecError
    else
      Gem::LoadError
    end
  pry_rails_spec =
    2.times do
      begin
        Gem::Specification.class_variable_set(:@@stubs, nil)
        break Gem::Dependency.new('pry-rails').to_spec
      rescue gem_load_error
        Gem::Specification.class_variable_set(:@@stubs, old_stubs)
        begin
          Gem.install('pry-rails')
        rescue gem_load_error
        end
      end
    end
  specs = [pry_rails_spec]
  specs.each do |spec|
    # https://makandracards.com/makandra/45308-howto-require-gem-that-is-not-in-gemfile
    $LOAD_PATH << "#{spec.full_gem_path}/#{spec.require_path}"

    spec.runtime_dependencies.each do |dep|
      specs << dep.to_spec
    end
  end
  require 'pry-rails'
  Gem::Specification.class_variable_set(:@@stubs, old_stubs)
  if defined?(Rails)
    Rails.application.config.console = Pry

    rails_logger_extend_method = Rails.logger.method(:extend)
    Rails.logger.define_singleton_method(:extend) { |*_args| }
    Rails.application.load_console
    Rails.logger.define_singleton_method(:extend, rails_logger_extend_method)

    include(Rails::ConsoleMethods)

    Rails.application.config.console.start
  else
    Pry.start
  end
  exit
end
