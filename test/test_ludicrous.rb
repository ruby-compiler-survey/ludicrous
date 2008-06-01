require 'test/unit/autorunner'
require 'test/unit/testcase'
require 'ludicrous'

class TestLudicrous < Test::Unit::TestCase
  def compile_and_run(obj, method, *args)
    m = obj.method(method)
    f = m.ludicrous_compile
    f.apply(obj, *args)
  end

  def test_raise
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        raise "FOO!"
      end
    end
    assert_raise(RuntimeError) do
      compile_and_run(foo.new, :foo)
    end
  end

  def test_reassign_no_block
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        a = 1
        a = 2
        assert_equal(2, a)
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_reassign_with_block
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        a = 1
        a = 2
        [].each { }
        assert_equal(2, a)
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_two_block_args_passed_two_values
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        [ [1, 2] ].each do |x, y|
          assert_equal 1, x
          assert_equal 2, y
        end
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_two_block_args_passed_three_values
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        [ [1, 2, 3] ].each do |x, y|
          assert_equal 1, x
          assert_equal [2, 3], y
        end
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_block_inside_else
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        a = "FOO"
        assert_equal("FOO", a)
        if true then
          assert_equal("FOO", a)
        else
          [].each { false }
        end
        assert_equal("FOO", a)
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_required_arg
    foo = Class.new do
      include Test::Unit::Assertions
      def foo(n)
        assert_equal(42, n)
      end
    end
    compile_and_run(foo.new, :foo, 42)
  end

  def test_optional_arg_passed_in
    foo = Class.new do
      include Test::Unit::Assertions
      def foo(n=0)
        assert_equal(42, n)
      end
    end
    compile_and_run(foo.new, :foo, 42)
  end

  def test_optional_arg_not_passed_in
    foo = Class.new do
      include Test::Unit::Assertions
      def foo(n=0)
        assert_equal(0, n)
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_array_foo
    foo = Class.new do
      include Test::Unit::Assertions
      def foo(n=0)
        a = []
        a[1] = 42
        assert_equal(42, a[1])
        a[1] = 43
        assert_equal(43, a[1])
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_massign_from_array
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        x, y = [1, 2]
      end
    end
    compile_and_run(foo.new, :foo)
  end

  FOO = 42

  def test_colon2
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        assert_equal 42, TestLudicrous::FOO
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_rest_arg
    foo = Class.new do
      include Test::Unit::Assertions
      def foo(expected, *rest)
        assert_equal(expected, rest)
      end
    end
    compile_and_run(foo.new, :foo, [])
    compile_and_run(foo.new, :foo, [1], 1)
    compile_and_run(foo.new, :foo, [1, 2], 1, 2)
    compile_and_run(foo.new, :foo, [1, 2, 3], 1, 2, 3)
  end

  def test_simple_rescue
    foo = Class.new do
      include Test::Unit::Assertions
      def foo(exc, *rest)
        begin
          raise exc
          assert false, "Should not reach this point"
        rescue exc
          assert exc === $!
        end
      end
    end
    compile_and_run(foo.new, :foo, StandardError)
    compile_and_run(foo.new, :foo, ArgumentError)
  end

  def test_retry
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        retried = false
        begin
          if not retried then
            raise "FOO"
          else
            return
          end
        rescue
          if not retried then
            retried = true
            retry
          else
            assert false, "Retried more than once"
          end
        end
        assert false, "Failed to retry"
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_when
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        case
        when Object
          assert true
        when true
          assert false
        when false
          assert false
        else
          assert false
        end
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_array_index_out_of_bounds
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        a = [ 1, 2, 3 ]
        assert_equal(nil, a[4])
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_optional_and_rest
    foo = Class.new do
      include Test::Unit::Assertions
      def foo(a=10, *rest)
        return a, rest
      end
    end
    a, rest = compile_and_run(foo.new, :foo)
    assert_equal(10, a)
    assert_equal([], rest)
  end

  def test_return_splat_nil
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        return *nil
      end
    end
    result = compile_and_run(foo.new, :foo)
    assert_equal(nil, result)
  end

  def test_splat_asgn_nil
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        a = nil
        *a = nil
        return a
      end
    end
    result = compile_and_run(foo.new, :foo)
    assert_equal([nil], result)
  end

  def test_splat_asgn_splat_nil
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        a = nil
        *a = *nil
        return a
      end
    end
    result = compile_and_run(foo.new, :foo)
    assert_equal([nil], result)
  end

  def test_op_asgn_and
    foo = Class.new do
      include Test::Unit::Assertions
      def foo
        c &&= 33
        assert_nil(c)
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_simple_next
    foo = Class.new do
      include Test::Unit::Assertions
      def bar(val)
        a = yield
        assert_equal(a, val)
      end
      def foo
        bar(nil) { next }
      end
    end
    compile_and_run(foo.new, :foo)
  end

  def test_return_from_iterator
    foo = Class.new do
      include Test::Unit::Assertions
      def iter
        yield
        assert false, "Should not reach this point"
      end
      def foo
        iter { return 42 }
        assert false, "Should not reach this point"
      end
    end
    result = compile_and_run(foo.new, :foo)
    assert_equal 42, result
  end

  def test_empty_bmethod
    foo = Class.new do
      include Test::Unit::Assertions
      define_method(:foo) {
      }
    end
    compile_and_run(foo.new, :foo)
  end

  def test_bmethod_one_arg
    foo = Class.new do
      include Test::Unit::Assertions
      define_method(:foo) { |x|
        x
      }
    end
    result = compile_and_run(foo.new, :foo, 42)
    assert_equal 42, result
  end

  def test_argspush
    foo = Class.new do
      include Test::Unit::Assertions

      def args
        a = 1, 2, 3
        self[4, 5, *a] = 6
      end

      def []=(*args)
        @args = args
      end

      attr_reader :foo
    end
    obj = foo.new
    compile_and_run(obj, :foo)

    assert_equal([4, 5, 1, 2, 3, 6], obj.foo)
  end

  def test_go_plaid_empty_method
    foo = Class.new do
      def foo
      end
    end
    
    foo.go_plaid

    obj = foo.new
    obj.foo
  end

  def test_toplevel_simple
    program = <<-END
      42
    END
    node = Node.compile_string(program)
    toplevel_self = Object.new
    f = node.ludicrous_compile_toplevel(toplevel_self)
    assert_equal 42, f.apply()
  end

  def test_toplevel_defn
    program = <<-END
      def foo
        42
      end
    END
    node = Node.compile_string(program)
    toplevel_self = Object.new
    f = node.ludicrous_compile_toplevel(toplevel_self)
    assert_equal nil, f.apply()
    assert_equal 42, toplevel_self.foo
  end

  # TODO: test constant access at toplevel

  def test_method_added_hook_then_module_function
    m = Module.new do
      go_plaid

      def foo
        42
      end
      module_function :foo
    end

    assert_equal(42, m.foo)

    # TODO: Shouldn't be compiled since we jit-compiled the module but
    # not its singleton class (how to test this?)
  end

  def test_method_added_hook_then_module_function_with_block
    m = Module.new do
      go_plaid

      def foo(&block)
        return block
      end
      module_function :foo
    end

    p = proc { 42 }
    p2 = m.foo(&p)
    assert_equal(p, p2)

    # TODO: Shouldn't be compiled since we jit-compiled the module but
    # not its singleton class (how to test this?)
  end

  def test_jit_stub_with_block
    c = Class.new do
      go_plaid

      def foo(&block)
        return block
      end
    end

    o = c.new
    p = proc { 42 }
    p2 = o.foo(&p)
    assert_equal(p, p2)
  end

  # TODO: need a test for a bug that causes an infinite loop when the
  # method_added hook fails (compilation causes the original method to
  # be readded, which causes the method_added hook to get called)

  def test_jit_stub_with_yield_to_block
    c = Class.new do
      def foo
        yield 42
      end

      go_plaid
    end

    # c.ludicrous_compile_method(:foo)

    o = c.new

    x = 0
    o.foo { |y| x = y }

    assert_equal(42, x)

    x = 0
    o.foo { |y| x = y }

    assert_equal(42, x)
  end

  def test_call_jit_stub_in_base_class
    $test_call_jit_stub_in_base_class__derived_foo_called = 0
    base = Class.new do
      def foo
        puts "in base"
        return 42
      end

      go_plaid
    end

    derived = Class.new(base) do
      def foo
        puts "in derived"
        $test_call_jit_stub_in_base_class__derived_foo_called += 1
        super
      end
    end

    o = derived.new
    assert_equal(42, o.foo)
    assert_equal(1, $test_call_jit_stub_in_base_class__derived_foo_called)
  end

  def test_match_data_is_local_to_method
    c = Class.new do
      include Test::Unit::Assertions

      def foo
        "foo" =~ /(foo)/
        assert_not_equal nil, $~
      end

      go_plaid
    end

    assert_equal nil, $~
    o = c.new
    o.foo
    assert_equal nil, $~
  end
end

if __FILE__ == $0 then
  require 'logger'
  Ludicrous.logger = Logger.new(STDERR)
  exit Test::Unit::AutoRunner.run #(true)
end

