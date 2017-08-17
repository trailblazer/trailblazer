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
  #-
  class ProtectedOrganization < Trailblazer::Operation
    step ->(options, **) { options["rumours"] = "Bla" }
    step ->(options, **) { options["secret"]  = "Psst!" }

    step Nested( Whistleblower,
      input: :input!
    )

    step ->(options, **) { options["org.rumours"] = options["edward.rumours"] } # what can we see from Edward?
    step ->(options, **) { options["org.secret"]  = options["edward.secret"] }  # what can we see from Edward?

    def input(options, public_data:raise, **)
      public_data#.merge( "secret" => "XxX" )
    end
  end

  # it do
  #   result = ProtectedOrganization.({}, "public_opinion" => "Freedom!")

  #   result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
  #     must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", nil, nil] >}
  # end


  class EncryptedOrganization < ProtectedOrganization
    def input!(options, **)
      # public_data.merge(  )
      puts "merge #{ options}"
      options.merge( "secret" => options["secret"]+"XxX" )
    end
  end

  it do
    result = EncryptedOrganization.({}, "public_opinion" => "Freedom!")

    result.inspect("public_opinion", "rumours", "secret", "edward.public_opinion", "edward.secret", "edward.rumours").
      must_equal %{<Result:true ["Freedom!", "Bla", "Psst!", "FREEDOM!", "Psst!XxX", "BlaBla"] >}
  end

  # def assert_almost_b(result, is_successful:raise)
  #   result.success?.must_equal is_successful # AlmostB was successful, so A is successful.

  #   # everything from A visible
  #   result["A.class.data"].       must_equal "yes"
  #   result["mutable.data.from.A"].must_equal "from A!"

  #   # AlmostB doesn't look for everything
  #   result["can.B.see.current_user?"].must_be_nil
  #   result["can.B.see.params?"].must_be_nil
  #   if is_successful
  #     result["can.B.see.A.mutable.data?"].must_equal "from A!"
  #     result["can.B.see.A.class.data?"].must_equal nil # we don't look for it.
  #     result["can.A.see.B.mutable.data?"].must_equal "from AlmostB!"
  #   else
  #     result["can.B.see.A.mutable.data?"].must_be_nil
  #     result["can.B.see.A.class.data?"].must_be_nil
  #     result["can.A.see.B.mutable.data?"].must_be_nil
  #   end
  #   result["can.B.see.container.data?"].must_be_nil


  #   # result[:is_successful].must_equal is_successful # FIXME: this is wrong!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! key is symbol
  # end

  # def assert_b(result, is_successful:raise)
  #   # everything from A visible
  #   result["A.class.data"].       must_equal "yes"
  #   result["mutable.data.from.A"].must_equal "from A!"

  #   # B can see everything
  #   result["can.B.see.A.mutable.data?"].must_equal "from A!"
  #   result["can.B.see.current_user?"].must_be_nil
  #   result["can.B.see.params?"].must_equal({})
  #   result["can.B.see.A.class.data?"].must_equal "yes"
  #   result["can.B.see.container.data?"].must_be_nil

  #   result["can.A.see.B.mutable.data?"].must_equal "from B!"

  #   result[:is_successful].must_be_nil
  #   result.success?.must_equal true # B was successful, so A is successful.
  # end
end
