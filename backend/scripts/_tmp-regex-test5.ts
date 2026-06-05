const word = 'marissa';

// Method: string concatenation with '\b'
const re1 = new RegExp('\b' + word + '\b');
console.log('String concat \b:', re1.source, '| test:', re1.test('marissa roy'));

// Method: '\\b' in source
const re2 = new RegExp('\\b' + word + '\\b');
console.log('String concat \\b:', re2.source, '| test:', re2.test('marissa roy'));

// The literal regex we want is /\bword\b/
// .source of that is: \bword\b
// So we need the string to contain: \bword\b
// In JS string literals: '\b' = \b (backslash + b) -- this is what we want
// Let's verify:
const s1 = '\b';
const s2 = '\b';
console.log('s1 charCodes:', [...s1].map(c => c.charCodeAt(0)));  // should be [92, 98]
console.log('s2 charCodes:', [...s2].map(c => c.charCodeAt(0)));  // should be [8] (backspace)
