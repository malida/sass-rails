require 'sassc'
require 'sass/rails/cache_store'
require 'sass/rails/helpers'
require 'sprockets/sass_functions'
require "sprockets/version"
require "sprockets/sass_template"
require "sprockets/utils"

module Sass
  module Rails
    class SassTemplate < Sprockets::SassTemplate
      module Sprockets3
        def call(input)
          context = input[:environment].context_class.new(input)

          options = {
            filename: input[:filename],
            syntax: self.class.syntax,
            load_paths: input[:environment].paths,
            importer: SassC::Rails::Importer,
            sprockets: {
              context: context,
              environment: input[:environment],
              dependencies: context.metadata[:dependency_paths]
            }
          }.merge(config_options)

          engine = ::SassC::Engine.new(input[:data], options)

          css = Sprockets::Utils.module_include(::SassC::Script::Functions, @functions) do
            engine.render
          end

          context.metadata.merge(data: css)
        end
      end

      def config_options
        opts = { style: sass_style }

        if Rails.application.config.sass.inline_source_maps
          opts.merge!({
            source_map_file: ".",
            source_map_embed: true,
            source_map_contents: true,
          })
        end

        opts
      end

      def sass_style
        (Rails.application.config.sass.style || :expanded).to_sym
      end
    end

    class ScssTemplate < SassTemplate
      unless Sprockets::VERSION > "3.0.0"
        self.default_mime_type = 'text/css'
      end

      # Sprockets 3
      def self.syntax
        :scss
      end



      private

      def importer_class
        SassImporter
      end
    end
  end
end
