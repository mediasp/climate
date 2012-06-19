module Climate
  class Error < ::StandardError ; end
  class UnexpectedArgumentError < Error ; end
  class MissingArgumentError < Error ; end
  class DefinitionError < Error ; end
end
