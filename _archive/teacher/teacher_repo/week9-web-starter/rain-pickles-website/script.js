// Õpetaja Rain's Kurgi Counter
let kurgiCount = 0;

function soolaKurgi() {
    kurgiCount++;
    document.getElementById('kurgi-counter').textContent = kurgiCount;
    
    // Add fun animation
    const counter = document.getElementById('kurgi-counter');
    counter.style.transform = 'scale(1.5)';
    counter.style.color = '#FF1493';
    setTimeout(() => {
        counter.style.transform = 'scale(1)';
        counter.style.color = '#8B008B';
    }, 200);
    
    // Show random Rain quote
    const quotes = [
        "🥒 Hea kurgi!",
        "🧂 Soola veel!",
        "😄 Rain on uhke!",
        "🏆 Eesti parim kurgi!"
    ];
    alert(quotes[Math.floor(Math.random() * quotes.length)]);
}

// Add click event to images
document.addEventListener('DOMContentLoaded', function() {
    const images = document.querySelectorAll('img');
    images.forEach(img => {
        img.addEventListener('click', soolaKurgi);
    });
});
