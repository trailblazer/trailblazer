class UserCell < Cell::Rails
  include Kaminari::Cells

  def show(users)
    @users = users

    render inline: <<-ERB
<%= paginate @users %>
ERB
  end
end

class ViewModelCell < Cell::ViewModel
  include Kaminari::Cells

  def show
    render inline: <<-ERB
<%= paginate model %>
ERB
  end
end