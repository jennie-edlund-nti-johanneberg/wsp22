require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model/model.rb'

enable :sessions

include Model

#Before functions
protectedRoutes = ["/logout", "/posts/", "/newpost/", "/post/", "/showprofile/", "/user/"]

before do
    path = request.path_info
    fixedPath = path.scan(/\w+/).first
    pathMethod = request.request_method

    answer = []
    protectedRoutes.each do |route|
        answer << route.scan(/\w+/).first
    end

    pathInclude = answer.include?(fixedPath)

    if pathInclude and not session[:auth] and path != "/error/401" and pathMethod == "GET"
        redirect("/error/401")

    end
end

# Display Landing Page

# @see Model#resetStart
get('/') do
    resetStart()

    slim(:start)
end

# Displays a register form

# @see Model#restartReg
get('/showregister') do
    restartReg()

    slim(:register)
end

# Displays a login form

# @see Model#restartLogin
get('/showlogin') do
    restartLogin()
    slim(:login)
end

# Displays Landing Page from logout

# @see Model#resetStart
get('/logout') do
    resetStart()
    slim(:start)
end

# Displays all posts according to the filter

# @param [String] :filter, the filter to filter the posts by 

# @see Model#restartPosts
# @see Model#posts
# @see Model#usernameAndId
# @see Model#likeCountClient
# @see Model#likeCountPost
# @see Model#isLiked
get('/posts/:filter') do
    restartPosts()
    filter = params[:filter]

    posts = posts(filter)
    usernameAndId = usernameAndId()
    likeCountClient(session[:id])
    likeCountPost = likeCountPost()
    isLiked = isLiked()
    
    slim(:"posts/index", locals:{posts:posts, usernameAndId:usernameAndId, isLiked:isLiked, likeCountPost:likeCountPost})
end


# Displays a new post form

# @param [Integer] :userid, The client ID

# @see Model#auth
# @see Model#likeCountClient
get('/newpost/:userid') do
    userid = params[:userid].to_i
    auth(userid)
    likeCountClient(session[:id])
    slim(:"posts/new")
end

# Displays a edit post form

# @param [Integer] :userid, The client ID
# @param [Integer] :postid, The ID of the post

# @see Model#auth
# @see Model#likeCountClient
# @see Model#post
get('/post/:postid/:userid/edit') do
    userid = params[:userid].to_i
    postid = params[:postid].to_i

    auth(userid)
    likeCountClient(session[:id])
    post = post(postid)

    slim(:"posts/edit", locals:{post:post})
end

#Displays a single Profile

# @param [Integer] :userid, The client ID

# @see Model#restartProfil
# @see Model#users
# @see Model#postSpecificInfo
# @see Model#usersPersonality
# @see Model#usernameAndId
# @see Model#likeCountTotal
# @see Model#likeCountPost
# @see Model#isLiked
# @see Model#likeCountClient
get('/showprofile/:userid') do
    userid = params[:userid].to_i

    restartProfil()
    userInfo = users(userid)
    postSpecificInfo = postSpecificInfo(userid)
    usersPersonality = usersPersonality(userid)
    usernameAndId = usernameAndId()
    likeCountTotal = likeCountTotal(userid)
    likeCountPost = likeCountPost()
    isLiked = isLiked()
    likeCountClient(session[:id])

    slim(:"users/show", locals:{userInfo:userInfo, posts:postSpecificInfo, personality:usersPersonality, likesCount:likeCountTotal, usernameAndId:usernameAndId, likeCountPost:likeCountPost, isLiked:isLiked})
end

# Displays a edit user form

# @param [Integer] :userid, The client ID

# @see Model#auth
# @see Model#likeCountClient
# @see Model#users
get('/user/:userid/edit') do
    userid = params[:userid].to_i

    auth(userid)
    likeCountClient(session[:id])
    user = users(userid).first

    slim(:"users/edit", locals:{user:user})
end

# Displays an error message

# @param [Integer] :id, The ID of the error
get('/error/:id') do
    errors = {
        401 => "Not authorized",
        404 => "Page not found"
    }

    errorId = params[:id].to_i
    errorMsg = errors[errorId]

    slim(:error, locals: {errorId:errorId, errorMsg:errorMsg})
end

# Catches not found routes and redirects to '/error/:id'
not_found do
    redirect("/error/404")
end

# Attempts register 

# @see Model#logTime
# @see Model#emptyCredentials
# @see Model#uniqueCredentials
# @see Model#registration
post('/register') do
    if logTime()
        credentials = [:username, :password, :passwordConfirm, :email, :phonenumber, :birthday]
        anyEmpty = emptyCredentials(credentials)

        credentials = [:username, :pwdigest, :email, :phonenumber]
        isNotUnique = uniqueCredentials(credentials)

        registration(anyEmpty, isNotUnique)
    else
        redirect('/showregister')
    end
end

# Attempts login 

# @param [String] :username, The username
# @param [String] :password, The password

# @see Model#logTime
# @see Model#isEmpty
# @see Model#authenticationLogin
post('/login') do
    if logTime()
        username = params[:username]
        password = params[:password]

        if isEmpty(username) || isEmpty(password)
            redirect('/showlogin')
        end

        authenticationLogin(username, password)
    else
        redirect('/showlogin')
    end
end

# Updates an existing user

# @param [Integer] :userid, The client ID
# @param [String] :email, The new user email
# @param [String] :phonenumber, The new user phonenumber

# @see Model#logTime
# @see Model#emptyCredentials
# @see Model#isEmail
# @see Model#isNumber
# @see Model#upadteProfil
post('/user/:userid/update') do
    userid = params[:userid].to_i
    if logTime()
        credentials = [:email, :phonenumber, :birthday]
        anyEmpty = emptyCredentials(credentials)

        if not isEmail(params[:email])
            route = "/user/#{userid}/edit"
            redirect(route)
        end

        if not isNumber(params[:phonenumber])
            route = "/user/#{userid}/edit"
            redirect(route)
        end

        upadteProfil(userid, anyEmpty, credentials)

    else
        route = "/user/#{userid}/edit"
        redirect(route)
    end
end

# Creates a new article

# @param [String] :title, The title of the post
# @param [String] :text, The text of the post

# @see Model#logTime
# @see Model#postNew
post('/post/new') do
    id = session[:id]
    if logTime()
        title = params[:title]
        text = params[:text]

        postNew(title, text, id)
    else
        route = "/newpost/#{id}"
        redirect(route)
    end
end

# Updates an existing post

# @param [Integer] :postid, The ID of the post
# @param [String] :title, The new title of the post

# @see Model#logTime
# @see Model#postUpdate
post('/post/:id/update') do
    userid = session[:id]
    postid = params[:id].to_i
    if logTime()
        title = params[:title]
        postUpdate(title, postid, userid)
    else
        route = "/post/#{postid}/#{userid}/edit"
        redirect(route)
    end
end

# Deletes an existing article

# @param [Integer] :userid, The client ID
# @param [String] :postid, The ID of the post

# @see Model#postDelete
post('/post/:postid/:userid/delete') do
    userid = params[:userid].to_i
    postid = params[:postid].to_i

    postDelete(userid, postid)
end

# Likes a post

# @param [Integer] :userid, The client ID
# @param [String] :postid, The ID of the post

# @see Model#auth
# @see Model#insertLike
# @see Model#filterRoute
post('/post/:postid/:userid/like') do
    userid = params[:userid].to_i
    auth(userid)

    postid = params[:postid].to_i
    insertLike(userid, postid)
    filterRoute()
end

# Unlikes a post

# @param [Integer] :userid, The client ID
# @param [String] :postid, The ID of the post

# @see Model#auth
# @see Model#deleteLike
# @see Model#filterRoute
post('/post/:postid/:userid/unlike') do
    userid = params[:userid].to_i
    auth(userid)

    postid = params[:postid].to_i
    deleteLike(userid, postid)
    filterRoute()
end