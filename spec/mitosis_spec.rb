require 'spec'
require 'ostruct'
require File.join(File.dirname(__FILE__), '..', 'lib', 'mitosis')

describe "Cell::Helper" do

	before :each do
		@view = OpenStruct.new({:template => OpenStruct.new({:source => "Hello World"})})
		@view.instance_eval do
			@state_name = 'on'
		end
		@view.extend Cell::HelperMethods
		@view.cell = OpenStruct.new({:cell_name => 'eg'})
		@top = @view.cell.root_view = OpenStruct.new
		@top.extend Cell::MitosisHelper
	end

	it "extracts scripts into cell info" do
		@view.should_receive(:capture).once.and_return("<script>foo = bar</script>")
		@view.script.should == "\nfoo = bar\n"
	end

	it "works no matter what attributes the script tag actually has" do
		@view.should_receive(:capture).once.and_return("<script type='text/javascript'>var x;</script>")
		@view.script.should	== "\nvar x;\n"
	end

	it "extracts style from cell" do
		@view.should_receive(:capture).once.and_return("<style type='text/css'>.foo {}</style>")
		@view.style.should == "\n.foo {}\n"
	end

	it "stores encountered cells in the views cell_info" do
		@view.should_receive(:capture).once.and_return(".foo {}")
		@view.style
		info	= @view.__cell_info['eg', 'on'].style.should == ".foo {}"
	end

	it "stores a reference to cells which it includes" do
		@view.should_receive(:render_cell).with(:foo, :bar, :with => :options)
		@view.include_cell :foo, :bar, :with => :options
		@view.__cell_info['eg', 'on'].depends.should include([:foo, :bar])
	end

	it "generates a unique hash representing this configuration of cells, including the content of their templates" do
		@view.stub!(:render_cell)
		@view.include_cell :foo, :bar
		@view.include_cell :baz, :bang
		@view.__cell_info.identifier.should == SHA1.hexdigest("foo.bar+baz.bang+eg.on.#{SHA1.hexdigest "Hello World"}")
	end

end

describe "Action View Extensions" do
	module Rails;end

	before :each do
		@view = OpenStruct.new({:template => OpenStruct.new({:source => "Hello World"})})
		@view.instance_eval do
			@state_name = 'on'
		end
		@view.extend Cell::HelperMethods
		@view.cell = OpenStruct.new({:cell_name => 'eg'})
		@top = @view.cell.root_view = OpenStruct.new
		@top.extend Cell::MitosisHelper

		Rails.stub!(:public_path).and_return("/path/to/public")
		@file = Object.new
	end


	it "has a cell_script_tag for views method which compiles the cell scripts and links them via a <script> tag" do
		@view.stub!(:render_cell)
		@view.should_receive(:capture).once.and_return("function() {return 'Hello World'}")
		@view.script
		@view.include_cell :foo, :bar
		@view.include_cell :baz, :bang
		info = @view.__cell_info
		@top.should_receive(:javascript_include_tag).with("gen/#{info.identifier}").and_return("some.js")
		File.should_receive(:open).with("/path/to/public/javascripts/gen/#{info.identifier}.js", "w").and_yield(@file)
		@file.should_receive(:write).with("function() {return 'Hello World'}")
		@top.cell_script_tag
	end

	it "has a cell_style_link for views method which compiles the pages cell stylesheets and links them via a <link> tag" do
		@view.stub!(:render_cell)
		@view.should_receive(:capture).once.and_return(".foo {}")
		@view.style
		info = @view.__cell_info
		@top.should_receive(:stylesheet_link_tag).with("gen/#{info.identifier}").and_return("stylesheet")
		File.should_receive(:open).with("/path/to/public/stylesheets/gen/#{info.identifier}.css", "w").and_yield(@file)
		@file.should_receive(:write).with(".foo {}")
		@top.cell_stylesheet_link_tag
	end

	it "doesn't write the file if it already exists" do
		@view.stub!(:render_cell)
		@view.should_receive(:capture).once.and_return(".foo {}")
		@view.style
		info = @view.__cell_info
		@top.should_receive(:stylesheet_link_tag).with("gen/#{info.identifier}").and_return("stylesheet")
		File.should_receive(:exist?).with("/path/to/public/stylesheets/gen/#{info.identifier}.css").and_return(true)
		File.should_receive(:open).never
		@top.cell_stylesheet_link_tag
	end

end


