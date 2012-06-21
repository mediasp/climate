module Climate
  class Error < ::StandardError ; end
  class UnexpectedArgumentError < Error ; end
  class MissingArgumentError < Error ; end
  class DefinitionError < Error ; end
  class UnknownCommandError < Error ; end
end
