# frozen_string_literal: true

RSpec.describe RuboCop::Cop::ThreadSafety::InstanceVariableInClassMethod, :config do
  it 'registers an offense for assigning to an ivar in a class method' do
    expect_offense(<<~RUBY)
      class Test
        def self.some_method(params)
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers no offense when the assignment is synchronized by a mutex' do
    expect_no_offenses(<<~RUBY)
      class Test
        SEMAPHORE = Mutex.new
        def self.some_method(params)
          SEMAPHORE.synchronize do
            @params = params
          end
        end
      end
    RUBY
  end

  it 'registers no offense when memoization is synchronized by a mutex' do
    expect_no_offenses(<<~RUBY)
      class Test
        SEMAPHORE = Mutex.new
        def self.types
          SEMAPHORE
            .synchronize { @all_types ||= type_class.all }
        end
      end
    RUBY
  end

  it 'registers no offense for assigning an ivar in define_method' do
    expect_no_offenses(<<~RUBY)
      class Test
        def self.factory_method
          define_method(:some_method) do |params|
            @params = params
          end
        end
      end
    RUBY
  end

  it 'registers an offense for reading an ivar in a class method' do
    expect_offense(<<~RUBY)
      class Test
        def self.some_method
          do_work(@params)
                  ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in module ClassMethods' do
    expect_offense(<<~RUBY)
      module ClassMethods
        def some_method(params)
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in class_methods' do
    expect_offense(<<~RUBY)
      module Test
        class_methods do
          def some_method(params)
            @params = params
            ^^^^^^^ Avoid instance variables in class methods.
          end
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in a class singleton method' do
    expect_offense(<<~RUBY)
      class Test
        class << self
          def some_method(params)
            @params = params
            ^^^^^^^ Avoid instance variables in class methods.
          end
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in define_singleton_method' do
    expect_offense(<<~RUBY)
      class Test
        define_singleton_method(:some_method) do |params|
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_get in a class method' do
    expect_offense(<<~RUBY)
      class Test
        def self.some_method
          do_work(instance_variable_get(:@params))
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in a class singleton method' do
    expect_offense(<<~RUBY)
      class Test
        class << self
          def some_method(name, params)
            instance_variable_set(:"@\#{name}", params)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
          end
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in module ClassMethods' do
    expect_offense(<<~RUBY)
      module ClassMethods
        def some_method(params)
          instance_variable_set(:@params, params)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in class_methods' do
    expect_offense(<<~RUBY)
      module Test
        class_methods do
          def some_method(params)
            instance_variable_set(:@params, params)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
          end
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in define_singleton_method' do
    expect_offense(<<~RUBY)
      class Test
        define_singleton_method(:some_method) do |params|
          instance_variable_set(:@params, params)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in a method below module_function directive' do
    expect_offense(<<~RUBY)
      module Test
        module_function

        def some_method(params)
          instance_variable_set(:@params, params)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for ivar_set in a method marked by module_function' do
    expect_offense(<<~RUBY)
      module Test
        def some_method(params)
          instance_variable_set(:@params, params)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid instance variables in class methods.
        end

        module_function :some_method
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in a method below module_function directive' do
    expect_offense(<<~RUBY)
      module Test
        module_function

        def some_method(params)
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end
      end
    RUBY
  end

  it 'registers an offense for assigning an ivar in a method marked by module_function' do
    expect_offense(<<~RUBY)
      module Test
        def some_method(params)
          @params = params
          ^^^^^^^ Avoid instance variables in class methods.
        end

        module_function :some_method
      end
    RUBY
  end

  it 'registers no offense for ivar_set in define_method' do
    expect_no_offenses(<<~RUBY)
      class Test
        def self.factory_method
          define_method(:some_method) do |params|
            instance_variable_set(:@params, params)
          end
        end
      end
    RUBY
  end

  it 'registers no offense for using ivar_get on object in a class method' do
    expect_no_offenses(<<~RUBY)
      class Test
        def self.some_method(obj, params)
          obj.instance_variable_get(:@params)
        end
      end
    RUBY
  end

  it 'registers no offense for using ivar_set on object in a class method' do
    expect_no_offenses(<<~RUBY)
      class Test
        class << self
          def some_method(obj, params)
            obj.instance_variable_set(:@params, params)
          end
        end
      end
    RUBY
  end

  it 'registers no offense for using an ivar in an instance method' do
    expect_no_offenses(<<~RUBY)
      class Test
        def some_method(params)
          @params = params
          do_work(@params)
        end
      end
    RUBY
  end

  it 'registers no offense for using ivar methods in an instance method' do
    expect_no_offenses(<<~RUBY)
      class Test
        def some_method(params)
          instance_variable_set(:@params, params)
          do_work(instance_variable_get(:@params))
        end
      end
    RUBY
  end

  it 'registers no offense for using an ivar in a module below ClassMethods' do
    expect_no_offenses(<<~RUBY)
      module ClassMethods
        module Other
          def some_method(params)
            @params = params
          end
        end
      end
    RUBY
  end

  it 'registers no offense for assigning an ivar in a method above module_function directive' do
    expect_no_offenses(<<~RUBY)
      module Test
        def some_method(params)
          @params = params
        end

        module_function
      end
    RUBY
  end

  it 'registers no offense for assigning an ivar in a method not marked by module_function' do
    expect_no_offenses(<<~RUBY)
      module Test
        def some_method(params)
          @params = params
        end

        def another_method(params)
          puts params
        end

        module_function :another_method
      end
    RUBY
  end
end
