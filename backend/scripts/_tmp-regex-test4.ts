const word = 'marissa';
const re = new RegExp(`\b${word}\b`);
console.log('source regex:', re.source);  // .source shows the raw pattern
console.log('full regex:', re.toString());
console.log('test marissa:', re.test('marissa'));
console.log('test marissa roy:', re.test('marissa roy'));
console.log('test xmarissax:', re.test('xmarissax'));

// Compared to compiled literal:
const re2 = /\bmarissa\b/;
console.log('\nliteral source:', re2.source);
console.log('literal test marissa:', re2.test('marissa'));
console.log('literal test marissa roy:', re2.test('marissa roy'));
console.log('literal test xmarissax:', re2.test('xmarissax'));
