require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model'

enable :sessions

#Before functions

# Before

# end

#Database called
def db_called(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

#Verification
def isUnique(db, table, attribute, check)
    query = "SELECT * FROM #{table} WHERE #{attribute} = ?"
    result = db.execute(query, check)
    if result.length == 0
        session[:notUnique] = false
        return true
    else
        session[:notUnique] = true
        return false
    end
end

def uniqueCredentials(credentials)
    db = db_called("db/database.db")

    isNotUnique = false
    credentials.each do |credential|
        isNotUnique = isNotUnique || !isUnique(db, "users", credential.to_s, params[credential])
    end
    return isNotUnique
end

def uniqueUserUpdate(credential, calledCredential, id)
    db = db_called("db/database.db")
    attribute = attributeSpecifikUsers(credential)

    if isUnique(db, "users", credential, calledCredential)
        db.execute("UPDATE users SET #{credential} = ? WHERE id = ?", calledCredential, id)

    elsif attribute[credential].to_s == calledCredential   
        isNotUnique = false
    else
        isNotUnique = true
    end
    return isNotUnique
end

def isEmpty(text)
    if text == ""
        session[:empty] = true
        return true
    else
        session[:empty] = false
        return false
    end
end

def emptyCredentials(credentials)
    anyEmpty = false
    credentials.each do |credential|
        anyEmpty = anyEmpty || isEmpty(params[credential])
    end
    return anyEmpty
end

def isEmail(text)
    if text.include?('@') && text.include?('.')
        session[:isEmail] = true
        return true
    else
        session[:isEmail] = false
        return false
    end
end

def isNumber(number)
    answer = number.scan(/\D/).empty?

    if answer
        session[:isNumber] = true
        return true
    else
        session[:isNumber] = false
        return false
    end
end

def logTime(id)
    tempTime = Time.now.to_i
    if session[:timeLogged] == nil
        session[:timeLogged] = 0
    end
    # p tempTime
    # p session[:timeLogged]
    tempTime = tempTime - session[:timeLogged]

    # p tempTime

    if tempTime < 3
        session[:timeLogged] = tempTime
        session[:stress] = true
        return false
    else
        session[:timeLogged] = tempTime
        session[:stress] = false
        return true
    end
end

def passwordMatch(pw1, pw2)
    if pw1 == pw2
        return true
    else
        return false
    end
end

# def personalityTest()

    

# end

def registration(password, passConfirm, username, email, phonenumber, birthday)

    if passwordMatch(password, passConfirm)
        passwordDigest = BCrypt::Password.create(password)
        db = db_called("db/database.db")
        db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, email, phonenumber, birthday).first

        # result = db.execute("SELECT * FROM users WHERE username = ?", username).first
        user = usersByUsername(username).first
        # p "user: #{user}"
        session[:id] = user["id"]
        session[:user] = username
        session[:auth] = true
        session[:empty] = false
        session[:notUnique] = false
        return true
    else
        session[:registerError] = true
        redirect('/showregister')
    end
end

def login(username, password)
    db = db_called("db/database.db")
    user = usersByUsername(username).first

    begin
        pwdigest = user["pwdigest"]
        id = user["id"]
    
        if BCrypt::Password.new(pwdigest) == password
            session[:loginError] = false
            session[:id] = id
            session[:auth] = true
            session[:user] = username
            redirect('/posts/all')
            
        else
            #WRONG PASSWORD
            session[:loginError] = true
            redirect('/showlogin')
        end
        
    rescue => exception
        #INVALID USERNAME
        session[:loginError] = true
        redirect('/showlogin')
    end
end

#Functions
def attributeSpecifikUsers(credential)
    db = db_called("db/database.db")
    return db.execute("SELECT #{credential} FROM users WHERE id = ?", session[:id]).first
end

# def updateAttributeUsers(credential, attribute, id)
#     db = db_called("db/database.db")
#     db.execute("UPDATE users SET #{credential} = ? WHERE id = ?", params[credential], id)
# end

def filter(filter)
    if filter == "woods"
        session[:filter] = "Woods"
        return 1
    elsif filter == "sea"
        session[:filter] = "Sea"
        return 2
    elsif filter == "mountains"
        session[:filter] = "Mountains"
        return 3
    elsif filter == "lakes"
        session[:filter] = "Lakes"
        return 4
    else
        session[:filter] = "All Posts"
        return "all"
    end
end

def filterRoute()
    if session[:filter] == "Lakes"
        redirect('/posts/lakes')
    elsif session[:filter] == "Woods"
        redirect('/posts/woods')
    elsif session[:filter] == "Sea"
        redirect('/posts/sea')
    elsif session[:filter] == "Mountains"
        redirect('/posts/mountains')
    else
        redirect('/posts/all')
    end
end

def insertLike(userid, postid)
    db = db_called("db/database.db")
    db.execute("INSERT INTO likes (userid,postid) VALUES (?,?)", userid, postid)
end

def deleteLike(userid, postid)
    db = db_called("db/database.db")
    db.execute("DELETE FROM likes WHERE postid = ? AND userid = ?", postid, userid)
end

def posts(filter)
    db = db_called("db/database.db")
    filterId = filter(filter)

    if filterId == "all"
        session[:filter] = "All Posts"
        return db.execute("SELECT * FROM posts")
    else
        return db.execute("SELECT * FROM posts WHERE creatorid IN (
            SELECT DISTINCT
                user_personality_relation.userid
            FROM user_personality_relation
                INNER JOIN category ON user_personality_relation.categoryid = ?)", filterId)
    end
end

def post(id)
    db = db_called("db/database.db")
    return db.execute("SELECT * FROM posts WHERE id = ?", id).first
end

def postSpecificInfo(id)
    db = db_called("db/database.db")

    return db.execute("SELECT
        posts.id,
        posts.title,
        posts.text,
        posts.creatorid,
        posts.time
    FROM posts
        INNER JOIN users ON users.id = posts.creatorid
    WHERE users.id = ?", id)
end

def postNew(title, text)
    if not isEmpty(title)
        db = db_called("db/database.db")
        if isUnique(db, "posts", "title", title)
            t = Time.now
            time = t.strftime("%Y-%m-%d %H:%M")
            db.execute("INSERT INTO posts (title, text, creatorid, time) VALUES (?,?,?,?)", title, text, session[:id], time)
            redirect('/posts/all')
        else
            route = "/newpost/#{id}"
            redirect(route)
        end
    else
        route = "/newpost/#{id}"
        redirect(route)
    end

end

def postUpdate(title, postid, userid)
    if not isEmpty(title)
        anyEmpty = false
    else
        anyEmpty = true
    end 

    if not anyEmpty
        db = db_called("db/database.db")
        result = db.execute("SELECT title FROM posts WHERE creatorid = ? AND id = ?", userid, postid).first

        text = params[:text]

        if isUnique(db, "posts", "title", title)
            # p "text till pots:#{text}"
            db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
            redirect('/posts/all')
        elsif result['title'] == title 
            db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
            redirect('/posts/all')
        else
            route = "/post/#{postid}/#{userid}/edit"
            redirect(route)
        end

    else
        route = "/post/#{postid}/#{userid}/edit"
        redirect(route)
    end

end

def postDelete(userid, postid)
    if userid == session[:id]
        db = db_called("db/database.db")
        db.execute("DELETE FROM posts WHERE id = ?", postid)
        db.execute("DELETE FROM likes WHERE postid = ?", postid)
        redirect('/posts/all')
    else
        redirect('/error/401')
    end

end

def users(id)
    db = db_called("db/database.db")
    return db.execute("SELECT * FROM users WHERE id = ?", id)
end

def usersByUsername(username)
    db = db_called("db/database.db")
    return db.execute("SELECT * FROM users WHERE username = ?", username)
end

def usernameAndId()
    db = db_called("db/database.db")
    return db.execute("SELECT username, id FROM users")
end

def usersPersonality(id)
    db = db_called("db/database.db")

    return db.execute("SELECT
        category.personality
    FROM category
        INNER JOIN user_personality_relation ON  category.id = user_personality_relation.categoryid
    WHERE user_personality_relation.userid = ?", id)
end

def likeCountClient(id)
    db = db_called("db/database.db")
    db.results_as_hash = false

    session[:likeCount] = db.execute("SELECT COUNT
        (likes.postid)
    FROM likes
        INNER JOIN posts ON posts.id = likes.postid
    WHERE creatorid = ?", id).first.first
end

def likeCountTotal(id)
    db = db_called("db/database.db")
    db.results_as_hash = false

    return db.execute("SELECT COUNT
        (likes.postid)
    FROM likes
        INNER JOIN posts ON posts.id = likes.postid
    WHERE creatorid = ?", id).first.first
end

def likeCountPost()
    db = db_called("db/database.db")
    db.results_as_hash = false

    return db.execute("SELECT postid FROM likes")
end

def isLiked()
    db = db_called("db/database.db")
    db.results_as_hash = false

    isLikeArr = db.execute("SELECT postid FROM likes WHERE userid = ?", session[:id])
    tempArr = isLikeArr.map do |el|
        el = el.first
    end

    return tempArr
end

def updateBirthday(birthday, id)
    db = db_called("db/database.db")
    return db.execute("UPDATE users SET birthday = ? WHERE id = ?", birthday, id)
end

def deletePersonalityUser(id)
    db = db_called("db/database.db")
    return db.execute("DELETE FROM user_personality_relation WHERE userid = ?", id)
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
    slim(:start)
end

get('/showregister') do
    session[:loginError] = false
    slim(:register)
end

get('/showlogin') do
    session[:notUnique] = false
    session[:registerError] = false
    session[:isEmail] = true
    session[:isNumber] = true
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
    id = session[:id]
    filter = params[:filter]

    # filterid = filter(filter)

    # if filter == "woods"
    #     session[:filter] = "Woods"
    #     filterid = 1
    # elsif filter == "sea"
    #     session[:filter] = "Sea"
    #     filterid = 2
    # elsif filter == "mountains"
    #     session[:filter] = "Mountains"
    #     filterid = 3
    # else
    #     session[:filter] = "Lakes"
    #     filterid = 4
    # end

    # db = db_called("db/database.db")

    # if filter == "all"
    #     session[:filter] = "All Posts"
    #     posts = db.execute("SELECT * FROM posts")
    # else
    #     posts = db.execute("SELECT * FROM posts WHERE creatorid IN (
    #         SELECT DISTINCT
    #             user_personality_relation.userid
    #         FROM user_personality_relation
    #             INNER JOIN category ON user_personality_relation.categoryid = ?)", filterid)
    # end

    posts = posts(filter)

    usernameAndId = usernameAndId()
    # ("SELECT DISTINCT
    #     users.username,
    #     posts.creatorid
    # FROM users
    #     INNER JOIN posts ON users.id = posts.creatorid")

    # db.results_as_hash = false
    likeCountClient(id)

    # session[:likeCount] = db.execute("SELECT COUNT
    #         (likes.postid)
    #     FROM likes
    #         INNER JOIN posts ON posts.id = likes.postid
    #     WHERE creatorid = ?", id).first.first



    likeCountPost = likeCountPost()
    isLiked = isLiked()
    # likeArr = db.execute("SELECT postid FROM likes WHERE userid = ?", session[:id])
    # newArr = likeArr.map do |el|
    #     el = el.first
    # end
    
    slim(:"posts/index", locals:{posts:posts, usernameAndId:usernameAndId, isLiked:isLiked, likeCountPost:likeCountPost})
end

get('/newpost/:id') do
    id = params[:id].to_i
    if session[:id] == id
        slim(:"posts/new")
    else
        redirect('/error/401')
    end
end

get('/post/:postid/:userid/edit') do
    userid = params[:userid].to_i
    if session[:id] == userid
        postid = params[:postid].to_i
        post = post(postid)
        # db = db_called("db/database.db")
        # result = db.execute("SELECT * FROM posts WHERE id = ?", postid).first
        slim(:"posts/edit", locals:{post:post})
    else
        redirect('/error/401')
    end
end

get('/showprofile/:id') do
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
    id = params[:id].to_i

    # db = db_called("db/database.db")
    # result = db.execute("SELECT * FROM users WHERE id = ?", id)

    userInfo = users(id)

    postSpecificInfo = postSpecificInfo(id)

    # result_2 = db.execute("SELECT
    #         posts.id,
    #         posts.title,
    #         posts.text,
    #         posts.creatorid,
    #         posts.time
    #     FROM posts
    #         INNER JOIN users ON users.id = posts.creatorid
    #     WHERE users.id = ?", id)

    # p db.execute("SELECT
    #     posts.id,
    #     posts.title,
    #     posts.text,
    #     posts.creatorid,
    #     posts.time
    # FROM posts
    #     INNER JOIN users ON users.id = posts.creatorid
    # WHERE users.id = ?", id)

    # p db.execute("SELECT
    #     posts.id,
    #     posts.title,
    #     posts.text,
    #     posts.creatorid,
    #     posts.time
    # FROM posts
    #     INNER JOIN users ON users.id = posts.creatorid
    # WHERE users.id = ?", id)

    # result_3 = db.execute("SELECT
    #         category.personality
    #     FROM category
    #         INNER JOIN user_personality_relation ON  category.id = user_personality_relation.categoryid
    #     WHERE user_personality_relation.userid = ?", id)

    usersPersonality = usersPersonality(id)

    # creatorid = db.execute("SELECT DISTINCT
    #     users.username,
    #     posts.creatorid
    # FROM users
    #     INNER JOIN posts ON users.id = posts.creatorid")

    usernameAndId = usernameAndId()

    # db.results_as_hash = false
    # likeCountTotal = db.execute("SELECT COUNT
    #     (likes.postid)
    # FROM likes
    #     INNER JOIN posts ON posts.id = likes.postid
    # WHERE creatorid = ?", id).first.first

    likeCountTotal = likeCountTotal(id)

    likeCountPost = likeCountPost()

    isLiked = isLiked()

    slim(:"users/show", locals:{userInfo:userInfo, posts:postSpecificInfo, personality:usersPersonality, likesCount:likeCountTotal, usernameAndId:usernameAndId, likeCountPost:likeCountPost, isLiked:isLiked})
end

get('/user/:id/edit') do
    id = params[:id].to_i
    if session[:id] == id
        # db = db_called("db/database.db")
        # result = db.execute("SELECT * FROM users WHERE id = ?", id).first
        user = users(id).first
        # p ""
        # p result
        # p ""
        # checked = db.execute("SELECT categoryid FROM user_personality_relation WHERE userid = ?", id)
        slim(:"users/edit", locals:{user:user})
    else
        redirect('/error/401')
    end
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

get('/*') do
    redirect('/error/404')
end

# POST called

post('/register') do
    # db = db_called("db/database.db")
    credentials = [:username, :password, :passwordConfirm, :email, :phonenumber, :birthday]

    anyEmpty = emptyCredentials(credentials)
    # anyEmpty = false
    # credentials.each do |credential|
    #     anyEmpty = anyEmpty || isEmpty(params[credential])
    # end

    

    credentials = [:username, :pwdigest, :email, :phonenumber]

    # isNotUnique = false
    # credentials.each do |credential|
    #     isNotUnique = isNotUnique || !isUnique(db, "users", credential.to_s, params[credential])
    # end

    isNotUnique = uniqueCredentials(credentials)

    if not anyEmpty and not isNotUnique

        if not isEmail(params[:email])
            redirect('/showregister')
        end
    
        if not isNumber(params[:phonenumber])
            redirect('/showregister')
        end

        # password = params[:password]
        # passwordConfirm = params[:passwordConfirm]
        # username = params[:username]
        # email = params[:email]
        # phonenumber = params[:phonenumber]
        # birthday = params[:birthday]

        if registration(params[:password], params[:passwordConfirm], params[:username], params[:email], params[:phonenumber], params[:birthday])
            
            # passwordDigest = BCrypt::Password.create(password)
            db = db_called("db/database.db")

            # db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, params[:email], params[:phonenumber], params[:birthday]).first
            # result = db.execute("SELECT * FROM users WHERE username = ?", username).first
            # session[:id] = result["id"]

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
        # else
        #     session[:registerError] = true
        #     redirect('/showregister')
        end
    else
        # route = "/post/#{id}/#{session[:id]}/edit"
        redirect('/showregister')
    end  
end

post('/login') do
    if logTime(session[:id])
        username = params[:username]
        password = params[:password]

        if isEmpty(username) || isEmpty(password)
            redirect('/showlogin')
        end

        login(username, password)
    
        # db = db_called("db/database.db")
        # result = db.execute("SELECT * FROM users WHERE username = ?", username).first

        # begin
        #     pwdigest = result["pwdigest"]
        #     id = result["id"]
        
        #     if BCrypt::Password.new(pwdigest) == password
        #         session[:loginError] = false
        #         session[:id] = id
        #         session[:auth] = true
        #         session[:user] = username
        #         redirect('/posts/all')
                
        #     else
        #         #WRONG PASSWORD
        #         session[:loginError] = true
        #         redirect('/showlogin')
        #     end
            
        # rescue => exception
        #     #INVALID USERNAME
        #     session[:loginError] = true
        #     redirect('/showlogin')
            
        # end
    else
        redirect('/showlogin')
    end
end

post('/user/:id/update') do
    credentials = [:email, :phonenumber, :birthday]

    # anyEmpty = false
    # credentials.each do |credential|
    #     anyEmpty = anyEmpty || isEmpty(params[credential])
    # end

    anyEmpty = emptyCredentials(credentials)

    id = params[:id].to_i

    if not isEmail(params[:email])
        route = "/user/#{id}/edit"
        redirect(route)
    end

    if not isNumber(params[:phonenumber])
        route = "/user/#{id}/edit"
        redirect(route)
    end

    if not anyEmpty
        isNotUnique = false
        credentials[0..credentials.length - 2].each do |credential|
            # result = db.execute("SELECT #{credential.to_s} FROM users WHERE id = ?", session[:id]).first
            
            # attribute = attributeSpecifikUsers(credential.to_s)

            # if isUnique(db, "users", credential.to_s, params[credential])
            #     updateAttributeUsers()

            #     # db.execute("UPDATE users SET #{credential.to_s} = ? WHERE id = ?", params[credential], id)
            # elsif attribute[credential.to_s].to_s == params[credential]
            #     isNotUnique = false

            # else
            #     isNotUnique = true
            # end

            uniqueUserUpdate(credential.to_s, params[credential], id)
        end

        db = db_called("db/database.db")

        if not isNotUnique 
            birthday = params[:birthday]
            # db.execute("UPDATE users SET birthday = ? WHERE id = ?", birthday, id)
            updateBirthday(birthday, id)
    
            # db.execute("DELETE FROM user_personality_relation WHERE userid = ?", id)
            deletePersonalityUser(id)

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
            route = "/showprofile/#{id}"
            redirect(route)
        else
            route = "/user/#{id}/edit"
            redirect(route)
        end
    else
        route = "/user/#{id}/edit"
        redirect(route)
    end
end

post('/post/new') do
    id = session[:id]
    title = params[:title]
    text = params[:text]

    postNew(title, text)
    # if not isEmpty(title)
    #     db = db_called("db/database.db")
    #     if isUnique(db, "posts", "title", title)
    #         text = params[:text]
    #         t = Time.now
    #         time = t.strftime("%Y-%m-%d %H:%M")
    #         db.execute("INSERT INTO posts (title, text, creatorid, time) VALUES (?,?,?,?)", title, text, session[:id], time)
    #         redirect('/posts/all')
    #     else
    #         route = "/newpost/#{id}"
    #         redirect(route)
    #     end
    # else
    #     route = "/newpost/#{id}"
    #     redirect(route)
    # end
end

post('/post/:id/update') do
    title = params[:title]
    postid = params[:id].to_i
    userid = session[:id]

    # arrTitle = [title]

    postUpdate(title, postid, userid)


    
    # if not anyEmpty
    #     db = db_called("db/database.db")
    #     result = db.execute("SELECT title FROM posts WHERE creatorid = ? AND id = ?", userid, postid).first

    #     text = params[:text]

    #     if isUnique(db, "posts", "title", title)
    #         # p "text till pots:#{text}"
    #         db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
    #         redirect('/posts/all')
    #     elsif result['title'] == title 
    #         db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
    #         redirect('/posts/all')
    #     else
    #         route = "/post/#{postid}/#{userid}/edit"
    #         redirect(route)
    #     end
    #     # end

    #     # if isUnique(db, "posts", "title", title) || result != title
    #     #     db = db_called("db/database.db")
    #     #     text = params[:text]
    #     #     db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
    #     #     redirect('/posts/all')
    #     # elsif result == title
    #     #     redirect('/posts/all')
    #     # else
    #     #     route = "/post/#{postid}/#{userid}/edit"
    #     #     redirect(route)
    #     # end

    # else
    #     route = "/post/#{postid}/#{userid}/edit"
    #     redirect(route)
    # end
end

post('/post/:postid/:userid/delete') do
    userid = params[:userid].to_i
    postid = params[:postid].to_i

    postDelete(userid, postid)
    # if userid == session[:id]
    #     postid = params[:postid].to_i
    #     db = db_called("db/database.db")
    #     db.execute("DELETE FROM posts WHERE id = ?", postid)
    #     db.execute("DELETE FROM likes WHERE postid = ?", postid)
    #     redirect('/posts/all')
    # else
    #     redirect('/error/401')
    # end
end

post('/post/:postid/:userid/like') do
    userid = params[:userid].to_i
    if userid == session[:id]
        postid = params[:postid].to_i
        # db = db_called("db/database.db")
        # db.execute("INSERT INTO likes (userid,postid) VALUES (?,?)", userid, postid)
        insertLike(userid, postid)

        # if session[:filter] == "Lakes"
        #     redirect('/posts/lakes')
        # elsif session[:filter] == "Woods"
        #     redirect('/posts/woods')
        # elsif session[:filter] == "Sea"
        #     redirect('/posts/sea')
        # elsif session[:filter] == "Mountains"
        #     redirect('/posts/mountains')
        # elsif session[:filter] == "Profil"
        #     redirect('/posts/mountains')
        # else
        #     redirect('/posts/all')
        # end

        filterRoute()
        
    else
        redirect('/error/401')
    end
end

post('/post/:postid/:userid/unlike') do
    userid = params[:userid].to_i
    if userid == session[:id]
        postid = params[:postid].to_i
        # db = db_called("db/database.db")
        # db.execute("DELETE FROM likes WHERE postid = ? AND userid = ?", postid, userid)
        deleteLike(userid, postid)

        # if session[:filter] == "Lakes"
        #     redirect('/posts/lakes')
        # elsif session[:filter] == "Woods"
        #     redirect('/posts/woods')
        # elsif session[:filter] == "Sea"
        #     redirect('/posts/sea')
        # elsif session[:filter] == "Mountains"
        #     redirect('/posts/mountains')
        # else
        #     redirect('/posts/all')
        # end
        filterRoute()
        
    else
        redirect('/error/401')
    end
end