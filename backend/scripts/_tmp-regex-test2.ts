// Test word boundary in regex
const word = 'marissa';
const pattern = '\b' + word + '\b';
console.log('pattern:', pattern);
const re = new RegExp(pattern);
console.log('regex:', re.toString());
console.log('test "marissa roy":', re.test('marissa roy'));
console.log('test "xmarissax":', re.test('xmarissax'));

// Also test with template literal
const re2 = new RegExp(`\b${word}\b`);
console.log('re2:', re2.toString());
console.log('re2 test:', re2.test('marissa roy'));
