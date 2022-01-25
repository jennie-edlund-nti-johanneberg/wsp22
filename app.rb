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
    passwordConfirm = params[:passwordConfirm]
  
    if password == passwordConfirm
        passwordDigest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)", username, passwordDigest).first
        session[:auth] = true
        redirect('/posts')
    else
        session[:registerError] = true
        redirect('/showregister')
    end
  end