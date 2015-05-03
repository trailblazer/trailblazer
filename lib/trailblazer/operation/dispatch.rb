module Trailblazer::Operation::Dispatch
  module ClassMethods
    def skip_dispatch(callback_name)
      _skip_dispatch << callback_name
    end
  end

  def self.included(base)
    base.extend ClassMethods

    base.extend Uber::InheritableAttr
    base.inheritable_attr :_skip_dispatch
    base._skip_dispatch = []
  end


  def dispatch(callback_name, *args)
    return if self.class._skip_dispatch.include?(callback_name)
    send(callback_name, *args)
  end
end