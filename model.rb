#Database called
def db_called(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end


#Restat sessoins
def resetStart()
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
    session[:auth] = false
end

def restartReg()
    session[:loginError] = false
    session[:auth] = false
end

def restartLogin()
    session[:registerError] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
    session[:auth] = false
end

def restartPosts()
    session[:notUnique] = false
    session[:empty] = false
    session[:isEmail] = true
    session[:isNumber] = true
end

def restartProfil()
    session[:loginError] = false
    session[:registerError] = false
    session[:like] = false
    session[:empty] = false
    session[:notUnique] = false
    session[:isEmail] = true
    session[:isNumber] = true
end


#Verification
def auth(userid)
    if session[:id] != userid
        redirect("/error/401/")
    end
end

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
    if text == nil
        session[:empty] = true
        return true
    elsif text.scan(/ /).empty? == false || text == ""
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
    if text == nil
        session[:isEmail] = true
        return true
    elsif text.include?('@') && text.include?('.')
        session[:isEmail] = true
        return true
    else
        session[:isEmail] = false
        return false
    end
end

def isNumber(number)
    if number != nil
        answer = number.scan(/\D/).empty?
    else
        answer == false
    end

    if answer
        session[:isNumber] = true
        return true
    else
        session[:isNumber] = false
        return false
    end
end

def logTime()
    tempTime = Time.now.to_i

    if session[:timeLogged] == nil
        session[:timeLogged] = 0
    end
    difTime = tempTime - session[:timeLogged]

    if difTime < 3
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

def authenticationReg(password, passConfirm, username, email, phonenumber, birthday)
    if passwordMatch(password, passConfirm)
        passwordDigest = BCrypt::Password.create(password)
        db = db_called("db/database.db")
        db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, email, phonenumber, birthday).first

        user = usersByUsername(username).first
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

def authenticationLogin(username, password)
    db = db_called("db/database.db")
    user = usersByUsername(username).first

    begin
        pwdigest = user["pwdigest"]
        id = user["id"]
    
        if passwordMatch(BCrypt::Password.new(pwdigest), password)
            session[:loginError] = false
            session[:id] = id
            session[:auth] = true
            session[:user] = username
            redirect('/posts/all')
            
        else
            session[:loginError] = true
            redirect('/showlogin')
        end
        
    rescue => exception
        session[:loginError] = true
        redirect('/showlogin')
    end
end

#Functions
def personalityUpdate()
    db = db_called("db/database.db")

    woods = params[:woods]
    sea = params[:sea]
    mountains = params[:mountains]
    lakes = params[:lakes]

    if woods == "woods"
        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 1)
    end  

    if sea == "sea"
        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 2)
    end

    if mountains == "mountains"
        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 3)
    end

    if lakes == "lakes"
        db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 4)
    end 
end 

def registration(anyEmpty, isNotUnique)
    if not anyEmpty and not isNotUnique

        if not isEmail(params[:email])
            redirect('/showregister')
        end
    
        if not isNumber(params[:phonenumber])
            redirect('/showregister')
        end

        if authenticationReg(params[:password], params[:passwordConfirm], params[:username], params[:email], params[:phonenumber], params[:birthday])
            personalityUpdate()
            # db = db_called("db/database.db")
            # begin
            #     woods = params[:woods]
            #     if woods == "woods"
            #         db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 1)
            #     end  
            # end

            # begin
            #     sea = params[:sea]
            #     if sea == "sea"
            #         db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 2)
            #     end
            # end

            # begin
            #     mountains = params[:mountains]
            #     if mountains == "mountains"
            #         db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 3)
            #     end
            # end

            # begin
            #     lakes = params[:lakes]
            #     if lakes == "lakes"
            #         db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", session[:id], 4)
            #     end 
            # end

            redirect('/posts/all')
        end
    else
        redirect('/showregister')
    end  
end

def upadteProfil(userid, anyEmpty, credentials)
    if not anyEmpty
        isNotUnique = false
        credentials[0..credentials.length - 2].each do |credential|
            uniqueUserUpdate(credential.to_s, params[credential], userid)
        end

        if not isNotUnique 
            birthday = params[:birthday]
            updateBirthday(birthday, userid)
            deletePersonalityUser(userid)
            personalityUpdate()
            
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
end

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

def postNew(title, text, id)
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
    auth(userid)
    
    db = db_called("db/database.db")
    db.execute("DELETE FROM posts WHERE id = ?", postid)
    db.execute("DELETE FROM likes WHERE postid = ?", postid)
    redirect('/posts/all')
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