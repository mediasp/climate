require 'helpers'

module DelegationTest
  describe 'declaring delegate methods that delegate method call to a parent' do

    class Parent < Climate::Command('parent')
      def foo ; 'foo' ; end
      def bar ; 'bar' ; end
      def baz ; 'baz' ; end
    end

    class Child < Climate::Command('child')
      subcommand_of Parent
      expose_ancestor_method Parent, :foo
      expose_ancestor_methods Parent, :bar, :baz
    end

    it 'defines a method on the command that calls the parent' do
      parent, child = Parent.build(['child'])
      assert_equal 'foo', child.foo
      assert_equal 'bar', child.bar
      assert_equal 'baz', child.baz
    end
  end
end
