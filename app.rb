require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions


# GET called

get('/') do
    slim(:start)
end

get('/showregister') do
    slim(:register)
end

get('/showlogin') do
    slim(:login)
end

get('/posts') do
    slim(:"posts/index")
end

# POST called

post('/register') do
    username = params[:username]
    password = params[:password]
    passwordconfirm = params[:passwordconfirm]
    email = params[:email]
    phonenumber = params[:phonenumber]
    birthday = params[:birthday]
  
    if password == passwordconfirm
        passwordDigest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, email, phonenumber, birthday).first
        session[:auth] = true
        session[:user] = username
        redirect('/posts')
    else
        session[:registerError] = true
        redirect('/showregister')
    end
end

post('/login') do
    username = params[:username]
    password = params[:password]
  
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    result = db.execute('SELECT * FROM users WHERE username = ?', username).first

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
            session[:loginError]=true
            redirect('/showlogin')
        end
        
    rescue => exception
        #INVALID USERNAME
        session[:loginError] = true
        redirect('/showlogin')
        
    end
end
