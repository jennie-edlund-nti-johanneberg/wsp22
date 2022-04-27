module Model

    # Attempts to open a new database connection

    # @return [Array] containing all the data from the database
    def db_called(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Attempts to check if the user is authorized

    # @param [Integer] sessionid, The user ID from sessions
    # @param [Integer] userid, The user ID from params

    # @return [Boolean] whether sessionid and userid is equal
    def auth(sessionid, userid)
        if sessionid != userid
            return false
        else
            return true
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
            return true
        else
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
        attribute = attributeSpecifikUsers(credential, id)

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
            return true
        elsif text.scan(/ /).empty? == false || text == ""
            return true
        else
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
            return false
        elsif text.include?('@') && text.include?('.')
            return true
        else
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
            answer = false
        end

        if answer
            return true
        else
            return false
        end
    end

    # Attempts to check if too many inputs are recieved in close proximity

    # @param [String] latestTempTime, the latest logged time

    # @return [Hash] whether the inputs are recieved in close proximity
    #   * :result [Boolean] whether the inputs are recieved in close proximity
    #   * :time [Integer] the new latest logged time
    def logTime(latestTempTime)
        tempTime = Time.now.to_i

        difTime = tempTime - latestTempTime

        if difTime < 1.5
            tempHash = {result: false, time: tempTime}
            return tempHash
        else
            tempHash = {result: true, time: tempTime}
            return tempHash
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

    # Attempts to register user

    # @param [String] password, the password input
    # @param [String] passConfirm, the password confirm input
    # @param [String] username, the user username
    # @param [String] email, the user email
    # @param [String] phonenumber, the user phonenumber
    # @param [String] birthday, the user birthday

    # @see Model#passwordMatch
    # @see Model#db_called

    # @return [Boolean] whether the user registration succeeds 
    def authenticationReg(password, passConfirm, username, email, phonenumber, birthday)
        if passwordMatch(password, passConfirm)
            passwordDigest = BCrypt::Password.create(password)
            db = db_called("db/database.db")
            db.execute("INSERT INTO users (username, pwdigest, email, phonenumber, birthday) VALUES (?,?,?,?,?)", username, passwordDigest, email, phonenumber, birthday).first
            return true
        else
            return false
        end
    end

    # Attempts to check if user can login

    # @param [String] username, the user username
    # @param [String] password, the user password
    # @param [Hash] user, all information of a specific user

    # @see Model#db_called
    # @see Model#passwordMatch

    # @return [Boolean] whether the user can login or not
    def authenticationLogin(username, password, user)
        db = db_called("db/database.db")

        begin
            pwdigest = user["pwdigest"]
            if passwordMatch(BCrypt::Password.new(pwdigest), password)
                return true
            else
                return false

            end
        rescue => exception
            return false
        end
    end

    # Attempts to update user personality

    # @param [String] userid, the user ID
    # @param [String] :woods, value "wood" if box is checked
    # @param [String] :sea, value "sea" if box is checked
    # @param [String] :mountains, value "mountains" if box is checked
    # @param [String] :lakes, value "lakes" if box is checked

    # @see Model#db_called
    def personalityUpdate(userid)
        db = db_called("db/database.db")

        woods = params[:woods]
        sea = params[:sea]
        mountains = params[:mountains]
        lakes = params[:lakes]

        if woods == "woods"
            db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", userid, 1)
        end  

        if sea == "sea"
            db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", userid, 2)
        end

        if mountains == "mountains"
            db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", userid, 3)
        end

        if lakes == "lakes"
            db.execute("INSERT INTO user_personality_relation (userid,categoryid) VALUES (?,?)", userid, 4)
        end 
    end 

    # Attempts to update user profile

    # @param [Integer] userid, the user ID
    # @param [Array] credentials, the inputform's credentials 
    # @param [String] :birthday, the user birthday

    # @see Model#uniqueUserUpdate
    # @see Model#updateBirthday
    # @see Model#deletePersonalityUser
    # @see Model#personalityUpdate

    # @return [Boolean] whether the user profile updates
    def updateProfile(userid, credentials)

        isNotUnique = false
        credentials[0..credentials.length - 2].each do |credential|
            isNotUnique = uniqueUserUpdate(credential.to_s, params[credential], userid)
        end

        if not isNotUnique 
            birthday = params[:birthday]
            updateBirthday(birthday, userid)
            deletePersonalityUser(userid)
            personalityUpdate(userid)
            return true
        else
            return false
        end
    end

    # Finds the information under a specific attribution for a specific user

    # @param [String] credential, the inputform's credential 
    # @param [String] id, the user ID

    # @see Model#db_called

    # @return [Array] the information under a specific attribution for a specific user
    def attributeSpecifikUsers(credential, id)
        db = db_called("db/database.db")
        return db.execute("SELECT #{credential} FROM users WHERE id = ?", id).first
    end

    # Attempts to check what ID the fitler value gives

    # @param [String] filter, the filter value

    # @return [Integer] the ID the filter value gives
    def filter(filter)
        if filter == "woods"
            return 1
        elsif filter == "sea"
            return 2
        elsif filter == "mountains"
            return 3
        elsif filter == "lakes"
            return 4
        else
            return "all"
        end
    end

    # Attempts to check what route the filter gives

    # @param [String] filter, the filter value

    # @return [Integer] the ID the filter value gives
    def filterRoute(filter)
        if filter == "Woods"
            return 1
        elsif filter == "Sea"
            return 2
        elsif filter == "Mountains"
            return 3
        elsif filter == "Lakes"
            return 4
        elsif filter == "All Posts"
            return "all"
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

    # @return [Hash] whether the inputs are recieved in close proximity
    #   * :filterId [Integer] the ID the filter gives
    #   * :posts [Array] all information about posts according to the filterID
    def posts(filter)
        db = db_called("db/database.db")
        filterId = filter(filter)

        if filterId == "all"
            posts = db.execute("SELECT * FROM posts")

        else
            posts = db.execute("SELECT * FROM posts WHERE creatorid IN (
                SELECT DISTINCT
                    user_personality_relation.userid
                FROM user_personality_relation
                    INNER JOIN category ON user_personality_relation.categoryid = ?)", filterId)
        end

        tempHash = {filterId: filterId, posts:posts}
        return tempHash
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

    # @see Model#db_called
    # @see Model#isUnique

    # @return [Boolean] whether a new post was created
    def postNew(title, text, id)
        db = db_called("db/database.db")
        if isUnique(db, "posts", "title", title)
            t = Time.now
            time = t.strftime("%Y-%m-%d %H:%M")
            db.execute("INSERT INTO posts (title, text, creatorid, time) VALUES (?,?,?,?)", title, text, id, time)
            return true
        else
            return false
        end
    end

    # Attempts to update a post

    # @param [Integer] title, the post title
    # @param [Integer] postid, the post ID
    # @param [Integer] userid, the user ID
    # @param [Integer] :text, the post text

    # @see Model#db_called
    # @see Model#isUnique

    # @return [Boolean] whether a post was updated
    def postUpdate(title, postid, userid)
        db = db_called("db/database.db")
        result = db.execute("SELECT title FROM posts WHERE creatorid = ? AND id = ?", userid, postid).first

        text = params[:text]

        if isUnique(db, "posts", "title", title)
            db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
            return true
        elsif result['title'] == title 
            db.execute("UPDATE posts SET title = ?, text = ? WHERE id = ?", title, text, postid)
            return true
        else
            return false
        end
    end

    # Attempts to delete a post

    # @param [Integer] postid, the post ID

    # @see Model#db_called
    def postDelete(postid)        
        db = db_called("db/database.db")
        db.execute("DELETE FROM posts WHERE id = ?", postid)
        db.execute("DELETE FROM likes WHERE postid = ?", postid)
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

    # @param [Integer] userid, the user ID

    # @see Model#db_called

    # @return [Array] the posts that a specific user liked
    def isLiked(userid)
        db = db_called("db/database.db")
        db.results_as_hash = false

        isLikeArr = db.execute("SELECT postid FROM likes WHERE userid = ?", userid)
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