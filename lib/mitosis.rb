require 'un'
require 'sha1'

module Cell
	module HelperMethods

		def script(&block)
			__cell_info.script(self, @state_name, capture(&block).gsub(/<[\/]?script.*?>/, "\n"))
		end

		def style(&block)
			__cell_info.style(self, @state_name, capture(&block).gsub(/<[\/]?style.*?>/, "\n"))
		end

		def include_cell(name, state, options = {})
			__cell_info.depend(self, @state_name, name, state)
			render_cell(name, state, options)
		end

		def require_content(channel, &block)
			state = @state_name
			cell = self.cell
			content = capture(channel, &block)
			cell.root_view.instance_eval do
				if @_cell_requirements.nil?
					@_cell_requirements = Hash.new {|h, k| h[k] = {}}
				end
				req = @_cell_requirements["#{cell.class}/#{state}"]
				if !req[channel]
					req[channel] = true
					content_for(channel, content)
				end
			end
		end


		def __cell_info
			self.cell.root_view.cell_info
		end

	end

	class Base
		helper HelperMethods
	end

	class CellInfo

		attr_reader :view

		def initialize
			@identifier = nil
			@order = []
			@contents = Hash.new do |h, k|
				@order << CellContent.new(self, k)
				h[k] = @order.last
			end
		end

		def style(view, state, src)
			self[view.cell.cell_name, state, view.template.source].style =	src
		end

		def script(view, state, src)
			self[view.cell.cell_name, state, view.template.source].script =	src
		end

		def depend(view, state, depname, depstate)
			self[view.cell.cell_name, state, view.template.source].depends << [depname, depstate]
		end

		def [](cell_name, state, template_src = nil)
			raise "no cell_name specified" unless cell_name
			raise "no state given" unless state
			@contents["#{cell_name}.#{state}"].source(template_src)
		end

		def identifier
			return @identifier if @identifier
			all = []
			deporder do |content|
				all << "#{content.key}#{'.' + SHA1.hexdigest(content.template) if content.template}"
			end
			@identifier = SHA1.hexdigest(all.join('+'))
		end


		def script_content
			scripts = []
			deporder do |content|
				scripts << content.script if content.script
			end
			scripts.join("\n")
		end

		def style_content
			styles = []
			deporder do |content|
				styles << content.style if content.style
			end
			styles.join("\n")
		end

		def deporder(&block)
			seen = {}
			for content in @order
				visit(content, seen, &block)
			end
		end

		def visit(content, seen, &block)
			unless seen[content.key]
				seen[content.key] = true
				for name, state in content.depends do
					visit(self[name, state], seen, &block)
				end
				block.call(content) if block_given?
			end
		end

	end

	class CellContent

		attr_accessor :script, :style
		attr_reader :key, :depends, :template

		def initialize(info, key)
			@info = info
			@key = key
			@styles = []
			@scripts = []
			@depends = []
			@template = nil
		end

		def source(source)
			@template = source if source && !@template
			self
		end
	end


	module MitosisHelper
		def cell_script_tag
			filename = "#{Rails.public_path}/javascripts/gen/#{cell_info.identifier}.js"
			File.open(filename, "w") do |file|
				file.write cell_info.script_content
			end unless File.exist?(filename)
			javascript_include_tag("gen/#{cell_info.identifier}").sub /\.js\?\d+"/, '.js"'
		end

		def cell_stylesheet_link_tag
			filename = "#{Rails.public_path}/stylesheets/gen/#{cell_info.identifier}.css"
			File.open(filename, "w") do |file|
				file.write cell_info.style_content
			end unless File.exist?(filename)
			stylesheet_link_tag("gen/#{cell_info.identifier}").sub /\.css\?\d+"/, '.css"'
		end

		def cell_info
			@__cell_info.nil?	? @__cell_info = CellInfo.new : @__cell_info
		end
	end

end