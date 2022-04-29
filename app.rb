require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model/model.rb'

enable :sessions

include Model


protectedRoutes = ["/logout", "/posts/", "/newpost/", "/post/", "/showprofile/", "/user/"]

# Attempts to check if the client has authorization
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
get('/') do
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
    session[:auth] = false

    slim(:start)
end

# Displays a register form
get('/showregister') do
    session[:loginError] = false
    session[:auth] = false

    slim(:register)
end

# Displays a login form
get('/showlogin') do
    session[:registerError] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
    session[:auth] = false
    slim(:login)
end

# Displays Landing Page from logout
get('/logout') do
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
    session[:auth] = false

    slim(:start)
end

# Displays all posts according to the filter

# @param [String] :filter, the filter to filter the posts by 

# @see Model#posts
# @see Model#usernameAndId
# @see Model#likeCountTotal
# @see Model#likeCountPost
# @see Model#isLiked
get('/posts/:filter') do
    session[:notUnique] = false
    session[:empty] = false
    session[:isEmail] = true
    session[:isNumber] = true
    filter = params[:filter]

    postsAndFilter = posts(filter)

    filterList = {
        1 => "Woods",
        2 => "Sea",
        3 => "Mountains",
        4 => "Lakes",
        "all" => "All Posts"
    }

    filterId = postsAndFilter[:filterId]
    session[:filter] = filterList[filterId]

    

    usernameAndId = usernameAndId()
    session[:likeCount] = likeCountTotal(session[:id])
    likeCountPost = likeCountPost()
    isLiked = isLiked(session[:id])
    
    slim(:"posts/index", locals:{posts:postsAndFilter[:posts], usernameAndId:usernameAndId, isLiked:isLiked, likeCountPost:likeCountPost})
end


# Displays a new post form

# @param [Integer] :userid, The client ID

# @see Model#auth
# @see Model#likeCountTotal
get('/newpost/:userid') do
    userid = params[:userid].to_i

    if not auth(session[:id], userid)
        redirect("/error/401/")
    end

    session[:likeCount] = likeCountTotal(session[:id])
    slim(:"posts/new")
end

# Displays a edit post form

# @param [Integer] :userid, The client ID
# @param [Integer] :postid, The post ID

# @see Model#auth
# @see Model#likeCountTotal
# @see Model#post
get('/post/:postid/:userid/edit') do
    userid = params[:userid].to_i
    postid = params[:postid].to_i

    if not auth(session[:id], userid)
        redirect("/error/401/")
    end

    session[:likeCount] = likeCountTotal(session[:id])
    post = post(postid)

    slim(:"posts/edit", locals:{post:post})
end

# Displays a single Profile

# @param [Integer] :userid, The client ID

# @see Model#users
# @see Model#postSpecificInfo
# @see Model#usersPersonality
# @see Model#usernameAndId
# @see Model#likeCountTotal
# @see Model#likeCountPost
# @see Model#isLiked
get('/showprofile/:userid') do
    userid = params[:userid].to_i

    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true

    userInfo = users(userid)
    postSpecificInfo = postSpecificInfo(userid)
    usersPersonality = usersPersonality(userid)
    usernameAndId = usernameAndId()
    likeCountTotal = likeCountTotal(userid)
    likeCountPost = likeCountPost()
    isLiked = isLiked(session[:id])
    session[:likeCount] = likeCountTotal(session[:id])

    slim(:"users/show", locals:{userInfo:userInfo, posts:postSpecificInfo, personality:usersPersonality, likesCount:likeCountTotal, usernameAndId:usernameAndId, likeCountPost:likeCountPost, isLiked:isLiked})
end

# Displays a edit user form

# @param [Integer] :userid, The client ID

# @see Model#auth
# @see Model#likeCountTotal
# @see Model#users
get('/user/:userid/edit') do
    userid = params[:userid].to_i
    if not auth(session[:id], userid)
        redirect("/error/401/")
    end

    session[:likeCount] = likeCountTotal(session[:id])
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

# @param [String] :email, The new user email
# @param [String] :phonenumber, The new user phonenumber
# @param [String] :password, The new user password
# @param [String] :passwordConfirm, The new password confirm
# @param [Integer] :username, The new user username
# @param [Integer] :birthday, The new user birthday

# @see Model#timeChecker
# @see Model#emptyCredentials
# @see Model#uniqueCredentials
# @see Model#isEmail
# @see Model#isNumber
# @see Model#authenticationReg
# @see Model#usersByUsername
# @see Model#personalityUpdate
post('/register') do
    if session[:timeLogged] == nil
        session[:timeLogged] = 0
    end

    logTime =  timeChecker(session[:timeLogged])

    session[:timeLogged] = Time.now.to_i

    if logTime
        session[:stress] = false

        credentials = [:username, :password, :passwordConfirm, :email, :phonenumber, :birthday]
        anyEmpty = emptyCredentials(credentials)

        if anyEmpty
            session[:empty] = true
        else
            session[:empty] = false
        end

        credentials = [:username, :pwdigest, :email, :phonenumber]
        isNotUnique = uniqueCredentials(credentials)

        if isNotUnique
            session[:notUnique] = true
        else
            session[:notUnique] = false
        end
        
        if not anyEmpty and not isNotUnique

            if isEmail(params[:email])
                session[:isEmail] = true
            else
                session[:isEmail] = false
                redirect('/showregister')
            end
        
            if isNumber(params[:phonenumber])
                session[:isNumber] = true
            else
                session[:isNumber] = false
                redirect('/showregister')
            end

            if authenticationReg(params[:password], params[:passwordConfirm], params[:username], params[:email], params[:phonenumber], params[:birthday])
                user = usersByUsername(params[:username]).first
                session[:id] = user["id"]
                session[:user] = params[:username]
                session[:auth] = true
                session[:empty] = false
                session[:notUnique] = false
                personalityUpdate(session[:id])

                redirect('/posts/all')
            else
                session[:registerError] = true
                redirect('/showregister')
            end
        else
            redirect('/showregister')
        end  
    else
        session[:stress] = true
        redirect('/showregister')
    end
end

# Attempts login 

# @param [String] :username, The username
# @param [String] :password, The password

# @see Model#timeChecker
# @see Model#isEmpty
# @see Model#usersByUsername
# @see Model#authenticationLogin
post('/login') do
    if session[:timeLogged] == nil
        session[:timeLogged] = 0
    end

    logTime =  timeChecker(session[:timeLogged])
    session[:timeLogged] = Time.now.to_i

    if logTime
        session[:stress] = false

        username = params[:username]
        password = params[:password]

        if isEmpty(username) || isEmpty(password)
            session[:empty] = true
            redirect('/showlogin')
        else
            session[:empty] = false
        end

        user = usersByUsername(username).first

        if authenticationLogin(username, password, user)
            session[:loginError] = false
            id = user["id"]
            session[:id] = id
            session[:auth] = true
            session[:user] = username
            redirect('/posts/all')
        else
            session[:loginError] = true
            redirect('/showlogin')
        end
    else
        session[:stress] = true
        redirect('/showlogin')
    end
end

# Updates an existing user

# @param [Integer] :userid, The client ID
# @param [String] :email, The new user email
# @param [String] :phonenumber, The new user phonenumber

# @see Model#timeChecker
# @see Model#emptyCredentials
# @see Model#isEmail
# @see Model#isNumber
# @see Model#updateProfile
post('/user/:userid/update') do
    userid = params[:userid].to_i

    if session[:timeLogged] == nil
        session[:timeLogged] = 0
    end

    logTime =  timeChecker(session[:timeLogged])
    session[:timeLogged] = Time.now.to_i

    if logTime
        session[:stress] = false

        credentials = [:email, :phonenumber, :birthday]
        anyEmpty = emptyCredentials(credentials)

        if anyEmpty
            session[:empty] = true
        else
            session[:empty] = false
        end

        if isEmail(params[:email])
            session[:isEmail] = true
        else
            session[:isEmail] = false
            route = "/user/#{userid}/edit"
            redirect(route)
        end

        if isNumber(params[:phonenumber])
            session[:isNumber] = true
        else
            session[:isNumber] = false
            route = "/user/#{userid}/edit"
            redirect(route)
        end

        if updateProfile(userid, credentials)
            session[:notUnique] = false
            route = "/showprofile/#{userid}"
            redirect(route)
        else
            session[:notUnique] = true
            route = "/user/#{userid}/edit"
            redirect(route)
        end

    else
        session[:stress] = true
        route = "/user/#{userid}/edit"
        redirect(route)
    end
end

# Creates a new article

# @param [String] :title, The post title
# @param [String] :text, The post text

# @see Model#timeChecker
# @see Model#isEmpty
# @see Model#postNew
post('/post/new') do
    id = session[:id]

    if session[:timeLogged] == nil
        session[:timeLogged] = 0
    end

    logTime =  timeChecker(session[:timeLogged])
    session[:timeLogged] = Time.now.to_i

    if logTime
        session[:stress] = false

        title = params[:title]
        text = params[:text]

        if not isEmpty(title)
            session[:empty] = false

            if postNew(title, text, id)
                session[:notUnique] = false
                redirect('/posts/all')
            else
                session[:notUnique] = true
                route = "/newpost/#{id}"
                redirect(route)
            end
        else
            session[:empty] = true
            route = "/newpost/#{id}"
            redirect(route)
        end
    else
        session[:stress] = true
        route = "/newpost/#{id}"
        redirect(route)
    end
end

# Updates an existing post

# @param [Integer] :postid, The post ID
# @param [String] :title, The new post title

# @see Model#timeChecker
# @see Model#isEmpty
# @see Model#postUpdate
post('/post/:id/update') do
    userid = session[:id]
    postid = params[:id].to_i

    if session[:timeLogged] == nil
        session[:timeLogged] = 0
    end

    logTime =  timeChecker(session[:timeLogged])
    session[:timeLogged] = Time.now.to_i

    if logTime
        session[:stress] = false

        title = params[:title]

        if not isEmpty(title)
            session[:empty] = false

            if postUpdate(title, postid, userid)
                session[:notUnique] = false
                redirect('/posts/all')
            else
                session[:notUnique] = true
                route = "/post/#{postid}/#{userid}/edit"
                redirect(route)
            end
        else
            route = "/post/#{postid}/#{userid}/edit"
            redirect(route)
            session[:empty] = true
        end 
    else
        session[:stress] = true
        route = "/post/#{postid}/#{userid}/edit"
        redirect(route)
    end
end

# Deletes an existing article

# @param [Integer] :userid, The client ID
# @param [String] :postid, The post ID

# @see Model#auth
# @see Model#postDelete
post('/post/:postid/:userid/delete') do
    userid = params[:userid].to_i
    postid = params[:postid].to_i

    if not auth(session[:id], userid)
        redirect("/error/401/")
    end

    postDelete(postid)
    redirect('/posts/all')
end

# Likes a post

# @param [Integer] :userid, The client ID
# @param [String] :postid, The post ID

# @see Model#auth
# @see Model#insertLike
# @see Model#filterRoute
post('/post/:postid/:userid/like') do
    userid = params[:userid].to_i
    if not auth(session[:id], userid)
        redirect("/error/401/")
    end

    postid = params[:postid].to_i
    insertLike(userid, postid)
    filterId = filterRoute(session[:filter])

    filterList = {
        1 => "Woods",
        2 => "Sea",
        3 => "Mountains",
        4 => "Lakes",
        "all" => "All Posts"
    }

    filter = filterList[filterId]
    session[:filter] = filter
    if filterId == 1
        redirect('/posts/woods')
    elsif filterId == 2
        redirect('/posts/sea')
    elsif filterId == 3
        redirect('/posts/mountains')
    elsif filterId == 4
        redirect('/posts/lakes')
    elsif filterId == "all"
        redirect('/posts/all')
    end
end

# Unlikes a post

# @param [Integer] :userid, The client ID
# @param [String] :postid, The post ID

# @see Model#auth
# @see Model#deleteLike
# @see Model#filterRoute
post('/post/:postid/:userid/unlike') do
    userid = params[:userid].to_i
    if not auth(session[:id], userid)
        redirect("/error/401/")
    end

    postid = params[:postid].to_i
    deleteLike(userid, postid)
    filterId = filterRoute(session[:filter])

    filterList = {
        1 => "Woods",
        2 => "Sea",
        3 => "Mountains",
        4 => "Lakes",
        "all" => "All Posts"
    }

    filter = filterList[filterId]
    session[:filter] = filter
    if filterId == 1
        redirect('/posts/woods')
    elsif filterId == 2
        redirect('/posts/sea')
    elsif filterId == 3
        redirect('/posts/mountains')
    elsif filterId == 4
        redirect('/posts/lakes')
    elsif filterId == "all"
        redirect('/posts/all')
    end
end