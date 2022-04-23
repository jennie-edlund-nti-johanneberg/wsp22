require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model'

enable :sessions

#Before functions
protectedRoutes = ["/logout", "/posts/", "/newpost/", "/post/", "/showprofile/", "/user/"]

# unProtectedRoutes = ['/', '/showregister', '/showlogin']

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

# GET route
get('/') do
    resetStart()

    slim(:start)
end

get('/showregister') do
    restartReg()

    slim(:register)
end

get('/showlogin') do
    restartLogin()
    slim(:login)
end

get('/logout') do
    resetStart()
    slim(:start)
end

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

get('/newpost/:userid') do
    userid = params[:userid].to_i
    auth(userid)
    likeCountClient(session[:id])
    slim(:"posts/new")
end

get('/post/:postid/:userid/edit') do
    userid = params[:userid].to_i
    auth(userid)

    likeCountClient(session[:id])
    postid = params[:postid].to_i
    post = post(postid)

    slim(:"posts/edit", locals:{post:post})
end

get('/showprofile/:userid') do
    restartProfil()
    userid = params[:userid].to_i

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

get('/user/:userid/edit') do
    userid = params[:userid].to_i
    auth(userid)

    likeCountClient(session[:id])
    user = users(userid).first
    slim(:"users/edit", locals:{user:user})
end

get('/error/:id') do
    errors = {
        401 => "Not authorized",
        404 => "Page not found"
    }

    errorId = params[:id].to_i
    errorMsg = errors[errorId]

    slim(:error, locals: {errorId:errorId, errorMsg:errorMsg})
end

not_found do
    redirect("/error/404")
end

# POST called
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

post('/login') do
    if logTime()
        username = params[:username]
        password = params[:password]

        if isEmpty(username) || isEmpty(password)
            p "was empty"
            redirect('/showlogin')
        end

        authenticationLogin(username, password)
    else
        redirect('/showlogin')
    end
end

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

post('/post/:postid/:userid/delete') do
    userid = params[:userid].to_i
    postid = params[:postid].to_i

    postDelete(userid, postid)
end

post('/post/:postid/:userid/like') do
    userid = params[:userid].to_i
    auth(userid)

    postid = params[:postid].to_i
    insertLike(userid, postid)
    filterRoute()
end

post('/post/:postid/:userid/unlike') do
    userid = params[:userid].to_i
    auth(userid)

    postid = params[:postid].to_i
    deleteLike(userid, postid)
    filterRoute()
end