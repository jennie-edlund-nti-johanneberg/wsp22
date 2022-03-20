let hearts = document.querySelectorAll('.likeHeart')
let forms = document.querySelectorAll('.likeForm')

hearts.forEach((heart, index) => {
    
    heart.addEventListener('click', () => {
        // console.log('click')
        forms[index].submit()
    })
})


