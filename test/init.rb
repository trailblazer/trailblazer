require "test_helper"

require "dry/initializer"

require "dry/container"
require "dry/auto_inject"

my_container = Dry::Container.new
my_container.register(:user_repository, -> { Object })

AutoInject = Dry::AutoInject(my_container)


class User
  extend Dry::Initializer::Mixin
    include AutoInject[:user_repository]

  # param  :name
  # param  :role
  option :admin
  option :user_repository
end


class A < User
  option :blubb

  def initialize(*)
    super

    @bla = "yo"
  end

  attr_reader :bla
end

user = A.new admin: true, blubb: 1

puts user.bla
puts user.admin
puts user.blubb
