module JsonPatch
  VERSION = '0.0.1'
end

require 'json_patch/pointer'
require 'json_patch/patch'
require 'json_patch/railtie' if defined?(Rails)
