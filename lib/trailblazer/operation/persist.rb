module Trailblazer::Operation::Persist
  def self.[]()
    {
      step: ->(input, options) { options["contract"].save },
      skills: {},
      operator: :&,
      name: "persist.save"
    }
  end
end
