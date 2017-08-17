require "test_helper"

class VariablesTest < Minitest::Spec
  # Nested op copies values and modifies/amplifies some of them.
  class Whistleblower < Trailblazer::Operation
    step ->(options, public_opinion:, **) { options["edward.public_opinion"] = public_opinion.upcase }
    step ->(options, secret:, **)         { options["edward.secret"]         = secret }
    step ->(options, rumours:, **)        { rumours.nil? ? rumours : options["edward.rumours"] = rumours*2 }
  end

  #---
  #- everything public. options is simply passed on.
  class OpenOrganization < Trailblazer::Operation
    step ->(options, **) { options["rumours"] = "Bla" }
    step ->(options, **) { options["secret"]  = "Psst!" }

    step Nested( Whistleblower )

    step ->(options, **) { options["org.rumours"] = options["edward.rumours"] } # what can we see from Edward?
    step ->(options, **) { options["org.secret"]  = options["edward.secret"] }  # what can we see from Edward?
  end

  it do
    result = OpenOrganization.({}, "public_opinion" => "Freedom!")

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", "Psst!", "BlaBla"] >}
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
    result = ConsideringButOpenOrganization.({}, "public_opinion" => "Freedom!")

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", "Psst!", "BlaBla"] >}
  end

  #---
  #- explicitely pass allowed variables, only.
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
    result = ProtectedOrganization.({}, "public_opinion" => "Freedom!")

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", 0, 0.0] >}
  end


  class EncryptedOrganization < ConsideringButOpenOrganization
    def input!(options, **)
      options.merge( "secret" => options["secret"]+"XxX" )
    end
  end


  # TODO write to options and get error

  it do
    result = EncryptedOrganization.({}, "public_opinion" => "Freedom!")

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", "Psst!XxX", "BlaBla"] >}
  end

end
