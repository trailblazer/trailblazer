require "test_helper"

class VariablesTest < Minitest::Spec
  # Nested op copies values and modifies/amplifies some of them.
  class Whistleblower < Trailblazer::Operation
    step ->(options, public_opinion:, **) { options["edward.public_opinion"] = public_opinion.upcase }        , id: "edward.public_opinion"
    step ->(options, secret:, **)         { options["edward.secret"]         = secret }                       , id: "edward.secret"
    step ->(options, rumours:, **)        { rumours.nil? ? rumours : options["edward.rumours"] = rumours*2 }  , id: "edward.test"
    pass ->(options, **)                  { options["edward.public_knowledge"] = options["public_knowledge"] }, id: "edward.read.public_knowledge"
  end

=begin
  Everything public. options are simply passed on.

  Both Org and Edward write and read from the same Context instance.
=end
  class OpenOrganization < Trailblazer::Operation
    step ->(options, **) { options["rumours"] = "Bla" }
    step ->(options, **) { options["secret"]  = "Psst!" }

    step Nested( Whistleblower )

    step ->(options, **) { options["org.rumours"] = options["edward.rumours"] } # what can we see from Edward?
    step ->(options, **) { options["org.secret"]  = options["edward.secret"] }  # what can we see from Edward?
  end

  it do
    result = OpenOrganization.("public_opinion" => "Freedom!", "public_knowledge" => true)

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours", "edward.public_knowledge").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", "Psst!", "BlaBla", true] >}
  end

  #---
  #- simply passes on the context
  class ConsideringButOpenOrganization < Trailblazer::Operation
    step ->(options, **) { options["rumours"] = "Bla" }
    step ->(options, **) { options["secret"]  = "Psst!" }

    step Nested( Whistleblower, input: :input! )

    step ->(options, **) { options["org.rumours"] = options["edward.rumours"] } # what can we see from Edward?
    step ->(options, **) { options["org.secret"]  = options["edward.secret"] }  # what can we see from Edward?

    def input!(options, **)
      options
    end
  end

  it do
    result = ConsideringButOpenOrganization.("public_opinion" => "Freedom!")

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", "Psst!", "BlaBla"] >}
  end

=begin
  Explicitely passes allowed variables, only.

  Edward can only read those three variables and can't see "public_knowledge" or others.
=end
  class ProtectedOrganization < ConsideringButOpenOrganization
    def input!(options, **)
      {
         "public_opinion" => options["public_opinion"],
         "secret"         => 0,
         "rumours"        => 0.0
      }
    end
  end

  it do
    result = ProtectedOrganization.( {}, "public_opinion" => "Freedom!", "public_knowledge" => true )

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours", "edward.public_knowledge").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", 0, 0.0, nil] >}
  end

  #---
  #- new ctx
=begin
:input produces a differing value for an existing key "secret"
this should only be visible in the nested activity, and the original
"secret" must be what it was before (unless :output would change that.)

NOTE: i decided it's better to not even allow Context#merge because it
defeats the idea of hiding information via :input and overcomplicates
the scoping.
=end
  class EncryptedOrganization < ConsideringButOpenOrganization
    def input!(options, **)
      options.merge( "secret" => options["secret"]+"XxX" )
    end
  end

  it do
    skip "no options.merge until we know we actually need it"
    result = EncryptedOrganization.("public_opinion" => "Freedom!")

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", "Psst!XxX", "BlaBla"] >}
  end

  # TODO write to options and get error

=begin
  Simply passes on the context to Edward, but applies an :output filter,
  so that Org can't see several nested values such as "edward.public_knowledge"
  or "edward.rumours" (see steps in #read-section).
=end
  class DiscreetOrganization < Trailblazer::Operation
    step ->(options, **) { options["rumours"] = "Bla" },    id: "set.rumours"
    step ->(options, **) { options["secret"]  = "Psst!" },   id: "set.secret"

    step Nested( Whistleblower, input: :input!, output: :output! )

    #read-section
    pass ->(options, **) { options["org.rumours"] = options["edward.rumours"] }, id: "read.edward.rumours" # what can we see from Edward?
    step ->(options, **) { options["org.secret"]  = options["edward.secret"] },  id: "read.edward.secret"  # what can we see from Edward?

    def input!(options, **)
      options
    end

    def output!(options, **)
      {
        "out.keys"    => options.keys,
        "out.rumours" => options["edward.rumours"].slice(0..2),
        "out.secret"  => options["edward.secret"].reverse,
      }
    end
  end

  it do
    result = DiscreetOrganization.("public_opinion" => "Freedom!", "public_knowledge" => true)

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours", "out.keys", "out.rumours", "out.secret", "org.rumours", "org.secret", "public_knowledge", "edward.public_knowledge").
      must_equal %{<Result:false [\"Freedom!\", \"Bla\", \"Psst!\", nil, nil, nil, [\"edward.public_opinion\", \"edward.secret\", \"edward.rumours\", \"edward.public_knowledge\"], \"Bla\", \"!tssP\", nil, nil, true, nil] >}
  end

  it "with tracing" do
    result = DiscreetOrganization.trace("public_opinion" => "Freedom!")

    result.wtf.gsub(/0x\w+/, "").gsub(/\d+/, "").must_equal %{|-- #<Trailblazer::Activity::Start semantic=:default>
|-- set.rumours
|-- set.secret
|-- Nested(VariablesTest::Whistleblower)
|   |-- #<Trailblazer::Activity::Start semantic=:default>
|   |-- edward.public_opinion
|   |-- edward.secret
|   |-- edward.test
|   |-- edward.read.public_knowledge
|   `-- #<Trailblazer::Operation::Railway::End::Success semantic=:success>
|-- read.edward.rumours
|-- read.edward.secret
`-- #<Trailblazer::Operation::Railway::End::Failure semantic=:failure>}
  end
end
