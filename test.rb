# protected_routes = ["/logout", "/posts/:filter", "/newpost/:userid", "/post/:postid/:userid/edit", "/showprofile/:id", "/user/:id/edit",]

# p protected_routes.include?("/logout")

protected_routes = ["/logout", "/posts/*", "/newpost/:userid", "/post/:postid/:userid/edit", "/showprofile/:id", "/user/:id/edit"]
temp = "/posts/all"
p protected_routes.include?(temp)
# before do
#     p "request: #{request.path_info}"
#     # if not session[:auth] && protected_routes.include?(request.path_info)
#     #     redirect('/error/401')
#     # end
# end

# def auth(userid)
#     p "auth"
#     if session[:id] != userid
#         redirect("/error/401/")
#     end
# end

# get('/newpost/:userid') do
#     userid = params[:userid].to_i
#     auth(userid)
#     slim(:"posts/new")

# end
