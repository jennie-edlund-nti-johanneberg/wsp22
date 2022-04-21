require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model'

enable :sessions

#Before functions
# protected_routes = ["/logout", "/posts/:filter", "/newpost/:userid", "/post/:postid/:userid/edit", "/showprofile/:id", "/user/:id/edit"]
unProtectedRoutes = ['/', '/showregister', '/showlogin']

before do
    path = request.path_info
    pathInclude = unProtectedRoutes.include?(path)
    pathMethod = request.request_method


    if not pathInclude and not session[:auth] and path != "/error/401" and pathMethod == "GET"
        redirect("/error/401")
    end
end


# GET route
get('/') do
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
    session[:timeLogged] = 0
    session[:auth] = false
    slim(:start)
end

get('/showregister') do
    session[:loginError] = false
    session[:auth] = false
    slim(:register)
end

get('/showlogin') do
    session[:notUnique] = false
    session[:registerError] = false
    session[:isEmail] = true
    session[:isNumber] = true
    session[:auth] = false
    slim(:login)
end

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

get('/posts/:filter') do
    session[:notUnique] = false
    session[:empty] = false
    session[:isEmail] = true
    session[:isNumber] = true
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
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
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

# get('/*') do
#     redirect('/error/404')
# end

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

        if not anyEmpty and not isNotUnique

            if not isEmail(params[:email])
                redirect('/showregister')
            end
        
            if not isNumber(params[:phonenumber])
                redirect('/showregister')
            end

            if registration(params[:password], params[:passwordConfirm], params[:username], params[:email], params[:phonenumber], params[:birthday])
                

                db = db_called("db/database.db")
                begin
                    woods = params[:woods]
                    if woods == "woods"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 1)
                    end  
                end

                begin
                    sea = params[:sea]
                    if sea == "sea"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 2)
                    end
                end

                begin
                    mountains = params[:mountains]
                    if mountains == "mountains"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 3)
                    end
                end

                begin
                    lakes = params[:lakes]
                    if lakes == "lakes"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 4)
                    end 
                end

                redirect('/posts/all')
            end
        else
            redirect('/showregister')
        end  
    else
        redirect('/showregister')
    end
end

post('/login') do
    if logTime()
        username = params[:username]
        password = params[:password]

        if isEmpty(username) || isEmpty(password)
            redirect('/showlogin')
        end

        login(username, password)
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

        if not anyEmpty
            isNotUnique = false
            credentials[0..credentials.length - 2].each do |credential|
                uniqueUserUpdate(credential.to_s, params[credential], userid)
            end

            if not isNotUnique 
                birthday = params[:birthday]
                updateBirthday(birthday, userid)
                deletePersonalityUser(userid)

                db = db_called("db/database.db")
                begin
                    woods = params[:woods]
                    if woods == "woods"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 1)
                    end  
                end
        
                begin
                    sea = params[:sea]
                    if sea == "sea"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 2)
                    end
                end
        
                begin
                    mountains = params[:mountains]
                    if mountains == "mountains"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 3)
                    end
                end
        
                begin
                    lakes = params[:lakes]
                    if lakes == "lakes"
                        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 4)
                    end 
                end
                
                session[:notUnique] = false
                route = "/showprofile/#{userid}"
                redirect(route)
            else
                route = "/user/#{userid}/edit"
                redirect(route)
            end
        else
            route = "/user/#{userid}/edit"
            redirect(route)
        end
    else
        route = "/user/#{userid}/edit"
        redirect(route)
    end
end

post('/post/new') do
    id = session[:id]
    title = params[:title]
    text = params[:text]

    postNew(title, text)
end

post('/post/:id/update') do
    title = params[:title]
    postid = params[:id].to_i
    userid = session[:id]

    postUpdate(title, postid, userid)
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