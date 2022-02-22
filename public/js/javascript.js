

let hearts = document.querySelectorAll('.likeHeart')
let forms = document.querySelectorAll('.likeForm')

hearts.forEach((heart, index) => {
    heart.addEventListener('click', () => {
        forms[index].submit()

        if(heart.src === "http://localhost:4567/img/heart.png"){
            // Like
            heart.src = "./img/heart_red.png"
        }else{
            // Unlike
            heart.src = "./img/heart.png"

        }
    })

})

