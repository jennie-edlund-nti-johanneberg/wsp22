let hearts = document.querySelectorAll('.likeHeart')
let forms = document.querySelectorAll('.likeForm')

async function fetchData(){
    let like = await fetch('http://localhost:4567/api/data')
    console.log(like)
}

hearts.forEach((heart, index) => {
    fetchData()
    heart.addEventListener('click', () => {
        forms[index].submit()

        // if (heart.src === "http://localhost:4567/img/heart_3.png") {
        //     // Like
        //     heart.src = "./img/heart_red.png"
        // } else{
        //     // Unlike
        //     heart.src = "./img/heart_3.png"
        // }

        // let like = fetch('http://localhost:4567/data')
        // console.log(like)

        // fetch('http://localhost:4567/data')
        //     .then(response=>response.text())
        //     .then(data=>console.log(data))

        if (like === true) {
            // Like
            heart.src = "./img/heart_red.png"
        } else{
            // Unlike
            heart.src = "./img/heart_3.png"
        }
        
    })
})



