require 'ruby-prof'

RSpec.configure do |c|
  c.before(:suite) do
    RubyProf.start
  end

  c.after(:suite) do
    result = RubyProf.stop
    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT)
  end
end
