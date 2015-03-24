require 'test_helper'
require 'trailblazer/operation/policy'

User = Struct.new(:admin) do
  attr_accessor :admin
  alias_method :admin?, :admin

  class << self
    def create(params)
      user = User.new
      user.admin = params[:admin]
      user
    end
  end
end
class Thing < ActiveRecord::Base; end

class PolicyTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class Create < Trailblazer::Operation
      include CRUD, Policy

      model Thing

      # policy definition for operation
      policy do
        def create?
          user.admin?
        end

        def update?
          user.admin? and resource.active?
        end
      end

      def process(params)
        self
      end
    end

    class Publish < Create
      action :update
    end

    class Index < Create
    end
  end

  # Create users
  let(:admin_user) { User.create(admin: true) }
  let(:normal_user) { User.create(admin: false) }

  # Create our dummy database files
  before do
    @thing_active = Thing.create(title: "Active Thing", active: true)
    @thing_inactive = Thing.create(title: "Inactive Thing", active: false)
  end

  # Allows create for admins
  it { Thing::Create[current_user: admin_user, thing: @thing_active.attributes].policy.create?.must_equal (true) }

  # Do not allow create for non-admins
  it do
    err = ->{ Thing::Create[current_user: normal_user, thing: @thing_active.attributes].policy.create? }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /Not Authorized/
  end

  # Allows publish for admins and active resources
  it { Thing::Publish[current_user: admin_user, id: @thing_active.id].policy.update?.must_equal (true) }

  # Do not allow public for admin but inactive resource
  it do
    err = ->{ Thing::Publish[current_user: admin_user, id: @thing_inactive.id].policy.update? }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /Not Authorized/
  end

  # Do not allows undefined policy (strict mode)
  it do
    err = ->{ Thing::Index[current_user: admin_user].policy.verify(:index) }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /No Policy Defined \(Strict Mode On\)/
  end
end

class DefaultPolicyNotAllowGuestTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class NotAllowGuest < Trailblazer::Operation
      include CRUD, Policy

      model Thing

      # policy definition for operation
      policy do
        def create?
          user.admin?
        end
      end
      def process(params); self end
    end
  end

  it do
    err = ->{ Thing::NotAllowGuest[current_user: nil] }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /Guest Not Allowed/
  end
end

class DefaultPolicyAllowGuestTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class AllowGuest < Trailblazer::Operation
      include CRUD, Policy

      model Thing

      policy do
        allow_guest true
        def create?
          user.admin?
        end
      end
      def process(params); self end
    end
  end

  it { Thing::AllowGuest[current_user: nil].policy.verify(:create).must_equal (true) }
end

class DefaultPolicyUndefinedActionStrictModeDefaultTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class NotAllowUndefinedAction < Trailblazer::Operation
      include CRUD, Policy

      model Thing

      # policy definition for operation
      policy do
      end
      def process(params); self end
    end
  end

  let(:admin_user) { User.create(admin: true) }
  it do
    err = ->{ Thing::NotAllowUndefinedAction[current_user: admin_user] }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /No Policy Defined \(Strict Mode On\)/
  end
end

class DefaultPolicyUndefinedActionStrictModeOffTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class AllowUndefinedAction < Trailblazer::Operation
      include CRUD, Policy

      model Thing

      policy do
        strict false
      end
      def process(params); self end
    end
  end

  let(:admin_user) { User.create(admin: true) }
  it { Thing::AllowUndefinedAction[current_user: admin_user].policy.verify(:create).must_equal (true) }
end

class DefaultPolicyDefinedResourceTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class ResourceAvailable < Trailblazer::Operation
      include CRUD, Policy

      action :update
      model Thing

      # policy definition for operation
      policy do
        def update?
          resource.active?
        end
      end
      def process(params); self end
    end
  end

  let(:admin_user) { User.create(admin: true) }
  before do
    @thing_active = Thing.create(title: "Active Thing", active: true)
  end
  it { Thing::ResourceAvailable[current_user: admin_user, id: @thing_active.id].policy.verify(:update).must_equal (true) }
end

class DefaultPolicyAllowAccessTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class AllowAccess < Trailblazer::Operation
      include CRUD, Policy

      action :create
      model Thing

      # policy definition for operation
      policy do
        def create?
          user.admin?
        end
      end
      def process(params); self end
    end
  end

  let(:admin_user) { User.create(admin: true) }
  it { Thing::AllowAccess[current_user: admin_user].policy.verify(:create).must_equal (true) }
end

class DefaultPolicyNotAllowAccessTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class NotAllowAccess < Trailblazer::Operation
      include CRUD, Policy

      action :create
      model Thing

      # policy definition for operation
      policy do
        def create?
          user.admin?
        end
      end
      def process(params); self end
    end
  end

  let(:normal_user) { User.create(admin: false) }
  it do
    err = ->{ Thing::NotAllowAccess[current_user: normal_user] }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /Not Authorized/
  end
end

class DefaultPolicyNotAllowAccessTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class NotAllowAccess < Trailblazer::Operation
      include CRUD, Policy

      action :create
      model Thing

      # policy definition for operation
      policy do
        def create?
          user.admin?
        end
      end
      def process(params); self end
    end
  end

  let(:normal_user) { User.create(admin: false) }
  it do
    err = ->{ Thing::NotAllowAccess[current_user: normal_user] }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /Not Authorized/
  end
end

class DefaultPolicyExceptionOnPolicyFalseTest < MiniTest::Spec
  class Thing < ActiveRecord::Base
    class NotAllowedAction < Trailblazer::Operation
      include CRUD, Policy

      action :create
      model Thing

      # policy definition for operation
      policy do
        policy_action :boom
        strict true
        allow_guest false
        
        def create?
          true
        end

        def boom?
          false
        end
      end
      def process(params); self end
    end
  end

  let(:admin_user) { User.create(admin: true) }
  it do
    err = ->{ Thing::NotAllowedAction[current_user: admin_user] }.must_raise Trailblazer::Operation::NotAuthorized
    err.message.must_match /Not Authorized/
  end
end
