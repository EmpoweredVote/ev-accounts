// Correct way to use \b in RegExp constructor
const word = 'marissa';

// Method 1: double backslash in template (should give \b in regex)  
const re1 = new RegExp('\\b' + word + '\\b');
console.log('re1 (\\b):', re1.toString(), 'test:', re1.test('marissa roy'));

// Method 2: literal slash-b
const re2 = /\bmarissa\b/;
console.log('re2 (literal):', re2.toString(), 'test:', re2.test('marissa roy'));

// Method 3: use string with actual \b 
const wbPattern = String.raw`\b` + word + String.raw`\b`;
console.log('pattern raw:', wbPattern);
const re3 = new RegExp(wbPattern);
console.log('re3 (String.raw):', re3.toString(), 'test:', re3.test('marissa roy'));

// So the existing code in the OTHER script (discover-la-metro) uses the same pattern
// Let me check how it works there
const last = 'roy';
const first = 'marissa'; 
const lastRegex = new RegExp(`\b${last}\b`);
const firstRegex = new RegExp(`\b${first}\b`);
console.log('\nlastRegex:', lastRegex.toString());
console.log('firstRegex:', firstRegex.toString());
console.log('test "marissa roy":', lastRegex.test('marissa roy') && firstRegex.test('marissa roy'));
