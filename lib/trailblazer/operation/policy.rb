module Trailblazer
  class Operation
    module Policy
      class Default
        extend Uber::InheritableAttr
        # Strict policy is a behavior that force policies to exists
        # strict :true raises an exception if no policy is defined for operation
        # If you are on Op::Update and theres no update? prepare for an exception!
        # It forces developers to always define a policy for action
        # default: true
        inheritable_attr :strict_mode
        # If not user is set, raise Exception
        # default: true
        inheritable_attr :guest_allowed
        # Overwrite trailblazer action on can? check
        # default: nil
        inheritable_attr :check_action
        attr_reader :user, :resource, :strict_mode, :is_guest_allowed

        # Class Methods
        def self.strict(strict)
          self.strict_mode = strict
        end
    
        def self.allow_guest(allow_guest)
          self.guest_allowed = allow_guest
        end
        
        def self.policy_action(action)
          self.check_action = action
        end

        # Instance Methods
        def initialize(user = nil, resource = nil)
          @user = user
          @resource = resource
          self.class.strict_mode = true if self.class.strict_mode.nil?
          @strict_mode = self.class.strict_mode

          self.class.guest_allowed = false if self.class.guest_allowed.nil?
          @is_guest_allowed = self.class.guest_allowed
        end
    
        def verify(action)
          return true if !is_user_present and is_guest_allowed
          raise Trailblazer::Operation::NotAuthorized.new('Guest Not Allowed') if deny_guest
          return check_action(action)
        end

        private
        def check_action(action)
          if respond_to?("#{action}?".to_sym)
            raise Trailblazer::Operation::NotAuthorized.new('Not Authorized') unless send("#{action}?".to_sym)
          else
            raise Trailblazer::Operation::NotAuthorized.new('No Policy Defined (Strict Mode On)') if strict_mode
          end
          true
        end
    
        def is_user_present
          return false if user.nil?
          true
        end

        def deny_guest
          return true if !is_user_present and !is_guest_allowed
          false
        end
      end
  
      def self.included(base)
        base.extend Uber::InheritableAttr
        base.extend ClassMethods
        base.inheritable_attr :policy_class
      end

      module ClassMethods

        def policy(&block)
          build_policy_class.class_eval(&block)
        end

        def build_policy_class
          policy_class || self.policy_class= Default.dup
        end

      end
      
      def setup_policy!(params)
        # Get user, resource and create policy
        @user = params[:current_user]
        resource = @model
        @policy = self.class.policy_class.new(@user, resource)
        
        # Check against non trailblazer action
        if self.class.policy_class.check_action.nil?
          @policy.verify(self.class.action_name)
        else
          @policy.verify(self.class.policy_class.check_action)
        end
      end
    end
  end
end
