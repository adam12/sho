require 'tilt'

module Sho
  def self.included(mod)
    mod.define_singleton_method(:sho) {
      @__sho_configurator__ ||= Configurator.new(mod)
    }
  end

  class Configurator
    attr_reader :host
    attr_accessor :base_folder

    def initialize(host)
      @host = host
    end

    def template(name, template, *, _layout: nil, **)
      define_template_method name, File.join(base_folder || Dir.pwd, template), _layout: _layout
    end

    def template_relative(name, template, *, _layout: nil, **)
      base = File.dirname(caller.first.split(':').first)
      define_template_method name, File.join(base, template), _layout: _layout
    end

    def template_inline(name, _layout: nil, **options)
      kind, template = options.detect { |key,| Tilt.registered?(key.to_s) }
      template or fail ArgumentError, "No known templates found in #{options.keys}"

      @host.__send__(:define_method, name) do |**locals|
        tilt = Tilt.default_mapping[kind].new { template }
        if _layout
          __send__(_layout) { tilt.render(self, **locals) }
        else
          tilt.render(self, **locals)
        end
      end
    end

    alias inline_template template_inline

    private

    def define_template_method(name, path, _layout:)
      @host.__send__(:define_method, name) do |**locals|
        tilt = Tilt.new(path)
        if _layout
          __send__(_layout) { tilt.render(self, **locals) }
        else
          tilt.render(self, **locals)
        end
      end
    end
  end
end