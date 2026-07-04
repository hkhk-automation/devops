// JavaScript fail - veebisaidi interaktiivsus

// DOM elementide valimine
const ctaButton = document.getElementById('cta-button');
const contactForm = document.getElementById('contact-form');

// CTA nupu funktsionaalsus
ctaButton.addEventListener('click', function() {
    alert('Tere! Oled valmis alustama?');
    console.log('Kasutaja vajutas CTA nuppu');
});

// Kontaktvormi töötlemine
contactForm.addEventListener('submit', function(e) {
    e.preventDefault(); // Vältib lehe uuesti laadimist
    
    // Võta vormi andmed
    const formData = new FormData(contactForm);
    const name = contactForm.querySelector('input[type="text"]').value;
    const email = contactForm.querySelector('input[type="email"]').value;
    const message = contactForm.querySelector('textarea').value;
    
    // Kontrolli, et kõik väljad on täidetud
    if (name && email && message) {
        alert('Täname! Sinu sõnum on saadetud.');
        console.log('Sõnum saadetud:', { name, email, message });
        
        // Tühjenda vorm
        contactForm.reset();
    } else {
        alert('Palun täida kõik väljad!');
    }
});

// Smooth scrolling menüü linkidele
document.querySelectorAll('nav a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Lihtne animatsioon - fade in efekt
window.addEventListener('load', function() {
    const hero = document.querySelector('.hero');
    hero.style.opacity = '0';
    hero.style.transition = 'opacity 1s ease-in';
    
    setTimeout(() => {
        hero.style.opacity = '1';
    }, 100);
});

// Console log - testimiseks
console.log('JavaScript fail laaditud edukalt!');
