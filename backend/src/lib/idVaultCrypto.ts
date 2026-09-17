/**
 * idVaultCrypto — pure sealing/keysplit primitives for the identity vault.
 * No env, no DB. The APP imports only sealTo/publicKeyFromB64 (public key only).
 * openSealed/split/combine are used by the OFFLINE CLIs and tests; they are
 * inert without a secret key, which never enters app config, env, or the DB.
 */
import _sodium from 'libsodium-wrappers';
import secrets from 'secrets.js-grempe';

let ready: Promise<void> | null = null;
export function sodiumReady(): Promise<void> {
  if (!ready) ready = _sodium.ready;
  return ready;
}

/** Seal a UTF-8 message to a recipient public key. Anyone with the public key can do this. */
export function sealTo(publicKey: Uint8Array, message: string): Buffer {
  const cipher = _sodium.crypto_box_seal(_sodium.from_string(message), publicKey);
  return Buffer.from(cipher);
}

/** Open a sealed box. Requires the secret key — throws on the wrong key or tampering. */
export function openSealed(publicKey: Uint8Array, secretKey: Uint8Array, sealed: Uint8Array): string {
  const plain = _sodium.crypto_box_seal_open(new Uint8Array(sealed), publicKey, secretKey);
  return _sodium.to_string(plain);
}

export async function generateKeypair(): Promise<{
  publicKeyB64: string; secretKeyHex: string; publicKey: Uint8Array; secretKey: Uint8Array;
}> {
  await sodiumReady();
  const kp = _sodium.crypto_box_keypair();
  return {
    publicKey: kp.publicKey,
    secretKey: kp.privateKey,
    publicKeyB64: _sodium.to_base64(kp.publicKey, _sodium.base64_variants.ORIGINAL),
    secretKeyHex: Buffer.from(kp.privateKey).toString('hex'),
  };
}

export function publicKeyFromB64(b64: string): Uint8Array {
  return _sodium.from_base64(b64, _sodium.base64_variants.ORIGINAL);
}

const SHARES = 4;
const THRESHOLD = 2;

/** Split the 32-byte (64 hex char) secret key into 4 shares; any 2 reconstruct it. */
export function splitSecretKey(secretKeyHex: string): string[] {
  return secrets.share(secretKeyHex, SHARES, THRESHOLD);
}

/** Reconstruct the secret key hex from >= 2 shares. Fewer than 2 yields non-key output. */
export function combineSecretKey(shares: string[]): string {
  return secrets.combine(shares);
}
