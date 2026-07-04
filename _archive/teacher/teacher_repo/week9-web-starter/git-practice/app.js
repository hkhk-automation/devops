// JavaScript fail Git praktika jaoks

// Funktsioonid, mida saate testida ja muuta

function hello() {
    console.log('Hello Git!');
    return 'Hello from Git!';
}

function calculateSum(a, b) {
    return a + b;
}

function createUser(name, email) {
    return {
        name: name,
        email: email,
        createdAt: new Date()
    };
}

// Ekspordi funktsioonid
module.exports = {
    hello,
    calculateSum,
    createUser
};

// Testi funktsioone
if (typeof window === 'undefined') {
    // Node.js keskkonnas
    console.log('Node.js keskkonnas');
    console.log(hello());
    console.log(calculateSum(5, 3));
    console.log(createUser('Mari', 'mari@example.com'));
} else {
    // Brauseri keskkonnas
    console.log('Brauseri keskkonnas');
    window.hello = hello;
    window.calculateSum = calculateSum;
    window.createUser = createUser;
}
