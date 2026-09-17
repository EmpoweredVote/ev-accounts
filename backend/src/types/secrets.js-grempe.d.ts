declare module 'secrets.js-grempe' {
  export function share(secretHex: string, numShares: number, threshold: number, padLength?: number): string[];
  export function combine(shares: string[]): string;
  export function random(bits: number): string;
  export function str2hex(str: string): string;
  export function hex2str(hex: string): string;
}
