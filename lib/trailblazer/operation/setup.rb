module Trailblazer::Operation::Setup
  # TRB 1.1
  #   build_operation(params).run
  #     process(@params)
  #
  # TRB 1.2
  #   build_operation(params, *).call(params)
  # In 1.2, the possibly modified @params is not passed to #call, which SHOULD BE the correct behavior.
  def call(params)
    super(@params)
  end

  def model
    self["model"]
  end

private
  def model=(model)
    self["model"] = model
  end

  def initialize(params, options={})
    @params = params
    super
    setup!(params) # assign/find the model
  end

  def setup!(params)
    params = assign_params!(params)
    setup_params!(params)

    build_model!(params)
    result[:model] = self["model"] # this sucks and will be so much better in 2.0/trailblazer-pipetree.

    params # TODO: test me.
  end

  def assign_params!(params)
    @params = params!(params)
  end

  # Overwrite #params! if you need to change its structure, by returning a new params object
  # from this method.
  # This is helpful if you don't want to change the original via #setup_params!.
  def params!(params)
    params
  end

  def setup_params!(params)
  end

  # DISCUSS: move to Setup::Model?
  def build_model!(*args)
    assign_model!(*args) # self["model"] = ..
    setup_model!(*args)
  end

  def assign_model!(*args)
    self.model = model!(*args)
  end

  # Implement #model! to find/create your operation model (if required).
  def model!(params)
  end

  # Override to add attributes that can be inferred from params.
  def setup_model!(params)
  end
end
