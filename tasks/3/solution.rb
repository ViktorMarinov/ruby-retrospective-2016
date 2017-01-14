class CommandParser
  def initialize(command)
    @command = command
    @args = []
    @options = []
  end

  def argument(name, &block)
    @args << Argument.new(name, &block)
  end

  def option(*args, &block)
    @options << Option.new(*args, &block)
  end

  def option_with_parameter(*args, &block)
    @options << OptionWithParameter.new(*args, &block)
  end

  def parse(command_runner, argv)
    execute_args(command_runner, argv.reject { |a| a.include? '-' })
    execute_options(command_runner, argv.select { |o| o.include? '-' })
  end

  def help
    help_message = "Usage: #{@command}" 
    help_message << " #{@args.map(&:help).join(' ')}" unless @args.empty?
    help_message << "\n#{opitions_help}" unless @options.empty?

    help_message
  end

  private

  def opitions_help
    @options.map(&:help).join("\n")
  end

  def execute_args(command_runner, args)
    @args.zip(args) { |arg, value| arg.call(command_runner, value) }
  end

  def execute_options(command_runner, options)
    @options.each { |opt| opt.parse(command_runner, options) }
  end
end

class Argument
  def initialize(name, &block)
    @name = name
    @block = block
  end

  def call(command_runner, value)
    @block.call(command_runner, value)
  end

  def help
    "[#{@name}]"
  end
end

class Option
  def initialize(short_name, full_name, description, &block)
    @short_name = short_name
    @full_name = full_name
    @description = description
    @block = block
  end

  def call(command_runner, value = true)
    @block.call(command_runner, value)
  end

  def parse(command_runner, options)
    call(command_runner) if options.any? { |opt| matches?(opt) }
  end

  def help
    "    -#{@short_name}, #{full_name_to_s} #{@description}"
  end

  def full_name_to_s
    "--#{@full_name}"
  end

  private

  def matches?(option)
    key = option.tr('-', '')
    key == @short_name || key == @full_name
  end
end

class OptionWithParameter < Option
  def initialize(short_name, full_name, description, value_name, &block)
    super(short_name, full_name, description, &block)
    @value_name = value_name
  end

  def full_name_to_s
    "--#{@full_name}=#{@value_name}"
  end

  def parse(command_runner, options)
    options.each do |opt|
      key, value = get_pair(opt)
      call(command_runner, value) if matches?(key)
    end
  end

  private
  
  def get_pair(option)
    if option.count('-') == 1
      [option[1], option[2..-1]]
    else
      key, _, value = option.partition('=')
      [key.tr('-', ''), value]
    end
  end
end