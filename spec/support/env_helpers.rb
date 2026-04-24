module EnvHelpers
  def with_env(values)
    previous_values = values.to_h { |key, _value| [ key, ENV[key] ] }

    values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end

    yield
  ensure
    previous_values.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end

RSpec.configure do |config|
  config.include EnvHelpers
end
