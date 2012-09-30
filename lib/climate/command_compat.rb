module Climate
  # require this file to monkey patch Command to have old <= 0.4 Command.name
  # method that was removed to fix https://github.com/playlouder/climate/issues/6
  class Command
    def self.name(name=nil)
      set_name(name) if name
      command_name
    end

    # because we've extended Class.name, we expose the original method
    # under another name.  Can be removed once we move away from Command.name
    # method
    # FIXME: surely there is a saner way of doing this?
    def self.class_name
      Class.method(:name).unbind.bind(self).call
    end
  end
end
