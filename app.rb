require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative 'model'

enable :sessions

#Functions

def db_called(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end


def isUnique(db, table, attribute, check)
    query = "SELECT * FROM #{table} WHERE #{attribute} = ?"
    result = db.execute(query, check)
    # p result
    p result.length
    if result.length == 0
        session[:notUnique] = false
        p true
        return true
    else
        session[:notUnique] = true
        p false
        return false
    end
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

# GET called

get('/') do
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    slim(:start)
end

get('/showregister') do
    session[:loginError] = false
    slim(:register)
end

get('/showlogin') do
    session[:notUnique] = false
    session[:registerError] = false
    slim(:login)
end

get('/logout') do
    session[:auth] = false
    slim(:start)
end

get('/posts/:filter') do
    session[:notUnique] = false
    session[:empty] = false
    id = session[:id]
    filter = params[:filter]

    if filter == "woods"
        session[:filter] = "Woods"
        filterid = 1
    elsif filter == "sea"
        session[:filter] = "Sea"
        filterid = 2
    elsif filter == "mountains"
        session[:filter] = "Mountains"
        filterid = 3
    else
        session[:filter] = "Lakes"
        filterid = 4
    end

    db = db_called("db/database.db")

    if filter == "all"
        session[:filter] = "All Posts"
        result = db.execute("SELECT * FROM posts")
    else
        result = db.execute("SELECT * FROM posts WHERE creatorid IN (
            SELECT DISTINCT
                user_personality_relation.userid
            FROM user_personality_relation
                INNER JOIN category ON user_personality_relation.categoryid = ?)", filterid)
    end

    creatorid = db.execute("SELECT DISTINCT
        users.username,
        posts.creatorid
    FROM users
        INNER JOIN posts ON users.id = posts.creatorid")

    db.results_as_hash = false
    session[:likeCount] = db.execute("SELECT COUNT
            (likes.postid)
        FROM likes
            INNER JOIN posts ON posts.id = likes.postid
        WHERE creatorid = ?", id).first.first

    likeCountPost = db.execute("SELECT postid FROM likes")
    likeArr = db.execute("SELECT postid FROM likes WHERE userid = ?", session[:id])
    newArr = likeArr.map do |el|
        el = el.first
    end
    
    slim(:"posts/index", locals:{posts:result, username_posts:creatorid, likes:newArr, likeCountPost:likeCountPost})
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
        db = db_called("db/database.db")
        result = db.execute("SELECT * FROM posts WHERE id = ?", postid).first
        slim(:"posts/edit", locals:{post:result})
    else
        redirect('/error/401')
    end
end

get('/showprofile/:id') do
    id = params[:id].to_i
    db = db_called("db/database.db")
    result = db.execute("SELECT * FROM users WHERE id = ?", id)

    result_2 = db.execute("SELECT
            posts.id,
            posts.title,
            posts.text,
            posts.creatorid,
            posts.time
        FROM posts
            INNER JOIN users ON users.id = posts.creatorid
        WHERE users.id = ?", id)

    result_3 = db.execute("SELECT
            category.personality
        FROM category
            INNER JOIN user_personality_relation ON  category.id = user_personality_relation.categoryid
        WHERE user_personality_relation.userid = ?", id)

    creatorid = db.execute("SELECT DISTINCT
        users.username,
        posts.creatorid
    FROM users
        INNER JOIN posts ON users.id = posts.creatorid")

    db.results_as_hash = false
    likeCountTotal = db.execute("SELECT COUNT
        (likes.postid)
    FROM likes
        INNER JOIN posts ON posts.id = likes.postid
    WHERE creatorid = ?", id).first.first

    likeCountPost = db.execute("SELECT postid FROM likes")

    likeArr = db.execute("SELECT postid FROM likes WHERE userid = ?", session[:id])
    newArr = likeArr.map do |el|
        el = el.first
    end

    slim(:"users/show", locals:{userinfo:result, posts:result_2, personality:result_3, likesCount:likeCountTotal, username_posts:creatorid, likeCountPost:likeCountPost, likes:newArr})
end

get('/user/:id/edit') do
    id = params[:id].to_i
    if session[:id] == id
        db = db_called("db/database.db")
        result = db.execute("SELECT * FROM users WHERE id = ?", id).first
        checked = db.execute("SELECT categoryid FROM user_personality_relation WHERE userid = ?", id)
        slim(:"users/edit", locals:{user:result, checked:checked})
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
    db = db_called("db/database.db")
    credentials = [:username, :password, :passwordconfirm, :email, :phonenumber, :birthday]

    anyEmpty = false
    credentials.each do |credential|
        p "empty"
        anyEmpty = anyEmpty || isEmpty(params[credential])
        p "#{anyEmpty}"
    end

    credentials = [:username, :pwdigest, :email, :phonenumber]

    isNotUnique = false
    credentials.each do |credential|
        p "yes"
        isNotUnique = isNotUnique || !isUnique(db, "users", credential.to_s, params[credential])
        p "#{isNotUnique}"
    end

    password = params[:password]
    passwordconfirm = params[:passwordconfirm]

    if not anyEmpty and not isNotUnique
        if password == passwordconfirm
            username = params[:username]
            passwordDigest = BCrypt::Password.create(password)
            db = db_called("db/database.db")

            db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, params[:email], params[:phonenumber], params[:birthday]).first
            result = db.execute("SELECT * FROM users WHERE username = ?", username).first
            session[:id] = result["id"]

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

            session[:auth] = true
            session[:user] = username
            session[:empty] = false
            session[:notUnique] = false
            redirect('/posts/all')
        else
            session[:registerError] = true
            redirect('/showregister')
        end

    else
        # route = "/post/#{id}/#{session[:id]}/edit"
        redirect('/showregister')
    end  
end

post('/login') do
    username = params[:username]
    password = params[:password]

    if isEmpty(username) || isEmpty(password)
        redirect('/showlogin')
    end
  
    db = db_called("db/database.db")
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first

    begin
        pwdigest = result["pwdigest"]
        id = result["id"]
    
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

post('/user/:id/update') do
    credentials = [:email, :phonenumber, :birthday]
    db = db_called("db/database.db")
    id = params[:id].to_i

    anyEmpty = false
    credentials.each do |credential|
        anyEmpty = anyEmpty || isEmpty(params[credential])
    end

    if not anyEmpty
        isNotUnique = false
        credentials[0..credentials.length - 2].each do |credential|
            result = db.execute("SELECT #{credential.to_s} FROM users WHERE id = ?", session[:id])

            if isUnique(db, "users", credential.to_s, params[credential]) || result != params[credential]
                db.execute("UPDATE users SET #{credential.to_s} = ? WHERE id = ?", params[credential], id)
            else
                isNotUnique = true
            end
        end

        if not isNotUnique 
            birthday = params[:birthday]
            db.execute("UPDATE users SET birthday = ? WHERE id = ?", birthday, id)
    
            db.execute("DELETE FROM user_personality_relation WHERE userid = ?", id)
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
    credentials = [:title, :text]
    id = session[:id]

    anyEmpty = false
    credentials.each do |credential|
        anyEmpty = anyEmpty || isEmpty(params[credential])
    end


    if not anyEmpty
        title = params[:title]
        db = db_called("db/database.db")
        if isUnique(db, "posts", "title", title)
            text = params[:text]
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

post('/post/:id/update') do
    title = params[:title]

    arrTitle = [title]

    if not isEmpty(title)
        anyEmpty = false
    else
        anyEmpty = true
    end 

    # credentials.each do |credential|
    #     anyEmpty = anyEmpty || isEmpty(params[credential])
    # end

    # p "anyEmpty: #{anyEmpty}"

    postid = params[:id].to_i
    userid = session[:id]
    
    if not anyEmpty
        db = db_called("db/database.db")
        # result = db.execute("SELECT title FROM posts WHERE creatorid = ? AND id = ?", userid, postid).first
 

        # arrTitle.each do |title|
        result = db.execute("SELECT title FROM posts WHERE creatorid = ? AND id = ?", userid, postid).first

        p "result: #{result}"
        p "#{result.class}"
        p "får ut: #{result['title']}"
        p "title: #{title}"
        p "#{title.class}"

        if isUnique(db, "posts", "title", title)
            text = params[:text]
            db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
            redirect('/posts/all')
        elsif result['title'] == title
            redirect('/posts/all')
        else
            route = "/post/#{postid}/#{userid}/edit"
            redirect(route)
        end
        # end

        # if isUnique(db, "posts", "title", title) || result != title
        #     db = db_called("db/database.db")
        #     text = params[:text]
        #     db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
        #     redirect('/posts/all')
        # elsif result == title
        #     redirect('/posts/all')
        # else
        #     route = "/post/#{postid}/#{userid}/edit"
        #     redirect(route)
        # end

    else
        route = "/post/#{postid}/#{userid}/edit"
        redirect(route)
    end
end

post('/post/:postid/:userid/delete') do
    userid = params[:userid].to_i
    if userid == session[:id]
        postid = params[:postid].to_i
        db = db_called("db/database.db")
        db.execute("DELETE FROM posts WHERE id = ?", postid)
        db.execute("DELETE FROM likes WHERE postid = ?", postid)
        redirect('/posts/all')
    else
        redirect('/error/401')
    end
end

post('/post/:postid/:userid/like') do
    userid = params[:userid].to_i
    if userid == session[:id]
        postid = params[:postid].to_i
        db = db_called("db/database.db")
        db.execute("INSERT INTO likes (userid,postid) VALUES (?,?)", userid, postid)

        if session[:filter] == "Lakes"
            redirect('/posts/lakes')
        elsif session[:filter] == "Woods"
            redirect('/posts/woods')
        elsif session[:filter] == "Sea"
            redirect('/posts/sea')
        elsif session[:filter] == "Mountains"
            redirect('/posts/mountains')
        elsif session[:filter] == "Profil"
            redirect('/posts/mountains')
        else
            redirect('/posts/all')
        end
        
    else
        redirect('/error/401')
    end
end

post('/post/:postid/:userid/unlike') do
    userid = params[:userid].to_i
    if userid == session[:id]
        postid = params[:postid].to_i
        db = db_called("db/database.db")
        db.execute("DELETE FROM likes WHERE postid = ? AND userid = ?", postid, userid)

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
        
    else
        redirect('/error/401')
    end
end