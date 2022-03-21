let hearts = document.querySelectorAll('.likeHeart')
let formsHearts = document.querySelectorAll('.likeForm')

hearts.forEach((heart, index) => {
    
    heart.addEventListener('click', () => {
        // console.log('click')
        formsHearts[index].submit()
    })
})

let deleteBtn = document.querySelectorAll('.deleteButton')
let formsDelete = document.querySelectorAll('.modalContent')


deleteBtn.forEach((eachdelete, index) => {
    const modalDiv = document.querySelectorAll('#modalDiv')[index]
    
    eachdelete.addEventListener('click', () => {
        deleteBtn[index].style.display = 'none'
        modalDiv.style.display = 'block'

        let cancelBtn = document.getElementsByClassName('cancelBtn')[index]
        let confirmDelete = document.getElementsByClassName('confirmDelete')[index]

        cancelBtn.addEventListener('click', () => {
            modalDiv.style.display = 'none'
            deleteBtn[index].style.display = 'block'
        })

        confirmDelete.addEventListener('click', () => {
            formsDelete[index].submit()
        })
    })
})