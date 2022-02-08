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

# GET called

get('/') do
    session[:loginError] = false
    session[:registerError] = false
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

get('/posts') do
    db = db_called("db/database.db")
    result = db.execute("SELECT * FROM posts")
    creatorid = db.execute("SELECT DISTINCT
            users.username,
            posts.creatorid
        FROM users
            INNER JOIN posts ON users.id = posts.creatorid")
    slim(:"posts/index", locals:{posts:result, username_posts:creatorid})
end

get('/newpost') do
    slim(:"posts/new")
end

get('/post/:id/edit') do
    id = params[:id].to_i
    db = db_called("db/database.db")
    result = db.execute("SELECT * FROM posts WHERE id = ?", id).first
    slim(:"posts/edit", locals:{post:result})
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
        personality = "hej"

        p "Person: #{personality}"
    
        if password == passwordconfirm
            passwordDigest = BCrypt::Password.create(password)
            db = db_called("db/database.db")

            db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, email, phonenumber, birthday).first
            result = db.execute("SELECT * FROM users WHERE username = ?", username).first
            session[:id] = result["id"]

            db.execute("INSERT INTO category (personality) VALUES (?)", personality).first
            result_2 = db.execute("SELECT id FROM category WHERE personality = ?", personality).first

            db.execute("INSERT INTO user_personality_relation (userid, categoryid) VALUES (?,?)", session[:id], result_2["id"]).first
            session[:auth] = true
            session[:user] = username
            redirect('/posts')
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

    #p "RRRRRRRRR: #{result}"

    begin
        pwdigest = result["pwdigest"]
        id = result["id"]
    
        if BCrypt::Password.new(pwdigest) == password
            session[:loginError] = false
            session[:id] = id
            session[:auth] = true
            session[:user] = username
            redirect('/posts')
            
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

post('/post/new') do
    title = params[:title]
    text = params[:text]
    db = db_called("db/database.db")
    db.execute("INSERT INTO posts (title, text, creatorid) VALUES (?,?,?)", title, text, session[:id]) #.first
    # result = db.execute("SELECT id FROM posts WHERE title = ?", title).first
    # db.execute("INSERT INTO user_posts_relation (userid, postid) VALUES (?,?)", session[:id], result["id"]) #.first
    redirect('/posts')
end

post('/post/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    text = params[:text]
    db = db_called("db/database.db")
    db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, id)
    redirect('/posts')
end

post('/post/:id/delete') do
    id = params[:id].to_i
    db = db_called("db/database.db")
    db.execute("DELETE FROM posts WHERE id = ?", id)
    redirect('/posts')
  end