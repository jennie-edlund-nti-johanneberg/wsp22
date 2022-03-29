require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

#Functions

def db_called(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def unique(text, column, table)
    db = db_called("db/database.db")
    result = db.execute("SELECT #{column} FROM #{table}")
    temparr = []
    result.each do |title|
        temparr << title['title']
    end

    if not temparr.include?(text)
        session[:unique] = false
        return true
    else
        session[:unique] = true
        return false
    end
end

def notempty(text)
    if text == ""
        session[:empty] = true
        return false
    else
        session[:empty] = false
        return true
    end
end

# GET called

get('/') do
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    slim(:start)
end

get('/showregister') do
    session[:loginError] = false
    slim(:register)
end

get('/showlogin') do
    session[:registerError] = false
    slim(:login)
end

get('/logout') do
    session[:auth] = false
    slim(:start)
end

get('/posts/:filter') do
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
    # begin
        username = params[:username]
        password = params[:password]
        passwordconfirm = params[:passwordconfirm]
        email = params[:email]
        phonenumber = params[:phonenumber]
        birthday = params[:birthday]
    
        if password == passwordconfirm
            passwordDigest = BCrypt::Password.create(password)
            db = db_called("db/database.db")

            db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, email, phonenumber, birthday).first
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
            redirect('/posts/all')
        else
            session[:registerError] = true
            redirect('/showregister')
        end
        
    # rescue => exception
    #     session[:registerError] = true
    #     redirect('/showregister')
        
    # end
end

post('/login') do
    username = params[:username]
    password = params[:password]
  
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
    id = params[:id].to_i
    email = params[:email]
    phonenumber = params[:phonenumber]
    birthday = params[:birthday]

    db = db_called("db/database.db")
    db.execute("UPDATE users SET email = ?, phonenumber = ?, birthday = ? WHERE id = ?", email, phonenumber, birthday, id)
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

    route = "/showprofile/#{id}"

    redirect(route)
end

post('/post/new') do
    title = params[:title]
    if notempty(title) and unique(title, "title", "posts")
        text = params[:text]
        t = Time.now
        time = t.strftime("%Y-%m-%d %H:%M")
        db = db_called("db/database.db")
        db.execute("INSERT INTO posts (title, text, creatorid, time) VALUES (?,?,?,?)", title, text, session[:id], time) #.first
        # result = db.execute("SELECT id FROM posts WHERE title = ?", title).first
        # db.execute("INSERT INTO user_posts_relation (userid, postid) VALUES (?,?)", session[:id], result["id"]) #.first
        redirect('/posts/all')
    else
        route = "/newpost/#{session[:id]}"
        redirect(route)
    end
end

post('/post/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    text = params[:text]
    db = db_called("db/database.db")
    db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, id)
    redirect('/posts/all')
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