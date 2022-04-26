module Model

    # Attempts to open a new database connection

    # @return [Array], containing all the data from the database
    def db_called(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Attempts to reset sessions
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

    # Attempts to reset sessions
    def restartReg()
        session[:loginError] = false
        session[:auth] = false
    end

    # Attempts to reset sessions
    def restartLogin()
        session[:registerError] = false
        session[:notUnique] = false
        session[:isEmail] = true
        session[:isNumber] = true
        session[:auth] = false
    end

    # Attempts to reset sessions
    def restartPosts()
        session[:notUnique] = false
        session[:empty] = false
        session[:isEmail] = true
        session[:isNumber] = true
    end

    # Attempts to reset sessions
    def restartProfil()
        session[:loginError] = false
        session[:registerError] = false
        session[:like] = false
        session[:empty] = false
        session[:notUnique] = false
        session[:isEmail] = true
        session[:isNumber] = true
    end

    # Attempts to check if the user is authorized

    # @param [Integer] userid, The user ID
    def auth(userid)
        if session[:id] != userid
            redirect("/error/401/")
        end
    end

    # Attempts to verify the inputs uniqueness

    # @param [Hash] db, containing all the data from the database
    # @param [String] table, the table that will be selected 
    # @param [String] attribute, the attribute that will be selected 
    # @param [String] check, the user input

    # @return [Boolean] whether the input is unique or not
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

    # Attempts to verify the credentials uniqueness

    # @param [Array] credentials, the inputform's credentials 

    # @see Model#db_called
    # @see Model#isUnique

    # @return [Boolean] whether the credential is unique or not
    def uniqueCredentials(credentials)
        db = db_called("db/database.db")

        isNotUnique = false
        credentials.each do |credential|
            isNotUnique = isNotUnique || !isUnique(db, "users", credential.to_s, params[credential])
        end
        return isNotUnique
    end

    # Attempts to update the user information

    # @param [String] credential, the inputform's credential 
    # @param [String] calledCredential, the user input 
    # @param [Integer] id, the user ID


    # @see Model#db_called
    # @see Model#attributeSpecifikUsers
    # @see Model#isUnique

    # @return [Boolean] whether the credential is unique or not
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

    # Attempts to check if the inputs are empty

    # @param [String] text, the user input

    # @return [Boolean] whether the input is empyt or not
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

    # Attempts to verify the if the credentials are empty

    # @param [Array] credentials, the inputform's credentials 

    # @see Model#isEmpty

    # @return [Boolean] whether the credential is unique or not
    def emptyCredentials(credentials)
        anyEmpty = false
        credentials.each do |credential|
            anyEmpty = anyEmpty || isEmpty(params[credential])
        end
        return anyEmpty
    end

    # Attempts to check if the inputs contain "@" and "."

    # @param [String] text, the user input

    # @return [Boolean] whether the input is an email or not
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

    # Attempts to check if the inputs cointain only numbers

    # @param [String] number, the user input

    # @return [Boolean] whether the input only cointain numbers
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

    # Attempts to check if too many inputs are recieved in close proximity

    # @return [Boolean] whether the inputs are recieved in close proximity
    def logTime()
        tempTime = Time.now.to_i

        if session[:timeLogged] == nil
            session[:timeLogged] = 0
        end
        difTime = tempTime - session[:timeLogged]

        if difTime < 1.5
            session[:timeLogged] = tempTime
            session[:stress] = true
            return false
        else
            session[:timeLogged] = tempTime
            session[:stress] = false
            return true
        end
    end

    # Attempts to check if the passwords match

    # @param [String] pw1, the first password
    # @param [String] pw2, the second password

    # @return [Boolean] whether the passwords match
    def passwordMatch(pw1, pw2)
        if pw1 == pw2
            return true
        else
            return false
        end
    end

    # Attempts to check if user can register

    # @param [String] password, the password input
    # @param [String] passConfirm, the password confirm input
    # @param [String] username, the user username
    # @param [String] email, the user email
    # @param [String] phonenumber, the user phonenumber
    # @param [String] birthday, the user birthday

    # @see Model#passwordMatch
    # @see Model#db_called
    # @see Model#usersByUsername

    # @return [Boolean] whether the user registration succeeds 
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

    # Attempts to check if user can login

    # @param [String] username, the user username
    # @param [String] password, the user password

    # @see Model#db_called
    # @see Model#usersByUsername
    # @see Model#passwordMatch
    # @see Model#passwordMatch
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

    # Attempts to update user personality

    # @param [String] :woods, value "wood" if box is checked
    # @param [String] :sea, value "sea" if box is checked
    # @param [String] :mountains, value "mountains" if box is checked
    # @param [String] :lakes, value "lakes" if box is checked

    # @see Model#db_called
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

    # Attempts to register user

    # @param [String] anyEmpty, true or false whether the credentials were empty
    # @param [String] isNotUnique, true or false whether the credentials were unique
    # @param [String] :email, the user email
    # @param [String] :phonenumber, the user phonenumber
    # @param [String] :password, the password input
    # @param [String] :passwordConfirm, the password confirm input
    # @param [String] :username, the user username
    # @param [String] :birthday, the user birthday

    # @see Model#isEmail
    # @see Model#isNumber
    # @see Model#authenticationReg
    # @see Model#personalityUpdate
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

                redirect('/posts/all')
            end
        else
            redirect('/showregister')
        end  
    end
    # Attempts to update user profile

    # @param [Integer] userid, the user ID
    # @param [String] anyEmpty, true or false whether the credentials were empty
    # @param [Array] credentials, the inputform's credentials 
    # @param [String] :birthday, the user birthday

    # @see Model#uniqueUserUpdate
    # @see Model#updateBirthday
    # @see Model#deletePersonalityUser
    # @see Model#personalityUpdate
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

    # Finds the information under a specific attribution for a specific user

    # @param [String] credential, the inputform's credential 

    # @see Model#db_called

    # @return [Array] the information under a specific attribution for a specific user
    def attributeSpecifikUsers(credential)
        db = db_called("db/database.db")
        return db.execute("SELECT #{credential} FROM users WHERE id = ?", session[:id]).first
    end

    # Attempts to check what ID the fitler value gives

    # @param [String] filter, the filter value

    # @return [Integer] the ID the filter value gives
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

    # Attempts to check what route the filter gives
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

    # Attempts to insert userid and postid into likes

    # @param [Integer] userid, the user ID
    # @param [Integer] postid, the post ID

    # @see Model#db_called
    def insertLike(userid, postid)
        db = db_called("db/database.db")
        db.execute("INSERT INTO likes (userid,postid) VALUES (?,?)", userid, postid)
    end

    # Attempts to delete userid and postid from likes

    # @param [Integer] userid, the user ID
    # @param [Integer] postid, the post ID

    # @see Model#db_called
    def deleteLike(userid, postid)
        db = db_called("db/database.db")
        db.execute("DELETE FROM likes WHERE postid = ? AND userid = ?", postid, userid)
    end

    # Finds all posts according to the filter value

    # @param [String] filter, the filter value

    # @see Model#db_called
    # @see Model#filter

    # @return [Array] all posts according to the filter value
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

    # Finds one specific post

    # @param [Integer] id, the post ID

    # @see Model#db_called

    # @return [Array] one specific post
    def post(id)
        db = db_called("db/database.db")
        return db.execute("SELECT * FROM posts WHERE id = ?", id).first
    end

    # Finds specific information on user's own posts

    # @param [Integer] id, the user ID

    # @see Model#db_called

    # @return [Array] specific information on user's own posts
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

    # Attempts to create a new post

    # @param [Integer] title, the post title
    # @param [Integer] text, the post text
    # @param [Integer] id, the user ID

    # @see Model#isEmpty
    # @see Model#db_called
    # @see Model#isUnique
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

    # Attempts to update a post

    # @param [Integer] title, the post title
    # @param [Integer] postid, the post ID
    # @param [Integer] userid, the user ID
    # @param [Integer] :text, the post text

    # @see Model#isEmpty
    # @see Model#db_called
    # @see Model#isUnique
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

    # Attempts to delete a post

    # @param [Integer] postid, the post ID
    # @param [Integer] userid, the user ID

    # @see Model#auth
    # @see Model#db_called
    def postDelete(userid, postid)
        auth(userid)
        
        db = db_called("db/database.db")
        db.execute("DELETE FROM posts WHERE id = ?", postid)
        db.execute("DELETE FROM likes WHERE postid = ?", postid)
        redirect('/posts/all')
    end

    # Finds a specific user information by ID

    # @param [Integer] id, the user ID

    # @see Model#db_called

    # @return [Array] specific user information by ID
    def users(id)
        db = db_called("db/database.db")
        return db.execute("SELECT * FROM users WHERE id = ?", id)
    end

    # Finds a specific user information by username

    # @param [Integer] username, the user username

    # @see Model#db_called

    # @return [Array] specific user information by username
    def usersByUsername(username)
        db = db_called("db/database.db")
        return db.execute("SELECT * FROM users WHERE username = ?", username)
    end

    # Finds all usernames and ID of the users

    # @see Model#db_called

    # @return [Array] all usernames and ID of the users
    def usernameAndId()
        db = db_called("db/database.db")
        return db.execute("SELECT username, id FROM users")
    end

    # Finds the personalitys of a specific user

    # @param [Integer] id, the user ID

    # @see Model#db_called

    # @return [Array] the personalitys of a specific user
    def usersPersonality(id)
        db = db_called("db/database.db")

        return db.execute("SELECT
            category.personality
        FROM category
            INNER JOIN user_personality_relation ON  category.id = user_personality_relation.categoryid
        WHERE user_personality_relation.userid = ?", id)
    end

    # Finds the total likes of the client

    # @param [Integer] id, the user ID

    # @see Model#db_called
    def likeCountClient(id)
        db = db_called("db/database.db")
        db.results_as_hash = false

        session[:likeCount] = db.execute("SELECT COUNT
            (likes.postid)
        FROM likes
            INNER JOIN posts ON posts.id = likes.postid
        WHERE creatorid = ?", id).first.first
    end

    # Finds the total likes of a specific user

    # @param [Integer] id, the user ID

    # @see Model#db_called

    # @return [Integer] the total likes of a specific user
    def likeCountTotal(id)
        db = db_called("db/database.db")
        db.results_as_hash = false

        return db.execute("SELECT COUNT
            (likes.postid)
        FROM likes
            INNER JOIN posts ON posts.id = likes.postid
        WHERE creatorid = ?", id).first.first
    end

    # Finds all the postids from the "likes" table

    # @see Model#db_called

    # @return [Array] all the postids from the "likes" table
    def likeCountPost()
        db = db_called("db/database.db")
        db.results_as_hash = false

        return db.execute("SELECT postid FROM likes")
    end

    # Finds the posts that a specific user liked

    # @see Model#db_called

    # @return [Array] the posts that a specific user liked
    def isLiked()
        db = db_called("db/database.db")
        db.results_as_hash = false

        isLikeArr = db.execute("SELECT postid FROM likes WHERE userid = ?", session[:id])
        tempArr = isLikeArr.map do |el|
            el = el.first
        end

        return tempArr
    end

    # Updates the user birthday

    # @param [Integer] birthday, the user birthday
    # @param [Integer] id, the user ID

    # @see Model#db_called
    def updateBirthday(birthday, id)
        db = db_called("db/database.db")
        db.execute("UPDATE users SET birthday = ? WHERE id = ?", birthday, id)
    end

    # Deletes the user personalitys from the "user_personality_relation" table

    # @param [Integer] id, the user ID

    # @see Model#db_called
    def deletePersonalityUser(id)
        db = db_called("db/database.db")
        db.execute("DELETE FROM user_personality_relation WHERE userid = ?", id)
    end
end