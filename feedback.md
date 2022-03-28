Good job working through the Facade/Service/PORO design pattern on this project. There is some room for refactoring, but overall each class is handling the responsibilities I'd expect.
I left some comments with specific ideas for refactoring and troubleshooting.
A couple of more general thoughts:

In the future, if VCR adds too much build time or complexity, you could consider Webmock on its own for stubbing test responses.
I left a comment about this with an example: typically with this design pattern, class methods are preferred for Facades and Services.

We probably don't want launchy in the 'development only' group.

app/controllers/users_controller.rb
      redirect_to "/"
    else
      redirect_to "/register"
      flash[:alert] = "Error: Email already registered"
 
@jamisonordway jamisonordway 1 hour ago
What if @user can't be saved due to a different error, for example, a blank field?
I would probably rely on the @user.errors object to populate a dynamic error message here.

app/facades/movie_facade.rb
    response.map do |data|
      Movie.new(data)
    end.take(40)
 
@jamisonordway jamisonordway 1 hour ago
Instead of creating an indefinite amount of Movie objects and then grabbing 40 of those, it might be more efficient to limit the amount of iterations:

response.first(40).map do |data|
...etc

app/services/movie_service.rb
# require 'faraday'
# require 'json'
 
@jamisonordway jamisonordway 1 hour ago
These lines shouldn't be necessary in Rails.

app/views/user_movies/discover.html.erb
@@ -0,0 +1,7 @@
<%= button_to "Discover Top Rated Movies",  "movies?q=top%20rated", method: :get%>
<%= form_with url: "/users/#{@user.id}/movies?q=keyword", method: :get, local: true do |form| %>
 
@jamisonordway jamisonordway 1 hour ago
It looks like you're hard-coding in a query param here, which sheds some light on the keyword search implementation bug. The keyword that we're sending to the API (/movies?q=<some keyword) should be the user input. We would get that value through the form fields, which means it doesn't need to be interpolated on this line.

<%= form_with url: "/users/#{@user.id}/movies", method: :get, local: true do |form| %>

  <%= form.label :keyword, "Keywords" %>
  <%= form.text_field :keyword %>
  <%= form.submit "Search Movie by Title" %>
<% end %>

config/routes.rb

  resources :users, only: [:create, :show]

  get '/users/:id/discover', to: 'user_movies#discover'
 
@jamisonordway jamisonordway 1 hour ago
Some less-than-restful routing is expected on this project. I think these custom actions are a fine approach, especially if the goal is to have the same action handle both top_rated and the keyword search.

spec/features/user_movies/discover_spec.rb
    fill_in :keywords, with: "Shawsha"
    click_button("Search Movie by Title")
    expect(current_path).to eq("/users/#{@user1.id}/movies")
  end
 
@jamisonordway jamisonordway 1 hour ago
This would be a good place for a sad path test. What happens if the user doesn't fill in the keyword field? What if they search for the string 'Top Rated'? What if they search for the string "asdfasdfasdfasdfasdfasdf"?


spec/features/users/create_spec.rb
      expect(page).to have_content("Error: Email already registered")
      expect(current_path).to eq('/register')
    end
  end
 
@jamisonordway jamisonordway 1 hour ago
Again, regarding sad path testing, what if the user doesn't fill out the required fields?

app/controllers/user_movies_controller.rb
    facade = MovieFacade.new
    @movies = facade.find_top_rated_movies
 
@jamisonordway jamisonordway 1 hour ago
You mentioned this in your presentation; by making find_top_rated_movies a class method, we could cut down on instantiated object and lines of code.

@movies = MovieFacade.find_top_rated_movies

app/facades/movie_facade.rb
    response = MovieService.cast_members(movie_id)

    response.map do |data|
      CastMember.new
    end.take(10)
 
@jamisonordway jamisonordway 1 hour ago
If the MovieService.cast_members method took another argument, we could make the amount of cast members returned more dynamic and more efficient. With a default argument, we could return 10 of them by default but still have the ability to pass a different limit if needed.

response = MovieService.cast_members(movie_id, limit = 10)
This would eliminate the need to create lots of new cast members and then take 10 of them on line 24.