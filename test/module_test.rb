# require 'test_helper'
# require "trailblazer/operation/module"
# require "trailblazer/operation/callback"
# require "trailblazer/operation/contract"

# class OperationModuleTest < MiniTest::Spec
#   Song = Struct.new(:name, :artist)
#   Artist = Struct.new(:id, :full_name)

#   class Create < Trailblazer::Operation
#     include Trailblazer::Operation::Callback
#     include Contract::Explicit

#     contract do
#       property :name
#       property :artist, populate_if_empty: Artist do
#         property :id
#       end
#     end

#     callback do
#       on_change :notify_me!
#     end

#     attr_reader :model
#     def call(params)
#       self["model"] = Song.new

#       validate(params, model: self["model"]) do
#         contract.sync

#         dispatch!
#       end

#       self
#     end

#     def dispatched
#       self["dispatched"] ||= []
#     end

#   private
#     def notify_me!(*)
#       dispatched << :notify_me!
#     end
#   end


#   module SignedIn
#     include Trailblazer::Operation::Module

#     contract do
#       property :artist, inherit: true do
#         property :full_name

#         puts definitions.inspect
#       end
#     end

#     callback do
#       on_change :notify_you!
#     end

#     def notify_you!(*)
#       dispatched << :notify_you!
#     end
#   end


#   class Update < Create
#     callback do
#       on_change :notify_them!
#     end

#     include SignedIn

#     def notify_them!(*)
#       dispatched << :notify_them!
#     end
#   end


#   it do
#     op = Create.({name: "Feelings", artist: {id: 1, full_name: "The Offspring"}})

#     op["dispatched"].must_equal [:notify_me!]
#     op["model"].name.must_equal "Feelings"
#     op["model"].artist.id.must_equal 1
#     op["model"].artist.full_name.must_be_nil # property not declared.
#   end

#   it do
#     op = Update.({name: "Feelings", artist: {id: 1, full_name: "The Offspring"}})

#     op["dispatched"].must_equal [:notify_me!, :notify_them!, :notify_you!]
#     op["model"].name.must_equal "Feelings"
#     op["model"].artist.id.must_equal 1
#     op["model"].artist.full_name.must_equal "The Offspring" # property declared via Module.
#   end
# end
